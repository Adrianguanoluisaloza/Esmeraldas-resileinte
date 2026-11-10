import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/analisis.dart';
import '../../domain/repositories/analisis_repository.dart';

/// Implementación HTTP contra la API (`contrato/openapi.yaml`): `/estadisticas` y `/asistencia/*`.
class AnalisisRepositoryImpl implements AnalisisRepository {
  AnalisisRepositoryImpl({required AuthRepository authRepository, Dio? dio})
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
  Future<ResumenCoe> resumen() async {
    final Map<String, dynamic> m = await _obtenerMapa('/estadisticas');
    final Map<dynamic, dynamic> nec =
        m['necesidades_acumuladas'] as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{};
    return ResumenCoe(
      totalReportes: _entero(m['total_reportes']),
      pendientes: _entero(m['pendientes']),
      enProceso: _entero(m['en_proceso']),
      atendidos: _entero(m['atendidos']),
      criticos: _entero(m['criticos']),
      personasAfectadas: _entero(m['personas_afectadas_total']),
      ninos: _entero(m['ninos_total']),
      adultosMayores: _entero(m['adultos_mayores_total']),
      viasBloqueadas: _entero(m['vias_bloqueadas_total']),
      alberguesDisponibles: _entero(m['albergues_disponibles']),
      necesidades: <NecesidadFamiliar, int>{
        for (final NecesidadFamiliar n in NecesidadFamiliar.values)
          n: _entero(nec[n.valor]),
      },
    );
  }

  @override
  Future<List<SectorPrioridad>> prioridadSectores() async {
    final List<Map<dynamic, dynamic>> lista = await _obtenerLista(
      '/estadisticas/recurrencia',
    );
    return lista
        .map(
          (Map<dynamic, dynamic> m) => SectorPrioridad(
            sector: '${m['sector'] ?? 'Sin sector'}',
            cantidad: _entero(m['cantidad']),
            abiertos: _entero(m['abiertos']),
            personasAfectadas: _entero(m['personas_afectadas']),
            gravedadPromedio: GravedadIncidente.fromValor(
              '${m['gravedad_promedio'] ?? 'media'}',
            ),
            puntaje: (m['puntaje'] as num?) ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<NecesidadPendiente>> necesidadesPendientes() async {
    final List<Map<dynamic, dynamic>> lista = await _obtenerLista(
      '/asistencia/pendientes',
    );
    return lista
        .map(
          (Map<dynamic, dynamic> m) => NecesidadPendiente(
            reporteId: '${m['reporte_id']}',
            necesidad: NecesidadFamiliar.fromValor('${m['necesidad']}'),
            sector: m['sector'] as String?,
            personas: _entero(m['personas']),
            gravedad: GravedadIncidente.fromValor('${m['gravedad']}'),
            prioridad: (m['prioridad'] as num?) ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<ItemInventario>> inventario() async {
    final List<Map<dynamic, dynamic>> lista = await _obtenerLista(
      '/asistencia/inventario',
    );
    return lista
        .map(
          (Map<dynamic, dynamic> m) => ItemInventario(
            necesidad: NecesidadFamiliar.fromValor('${m['necesidad']}'),
            cantidad: _entero(m['cantidad']),
            unidad: '${m['unidad'] ?? ''}',
          ),
        )
        .toList();
  }

  @override
  Future<void> registrarEntrega({
    required String reporteId,
    required NecesidadFamiliar necesidad,
    required int cantidad,
    String? nota,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/asistencia/entregas',
        data: <String, dynamic>{
          'reporte_id': reporteId,
          'necesidad': necesidad.valor,
          'cantidad': cantidad,
          if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        },
      );
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  Future<Map<String, dynamic>> _obtenerMapa(String ruta) async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(ruta);
      final dynamic data = r.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  Future<List<Map<dynamic, dynamic>>> _obtenerLista(String ruta) async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(ruta);
      final dynamic data = r.data;
      return data is List
          ? data.whereType<Map<dynamic, dynamic>>().toList()
          : const <Map<dynamic, dynamic>>[];
    } on DioException catch (e) {
      throw _mapearError(e);
    }
  }

  static int _entero(dynamic v) => v is num ? v.toInt() : 0;

  static Failure _mapearError(DioException e) {
    final int? status = e.response?.statusCode;
    final dynamic data = e.response?.data;
    final String? mensaje = data is Map && data['mensaje'] != null
        ? '${data['mensaje']}'
        : null;
    if (status == null) return const NetworkFailure();
    if (status == 401) return const UnauthorizedFailure();
    if (status == 403) {
      return const ValidationFailure(
        'Tu rol no tiene acceso a los indicadores del COE.',
      );
    }
    if (status >= 400 && status < 500) {
      return ValidationFailure(mensaje ?? 'Solicitud rechazada ($status).');
    }
    return ServerFailure(mensaje ?? 'Error temporal del servidor.');
  }
}
