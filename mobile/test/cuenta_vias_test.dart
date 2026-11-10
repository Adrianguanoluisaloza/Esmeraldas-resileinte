import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/core/widgets/rejilla_adaptable.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/autoproteccion/data/autoproteccion_esmeraldas.dart';
import 'package:mobile/features/autoproteccion/presentation/pages/cuenta_ciudadano_page.dart';
import 'package:mobile/features/vias/data/vias_repository_impl.dart';
import 'package:mobile/features/vias/domain/vias.dart';

class _AuthFalso implements AuthRepository {
  @override
  Future<String?> obtenerTokenSeguro() async => 'tok';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adaptador implements HttpClientAdapter {
  final List<RequestOptions> pedidos = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    pedidos.add(o);
    final Object cuerpo = o.method == 'GET'
        ? <String, Object>{
            'type': 'FeatureCollection',
            'features': <Object>[
              <String, Object>{
                'type': 'Feature',
                'properties': <String, String>{
                  'id': 'v1',
                  'nombre': 'Acceso Puente Tachina',
                  'estado': 'bloqueada',
                  'origen': 'simulado',
                },
              },
            ],
          }
        : <String, String>{'id': 'v1'};
    return ResponseBody.fromString(
      jsonEncode(cuerpo),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Solo 911 está verificado; los demás quedan por confirmar', () {
    final verificados = contactosEmergenciaEsmeraldas.where(
      (c) => c.verificado,
    );
    expect(verificados.map((c) => c.numeros.single), <String>['911']);
    expect(pautasInundacionDeslizamiento.length, 3);
  });

  testWidgets('Cuenta del ciudadano: llamar al 911 y sin matriz de roles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CuentaCiudadanoPage(
            sesion: UsuarioSesion(
              id: 'u1',
              nombre: 'Ana',
              correo: 'ana@correo.ec',
              rol: RolUsuario.ciudadano,
              expiraEn: DateTime.now().add(const Duration(hours: 1)),
            ),
            sinCuenta: false,
            onCerrarSesion: () {},
          ),
        ),
      ),
    );
    expect(find.text('Llamar al 911'), findsOneWidget);
    expect(find.text('Llamar al 101'), findsNothing);
    expect(find.text('Por confirmar'), findsNWidgets(3));
    expect(find.textContaining('Matriz'), findsNothing);
  });

  test('Rejilla: 1 columna en teléfono, 2 en tableta y 3 como máximo', () {
    expect(RejillaAdaptable.columnasPara(390, 340, 3), 1);
    expect(RejillaAdaptable.columnasPara(800, 340, 3), 2);
    expect(RejillaAdaptable.columnasPara(2000, 340, 3), 3);
  });

  test('Vías: lee GeoJSON y cambia estado con token', () async {
    final _Adaptador a = _Adaptador();
    final ViasRepositoryImpl repo = ViasRepositoryImpl(
      authRepository: _AuthFalso(),
      dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = a,
    );
    final List<Via> vias = await repo.listar();
    expect(vias.single.estado, EstadoVia.bloqueada);
    expect(vias.single.esSimulada, isTrue);

    await repo.cambiarEstado('v1', EstadoVia.habilitada);
    expect(a.pedidos.last.path, '/vias/v1/estado');
    expect(a.pedidos.last.data, <String, String>{'estado': 'habilitada'});
    expect(a.pedidos.last.headers['Authorization'], 'Bearer tok');
  });
}
