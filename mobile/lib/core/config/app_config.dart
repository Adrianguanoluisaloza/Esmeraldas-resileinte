import 'package:flutter/foundation.dart';

/// Configuración por entorno para la aplicación móvil Esmeraldas Resiliente.
/// No almacena secretos ni claves privadas en el código fuente.
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');

  /// URL base del backend. En web usa localhost:3000, en emulador 10.0.2.2:3000,
  /// o la URL pasada por --dart-define=API_BASE_URL=...
  static String get apiBaseUrl {
    if (_apiBaseUrlEnv.isNotEmpty) return _apiBaseUrlEnv;
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000';
  }

  /// Modo demostración: cuando es false usa la API real.
  static const bool modoDemo = bool.fromEnvironment(
    'MODO_DEMO',
    defaultValue: false,
  );

  /// OAuth de Google (cliente de tipo Android/iOS; nunca se incluye client secret).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  /// Debe coincidir con `appAuthRedirectScheme` en `android/app/build.gradle.kts`
  /// (para Google: el client ID invertido, ej. `com.googleusercontent.apps.XXXX:/oauthredirect`).
  static const String googleRedirectUri = String.fromEnvironment(
    'GOOGLE_REDIRECT_URI',
    defaultValue: 'ec.esmeraldas.resiliente.mobile:/oauthredirect',
  );

  /// Seguridad de sesión.
  static const Duration duracionSesion = Duration(minutes: 15);
  static const Duration cierrePorInactividad = Duration(minutes: 5);
  static const int maxIntentosLogin = 5;
  static const Duration bloqueoLogin = Duration(seconds: 30);

  /// Identificador de paquete requerido por la política de uso de OpenStreetMap.
  static const String osmUserAgentPackageName =
      'ec.esmeraldas.resiliente.mobile';

  /// Plantilla de servidor de teselas de OpenStreetMap.
  static const String osmTileUrlTemplate = String.fromEnvironment(
    'PUBLIC_MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Atribución obligatoria de OpenStreetMap.
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Coordenadas de referencia para centrar el mapa en Esmeraldas.
  static const double esmeraldasCenterLat = 0.9592;
  static const double esmeraldasCenterLng = -79.6539;
  static const double defaultZoom = 13.5;
  static const double maxZoom = 18.0;
  static const double minZoom = 10.0;

  /// Parámetros de captura offline.
  static const Duration gpsTimeout = Duration(seconds: 20);
  static const int photoMaxDimensionPx = 1280;
  static const int photoCompressQuality = 75;

  /// Tiempos de espera creciente (backoff) para reintentos de sincronización.
  static const List<int> syncBackoffSeconds = <int>[5, 15, 30, 60];
}
