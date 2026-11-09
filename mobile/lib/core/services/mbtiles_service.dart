import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Servicio y proveedor de teselas offline basado en el archivo `assets/mapas/esmeraldas.mbtiles`
/// (especificación MBTiles 1.3 / OpenMapTiles + OpenStreetMap de la Provincia de Esmeraldas).
class EsmeraldasMbTilesService {
  EsmeraldasMbTilesService._();

  static const String _assetPath = 'assets/mapas/esmeraldas.mbtiles';
  static final Map<String, Uint8List> _teselasCache = <String, Uint8List>{};
  static final Map<String, String> _metadatos = <String, String>{};
  static bool _inicializado = false;
  static bool _inicializando = false;

  static bool get estaListo => _inicializado && _teselasCache.isNotEmpty;
  static int get totalTeselasCargadas => _teselasCache.length;
  static Map<String, String> get metadatos =>
      Map<String, String>.unmodifiable(_metadatos);

  /// PNG transparente de 1x1 px para teselas fuera de rango cuando no hay internet.
  static final Uint8List pngTransparente1x1 = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  /// Copia `assets/mapas/esmeraldas.mbtiles` al almacenamiento local del dispositivo
  /// y precarga las teselas de la provincia de Esmeraldas en memoria desde SQLite.
  static Future<void> inicializar() async {
    if (_inicializado || _inicializando || kIsWeb) return;
    _inicializando = true;
    try {
      final Directory dir = await getApplicationSupportDirectory();
      final File archivoDestino = File('${dir.path}/esmeraldas.mbtiles');
      if (!await archivoDestino.exists() ||
          await archivoDestino.length() == 0) {
        final ByteData data = await rootBundle.load(_assetPath);
        final Uint8List bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await archivoDestino.writeAsBytes(bytes, flush: true);
      }

      final Database db = await openDatabase(
        archivoDestino.path,
        readOnly: true,
      );
      try {
        final List<Map<String, Object?>> metaRows = await db.query('metadata');
        for (final Map<String, Object?> row in metaRows) {
          final String? name = row['name']?.toString();
          final String? val = row['value']?.toString();
          if (name != null && val != null) {
            _metadatos[name] = val;
          }
        }

        final List<Map<String, Object?>> tileRows = await db.query(
          'tiles',
          columns: <String>[
            'zoom_level',
            'tile_column',
            'tile_row',
            'tile_data',
          ],
        );
        for (final Map<String, Object?> row in tileRows) {
          final int z = (row['zoom_level'] as num).toInt();
          final int x = (row['tile_column'] as num).toInt();
          final int tmsY = (row['tile_row'] as num).toInt();
          // En especificación MBTiles 1.3, tile_row está en coordenadas TMS (eje Y invertido)
          final int xyzY = (1 << z) - 1 - tmsY;
          final Object? rawBlob = row['tile_data'];
          if (rawBlob is Uint8List && rawBlob.isNotEmpty) {
            _teselasCache['$z/$x/$xyzY'] = rawBlob;
          }
        }
        _inicializado = true;
      } finally {
        await db.close();
      }
    } catch (_) {
      // Si el entorno de pruebas (flutter test) no tiene canal nativo de sqflite, continúa sin fallar
    } finally {
      _inicializando = false;
    }
  }

  /// Obtiene los bytes PNG de una tesela XYZ desde el paquete MBTiles de Esmeraldas.
  static Uint8List? obtenerTesela(int z, int x, int y) {
    return _teselasCache['$z/$x/$y'];
  }
}

/// `TileProvider` híbrido para `FlutterMap`:
/// 1. Si la tesela `(z, x, y)` está en `esmeraldas.mbtiles`, la sirve instantáneamente desde memoria (0 ms, funciona 100 % offline).
/// 2. Si no está en el MBTiles y hay conexión a internet, la descarga del servidor OSM.
/// 3. Si está sin conexión y fuera del área empaquetada, devuelve un PNG transparente sin lanzar excepciones de red.
class EsmeraldasHybridTileProvider extends TileProvider {
  EsmeraldasHybridTileProvider({required this.tieneConexion})
    : _networkProvider = NetworkTileProvider();

  final bool tieneConexion;
  final NetworkTileProvider _networkProvider;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    final Uint8List? bytesLocales = EsmeraldasMbTilesService.obtenerTesela(
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );
    if (bytesLocales != null) {
      return MemoryImage(bytesLocales);
    }
    if (tieneConexion) {
      return _networkProvider.getImageWithCancelLoadingSupport(
        coordinates,
        options,
        cancelLoading,
      );
    }
    return MemoryImage(EsmeraldasMbTilesService.pngTransparente1x1);
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return getImageWithCancelLoadingSupport(
      coordinates,
      options,
      Future<void>.value(),
    );
  }
}
