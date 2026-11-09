import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  /// Obtiene la ubicación actual forzando lectura de hardware GPS cuando está disponible;
  /// si agota el tiempo, recurre a la última ubicación conocida del GPS o al centro de Esmeraldas.
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

/// Implementación con `Geolocator` que fuerza el proveedor GPS nativo en Android
/// (`forceLocationManager: true`) y valida pertenencia a la provincia de Esmeraldas.
class LocalLocationService implements LocationService {
  const LocalLocationService();

  static const CoordenadaCapturada _respaldoEsmeraldas = CoordenadaCapturada(
    latitud: AppConfig.esmeraldasCenterLat,
    longitud: AppConfig.esmeraldasCenterLng,
    precisionMetros: 12.0,
    esAproximada: true,
  );

  /// Verifica si la coordenada cae dentro del recuadro geográfico de la provincia de Esmeraldas
  /// exigido por el backend (`lat` entre -0.5 y 1.6, `lon` entre -80.3 y -78.4).
  static bool estaEnProvinciaEsmeraldas(double lat, double lon) {
    return lat >= -0.5 && lat <= 1.6 && lon >= -80.3 && lon <= -78.4;
  }

  @override
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo() async {
    try {
      final bool habilitado = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2));
      if (!habilitado) {
        await Geolocator.openLocationSettings().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () => false,
        );
      }

      LocationPermission permiso = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
      );
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 8),
        );
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return _respaldoEsmeraldas;
      }

      final LocationSettings settings =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? AndroidSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              forceLocationManager: true,
              intervalDuration: const Duration(seconds: 1),
              timeLimit: const Duration(seconds: 10),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              timeLimit: Duration(seconds: 10),
            );

      try {
        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        if (estaEnProvinciaEsmeraldas(pos.latitude, pos.longitude)) {
          return CoordenadaCapturada(
            latitud: pos.latitude,
            longitud: pos.longitude,
            precisionMetros: pos.accuracy > 0 ? pos.accuracy : 8.0,
            esAproximada: false,
          );
        }
      } catch (_) {
        // Si el fix satelital directo tarda más de 10 s bajo techo, consulta la última posición de hardware GPS
      }

      final Position? ultimaPos = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (ultimaPos != null &&
          estaEnProvinciaEsmeraldas(ultimaPos.latitude, ultimaPos.longitude)) {
        return CoordenadaCapturada(
          latitud: ultimaPos.latitude,
          longitud: ultimaPos.longitude,
          precisionMetros: ultimaPos.accuracy > 0 ? ultimaPos.accuracy : 15.0,
          esAproximada: true,
        );
      }

      return _respaldoEsmeraldas;
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
