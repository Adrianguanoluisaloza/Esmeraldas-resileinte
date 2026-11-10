import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/albergues/data/models/punto_servicio_model.dart';
import '../../features/reporte/data/models/reporte_cola_model.dart';
import '../../features/reporte/data/repositories/cola_reportes_repository.dart';
import '../../features/operaciones/data/repositories/operaciones_repository.dart';
import '../../features/admin/presentation/pages/admin_pages.dart';
import '../../features/admin/presentation/pages/administracion_page.dart';
import '../../features/ia/domain/sugerencia_ia.dart';
import '../../features/vias/domain/vias.dart';
import '../../features/vias/presentation/vias_section.dart';
import '../../features/analisis/domain/repositories/analisis_repository.dart';
import '../../features/analisis/presentation/pages/analisis_page.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/autoproteccion/presentation/pages/cuenta_ciudadano_page.dart';
import '../../features/albergues/presentation/pages/directorio_albergues_page.dart';
import '../../features/mis_reportes/presentation/pages/mis_reportes_page.dart';
import '../../features/operaciones/presentation/pages/operaciones_pages.dart';
import '../../features/reporte/domain/usecases/crear_reporte_offline_usecase.dart';
import '../../features/reporte/presentation/pages/crear_reporte_page.dart';
import '../../features/sync/data/services/sync_worker_service.dart';
import '../../features/sync/presentation/widgets/sync_status_banner.dart';
import '../config/app_config.dart';
import '../enums/app_enums.dart';
import '../location/location_service.dart';
import '../network/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/mapa_fondo_esmeraldas.dart';

/// Shell principal de navegación de Esmeraldas Resiliente.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    required this.colaRepository,
    required this.authRepository,
    required this.locationService,
    required this.crearReporteUseCase,
    required this.syncWorkerService,
    this.apiClient,
    this.operacionesRepository,
    this.analisisRepository,
    this.viasRepository,
    this.sugerenciaIaRepository,
  });

  final ColaReportesRepository colaRepository;
  final AuthRepository authRepository;
  final LocationService locationService;
  final CrearReporteOfflineUseCase crearReporteUseCase;
  final SyncWorkerService syncWorkerService;
  final ApiClient? apiClient;
  final OperacionesRepository? operacionesRepository;
  final AnalisisRepository? analisisRepository;
  final ViasRepository? viasRepository;
  final SugerenciaIaRepository? sugerenciaIaRepository;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  late final OperacionesRepository _ops;
  UsuarioSesion? _sesion;
  bool _modoEmergenciaSinCuenta = false;
  int _indiceActual = 0;

  List<ReporteColaModel> _reportes = <ReporteColaModel>[];
  List<PuntoServicioModel> _puntos = <PuntoServicioModel>[];
  bool _sincronizando = false;
  bool _modoOfflineSimulado = false;

  DateTime _ultimaActividad = DateTime.now();
  Timer? _relojSesion;

  @override
  void initState() {
    super.initState();
    _ops =
        widget.operacionesRepository ??
        OperacionesRepository(apiClient: widget.apiClient);
    _ops.apiClient ??= widget.apiClient;
    _ops.addListener(_onOperacionesActualizadas);
    widget.syncWorkerService.onNoAutenticado = () {
      unawaited(_manejarSesionVencida401());
    };
    _inicializarDatosYSincronizar();
    _restaurarSesion();
    _relojSesion = Timer.periodic(const Duration(seconds: 15), (_) {
      _vigilarSesion();
      if (!_modoOfflineSimulado && !_sincronizando && _cantidadPendientes > 0) {
        unawaited(_ejecutarSincronizacion());
      }
    });
  }

  void _onOperacionesActualizadas() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _manejarSesionVencida401() async {
    await widget.authRepository.cerrarSesion();
    if (!mounted) return;
    setState(() {
      _sesion = null;
      _modoEmergenciaSinCuenta = false;
      _indiceActual = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tu sesión venció. Inicia sesión nuevamente; tu cola de reportes sigue intacta.',
        ),
      ),
    );
  }

  Future<void> _inicializarDatosYSincronizar() async {
    await _recargarDatosLocales();
    if (!_modoOfflineSimulado && _cantidadPendientes > 0) {
      await _ejecutarSincronizacion(forzar: true);
    }
  }

  @override
  void dispose() {
    _ops.removeListener(_onOperacionesActualizadas);
    _relojSesion?.cancel();
    super.dispose();
  }

  Future<void> _restaurarSesion() async {
    final UsuarioSesion? s = await widget.authRepository.obtenerSesionActual();
    if (mounted && s != null) {
      setState(() => _sesion = s);
      if (!_modoOfflineSimulado) {
        unawaited(_sincronizarDatosBackend());
      }
    }
  }

  Future<void> _vigilarSesion() async {
    final UsuarioSesion? s = _sesion;
    if (s == null) return;
    final bool inactivo =
        DateTime.now().difference(_ultimaActividad) >
        AppConfig.cierrePorInactividad;
    if (s.expirada || inactivo) {
      _ops.auditar(
        s,
        'LOGOUT AUTOMÁTICO',
        s.expirada ? 'JWT expirado' : 'Inactividad',
      );
      await widget.authRepository.cerrarSesion();
      if (!mounted) return;
      setState(() {
        _sesion = null;
        _indiceActual = 0;
      });
    }
  }

  Future<void> _recargarDatosLocales() async {
    final List<ReporteColaModel> listaReportes = await widget.colaRepository
        .obtenerTodosLosReportes();
    final List<PuntoServicioModel> listaPuntos = await widget.colaRepository
        .obtenerDirectorioPuntosServicio();
    _ops.sincronizarDesdeColaLocal(
      listaReportes,
      usuarioIdActual: _sesion?.id ?? 'u1',
    );
    if (!mounted) return;
    setState(() {
      _reportes = listaReportes;
      _puntos = listaPuntos;
    });
    if (!_modoOfflineSimulado && widget.apiClient != null) {
      unawaited(_sincronizarDatosBackend());
    }
  }

  Future<void> _sincronizarDatosBackend() async {
    final ApiClient? cliente = widget.apiClient;
    if (cliente == null || _modoOfflineSimulado) return;
    await _ops.sincronizarDesdeBackend(cliente);
    if (_ops.puntos.isNotEmpty) {
      await widget.colaRepository.guardarDirectorioPuntosServicio(_ops.puntos);
      if (mounted) {
        setState(() {
          _puntos = List<PuntoServicioModel>.from(_ops.puntos);
        });
      }
    }
  }

  Future<void> _ejecutarSincronizacion({bool forzar = false}) async {
    if (_modoOfflineSimulado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo sin conexión activo: los reportes siguen en cola.',
          ),
        ),
      );
      return;
    }
    setState(() => _sincronizando = true);
    try {
      await widget.syncWorkerService.sincronizarPendientes(forzar: forzar);
      await _recargarDatosLocales();
    } finally {
      if (mounted) {
        setState(() => _sincronizando = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    _ops.auditar(_sesion, 'LOGOUT', 'manual');
    await widget.authRepository.cerrarSesion();
    if (!mounted) return;
    setState(() {
      _sesion = null;
      _modoEmergenciaSinCuenta = false;
      _indiceActual = 0;
    });
  }

  int get _cantidadPendientes =>
      _reportes.where((r) => !r.estadoCola.estaSincronizado).length;

  @override
  Widget build(BuildContext context) {
    if (_sesion == null && !_modoEmergenciaSinCuenta) {
      return LoginPage(
        authRepository: widget.authRepository,
        onLoginSuccess: (UsuarioSesion s) {
          _ops.auditar(s, 'LOGIN OK', '${s.rol.valor} (${s.proveedor})');
          setState(() {
            _sesion = s;
            _modoEmergenciaSinCuenta = false;
            _ultimaActividad = DateTime.now();
            _indiceActual = 0;
          });
          if (!_modoOfflineSimulado) {
            unawaited(_sincronizarDatosBackend());
            if (_cantidadPendientes > 0) {
              unawaited(_ejecutarSincronizacion());
            }
          }
        },
        onContinuarSinCuenta: () {
          setState(() {
            _modoEmergenciaSinCuenta = true;
            _indiceActual = 0;
          });
        },
      );
    }

    final UsuarioSesion sesionEfectiva =
        _sesion ??
        UsuarioSesion(
          id: 'anonimo-offline',
          nombre: 'Ciudadano (sin cuenta)',
          correo: 'Modo emergencia offline',
          rol: RolUsuario.ciudadano,
          expiraEn: DateTime.now().toUtc().add(const Duration(hours: 12)),
        );

    final (List<Widget> paginas, List<NavigationDestination> destinos) =
        _construirNavegacionPorRol(sesionEfectiva);
    final int idx = _indiceActual.clamp(0, paginas.length - 1);

    return Listener(
      onPointerDown: (_) => _ultimaActividad = DateTime.now(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('assets/logo.png', width: 18, height: 21),
              const SizedBox(width: 5),
              const Text('ESMERALDAS '),
              const Text(
                'RESILIENTE',
                style: TextStyle(color: AppTheme.colorPrimario),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.colorRol(sesionEfectiva.rol)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline,
                      size: 11,
                      color: AppTheme.colorRol(sesionEfectiva.rol),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      AppTheme.etiquetaRol(sesionEfectiva.rol),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorRol(sesionEfectiva.rol),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FilterChip(
              label: Text(
                _modoOfflineSimulado ? 'Offline' : 'Online',
                style: const TextStyle(fontSize: 11),
              ),
              selected: _modoOfflineSimulado,
              avatar: Icon(
                _modoOfflineSimulado ? Icons.airplanemode_active : Icons.wifi,
                size: 16,
              ),
              onSelected: (bool valor) {
                setState(() => _modoOfflineSimulado = valor);
                if (!valor) _ejecutarSincronizacion(forzar: true);
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: <Widget>[
            SyncStatusBanner(
              pendientesCount: _cantidadPendientes,
              sincronizando: _sincronizando,
              onReintentar: () => _ejecutarSincronizacion(forzar: true),
            ),
            Expanded(child: paginas[idx]),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          labelBehavior: destinos.length > 5
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (int nuevoIndice) {
            setState(() => _indiceActual = nuevoIndice);
          },
          destinations: destinos,
        ),
      ),
    );
  }

  (List<Widget>, List<NavigationDestination>) _construirNavegacionPorRol(
    UsuarioSesion s,
  ) {
    switch (s.rol) {
      case RolUsuario.ciudadano:
        final Set<String> idsCola = _reportes.map((r) => r.id).toSet();
        final List<PinMapaIncidente> incidentesSector = _ops.reportes
            .where(
              (op) =>
                  op.estado != EstadoReporte.atendido &&
                  !idsCola.contains(op.id),
            )
            .map(
              (op) => PinMapaIncidente(
                punto: op.punto,
                gravedad: op.gravedad,
                etiqueta: '${op.tipo.etiqueta} (${op.sector})',
              ),
            )
            .toList();
        return (
          <Widget>[
            CrearReportePage(
              crearReporteUseCase: widget.crearReporteUseCase,
              locationService: widget.locationService,
              tieneConexionReal: !_modoOfflineSimulado,
              puntosServicio: _puntos,
              reportes: _reportes,
              incidentesExtra: incidentesSector,
              onReporteGuardado: () async {
                await _recargarDatosLocales();
                if (!_modoOfflineSimulado) {
                  await _ejecutarSincronizacion();
                }
                if (!mounted) return;
                final bool quedoPendiente =
                    _modoOfflineSimulado || _cantidadPendientes > 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      quedoPendiente
                          ? 'Reporte guardado en cola local y marcado en el mapa; se enviará al conectar con el servidor.'
                          : 'Reporte sincronizado con el servidor y publicado en el mapa de Esmeraldas.',
                    ),
                    action: SnackBarAction(
                      label: 'Mis reportes',
                      onPressed: () {
                        if (mounted) {
                          setState(() => _indiceActual = 1);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            MisReportesPage(
              reportes: _reportes,
              onSincronizarManual: () => _ejecutarSincronizacion(forzar: true),
              onEliminarReporte: (String id) async {
                await widget.colaRepository.eliminarReporte(id);
                await _recargarDatosLocales();
              },
              sinCuenta: _sesion == null,
              onIniciarSesion: () {
                setState(() {
                  _modoEmergenciaSinCuenta = false;
                  _indiceActual = 0;
                });
              },
            ),
            DirectorioAlberguesPage(
              puntos: _puntos,
              locationService: widget.locationService,
              tieneConexionReal: !_modoOfflineSimulado,
              apiClient: widget.apiClient,
              colaRepository: widget.colaRepository,
            ),
            CuentaCiudadanoPage(
              sesion: s,
              sinCuenta: _sesion == null,
              onCerrarSesion: _cerrarSesion,
            ),
          ],
          <NavigationDestination>[
            const NavigationDestination(
              icon: Icon(Icons.add_a_photo_outlined),
              selectedIcon: Icon(Icons.add_a_photo),
              label: 'Reportar',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _cantidadPendientes > 0,
                label: Text('$_cantidadPendientes'),
                child: const Icon(Icons.outbox_outlined),
              ),
              selectedIcon: const Icon(Icons.outbox),
              label: 'Mis reportes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.night_shelter_outlined),
              selectedIcon: Icon(Icons.night_shelter),
              label: 'Albergues',
            ),
            const NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: 'Cuenta',
            ),
          ],
        );

      case RolUsuario.operador911:
        return (
          <Widget>[
            _paginaSituacion(s),
            IncidentesOperadorPage(
              repo: _ops,
              sesion: s,
              ia: widget.sugerenciaIaRepository,
            ),
            _paginaAnalisis(),
            _paginaTerritorio(s),
            SeguridadCuentaPage(
              repo: _ops,
              sesion: s,
              onCerrarSesion: _cerrarSesion,
            ),
          ],
          const <NavigationDestination>[
            _destinoSituacion,
            _destinoIncidentes,
            _destinoAnalisis,
            _destinoTerritorio,
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Seguridad',
            ),
          ],
        );

      case RolUsuario.bomberos:
      case RolUsuario.policia:
        return (
          <Widget>[
            SituacionOperadorPage(
              repo: _ops,
              sesion: s,
              tieneConexion: !_modoOfflineSimulado,
              onSeleccionarReporte: (ReporteOperacion r) =>
                  mostrarHojaGestionReporte(
                    context,
                    repo: _ops,
                    sesion: s,
                    reporte: r,
                    ia: widget.sugerenciaIaRepository,
                  ),
            ),
            IncidentesOperadorPage(
              repo: _ops,
              sesion: s,
              ia: widget.sugerenciaIaRepository,
            ),
            _paginaTerritorio(s),
            SeguridadCuentaPage(
              repo: _ops,
              sesion: s,
              onCerrarSesion: _cerrarSesion,
            ),
          ],
          const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Situación',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined),
              selectedIcon: Icon(Icons.emergency),
              label: 'Incidentes',
            ),
            _destinoTerritorio,
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Seguridad',
            ),
          ],
        );

      case RolUsuario.admin:
        return (
          <Widget>[
            SituacionOperadorPage(
              repo: _ops,
              sesion: s,
              tieneConexion: !_modoOfflineSimulado,
              onSeleccionarReporte: (ReporteOperacion r) =>
                  mostrarHojaGestionReporte(
                    context,
                    repo: _ops,
                    sesion: s,
                    reporte: r,
                    ia: widget.sugerenciaIaRepository,
                  ),
            ),
            IncidentesOperadorPage(
              repo: _ops,
              sesion: s,
              ia: widget.sugerenciaIaRepository,
            ),
            _paginaAnalisis(),
            _paginaTerritorio(s),
            AdministracionPage(
              repo: _ops,
              sesion: s,
              onCerrarSesion: _cerrarSesion,
            ),
          ],
          const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Situación',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined),
              selectedIcon: Icon(Icons.emergency),
              label: 'Incidentes',
            ),
            _destinoAnalisis,
            _destinoTerritorio,
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Administración',
            ),
          ],
        );
    }
  }

  Widget _paginaSituacion(UsuarioSesion s) => SituacionOperadorPage(
    repo: _ops,
    sesion: s,
    tieneConexion: !_modoOfflineSimulado,
    onSeleccionarReporte: (ReporteOperacion r) => mostrarHojaGestionReporte(
      context,
      repo: _ops,
      sesion: s,
      reporte: r,
      ia: widget.sugerenciaIaRepository,
    ),
  );

  /// Albergues, vías y alertas por sector ("Alertas y vías" + "Albergues" de la web).
  Widget _paginaTerritorio(UsuarioSesion s) => PuntosAlertasOperadorPage(
    repo: _ops,
    sesion: s,
    seccionVias: ViasSection(
      repositorio: widget.viasRepository,
      puedeEditar: const <RolUsuario>{
        RolUsuario.operador911,
        RolUsuario.policia,
        RolUsuario.admin,
      }.contains(s.rol),
      tieneConexion: !_modoOfflineSimulado,
    ),
  );

  static const NavigationDestination _destinoTerritorio = NavigationDestination(
    icon: Icon(Icons.campaign_outlined),
    selectedIcon: Icon(Icons.campaign),
    label: 'Territorio',
  );

  Widget _paginaAnalisis() => AnalisisPage(
    repositorio: widget.analisisRepository,
    tieneConexion: !_modoOfflineSimulado,
  );

  static const NavigationDestination _destinoSituacion = NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Situación',
  );

  static const NavigationDestination _destinoIncidentes = NavigationDestination(
    icon: Icon(Icons.emergency_outlined),
    selectedIcon: Icon(Icons.emergency),
    label: 'Incidentes',
  );

  static const NavigationDestination _destinoAnalisis = NavigationDestination(
    icon: Icon(Icons.insights_outlined),
    selectedIcon: Icon(Icons.insights),
    label: 'Análisis',
  );
}
