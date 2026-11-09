import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Resultado de capturar y comprimir una foto de evidencia en el dispositivo.
class FotoCapturada {
  const FotoCapturada({
    required this.rutaLocal,
    required this.tamanoBytes,
    this.bytesEnMemoria,
  });

  /// Ruta del archivo JPEG comprimido en la carpeta de documentos de la app (fuera de Hive).
  final String rutaLocal;

  /// Tamaño final en bytes tras la compresión (1280 px máx, calidad 75%).
  final int tamanoBytes;

  /// Bytes en memoria (usado en Web o para previsualización inmediata).
  final Uint8List? bytesEnMemoria;

  String get etiquetaTamano {
    final int kb = (tamanoBytes / 1024).round().clamp(1, 99999);
    return '$kb KB';
  }
}

/// Excepción legible cuando el usuario rechaza el permiso de cámara/galería o falla el hardware.
class PermisoCamaraException implements Exception {
  const PermisoCamaraException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Servicio encargado de pedir permiso de cámara/galería al sistema operativo,
/// capturar la fotografía, comprimirla a máx 1280 px (calidad 75%, ~200-400 KB)
/// y guardarla en la carpeta de documentos de la aplicación (fuera de Hive).
class PhotoCaptureService {
  PhotoCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Almacén temporal de bytes para Web (donde no existe sistema de archivos `dart:io`).
  static final Map<String, Uint8List> _bytesWebPorRuta = <String, Uint8List>{};

  static Uint8List? obtenerBytesEnMemoria(String ruta) =>
      _bytesWebPorRuta[ruta];

  static void limpiarBytesEnMemoria(String ruta) {
    _bytesWebPorRuta.remove(ruta);
  }

  /// Abre la cámara o galería del celular, gestionando los permisos nativos de Android/iOS,
  /// comprime la imagen a JPEG (1280 px máx, calidad 75%) y la persiste fuera de Hive.
  /// Retorna `null` si el usuario canceló la cámara sin tomar foto.
  Future<FotoCapturada?> capturarYComprimir({
    required ImageSource origen,
  }) async {
    try {
      final XFile? archivoCapturado = await _picker.pickImage(
        source: origen,
        maxWidth: AppConfig.photoMaxDimensionPx.toDouble(),
        maxHeight: AppConfig.photoMaxDimensionPx.toDouble(),
        imageQuality: AppConfig.photoCompressQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (archivoCapturado == null) {
        return null; // El usuario cerró la cámara/galería sin elegir foto
      }

      final Uint8List bytesOriginales = await archivoCapturado.readAsBytes();

      if (kIsWeb) {
        final String rutaVirtual =
            'web_fotos/evidencia_${DateTime.now().millisecondsSinceEpoch}.jpg';
        _bytesWebPorRuta[rutaVirtual] = bytesOriginales;
        return FotoCapturada(
          rutaLocal: rutaVirtual,
          tamanoBytes: bytesOriginales.length,
          bytesEnMemoria: bytesOriginales,
        );
      }

      // En Android/iOS: guardar en carpeta privada de documentos de la app (fuera de Hive)
      final Directory dirDocs = await getApplicationDocumentsDirectory();
      final Directory dirFotos = Directory('${dirDocs.path}/fotos_reportes');
      if (!await dirFotos.exists()) {
        await dirFotos.create(recursive: true);
      }

      final String rutaDestino =
          '${dirFotos.path}/evidencia_${DateTime.now().millisecondsSinceEpoch}.jpg';

      Uint8List bytesFinales = bytesOriginales;
      try {
        final XFile? comprimido = await FlutterImageCompress.compressAndGetFile(
          archivoCapturado.path,
          rutaDestino,
          minWidth: AppConfig.photoMaxDimensionPx,
          minHeight: AppConfig.photoMaxDimensionPx,
          quality: AppConfig.photoCompressQuality,
          format: CompressFormat.jpeg,
        );
        if (comprimido != null) {
          bytesFinales = await comprimido.readAsBytes();
          return FotoCapturada(
            rutaLocal: comprimido.path,
            tamanoBytes: bytesFinales.length,
            bytesEnMemoria: bytesFinales,
          );
        }
      } catch (_) {
        // Si el compresor nativo falla en algún dispositivo, usamos la imagen ya redimensionada por ImagePicker
      }

      final File archivoLocal = File(rutaDestino);
      await archivoLocal.writeAsBytes(bytesFinales, flush: true);

      return FotoCapturada(
        rutaLocal: archivoLocal.path,
        tamanoBytes: bytesFinales.length,
        bytesEnMemoria: bytesFinales,
      );
    } on PlatformException catch (e) {
      final String codigo = e.code.toLowerCase();
      if (codigo.contains('camera_access_denied') ||
          codigo.contains('photo_access_denied') ||
          codigo.contains('permission')) {
        throw const PermisoCamaraException(
          'Permiso de cámara denegado. Actívalo en los Ajustes del celular para tomar la foto.',
        );
      }
      if (codigo.contains('no_available_camera')) {
        throw const PermisoCamaraException(
          'Este dispositivo no tiene cámara disponible. Puedes elegir una imagen de la galería.',
        );
      }
      throw PermisoCamaraException(
        'No se pudo abrir la cámara (${e.message ?? e.code}).',
      );
    }
  }
}

