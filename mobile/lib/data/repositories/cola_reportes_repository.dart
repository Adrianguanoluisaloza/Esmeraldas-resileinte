import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../core/enums/app_enums.dart';
import '../adapters/hive_adapters.dart';
import '../models/punto_servicio_model.dart';
import '../models/reporte_cola_model.dart';

/// Contrato del repositorio de la cola offline y directorio local.
/// Regla de oro: ninguna pantalla ni servicio habla con Hive directamente;
/// todo acceso pasa por esta única clase.
abstract interface class ColaReportesRepository {
  Future<void> inicializar();

  Future<void> encolarReporte(ReporteColaModel reporte);

  Future<List<ReporteColaModel>> obtenerTodosLosReportes();

  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio();

  Future<void> actualizarEstadoReporte({
    required String id,
    required EstadoColaReporte nuevoEstado,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  });

  Future<List<PuntoServicioModel>> obtenerDirectorioPuntosServicio();

  Future<void> guardarDirectorioPuntosServicio(List<PuntoServicioModel> puntos);
}

/// Implementación única respaldada por `hive_ce`.
/// Si en el futuro se migra a SQLite, solo cambia este archivo.
class HiveColaReportesRepository implements ColaReportesRepository {
  static const String _nombreCajaCola = 'cola_reportes_box';
  static const String _nombreCajaDirectorio = 'directorio_puntos_servicio_box';

  bool _inicializado = false;
  late Box<ReporteColaModel> _cajaCola;
  late Box<PuntoServicioModel> _cajaDirectorio;

  @override
  Future<void> inicializar() async {
    if (_inicializado) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ReporteColaAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PuntoServicioAdapter());
    }

    _cajaCola = await Hive.openBox<ReporteColaModel>(_nombreCajaCola);
    _cajaDirectorio = await Hive.openBox<PuntoServicioModel>(
      _nombreCajaDirectorio,
    );

    if (_cajaDirectorio.isEmpty) {
      await _sembrarDirectorioInicial();
    }

    _inicializado = true;
  }

  @override
  Future<void> encolarReporte(ReporteColaModel reporte) async {
    await _cajaCola.put(reporte.id, reporte);
  }

  @override
  Future<List<ReporteColaModel>> obtenerTodosLosReportes() async {
    final List<ReporteColaModel> lista = _cajaCola.values.toList();
    lista.sort((a, b) => b.capturadoEnUtc.compareTo(a.capturadoEnUtc));
    return lista;
  }

  @override
  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio() async {
    final DateTime ahora = DateTime.now().toUtc();
    return _cajaCola.values.where((reporte) {
      if (reporte.estadoCola == EstadoColaReporte.enviado ||
          reporte.estadoCola == EstadoColaReporte.error) {
        return false;
      }
      if (reporte.proximoIntentoUtc != null &&
          reporte.proximoIntentoUtc!.isAfter(ahora)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> actualizarEstadoReporte({
    required String id,
    required EstadoColaReporte nuevoEstado,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  }) async {
    final ReporteColaModel? actual = _cajaCola.get(id);
    if (actual == null) return;

    final ReporteColaModel actualizado = actual.copyWith(
      estadoCola: nuevoEstado,
      intentos: intentos,
      proximoIntentoUtc: proximoIntentoUtc,
      mensajeError: mensajeError,
      rutaFotoLocal: rutaFotoLocal,
    );
    await _cajaCola.put(id, actualizado);
  }

  @override
  Future<List<PuntoServicioModel>> obtenerDirectorioPuntosServicio() async {
    return _cajaDirectorio.values.where((p) => p.activo).toList();
  }

  @override
  Future<void> guardarDirectorioPuntosServicio(
    List<PuntoServicioModel> puntos,
  ) async {
    await _cajaDirectorio.clear();
    for (final PuntoServicioModel punto in puntos) {
      await _cajaDirectorio.put(punto.id, punto);
    }
  }

  Future<void> _sembrarDirectorioInicial() async {
    const List<PuntoServicioModel> puntosSemilla = <PuntoServicioModel>[
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000001',
        nombre: 'Albergue temporal UTLVTE',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9515,
        longitud: -79.6732,
        telefono: '911',
        capacidad: 120,
        ocupacion: 112,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000002',
        nombre: 'Coliseo Nubia Villacís',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9635,
        longitud: -79.6542,
        telefono: '911',
        capacidad: 200,
        ocupacion: 70,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000003',
        nombre: 'Unidad educativa Las Palmas',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9880,
        longitud: -79.6470,
        telefono: '911',
        capacidad: 90,
        ocupacion: 20,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000004',
        nombre: 'Hospital Delfina Torres de Concha',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9428,
        longitud: -79.6812,
        telefono: '911',
        capacidad: 150,
        ocupacion: 138,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000005',
        nombre: 'Centro de salud Las Palmas',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9902,
        longitud: -79.6455,
        telefono: '911',
        capacidad: 40,
        ocupacion: 22,
      ),
    ];
    await guardarDirectorioPuntosServicio(puntosSemilla);
  }
}
