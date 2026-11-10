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
  /// si agota el tiempo, recurre a la última ubicación conocida. Devuelve null si no hay ninguna.
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

  // Sin datos móviles el GPS tarda en fijar: el resultado se reutiliza y las
  // peticiones simultáneas comparten la misma búsqueda de satélites.
  static Future<CoordenadaCapturada?>? _busquedaEnCurso;
  static CoordenadaCapturada? _ultimoFijo;
  static DateTime? _ultimoFijoEn;

  /// Verifica si la coordenada cae dentro del recuadro geográfico de la provincia de Esmeraldas
  /// exigido por el backend (`lat` entre -0.5 y 1.6, `lon` entre -80.3 y -78.4).
  static bool estaEnProvinciaEsmeraldas(double lat, double lon) {
    return lat >= -0.5 && lat <= 1.6 && lon >= -80.3 && lon <= -78.4;
  }

  @override
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo() {
    final CoordenadaCapturada? fijo = _ultimoFijo;
    final DateTime? fijoEn = _ultimoFijoEn;
    if (fijo != null &&
        fijoEn != null &&
        DateTime.now().difference(fijoEn) < AppConfig.gpsVigencia) {
      return Future<CoordenadaCapturada?>.value(fijo);
    }
    return _busquedaEnCurso ??= _buscarUbicacion().whenComplete(() {
      _busquedaEnCurso = null;
    });
  }

  /// Devuelve null si no hay ubicación real: nunca inventa un punto.
  Future<CoordenadaCapturada?> _buscarUbicacion() async {
    try {
      final bool habilitado = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2));
      if (!habilitado) {
        await Geolocator.openLocationSettings().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () => false,
        );
        return null;
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
        return null;
      }

      final LocationSettings settings =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? AndroidSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              forceLocationManager: true,
              intervalDuration: const Duration(seconds: 1),
              timeLimit: AppConfig.gpsTimeoutSinRed,
            )
          : LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              timeLimit: AppConfig.gpsTimeoutSinRed,
            );

      try {
        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        if (estaEnProvinciaEsmeraldas(pos.latitude, pos.longitude)) {
          final CoordenadaCapturada fijo = CoordenadaCapturada(
            latitud: pos.latitude,
            longitud: pos.longitude,
            precisionMetros: pos.accuracy > 0 ? pos.accuracy : 8.0,
            esAproximada: false,
          );
          _ultimoFijo = fijo;
          _ultimoFijoEn = DateTime.now();
          return fijo;
        }
      } catch (_) {
        // Sin cielo despejado puede no fijar: se consulta la última posición conocida.
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

      return null;
    } catch (_) {
      return null;
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
