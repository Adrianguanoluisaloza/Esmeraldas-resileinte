import '../../../core/enums/app_enums.dart';

/// Sugerencia del asistente "Vigía Esmeraldas" (`POST /reportes/{id}/clasificar`).
/// Nunca es oficial: el operador decide si la aplica.
class SugerenciaIa {
  const SugerenciaIa({
    required this.tipo,
    required this.gravedad,
    required this.explicacion,
    required this.confianza,
    required this.analizoFoto,
    required this.aviso,
  });

  final TipoIncidente tipo;
  final GravedadIncidente gravedad;
  final String explicacion;
  final double confianza;
  final bool analizoFoto;
  final String aviso;
}

abstract interface class SugerenciaIaRepository {
  Future<SugerenciaIa> pedir(String reporteId);
}
