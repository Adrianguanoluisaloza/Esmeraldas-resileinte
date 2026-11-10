import '../../core/enums/app_enums.dart';

/// Modelo de albergue o centro de salud almacenado en la caja local del directorio (Hive).
class PuntoServicioModel {
  const PuntoServicioModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.capacidad,
    required this.ocupacion,
    this.activo = true,
    this.pasoBloqueado = false,
  });

  final String id;
  final String nombre;
  final TipoPuntoServicio tipo;
  final double latitud;
  final double longitud;
  final String telefono;
  final int capacidad;
  final int ocupacion;
  final bool activo;

  /// El tramo recto hasta el punto cruza una vía bloqueada (PostGIS, `paso_bloqueado`).
  final bool pasoBloqueado;

  int get cuposDisponibles => (capacidad - ocupacion).clamp(0, capacidad);

  /// Porcentaje de ocupación entre 0.0 y 1.0 para colorear en verde, ámbar o rojo.
  double get ratioOcupacion =>
      capacidad <= 0 ? 1.0 : (ocupacion / capacidad).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'tipo': tipo.valor,
      'latitud': latitud,
      'longitud': longitud,
      'telefono': telefono,
      'capacidad': capacidad,
      'ocupacion': ocupacion,
      'activo': activo,
      'paso_bloqueado': pasoBloqueado,
    };
  }

  factory PuntoServicioModel.fromMap(Map<dynamic, dynamic> map) {
    return PuntoServicioModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      tipo: TipoPuntoServicio.fromValor(map['tipo'] as String? ?? 'albergue'),
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      telefono: map['telefono'] as String? ?? '',
      capacidad: map['capacidad'] as int? ?? 0,
      ocupacion: map['ocupacion'] as int? ?? 0,
      activo: map['activo'] as bool? ?? true,
      pasoBloqueado: map['paso_bloqueado'] as bool? ?? false,
    );
  }
}
