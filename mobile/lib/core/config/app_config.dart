import 'package:flutter/foundation.dart';

/// Configuración por entorno para la aplicación móvil Esmeraldas Resiliente.
/// No almacena secretos ni claves privadas en el código fuente.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://seasonal-acceptable-crimes-remember.trycloudflare.com',
  );

  /// URL base del backend configurada mediante `--dart-define=API_BASE_URL=...`.
  /// Por defecto conecta al backend público en vivo del proyecto.
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }

  /// Modo demostración: usa cuentas y datos simulados en el dispositivo
  /// mientras el backend no está listo. `--dart-define=MODO_DEMO=false` para usar la API.
  static const bool modoDemo = bool.fromEnvironment(
    'MODO_DEMO',
    defaultValue: true,
  );

  /// OAuth de Google (cliente configurado en `google-services.json`, proyecto `esmeralsrelesiente`).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '644267053650-hdva73c46tut51k2tjrgk23ul4n4r5ve.apps.googleusercontent.com',
  );

  /// Esquema inverso del `client_id` de Google (`appAuthRedirectScheme` en `android/app/build.gradle.kts`).
  static const String googleRedirectUri = String.fromEnvironment(
    'GOOGLE_REDIRECT_URI',
    defaultValue: 'com.googleusercontent.apps.644267053650-hdva73c46tut51k2tjrgk23ul4n4r5ve:/oauthredirect',
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
