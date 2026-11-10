import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/enums/app_enums.dart';
import '../adapters/hive_adapters.dart';
import '../../../albergues/data/models/punto_servicio_model.dart';
import '../models/reporte_cola_model.dart';

/// Contrato del repositorio de la cola offline y directorio local.
/// Regla de oro: ninguna pantalla ni servicio habla con Hive directamente;
/// todo acceso pasa por esta única clase.
abstract interface class ColaReportesRepository {
  Future<void> inicializar();

  Future<void> encolarReporte(ReporteColaModel reporte);

  Future<List<ReporteColaModel>> obtenerTodosLosReportes();

  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio({
    bool ignorarEspera = false,
  });

  Future<void> actualizarEstadoReporte({
    required String id,
    required EstadoColaReporte nuevoEstado,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  });

  Future<void> eliminarReporte(String id);

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
  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio({
    bool ignorarEspera = false,
  }) async {
    final DateTime ahora = DateTime.now().toUtc();
    return _cajaCola.values.where((reporte) {
      if (reporte.estadoCola == EstadoColaReporte.enviado) {
        return false;
      }
      if (!ignorarEspera && reporte.estadoCola == EstadoColaReporte.error) {
        return false;
      }
      if (!ignorarEspera &&
          reporte.proximoIntentoUtc != null &&
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
  Future<void> eliminarReporte(String id) async {
    await _cajaCola.delete(id);
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
}
