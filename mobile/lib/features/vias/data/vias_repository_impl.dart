import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failures.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/vias.dart';

class ViasRepositoryImpl implements ViasRepository {
  ViasRepositoryImpl({required AuthRepository authRepository, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await authRepository.obtenerTokenSeguro();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );
  }

  final Dio _dio;

  @override
  Future<List<Via>> listar() async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>('/vias');
      final dynamic data = r.data;
      final List<dynamic> features = data is Map && data['features'] is List
          ? data['features'] as List<dynamic>
          : const <dynamic>[];
      return features.whereType<Map<dynamic, dynamic>>().map((
        Map<dynamic, dynamic> f,
      ) {
        final Map<dynamic, dynamic> p =
            f['properties'] as Map<dynamic, dynamic>? ??
            const <dynamic, dynamic>{};
        return Via(
          id: '${p['id'] ?? f['id']}',
          nombre: '${p['nombre'] ?? 'Vía sin nombre'}',
          estado: EstadoVia.fromValor('${p['estado']}'),
          esSimulada: p['origen'] != 'oficial',
        );
      }).toList();
    } on DioException catch (e) {
      throw _mapear(e);
    }
  }

  @override
  Future<void> cambiarEstado(String id, EstadoVia estado) async {
    try {
      await _dio.patch<dynamic>(
        '/vias/$id/estado',
        data: <String, dynamic>{'estado': estado.valor},
      );
    } on DioException catch (e) {
      throw _mapear(e);
    }
  }

  static Failure _mapear(DioException e) {
    final int? status = e.response?.statusCode;
    if (status == null) return const NetworkFailure();
    if (status == 401) return const UnauthorizedFailure();
    if (status == 403) {
      return const ValidationFailure(
        'Tu rol no puede cambiar el estado de vías.',
      );
    }
    return ServerFailure('No se pudo actualizar la vía ($status).');
  }
}
