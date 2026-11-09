import 'dart:math' as math;

/// Resultado de captura de coordenadas en el dispositivo.
class CoordenadaCapturada {
  const CoordenadaCapturada({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.esAproximada,
  });

  final double latitud;
  final double longitud;
  final double precisionMetros;
  final bool esAproximada;
}

/// Contrato del servicio de ubicación del dominio.
abstract interface class LocationService {
  /// Obtiene la ubicación actual con límite de espera; si agota el tiempo,
  /// recurre a la última ubicación conocida marcada como aproximada.
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo();

  /// Calcula la distancia en kilómetros entre dos coordenadas (fórmula de Haversine)
  /// para ordenar albergues cercanos sin conexión a internet.
  double calcularDistanciaKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  });
}

/// Implementación base con cálculo geométrico local sin depender de red ni PostGIS.
class LocalLocationService implements LocationService {
  const LocalLocationService();

  @override
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo() async {
    // Esqueleto: se conectará con Geolocator.getCurrentPosition(timeLimit: AppConfig.gpsTimeout)
    // y Geolocator.getLastKnownPosition() como respaldo marcado con esAproximada: true.
    return const CoordenadaCapturada(
      latitud: 0.9592,
      longitud: -79.6539,
      precisionMetros: 12.0,
      esAproximada: false,
    );
  }

  @override
  double calcularDistanciaKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double radioTierraKm = 6371.0;
    final double dLat = _gradosARadianes(lat2 - lat1);
    final double dLon = _gradosARadianes(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradosARadianes(lat1)) *
            math.cos(_gradosARadianes(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radioTierraKm * c;
  }

  double _gradosARadianes(double grados) => grados * (math.pi / 180.0);
}
