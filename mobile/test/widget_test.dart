import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/data/models/punto_servicio_model.dart';
import 'package:mobile/data/models/reporte_cola_model.dart';
import 'package:mobile/data/repositories/cola_reportes_repository.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/main.dart';

class InMemoryColaReportesRepository implements ColaReportesRepository {
  final List<ReporteColaModel> _cola = <ReporteColaModel>[];
  List<PuntoServicioModel> _directorio = <PuntoServicioModel>[
    const PuntoServicioModel(
      id: 'alb-01',
      nombre: 'Coliseo Nubia Villacís (Albergue Temporal)',
      tipo: TipoPuntoServicio.albergue,
      latitud: 0.9615,
      longitud: -79.6522,
      telefono: '911',
      capacidad: 250,
      ocupacion: 110,
    ),
  ];

  @override
  Future<void> inicializar() async {}

  @override
  Future<void> encolarReporte(ReporteColaModel reporte) async =>
      _cola.add(reporte);

  @override
  Future<List<ReporteColaModel>> obtenerTodosLosReportes() async =>
      List<ReporteColaModel>.from(_cola);

  @override
  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio() async =>
      _cola.where((r) => !r.estadoCola.estaSincronizado).toList();

  @override
  Future<void> actualizarEstadoReporte({
    required String id,
    required EstadoColaReporte nuevoEstado,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  }) async {
    final int idx = _cola.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _cola[idx] = _cola[idx].copyWith(
      estadoCola: nuevoEstado,
      intentos: intentos,
      proximoIntentoUtc: proximoIntentoUtc,
      mensajeError: mensajeError,
      rutaFotoLocal: rutaFotoLocal,
    );
  }

  @override
  Future<List<PuntoServicioModel>> obtenerDirectorioPuntosServicio() async =>
      _directorio;

  @override
  Future<void> guardarDirectorioPuntosServicio(
    List<PuntoServicioModel> puntos,
  ) async {
    _directorio = List<PuntoServicioModel>.from(puntos);
  }
}

class FakeAuthRepository implements AuthRepository {
  UsuarioSesion? sesion;

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async => sesion;

  @override
  Future<String?> obtenerTokenSeguro() async => 'fake-jwt';

  @override
  Future<UsuarioSesion> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    return sesion = UsuarioSesion(
      id: 'u1',
      nombre: 'Ciudadano Demo',
      correo: correo,
      rol: RolUsuario.ciudadano,
      expiraEn: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UsuarioSesion> registrar({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    return sesion = UsuarioSesion(
      id: 'u2',
      nombre: nombre,
      correo: correo,
      rol: RolUsuario.ciudadano,
      expiraEn: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<UsuarioSesion> iniciarSesionConGoogle() async {
    return sesion = UsuarioSesion(
      id: 'g1',
      nombre: 'Google Demo',
      correo: 'google@demo.ec',
      rol: RolUsuario.ciudadano,
      expiraEn: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      proveedor: 'google',
    );
  }

  @override
  Future<void> cerrarSesion() async => sesion = null;
}

void main() {
  testWidgets(
    'Muestra login con Google, registro y permite pasar al formulario de reporte',
    (WidgetTester tester) async {
      final InMemoryColaReportesRepository repo =
          InMemoryColaReportesRepository();
      final FakeAuthRepository auth = FakeAuthRepository();

      await tester.pumpWidget(
        EsmeraldasResilienteApp(colaRepository: repo, authRepository: auth),
      );
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(
        find.text('¿No tienes cuenta? Crear cuenta ciudadana'),
        findsOneWidget,
      );

      // Entrar en modo emergencia sin cuenta
      await tester.ensureVisible(
        find.text('Emergencia sin internet: reportar ahora'),
      );
      await tester.tap(find.text('Emergencia sin internet: reportar ahora'));
      await tester.pumpAndSettle();

      // Paso 1: Mapa inicial con botón lateral de GPS y botón inferior "Reportar emergencia"
      expect(find.byTooltip('Obtener mi ubicación actual'), findsOneWidget);
      expect(find.text('Reportar emergencia'), findsOneWidget);

      await tester.tap(find.text('Reportar emergencia'));
      await tester.pumpAndSettle();

      // Paso 2: Confirmación de ubicación
      expect(
        find.text('Confirmar la ubicación de la emergencia'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Paso 3: Formulario del reporte
      expect(find.text('¿Qué está pasando?'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Enviar reporte de emergencia'), findsOneWidget);
    },
  );
}
