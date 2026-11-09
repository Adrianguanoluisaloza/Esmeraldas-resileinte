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
        id: 'alb-01',
        nombre: 'Coliseo Nubia Villacís (Albergue Temporal)',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9615,
        longitud: -79.6522,
        telefono: '911',
        capacidad: 250,
        ocupacion: 110,
      ),
      PuntoServicioModel(
        id: 'alb-02',
        nombre: 'Unidad Educativa 5 de Agosto',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9540,
        longitud: -79.6580,
        telefono: '911',
        capacidad: 180,
        ocupacion: 155,
      ),
      PuntoServicioModel(
        id: 'cs-01',
        nombre: 'Hospital Delfina Torres de Concha',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9285,
        longitud: -79.6641,
        telefono: '911',
        capacidad: 120,
        ocupacion: 95,
      ),
    ];
    await guardarDirectorioPuntosServicio(puntosSemilla);
  }
}
