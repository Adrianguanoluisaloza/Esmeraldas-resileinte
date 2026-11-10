import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/config/firebase_web_options.dart';
import 'core/location/location_service.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/services/mbtiles_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/cola_reportes_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/reporte/domain/usecases/crear_reporte_offline_usecase.dart';
import 'features/sync/data/services/sync_worker_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: kIsWeb ? opcionesFirebaseWeb : null);

  // Inicialización de Hive y del paquete offline MBTiles de la Provincia de Esmeraldas
  final ColaReportesRepository colaRepository = HiveColaReportesRepository();
  await Future.wait(<Future<void>>[
    colaRepository.inicializar(),
    EsmeraldasMbTilesService.inicializar(),
  ]);

  runApp(EsmeraldasResilienteApp(colaRepository: colaRepository));
}

class EsmeraldasResilienteApp extends StatefulWidget {
  const EsmeraldasResilienteApp({
    super.key,
    required this.colaRepository,
    this.authRepository,
    this.locationService,
    this.apiClient,
  });

  final ColaReportesRepository colaRepository;
  final AuthRepository? authRepository;
  final LocationService? locationService;
  final ApiClient? apiClient;

  @override
  State<EsmeraldasResilienteApp> createState() =>
      _EsmeraldasResilienteAppState();
}

class _EsmeraldasResilienteAppState extends State<EsmeraldasResilienteApp> {
  late final AuthRepository _authRepository;
  late final LocationService _locationService;
  late final ApiClient _apiClient;
  late final CrearReporteOfflineUseCase _crearReporteUseCase;
  late final SyncWorkerService _syncWorkerService;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? SecureStorageAuthRepository();
    _locationService = widget.locationService ?? const LocalLocationService();
    _apiClient =
        widget.apiClient ?? DioApiClient(authRepository: _authRepository);
    _crearReporteUseCase = CrearReporteOfflineUseCase(
      colaRepository: widget.colaRepository,
    );
    _syncWorkerService = SyncWorkerService(
      colaRepository: widget.colaRepository,
      apiClient: _apiClient,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esmeraldas Resiliente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeShellPage(
        colaRepository: widget.colaRepository,
        authRepository: _authRepository,
        locationService: _locationService,
        apiClient: _apiClient,
        crearReporteUseCase: _crearReporteUseCase,
        syncWorkerService: _syncWorkerService,
      ),
    );
  }
}
