import '../../../../core/enums/app_enums.dart';
import '../entities/analisis.dart';

/// Indicadores y asistencia humanitaria del COE. Solo ECU 911 y administrador:
/// la API responde 403 a los demás roles.
abstract interface class AnalisisRepository {
  Future<ResumenCoe> resumen();

  Future<List<SectorPrioridad>> prioridadSectores();

  Future<List<NecesidadPendiente>> necesidadesPendientes();

  Future<List<ItemInventario>> inventario();

  /// Descuenta del inventario. Falla si el reporte no pidió esa necesidad o no hay stock.
  Future<void> registrarEntrega({
    required String reporteId,
    required NecesidadFamiliar necesidad,
    required int cantidad,
    String? nota,
  });
}
