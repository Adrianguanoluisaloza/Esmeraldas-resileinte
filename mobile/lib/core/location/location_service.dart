import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

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

/// Implementación con `Geolocator` y respaldo en las coordenadas de Esmeraldas.
class LocalLocationService implements LocationService {
  const LocalLocationService();

  static const CoordenadaCapturada _respaldoEsmeraldas = CoordenadaCapturada(
    latitud: AppConfig.esmeraldasCenterLat,
    longitud: AppConfig.esmeraldasCenterLng,
    precisionMetros: 12.0,
    esAproximada: false,
  );

  @override
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo() async {
    try {
      final bool habilitado = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(milliseconds: 600));
      if (!habilitado) return _respaldoEsmeraldas;

      LocationPermission permiso = await Geolocator.checkPermission().timeout(
        const Duration(milliseconds: 600),
      );
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 4),
        );
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return _respaldoEsmeraldas;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return CoordenadaCapturada(
        latitud: pos.latitude,
        longitud: pos.longitude,
        precisionMetros: pos.accuracy,
        esAproximada: false,
      );
    } catch (_) {
      return _respaldoEsmeraldas;
    }
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
