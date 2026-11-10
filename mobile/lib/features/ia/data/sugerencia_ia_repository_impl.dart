import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/error/failures.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/sugerencia_ia.dart';

class SugerenciaIaRepositoryImpl implements SugerenciaIaRepository {
  SugerenciaIaRepositoryImpl({required AuthRepository authRepository, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              // El modelo puede tardar; la API corta a los 25 s.
              receiveTimeout: const Duration(seconds: 30),
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
  Future<SugerenciaIa> pedir(String reporteId) async {
    try {
      final Response<dynamic> r = await _dio.post<dynamic>(
        '/reportes/$reporteId/clasificar',
      );
      final Map<dynamic, dynamic> m = r.data as Map<dynamic, dynamic>;
      return SugerenciaIa(
        tipo: TipoIncidente.fromValor('${m['tipo_sugerido']}'),
        gravedad: GravedadIncidente.fromValor('${m['gravedad_sugerida']}'),
        explicacion: '${m['explicacion'] ?? ''}',
        confianza: (m['confianza'] as num?)?.toDouble() ?? 0,
        analizoFoto: m['analizo_foto'] == true,
        aviso: '${m['aviso'] ?? 'Sugerencia de apoyo, no oficial.'}',
      );
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      if (status == null) throw const NetworkFailure();
      if (status == 401) throw const UnauthorizedFailure();
      if (status == 403) {
        throw const ValidationFailure(
          'Tu rol no puede pedir sugerencias de IA.',
        );
      }
      if (status == 404) {
        throw const ValidationFailure(
          'El reporte aún no está en el servidor. Sincroniza y vuelve a intentar.',
        );
      }
      if (status == 501) {
        throw const ServerFailure('La IA aún no está activada en el servidor.');
      }
      throw const ServerFailure(
        'El asistente de IA no respondió. Intenta de nuevo en un momento.',
      );
    }
  }
}
