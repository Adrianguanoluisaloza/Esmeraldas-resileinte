import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/punto_servicio_model.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../config/app_config.dart';
import '../error/failures.dart';
import '../services/photo_capture_service.dart';

/// Contrato del cliente HTTP de la aplicación (M1 y M5 de `TAREAS_MOVIL_FRANCO.md`).
abstract interface class ApiClient {
  /// `GET /salud` -> `200 {"estado":"ok"}` (timeout 5 s).
  Future<bool> verificarSaludServidor();

  /// Paso 1: `POST /reportes` con `Authorization: Bearer <token>`.
  /// Retorna normalmente tanto en `201` (nuevo) como en `200` (idempotente).
  Future<void> enviarDatosReporte(Map<String, dynamic> payload);

  /// Paso 2: `POST /reportes/{id}/foto` multipart con campo `foto` (timeout 20 s).
  Future<void> subirFotoReporte({
    required String reporteId,
    required String rutaArchivoLocal,
  });

  /// `GET /puntos-servicio` (sin token) para actualizar el directorio offline (M5).
  Future<List<PuntoServicioModel>> obtenerPuntosServicio();

  /// `GET /puntos-servicio/cercanos?lat=&lng=&personas=` ordenado por PostGIS (M5).
  Future<List<PuntoServicioModel>> obtenerPuntosCercanos({
    required double lat,
    required double lng,
    int personas = 1,
  });

  /// `GET /alertas` (sin token) para mostrar alertas activas en Albergues y alertas (M6).
  Future<List<Map<String, dynamic>>> obtenerAlertasActivas() async =>
      const <Map<String, dynamic>>[];

  /// `GET /reportes?limite=100` (con token) para poblar los incidentes georreferenciados en el mapa y panel.
  Future<List<Map<String, dynamic>>> obtenerReportesRemotos() async =>
      const <Map<String, dynamic>>[];

  /// `PATCH /reportes/{id}/estado` (operador_911 / admin).
  Future<void> actualizarEstadoReporteRemoto({
    required String id,
    required String estado,
    required bool verificado,
    required String nota,
  }) async {}

  /// `PATCH /albergues/{id}/ocupacion` (operador_911 / admin).
  Future<void> actualizarOcupacionAlbergueRemoto({
    required String id,
    required int ocupacion,
  }) async {}

  /// `POST /alertas` (operador_911 / admin).
  Future<void> crearAlertaRemota({
    required String sector,
    required String nivel,
    required String mensaje,
    required String origen,
  }) async {}
}

/// Implementación real con `Dio`, interceptor JWT y mapeo de errores tipados (`Failure`).
class DioApiClient implements ApiClient {
  DioApiClient({String? baseUrl, this.authRepository, Dio? dio})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final bool sinToken = options.extra['sinToken'] == true;
              if (!sinToken && authRepository != null) {
                final String? token = await authRepository!
                    .obtenerTokenSeguro();
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              handler.next(options);
            },
      ),
    );
  }

  final String _baseUrl;
  final AuthRepository? authRepository;
  late final Dio _dio;
  bool _servidorRealActivo = true;

  String get baseUrl => _baseUrl;

  @override
  Future<bool> verificarSaludServidor() async {
    try {
      final Response<dynamic> r = await _dio
          .get<dynamic>(
            '/salud',
            options: Options(
              extra: const <String, dynamic>{'sinToken': true},
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          )
          .timeout(const Duration(seconds: 5));
      _servidorRealActivo = true;
      if (r.statusCode == 200 && r.data is Map) {
        return (r.data as Map<dynamic, dynamic>)['estado'] == 'ok';
      }
      return r.statusCode == 200;
    } on DioException {
      _servidorRealActivo = false;
      return AppConfig.modoDemo;
    } catch (_) {
      _servidorRealActivo = false;
      return AppConfig.modoDemo;
    }
  }

  @override
  Future<void> enviarDatosReporte(Map<String, dynamic> payload) async {
    if (AppConfig.modoDemo && !_servidorRealActivo) {
      return;
    }
    try {
      await _dio.post<dynamic>('/reportes', data: payload);
    } on DioException catch (e) {
      if (AppConfig.modoDemo && _esErrorConexion(e)) {
        return;
      }
      throw _mapearError(e);
    }
  }

  @override
  Future<void> subirFotoReporte({
    required String reporteId,
    required String rutaArchivoLocal,
  }) async {
    if (AppConfig.modoDemo && !_servidorRealActivo) {
      return;
    }
    try {
      MultipartFile archivo;
      final Uint8List? bytesEnMemoria =
          PhotoCaptureService.obtenerBytesEnMemoria(rutaArchivoLocal);
      bool existeArchivoFisico = false;
      if (!kIsWeb && rutaArchivoLocal.isNotEmpty) {
        try {
          existeArchivoFisico = await File(rutaArchivoLocal).exists();
        } catch (_) {
          existeArchivoFisico = false;
        }
      }
      if (existeArchivoFisico) {
        archivo = await MultipartFile.fromFile(
          rutaArchivoLocal,
          filename: '$reporteId.jpg',
        );
      } else if (bytesEnMemoria != null) {
        archivo = MultipartFile.fromBytes(
          bytesEnMemoria,
          filename: '$reporteId.jpg',
        );
      } else {
        // M10: No subir fotos falsas de relleno si el archivo ya no existe.
        return;
      }
      final FormData form = FormData.fromMap(<String, dynamic>{
        'foto': archivo,
      });
      await _dio.post<dynamic>(
        '/reportes/$reporteId/foto',
        data: form,
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
    } on DioException catch (e) {
      if (AppConfig.modoDemo && _esErrorConexion(e)) {
        return;
      }
      throw _mapearError(e);
    }
  }

  @override
  Future<List<PuntoServicioModel>> obtenerPuntosServicio() async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/puntos-servicio',
        options: Options(extra: const <String, dynamic>{'sinToken': true}),
      );
      return _parsearPuntos(r.data);
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<List<PuntoServicioModel>> obtenerPuntosCercanos({
    required double lat,
    required double lng,
    int personas = 1,
  }) async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/puntos-servicio/cercanos',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lng': lng,
          'personas': personas,
        },
        options: Options(extra: const <String, dynamic>{'sinToken': true}),
      );
      return _parsearPuntos(r.data);
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerAlertasActivas() async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/alertas',
        options: Options(extra: const <String, dynamic>{'sinToken': true}),
      );
      final dynamic data = r.data;
      final List<dynamic> lista = data is List
          ? data
          : (data is Map && data['datos'] is List)
          ? data['datos'] as List<dynamic>
          : (data is Map && data['items'] is List)
          ? data['items'] as List<dynamic>
          : const <dynamic>[];
      return lista
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerReportesRemotos() async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/reportes',
        queryParameters: const <String, dynamic>{'limite': 100},
      );
      final dynamic data = r.data;
      final List<dynamic> lista = data is List
          ? data
          : (data is Map && data['items'] is List)
          ? data['items'] as List<dynamic>
          : (data is Map && data['datos'] is List)
          ? data['datos'] as List<dynamic>
          : const <dynamic>[];
      return lista
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<void> actualizarEstadoReporteRemoto({
    required String id,
    required String estado,
    required bool verificado,
    required String nota,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/reportes/$id/estado',
        data: <String, dynamic>{
          'estado': estado,
          'verificado': verificado,
          'nota': nota,
        },
      );
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<void> actualizarOcupacionAlbergueRemoto({
    required String id,
    required int ocupacion,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/albergues/$id/ocupacion',
        data: <String, dynamic>{'ocupacion': ocupacion},
      );
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<void> crearAlertaRemota({
    required String sector,
    required String nivel,
    required String mensaje,
    required String origen,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/alertas',
        data: <String, dynamic>{
          'sector': sector,
          'nivel': nivel,
          'mensaje': mensaje,
          'origen': origen,
        },
      );
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  List<PuntoServicioModel> _parsearPuntos(dynamic data) {
    final List<dynamic> lista = data is List
        ? data
        : (data is Map && data['datos'] is List)
        ? data['datos'] as List<dynamic>
        : const <dynamic>[];
    return lista.map((dynamic raw) {
      final Map<dynamic, dynamic> m = raw as Map<dynamic, dynamic>;
      return PuntoServicioModel.fromMap(<String, dynamic>{
        'id': '${m['id']}',
        'nombre': m['nombre'] ?? '',
        'tipo': m['tipo'] ?? 'albergue',
        'latitud':
            (m['latitud'] ?? m['lat'] ?? AppConfig.esmeraldasCenterLat) as num,
        'longitud':
            (m['longitud'] ?? m['lng'] ?? AppConfig.esmeraldasCenterLng) as num,
        'telefono': m['telefono'] ?? '911',
        'capacidad': (m['capacidad'] ?? 0) as int,
        'ocupacion': (m['ocupacion'] ?? 0) as int,
        'activo': (m['activo'] ?? true) as bool,
      });
    }).toList();
  }

  bool _esErrorConexion(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  Failure _mapearError(DioException e) {
    final int? status = e.response?.statusCode;
    final dynamic data = e.response?.data;
    final String codigo = data is Map ? '${data['codigo'] ?? ''}' : '';
    final String mensaje = data is Map && data['mensaje'] != null
        ? '${data['mensaje']}'
        : 'Error de comunicación con el servidor.';

    if (status == 401 || codigo == 'NO_AUTENTICADO') {
      return UnauthorizedFailure(mensaje);
    }
    if (status == 400 ||
        status == 409 ||
        codigo == 'VALIDACION' ||
        codigo == 'CONFLICTO') {
      return ValidationFailure(mensaje);
    }
    if (_esErrorConexion(e)) {
      return const NetworkFailure();
    }
    return ServerFailure(mensaje);
  }
}
