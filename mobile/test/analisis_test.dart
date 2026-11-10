import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/analisis/data/repositories/analisis_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

/// Responde según la ruta, sin red real.
class _AdaptadorFalso implements HttpClientAdapter {
  _AdaptadorFalso(this.respuestas);

  final Map<String, (int, Object)> respuestas;
  final List<RequestOptions> pedidos = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pedidos.add(options);
    final (int, Object) r =
        respuestas[options.path] ?? (404, <String, String>{});
    return ResponseBody.fromString(
      jsonEncode(r.$2),
      r.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _AuthFalso implements AuthRepository {
  @override
  Future<String?> obtenerTokenSeguro() async => 'tok';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AnalisisRepositoryImpl _repo(_AdaptadorFalso a) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = a;
  return AnalisisRepositoryImpl(authRepository: _AuthFalso(), dio: dio);
}

void main() {
  test('Lee indicadores, sectores e inventario del contrato', () async {
    final _AdaptadorFalso a = _AdaptadorFalso(<String, (int, Object)>{
      '/estadisticas': (
        200,
        <String, Object>{
          'total_reportes': 12,
          'pendientes': 8,
          'criticos': 3,
          'personas_afectadas_total': 40,
          'necesidades_acumuladas': <String, int>{'agua': 5, 'rescate': 2},
        },
      ),
      '/estadisticas/recurrencia': (
        200,
        <Object>[
          <String, Object>{
            'sector': 'Isla Piedad',
            'cantidad': 4,
            'abiertos': 3,
            'personas_afectadas': 18,
            'gravedad_promedio': 'alta',
            'puntaje': 9.5,
          },
        ],
      ),
      '/asistencia/inventario': (
        200,
        <Object>[
          <String, Object>{
            'necesidad': 'agua',
            'cantidad': 400,
            'unidad': 'bidones de 20 L',
          },
        ],
      ),
    });
    final AnalisisRepositoryImpl repo = _repo(a);

    final resumen = await repo.resumen();
    expect(resumen.totalReportes, 12);
    expect(resumen.necesidades[NecesidadFamiliar.agua], 5);
    expect(resumen.necesidades[NecesidadFamiliar.medicinas], 0);

    final sectores = await repo.prioridadSectores();
    expect(sectores.single.sector, 'Isla Piedad');
    expect(sectores.single.gravedadPromedio, GravedadIncidente.alta);

    final inventario = await repo.inventario();
    expect(inventario.single.cantidad, 400);
    expect(a.pedidos.first.headers['Authorization'], 'Bearer tok');
  });

  test('Sin stock o rol sin acceso devuelve un fallo con mensaje', () async {
    final _AdaptadorFalso a = _AdaptadorFalso(<String, (int, Object)>{
      '/asistencia/entregas': (
        409,
        <String, String>{'mensaje': 'No hay stock suficiente en el inventario'},
      ),
      '/estadisticas': (403, <String, String>{}),
    });
    final AnalisisRepositoryImpl repo = _repo(a);

    await expectLater(
      repo.registrarEntrega(
        reporteId: 'r1',
        necesidad: NecesidadFamiliar.agua,
        cantidad: 5,
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.mensaje,
          'mensaje',
          contains('stock'),
        ),
      ),
    );
    await expectLater(repo.resumen(), throwsA(isA<ValidationFailure>()));
  });
}
