import 'package:uuid/uuid.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/location/location_service.dart';
import '../../../../data/models/reporte_cola_model.dart';
import '../../../../data/repositories/cola_reportes_repository.dart';

/// Datos capturados en el formulario del ciudadano para crear un reporte offline.
class DatosNuevoReporte {
  const DatosNuevoReporte({
    required this.tipo,
    required this.descripcion,
    required this.gravedad,
    required this.coordenada,
    required this.rutaFotoLocal,
    this.personasAfectadas = 0,
    this.ninos = 0,
    this.adultosMayores = 0,
    this.necesidades = const <NecesidadFamiliar>[],
  });

  final TipoIncidente tipo;
  final String descripcion;
  final GravedadIncidente gravedad;
  final CoordenadaCapturada coordenada;
  final String rutaFotoLocal;
  final int personasAfectadas;
  final int ninos;
  final int adultosMayores;
  final List<NecesidadFamiliar> necesidades;
}

/// Caso de uso para guardar el reporte en la cola local sin depender de internet ni del mapa.
class CrearReporteOfflineUseCase {
  CrearReporteOfflineUseCase({required this.colaRepository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final ColaReportesRepository colaRepository;
  final Uuid _uuid;

  Future<ReporteColaModel> ejecutar(DatosNuevoReporte datos) async {
    final ReporteColaModel reporte = ReporteColaModel(
      id: _uuid.v4(),
      tipo: datos.tipo,
      descripcion: datos.descripcion.trim(),
      gravedad: datos.gravedad,
      latitud: datos.coordenada.latitud,
      longitud: datos.coordenada.longitud,
      precisionM: datos.coordenada.precisionMetros,
      ubicacionAproximada: datos.coordenada.esAproximada,
      capturadoEnUtc: DateTime.now().toUtc(),
      rutaFotoLocal: datos.rutaFotoLocal,
      personasAfectadas: datos.personasAfectadas,
      ninos: datos.ninos,
      adultosMayores: datos.adultosMayores,
      necesidades: datos.necesidades,
      estadoCola: EstadoColaReporte.pendiente,
    );

    await colaRepository.encolarReporte(reporte);
    return reporte;
  }
}
