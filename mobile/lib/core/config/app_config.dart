import 'package:flutter/foundation.dart';

/// Configuración por entorno para la aplicación móvil Esmeraldas Resiliente.
/// No almacena secretos ni claves privadas en el código fuente.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL base del backend configurada mediante `--dart-define=API_BASE_URL=...`.
  /// En desarrollo apunta al backend local si no se define otra URL.
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }

  /// Indica si la app opera en modo demostración (`--dart-define=MODO_DEMO=...`).
  static const bool modoDemo = bool.fromEnvironment(
    'MODO_DEMO',
    defaultValue: false,
  );

  /// OAuth de Google (pasar mediante `--dart-define=GOOGLE_CLIENT_ID=...`).
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'reemplazar-client-id.apps.googleusercontent.com',
  );

  /// Esquema inverso del `client_id` de Google (`appAuthRedirectScheme` en `android/app/build.gradle.kts`).
  static const String googleRedirectUri = String.fromEnvironment(
    'GOOGLE_REDIRECT_URI',
    defaultValue: 'com.googleusercontent.apps.reemplazar-client-id:/oauthredirect',
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
  static const double minZoom = 8.0;

  /// Número telefónico de emergencia para envío de punto GPS por SMS / llamada.
  /// Número que recibe el punto GPS por SMS. Vacío desactiva el envío:
  /// no debe apuntar a una línea de emergencia real sin un convenio.
  static const String smsEmergenciaNumero = String.fromEnvironment(
    'EMERGENCY_SMS_NUMBER',
  );

  /// Parámetros de captura offline.
  static const Duration gpsTimeout = Duration(seconds: 20);

  /// Sin datos el GPS no recibe ayuda de antenas y el primer fijado tarda mucho más.
  static const Duration gpsTimeoutSinRed = Duration(seconds: 60);

  /// Tiempo durante el que una ubicación ya fijada se considera actual.
  static const Duration gpsVigencia = Duration(seconds: 90);
  static const int photoMaxDimensionPx = 1280;
  static const int photoCompressQuality = 75;

  /// Tiempos de espera creciente (backoff) para reintentos de sincronización.
  static const List<int> syncBackoffSeconds = <int>[5, 15, 30, 60];
}
