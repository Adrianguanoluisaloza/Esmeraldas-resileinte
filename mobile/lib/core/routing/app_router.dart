import 'package:flutter/material.dart';

import '../../data/models/punto_servicio_model.dart';
import '../../data/models/reporte_cola_model.dart';
import '../../data/repositories/cola_reportes_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/mis_reportes/presentation/pages/directorio_albergues_page.dart';
import '../../features/mis_reportes/presentation/pages/mis_reportes_page.dart';
import '../../features/reporte/domain/usecases/crear_reporte_offline_usecase.dart';
import '../../features/reporte/presentation/pages/crear_reporte_page.dart';
import '../../features/sync/data/services/sync_worker_service.dart';
import '../../features/sync/presentation/widgets/sync_status_banner.dart';
import '../location/location_service.dart';

/// Shell principal de navegación de Esmeraldas Resiliente.
/// Compone las dependencias inyectadas desde `main.dart` respetando Clean Architecture.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    required this.colaRepository,
    required this.authRepository,
    required this.locationService,
    required this.crearReporteUseCase,
    required this.syncWorkerService,
  });

  final ColaReportesRepository colaRepository;
  final AuthRepository authRepository;
  final LocationService locationService;
  final CrearReporteOfflineUseCase crearReporteUseCase;
  final SyncWorkerService syncWorkerService;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _indiceActual = 0;
  List<ReporteColaModel> _reportes = <ReporteColaModel>[];
  List<PuntoServicioModel> _puntos = <PuntoServicioModel>[];
  bool _sincronizando = false;
  bool _modoOfflineSimulado = false;

  @override
  void initState() {
    super.initState();
    _recargarDatosLocales();
  }

  Future<void> _recargarDatosLocales() async {
    final List<ReporteColaModel> listaReportes = await widget.colaRepository
        .obtenerTodosLosReportes();
    final List<PuntoServicioModel> listaPuntos = await widget.colaRepository
        .obtenerDirectorioPuntosServicio();
    if (!mounted) return;
    setState(() {
      _reportes = listaReportes;
      _puntos = listaPuntos;
    });
  }

  Future<void> _ejecutarSincronizacion() async {
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
      await widget.syncWorkerService.sincronizarPendientes();
      await _recargarDatosLocales();
    } finally {
      if (mounted) {
        setState(() => _sincronizando = false);
      }
    }
  }

  int get _cantidadPendientes =>
      _reportes.where((r) => !r.estadoCola.estaSincronizado).length;

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = <Widget>[
      CrearReportePage(
        crearReporteUseCase: widget.crearReporteUseCase,
        locationService: widget.locationService,
        onReporteGuardado: () async {
          await _recargarDatosLocales();
          setState(() => _indiceActual = 1);
        },
      ),
      MisReportesPage(
        reportes: _reportes,
        onSincronizarManual: _ejecutarSincronizacion,
      ),
      DirectorioAlberguesPage(
        puntos: _puntos,
        locationService: widget.locationService,
        tieneConexionReal: !_modoOfflineSimulado,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esmeraldas Resiliente'),
        actions: <Widget>[
          FilterChip(
            label: Text(_modoOfflineSimulado ? 'Offline' : 'Online'),
            selected: _modoOfflineSimulado,
            avatar: Icon(
              _modoOfflineSimulado ? Icons.airplanemode_active : Icons.wifi,
              size: 18,
            ),
            onSelected: (bool valor) {
              setState(() => _modoOfflineSimulado = valor);
            },
          ),
          IconButton(
            tooltip: 'Acceso ciudadano',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LoginPage(
                    authRepository: widget.authRepository,
                    onLoginSuccess: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SyncStatusBanner(
            pendientesCount: _cantidadPendientes,
            sincronizando: _sincronizando,
            onReintentar: _ejecutarSincronizacion,
          ),
          Expanded(child: paginas[_indiceActual]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int nuevoIndice) {
          setState(() => _indiceActual = nuevoIndice);
        },
        destinations: <NavigationDestination>[
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
        ],
      ),
    );
  }
}
