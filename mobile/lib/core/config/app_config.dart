/// Configuración por entorno para la aplicación móvil Esmeraldas Resiliente.
/// No almacena secretos ni claves privadas en el código fuente.
class AppConfig {
  const AppConfig._();

  /// URL base del backend configurada mediante `--dart-define=API_BASE_URL=...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

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
