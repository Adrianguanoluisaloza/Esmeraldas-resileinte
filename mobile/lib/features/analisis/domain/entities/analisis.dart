import '../../../../core/enums/app_enums.dart';

/// Indicadores generales del COE (`GET /estadisticas`).
class ResumenCoe {
  const ResumenCoe({
    required this.totalReportes,
    required this.pendientes,
    required this.enProceso,
    required this.atendidos,
    required this.criticos,
    required this.personasAfectadas,
    required this.ninos,
    required this.adultosMayores,
    required this.viasBloqueadas,
    required this.alberguesDisponibles,
    required this.necesidades,
  });

  final int totalReportes;
  final int pendientes;
  final int enProceso;
  final int atendidos;
  final int criticos;
  final int personasAfectadas;
  final int ninos;
  final int adultosMayores;
  final int viasBloqueadas;
  final int alberguesDisponibles;
  final Map<NecesidadFamiliar, int> necesidades;
}

/// Sector ordenado por prioridad (`GET /estadisticas/recurrencia`).
class SectorPrioridad {
  const SectorPrioridad({
    required this.sector,
    required this.cantidad,
    required this.abiertos,
    required this.personasAfectadas,
    required this.gravedadPromedio,
    required this.puntaje,
  });

  final String sector;
  final int cantidad;
  final int abiertos;
  final int personasAfectadas;
  final GravedadIncidente gravedadPromedio;
  final num puntaje;
}

/// Necesidad de una familia que todavía no se entrega (`GET /asistencia/pendientes`).
class NecesidadPendiente {
  const NecesidadPendiente({
    required this.reporteId,
    required this.necesidad,
    required this.sector,
    required this.personas,
    required this.gravedad,
    required this.prioridad,
  });

  final String reporteId;
  final NecesidadFamiliar necesidad;
  final String? sector;
  final int personas;
  final GravedadIncidente gravedad;
  final num prioridad;
}

/// Existencias de un suministro (`GET /asistencia/inventario`).
class ItemInventario {
  const ItemInventario({
    required this.necesidad,
    required this.cantidad,
    required this.unidad,
  });

  final NecesidadFamiliar necesidad;
  final int cantidad;
  final String unidad;
}
