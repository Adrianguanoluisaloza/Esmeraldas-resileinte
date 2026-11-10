/// Teléfono de una institución de respuesta.
///
/// [verificado] es true solo cuando el número se confirmó con una fuente oficial.
/// Los no verificados se muestran como "por confirmar" y sin botón de llamada (regla 6 de AGENTS.md).
class ContactoEmergencia {
  const ContactoEmergencia({
    required this.institucion,
    required this.numeros,
    required this.detalle,
    required this.verificado,
  });

  final String institucion;
  final List<String> numeros;
  final String detalle;
  final bool verificado;
}

enum MomentoRiesgo { antes, durante, despues }

/// Pautas de autoprotección para un momento del evento.
class PautaAutoproteccion {
  const PautaAutoproteccion({required this.momento, required this.pasos});

  final MomentoRiesgo momento;
  final List<String> pasos;
}
