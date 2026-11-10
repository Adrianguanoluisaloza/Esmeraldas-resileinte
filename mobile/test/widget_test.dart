import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/telephony_service.dart';
import 'package:mobile/data/models/punto_servicio_model.dart';
import 'package:mobile/data/models/reporte_cola_model.dart';
import 'package:mobile/data/repositories/cola_reportes_repository.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/sync/data/services/sync_worker_service.dart';
import 'package:mobile/main.dart';

class FakeLocationService implements LocationService {
  int llamadasGps = 0;

  @override
  Future<CoordenadaCapturada?> capturarUbicacionConRespaldo() async {
    llamadasGps++;
    return const CoordenadaCapturada(
      latitud: 0.9592,
      longitud: -79.6539,
      precisionMetros: 6.5,
      esAproximada: false,
    );
  }

  @override
  double calcularDistanciaKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) => 1.2;
}

class InMemoryColaReportesRepository implements ColaReportesRepository {
  final List<ReporteColaModel> _cola = <ReporteColaModel>[];
  List<PuntoServicioModel> _directorio = <PuntoServicioModel>[];

  @override
  Future<void> inicializar() async {}

  @override
  Future<void> encolarReporte(ReporteColaModel reporte) async =>
      _cola.add(reporte);

  @override
  Future<List<ReporteColaModel>> obtenerTodosLosReportes() async =>
      List<ReporteColaModel>.from(_cola);

  @override
  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio({
    bool ignorarEspera = false,
  }) async {
    final DateTime ahora = DateTime.now().toUtc();
    return _cola.where((ReporteColaModel r) {
      if (r.estadoCola == EstadoColaReporte.enviado) return false;
      if (!ignorarEspera && r.estadoCola == EstadoColaReporte.error) {
        return false;
      }
      if (!ignorarEspera &&
          r.proximoIntentoUtc != null &&
          r.proximoIntentoUtc!.isAfter(ahora)) {
        return false;
      }
      return true;
    }).toList();
  }

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
  Future<void> eliminarReporte(String id) async {
    _cola.removeWhere((ReporteColaModel r) => r.id == id);
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

class FakeApiClient implements ApiClient {
  bool saludOk = true;
  Failure? falloPaso1;
  Failure? falloPaso2;
  int llamadasPaso1 = 0;
  int llamadasPaso2 = 0;

  @override
  Future<bool> verificarSaludServidor() async => saludOk;

  @override
  Future<void> enviarDatosReporte(Map<String, dynamic> payload) async {
    llamadasPaso1++;
    if (falloPaso1 != null) throw falloPaso1!;
  }

  @override
  Future<void> subirFotoReporte({
    required String reporteId,
    required String rutaArchivoLocal,
  }) async {
    llamadasPaso2++;
    if (falloPaso2 != null) throw falloPaso2!;
  }

  @override
  Future<List<PuntoServicioModel>> obtenerPuntosServicio() async =>
      const <PuntoServicioModel>[];

  @override
  Future<List<PuntoServicioModel>> obtenerPuntosCercanos({
    required double lat,
    required double lng,
    int personas = 1,
  }) async => const <PuntoServicioModel>[];

  @override
  Future<List<Map<String, dynamic>>> obtenerAlertasActivas() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> obtenerReportesRemotos() async =>
      const <Map<String, dynamic>>[];

  @override
  Future<void> actualizarEstadoReporteRemoto({
    required String id,
    required String estado,
    required bool verificado,
    required String nota,
  }) async {}

  @override
  Future<void> actualizarOcupacionAlbergueRemoto({
    required String id,
    required int ocupacion,
  }) async {}

  @override
  Future<void> crearAlertaRemota({
    required String sector,
    required String nivel,
    required String mensaje,
    required String origen,
  }) async {}
}

class FakeAuthRepository implements AuthRepository {
  UsuarioSesion? sesion;
  bool googleCancela = false;
  Exception? googleError;
  String? ultimoCorreoRecuperado;

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
  Future<UsuarioSesion?> iniciarSesionConGoogle() async {
    if (googleError != null) throw googleError!;
    if (googleCancela) return null;
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
  Future<void> recuperarPassword({required String correo}) async {
    ultimoCorreoRecuperado = correo;
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
      final FakeApiClient api = FakeApiClient();
      final FakeLocationService location = FakeLocationService();

      await tester.pumpWidget(
        EsmeraldasResilienteApp(
          colaRepository: repo,
          authRepository: auth,
          apiClient: api,
          locationService: location,
        ),
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

      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enviar reporte de emergencia'));
      await tester.pumpAndSettle();

      expect(find.text('Enviar reporte de emergencia'), findsOneWidget);
      await tester.tap(find.text('Enviar reporte de emergencia'));
      await tester.pumpAndSettle();

      // El reporte debe haber forzado lectura GPS, haberse sincronizado y estar en la cola local
      expect(location.llamadasGps, greaterThanOrEqualTo(2));
      final List<ReporteColaModel> guardados = await repo
          .obtenerTodosLosReportes();
      expect(guardados, hasLength(1));
      expect(guardados.first.estadoCola, EstadoColaReporte.enviado);
      expect(guardados.first.descripcion.length, greaterThanOrEqualTo(3));
    },
  );

  test('Verifica archivo MBTiles offline de Esmeraldas y formato SMS georreferenciado con telephony', () {
    final File mbtiles = File('assets/mapas/esmeraldas.mbtiles');
    expect(mbtiles.existsSync(), isTrue);
    expect(mbtiles.lengthSync(), greaterThan(500 * 1024));

    const TelephonyService telephony = TelephonyService();
    final String sms = telephony.construirMensajePuntoGps(
      latitud: 0.9592,
      longitud: -79.6539,
      tipo: TipoIncidente.inundacion,
      gravedad: GravedadIncidente.critica,
      precisionMetros: 8,
      personasAfectadas: 4,
      descripcion: 'Isla Piedad calle principal',
    );
    expect(sms, contains('SOS ESMERALDAS'));
    expect(sms, contains('0.95920,-79.65390'));
    expect(sms, contains('https://maps.google.com/?q=0.95920,-79.65390'));
  });

  test('Verifica flujo completo de la cola offline: sin red, backoff, paso 2 fallido, 401 y 400', () async {
    final InMemoryColaReportesRepository repo =
        InMemoryColaReportesRepository();
    final FakeApiClient api = FakeApiClient();
    bool pidioLogin401 = false;
    final SyncWorkerService worker = SyncWorkerService(
      colaRepository: repo,
      apiClient: api,
      onNoAutenticado: () => pidioLogin401 = true,
    );

    final ReporteColaModel r1 = ReporteColaModel(
      id: '11111111-1111-4111-8111-111111111111',
      tipo: TipoIncidente.inundacion,
      descripcion: '',
      gravedad: GravedadIncidente.critica,
      latitud: 0.9592,
      longitud: -79.6539,
      precisionM: 10,
      ubicacionAproximada: false,
      capturadoEnUtc: DateTime.now().toUtc(),
      rutaFotoLocal: 'foto_prueba.jpg',
    );
    await repo.encolarReporte(r1);

    // 1. Servidor sin conexión -> permanece pendiente
    api.saludOk = false;
    expect(await worker.sincronizarPendientes(), 0);
    expect(
      (await repo.obtenerTodosLosReportes()).first.estadoCola,
      EstadoColaReporte.pendiente,
    );

    // 2. Servidor online pero falla Paso 1 por red -> incrementa intentos y programa backoff
    api.saludOk = true;
    api.falloPaso1 = const NetworkFailure('Corte de red');
    expect(await worker.sincronizarPendientes(), 0);
    ReporteColaModel estado = (await repo.obtenerTodosLosReportes()).first;
    expect(estado.estadoCola, EstadoColaReporte.pendiente);
    expect(estado.intentos, 1);
    expect(estado.proximoIntentoUtc, isNotNull);
    expect(estado.mensajeError, contains('Corte de red'));

    // 3. Paso 1 pasa pero Paso 2 (foto) falla por red -> conserva estado datosEnviados
    api.falloPaso1 = null;
    api.falloPaso2 = const NetworkFailure('Fallo al subir foto');
    expect(await worker.sincronizarPendientes(forzar: true), 0);
    estado = (await repo.obtenerTodosLosReportes()).first;
    expect(estado.estadoCola, EstadoColaReporte.datosEnviados);
    expect(estado.intentos, 2);

    // 4. Error 401 (sesión vencida) -> conserva datosEnviados y dispara onNoAutenticado
    api.falloPaso2 = const UnauthorizedFailure('JWT vencido');
    expect(await worker.sincronizarPendientes(forzar: true), 0);
    estado = (await repo.obtenerTodosLosReportes()).first;
    expect(estado.estadoCola, EstadoColaReporte.datosEnviados);
    expect(pidioLogin401, isTrue);

    // 5. Reintento exitoso del Paso 2 -> pasa a enviado sin repetir Paso 1
    final int llamadasPaso1Antes = api.llamadasPaso1;
    api.falloPaso2 = null;
    expect(await worker.sincronizarPendientes(forzar: true), 1);
    expect(api.llamadasPaso1, llamadasPaso1Antes);
    estado = (await repo.obtenerTodosLosReportes()).first;
    expect(estado.estadoCola, EstadoColaReporte.enviado);
    expect(estado.mensajeError, isNull);

    // 6. Error 400 VALIDACION -> marca como error y no reintenta en automático
    final ReporteColaModel rInvalido = ReporteColaModel(
      id: '22222222-2222-4222-8222-222222222222',
      tipo: TipoIncidente.otro,
      descripcion: 'Reporte con conflicto',
      gravedad: GravedadIncidente.baja,
      latitud: 0.9592,
      longitud: -79.6539,
      precisionM: 10,
      ubicacionAproximada: false,
      capturadoEnUtc: DateTime.now().toUtc(),
      rutaFotoLocal: '',
    );
    await repo.encolarReporte(rInvalido);
    api.falloPaso1 = const ValidationFailure(
      'El id del reporte ya está en uso',
    );
    expect(await worker.sincronizarPendientes(forzar: true), 0);
    final ReporteColaModel r2Estado = (await repo.obtenerTodosLosReportes())
        .firstWhere((r) => r.id == rInvalido.id);
    expect(r2Estado.estadoCola, EstadoColaReporte.error);
    expect(r2Estado.mensajeError, contains('en uso'));
  });
}
