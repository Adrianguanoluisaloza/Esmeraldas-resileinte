import '../../../../core/enums/app_enums.dart';

/// Modelo de un reporte ciudadano almacenado en la cola local (Hive).
/// La foto NO se almacena dentro de Hive; solo se guarda [rutaFotoLocal].
class ReporteColaModel {
  const ReporteColaModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.gravedad,
    required this.latitud,
    required this.longitud,
    required this.precisionM,
    required this.ubicacionAproximada,
    required this.capturadoEnUtc,
    required this.rutaFotoLocal,
    this.personasAfectadas = 0,
    this.ninos = 0,
    this.adultosMayores = 0,
    this.necesidades = const <NecesidadFamiliar>[],
    this.estadoCola = EstadoColaReporte.pendiente,
    this.intentos = 0,
    this.proximoIntentoUtc,
    this.mensajeError,
  });

  final String id; // UUID v4 generado en el celular
  final TipoIncidente tipo;
  final String descripcion;
  final GravedadIncidente gravedad;
  final double latitud;
  final double longitud;
  final double precisionM;
  final bool ubicacionAproximada;
  final DateTime capturadoEnUtc;
  final String rutaFotoLocal;

  // Bloque opcional de familia afectada
  final int personasAfectadas;
  final int ninos;
  final int adultosMayores;
  final List<NecesidadFamiliar> necesidades;

  // Metadatos de sincronización de la cola
  final EstadoColaReporte estadoCola;
  final int intentos;
  final DateTime? proximoIntentoUtc;
  final String? mensajeError;

  ReporteColaModel copyWith({
    EstadoColaReporte? estadoCola,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  }) {
    return ReporteColaModel(
      id: id,
      tipo: tipo,
      descripcion: descripcion,
      gravedad: gravedad,
      latitud: latitud,
      longitud: longitud,
      precisionM: precisionM,
      ubicacionAproximada: ubicacionAproximada,
      capturadoEnUtc: capturadoEnUtc,
      rutaFotoLocal: rutaFotoLocal ?? this.rutaFotoLocal,
      personasAfectadas: personasAfectadas,
      ninos: ninos,
      adultosMayores: adultosMayores,
      necesidades: necesidades,
      estadoCola: estadoCola ?? this.estadoCola,
      intentos: intentos ?? this.intentos,
      proximoIntentoUtc: proximoIntentoUtc ?? this.proximoIntentoUtc,
      mensajeError: mensajeError,
    );
  }

  /// Convierte los datos livianos al formato esperado por `POST /reportes` (`contrato/openapi.yaml`).
  Map<String, dynamic> toApiPayload() {
    final bool coordValida =
        latitud >= -0.5 &&
        latitud <= 1.6 &&
        longitud >= -80.3 &&
        longitud <= -78.4;
    final double lat = coordValida ? latitud : 0.9592;
    final double lon = coordValida ? longitud : -79.6539;
    final String descLimpia = descripcion.trim();
    final String descFinal = descLimpia.length >= 3
        ? descLimpia
        : '${tipo.etiqueta} (${gravedad.etiqueta}) en Esmeraldas (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
    final int minPersonas = ninos + adultosMayores;
    final int totalPersonas = personasAfectadas < minPersonas
        ? minPersonas
        : personasAfectadas;

    return <String, dynamic>{
      'id': id,
      'tipo': tipo.valor,
      'descripcion': descFinal,
      'gravedad': gravedad.valor,
      'latitud': lat,
      'longitud': lon,
      'precision_m': precisionM.clamp(0.0, 100000.0),
      'ubicacion_aproximada': ubicacionAproximada || !coordValida,
      'capturado_en': capturadoEnUtc.toUtc().toIso8601String(),
      'personas_afectadas': totalPersonas,
      'ninos': ninos,
      'adultos_mayores': adultosMayores,
      'necesidades': necesidades.map((n) => n.valor).toSet().toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tipo': tipo.valor,
      'descripcion': descripcion,
      'gravedad': gravedad.valor,
      'latitud': latitud,
      'longitud': longitud,
      'precisionM': precisionM,
      'ubicacionAproximada': ubicacionAproximada,
      'capturadoEnUtc': capturadoEnUtc.toUtc().toIso8601String(),
      'rutaFotoLocal': rutaFotoLocal,
      'personasAfectadas': personasAfectadas,
      'ninos': ninos,
      'adultosMayores': adultosMayores,
      'necesidades': necesidades.map((n) => n.valor).toList(),
      'estadoCola': estadoCola.valor,
      'intentos': intentos,
      'proximoIntentoUtc': proximoIntentoUtc?.toUtc().toIso8601String(),
      'mensajeError': mensajeError,
    };
  }

  factory ReporteColaModel.fromMap(Map<dynamic, dynamic> map) {
    final List<dynamic> rawNecesidades =
        (map['necesidades'] as List<dynamic>?) ?? const <dynamic>[];
    return ReporteColaModel(
      id: map['id'] as String,
      tipo: TipoIncidente.fromValor(map['tipo'] as String? ?? 'otro'),
      descripcion: map['descripcion'] as String? ?? '',
      gravedad: GravedadIncidente.fromValor(
        map['gravedad'] as String? ?? 'media',
      ),
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      precisionM: (map['precisionM'] as num).toDouble(),
      ubicacionAproximada: map['ubicacionAproximada'] as bool? ?? false,
      capturadoEnUtc: DateTime.parse(map['capturadoEnUtc'] as String).toUtc(),
      rutaFotoLocal: map['rutaFotoLocal'] as String? ?? '',
      personasAfectadas: map['personasAfectadas'] as int? ?? 0,
      ninos: map['ninos'] as int? ?? 0,
      adultosMayores: map['adultosMayores'] as int? ?? 0,
      necesidades: rawNecesidades
          .map((e) => NecesidadFamiliar.fromValor(e.toString()))
          .toList(),
      estadoCola: EstadoColaReporte.fromValor(
        map['estadoCola'] as String? ?? 'pendiente',
      ),
      intentos: map['intentos'] as int? ?? 0,
      proximoIntentoUtc: map['proximoIntentoUtc'] != null
          ? DateTime.parse(map['proximoIntentoUtc'] as String).toUtc()
          : null,
      mensajeError: map['mensajeError'] as String?,
    );
  }
}
