import '../config/app_config.dart';

/// Contrato del cliente HTTP de la aplicación.
/// Separa la infraestructura de red (Dio) de los servicios de sincronización y casos de uso.
abstract interface class ApiClient {
  /// Verifica si hay salida real a internet consultando `GET /salud`.
  Future<bool> verificarSaludServidor();

  /// Paso 1 de sincronización: envía los datos livianos (`POST /reportes`).
  /// Es idempotente por UUID.
  Future<void> enviarDatosReporte(Map<String, dynamic> payload);

  /// Paso 2 de sincronización: sube el archivo de imagen (`POST /reportes/:id/foto`).
  Future<void> subirFotoReporte({
    required String reporteId,
    required String rutaArchivoLocal,
  });
}

/// Esqueleto del cliente HTTP configurado con la URL base de `AppConfig`.
class DioApiClient implements ApiClient {
  DioApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String _baseUrl;

  String get baseUrl => _baseUrl;

  @override
  Future<bool> verificarSaludServidor() async {
    // Esqueleto: GET $_baseUrl/salud con timeout corto (5s).
    return true;
  }

  @override
  Future<void> enviarDatosReporte(Map<String, dynamic> payload) async {
    // Esqueleto: POST $_baseUrl/reportes con cabecera Authorization Bearer token.
  }

  @override
  Future<void> subirFotoReporte({
    required String reporteId,
    required String rutaArchivoLocal,
  }) async {
    // Esqueleto: POST $_baseUrl/reportes/$reporteId/foto con FormData multipart.
  }
}
