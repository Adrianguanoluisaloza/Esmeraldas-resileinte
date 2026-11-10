// Listas únicas (enums) alineadas con `contrato/openapi.yaml`
// y `estructura-esmeraldas-resiliente.md`.

enum RolUsuario {
  ciudadano('ciudadano'),
  operador911('operador_911'),
  bomberos('bomberos'),
  policia('policia'),
  admin('admin');

  const RolUsuario(this.valor);
  final String valor;

  static RolUsuario fromValor(String valor) => RolUsuario.values.firstWhere(
    (e) => e.valor == valor,
    orElse: () => RolUsuario.ciudadano,
  );
}

enum TipoIncidente {
  inundacion('inundacion', 'Inundación'),
  deslizamiento('deslizamiento', 'Deslizamiento'),
  viaBloqueada('via_bloqueada', 'Vía bloqueada'),
  personasAtrapadas('personas_atrapadas', 'Personas atrapadas'),
  danoVivienda('dano_vivienda', 'Daño en vivienda'),
  otro('otro', 'Otro');

  const TipoIncidente(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoIncidente fromValor(String valor) => TipoIncidente.values
      .firstWhere((e) => e.valor == valor, orElse: () => TipoIncidente.otro);
}

enum EstadoReporte {
  pendiente('pendiente', 'Pendiente'),
  enProceso('en_proceso', 'En proceso'),
  atendido('atendido', 'Atendido'),
  descartado('descartado', 'Descartado');

  const EstadoReporte(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static EstadoReporte fromValor(String valor) =>
      EstadoReporte.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => EstadoReporte.pendiente,
      );
}

enum GravedadIncidente {
  baja('baja', 'Baja'),
  media('media', 'Media'),
  alta('alta', 'Alta'),
  critica('critica', 'Crítica');

  const GravedadIncidente(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static GravedadIncidente fromValor(String valor) =>
      GravedadIncidente.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => GravedadIncidente.media,
      );
}

enum TipoPuntoServicio {
  albergue('albergue', 'Albergue'),
  centroSalud('centro_salud', 'Centro de salud');

  const TipoPuntoServicio(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoPuntoServicio fromValor(String valor) =>
      TipoPuntoServicio.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => TipoPuntoServicio.albergue,
      );
}

enum NecesidadFamiliar {
  agua('agua', 'Agua'),
  alimentos('alimentos', 'Alimentos'),
  medicinas('medicinas', 'Medicinas'),
  rescate('rescate', 'Rescate');

  const NecesidadFamiliar(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static NecesidadFamiliar fromValor(String valor) =>
      NecesidadFamiliar.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => NecesidadFamiliar.agua,
      );
}

/// Estados del reporte dentro de la cola local (Hive).
/// Flujo: pendiente -> enviando_datos -> datos_enviados -> enviando_foto -> enviado
/// o error cuando el servidor rechaza el reporte con 4xx.
enum EstadoColaReporte {
  pendiente('pendiente', 'Guardado: se enviará al volver internet'),
  enviandoDatos('enviando_datos', 'Enviando datos...'),
  datosEnviados('datos_enviados', 'Datos enviados (falta foto)'),
  enviandoFoto('enviando_foto', 'Subiendo foto...'),
  enviado('enviado', 'Enviado'),
  error('error', 'Error de validación');

  const EstadoColaReporte(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  bool get estaSincronizado => this == EstadoColaReporte.enviado;

  bool get estaEnviando =>
      this == EstadoColaReporte.enviandoDatos ||
      this == EstadoColaReporte.enviandoFoto;

  static EstadoColaReporte fromValor(String valor) =>
      EstadoColaReporte.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => EstadoColaReporte.pendiente,
      );
}
