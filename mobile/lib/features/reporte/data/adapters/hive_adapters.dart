import 'package:hive_ce/hive.dart';

import '../../../albergues/data/models/punto_servicio_model.dart';
import '../models/reporte_cola_model.dart';

/// Adaptador Hive CE para [ReporteColaModel].
class ReporteColaAdapter extends TypeAdapter<ReporteColaModel> {
  @override
  final int typeId = 1;

  @override
  ReporteColaModel read(BinaryReader reader) {
    final Map<dynamic, dynamic> map = reader.readMap();
    return ReporteColaModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, ReporteColaModel obj) {
    writer.writeMap(obj.toMap());
  }
}

/// Adaptador Hive CE para [PuntoServicioModel].
class PuntoServicioAdapter extends TypeAdapter<PuntoServicioModel> {
  @override
  final int typeId = 2;

  @override
  PuntoServicioModel read(BinaryReader reader) {
    final Map<dynamic, dynamic> map = reader.readMap();
    return PuntoServicioModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, PuntoServicioModel obj) {
    writer.writeMap(obj.toMap());
  }
}
