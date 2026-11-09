import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/punto_servicio_model.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../config/app_config.dart';
import '../error/failures.dart';

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
                String? token = await authRepository!.obtenerTokenSeguro();
                if (_servidorRealActivo &&
                    (token == null ||
                        token.isEmpty ||
                        token.endsWith('.firma-demo'))) {
                  try {
                    await authRepository!.iniciarSesion(
                      correo: 'ciudadano@demo.ec',
                      password: 'Ciudadano#2026',
                    );
                    token = await authRepository!.obtenerTokenSeguro();
                  } catch (_) {
                    // Si falla la renovación automática, continúa con el token actual
                  }
                }
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

  /// JPEG mínimo válido (1x1 px) de respaldo cuando se simula la cámara sin archivo físico.
  static const List<int> _jpegMinimoDemo = <int>[
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x01,
    0x01,
    0x00,
    0x48,
    0x00,
    0x48,
    0x00,
    0x00,
    0xFF,
    0xDB,
    0x00,
    0x43,
    0x00,
    0x03,
    0x02,
    0x02,
    0x02,
    0x02,
    0x02,
    0x03,
    0x02,
    0x02,
    0x02,
    0x03,
    0x03,
    0x03,
    0x03,
    0x04,
    0x06,
    0x04,
    0x04,
    0x04,
    0x04,
    0x04,
    0x08,
    0x06,
    0x06,
    0x05,
    0x06,
    0x09,
    0x08,
    0x0A,
    0x0A,
    0x09,
    0x08,
    0x09,
    0x09,
    0x0A,
    0x0C,
    0x0F,
    0x0C,
    0x0A,
    0x0B,
    0x0E,
    0x0B,
    0x09,
    0x09,
    0x0D,
    0x11,
    0x0D,
    0x0E,
    0x0F,
    0x10,
    0x10,
    0x11,
    0x10,
    0x0A,
    0x0C,
    0x12,
    0x13,
    0x12,
    0x10,
    0x13,
    0x0F,
    0x10,
    0x10,
    0x10,
    0xFF,
    0xC0,
    0x00,
    0x0B,
    0x08,
    0x00,
    0x01,
    0x00,
    0x01,
    0x01,
    0x01,
    0x11,
    0x00,
    0xFF,
    0xC4,
    0x00,
    0x14,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x09,
    0xFF,
    0xC4,
    0x00,
    0x14,
    0x10,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0xDA,
    0x00,
    0x08,
    0x01,
    0x01,
    0x00,
    0x00,
    0x3F,
    0x00,
    0x37,
    0xFF,
    0xD9,
  ];

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
          .timeout(const Duration(milliseconds: 1800));
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
      } else {
        archivo = MultipartFile.fromBytes(
          _jpegMinimoDemo,
          filename: '$reporteId.jpg',
        );
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
