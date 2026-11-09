import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/services/photo_capture_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mapa_fondo_esmeraldas.dart';
import '../../../../data/models/punto_servicio_model.dart';
import '../../../../data/models/reporte_cola_model.dart';
import '../../domain/usecases/crear_reporte_offline_usecase.dart';
import '../widgets/bloque_familia_widget.dart';

enum _PasoReporte { mapaInicial, confirmarUbicacion, formulario }

/// Pantalla de inicio del ciudadano idéntica al flujo de 3 pasos del HTML (`fire-shield.html`):
/// 1. Mapa de Esmeraldas despejado, utilizable y seleccionable + botón pequeño lateral de GPS
///    + botón rojo inferior "Reportar emergencia".
/// 2. Tarjeta de confirmación de ubicación ("Confirmar" / "Cancelar").
/// 3. Tarjetas flotantes del formulario ("¿Qué está pasando?", foto, familia y envío).
class CrearReportePage extends StatefulWidget {
  const CrearReportePage({
    super.key,
    required this.crearReporteUseCase,
    required this.locationService,
    required this.onReporteGuardado,
    this.tieneConexionReal = true,
    this.puntosServicio = const <PuntoServicioModel>[],
    this.reportes = const <ReporteColaModel>[],
    this.incidentesExtra = const <PinMapaIncidente>[],
    this.photoCaptureService,
  });

  final CrearReporteOfflineUseCase crearReporteUseCase;
  final LocationService locationService;
  final VoidCallback onReporteGuardado;
  final bool tieneConexionReal;
  final List<PuntoServicioModel> puntosServicio;
  final List<ReporteColaModel> reportes;
  final List<PinMapaIncidente> incidentesExtra;
  final PhotoCaptureService? photoCaptureService;

  @override
  State<CrearReportePage> createState() => _CrearReportePageState();
}

class _CrearReportePageState extends State<CrearReportePage> {
  final MapController _mapController = MapController();
  late final PhotoCaptureService _photoService;

  _PasoReporte _paso = _PasoReporte.mapaInicial;
  TipoIncidente _tipoSeleccionado = TipoIncidente.inundacion;
  GravedadIncidente _gravedadSeleccionada = GravedadIncidente.alta;
  final TextEditingController _descripcionController = TextEditingController();

  CoordenadaCapturada? _coordenada;
  LatLng? _puntoMarcadoEnMapa;
  bool _capturandoGps = false;
  bool _capturandoFoto = false;
  FotoCapturada? _fotoCapturada;

  int _personasAfectadas = 0;
  int _ninos = 0;
  int _adultosMayores = 0;
  final Set<NecesidadFamiliar> _necesidades = <NecesidadFamiliar>{};

  static const Map<TipoIncidente, IconData> _iconosTipo =
      <TipoIncidente, IconData>{
        TipoIncidente.inundacion: Icons.water,
        TipoIncidente.deslizamiento: Icons.landscape,
        TipoIncidente.viaBloqueada: Icons.signpost,
        TipoIncidente.personasAtrapadas: Icons.sos,
        TipoIncidente.danoVivienda: Icons.house_siding,
        TipoIncidente.otro: Icons.add,
      };

  @override
  void initState() {
    super.initState();
    _photoService = widget.photoCaptureService ?? PhotoCaptureService();
    _obtenerUbicacionDispositivo(centrarMapa: false);
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _ubicacionGps => _coordenada != null
      ? LatLng(_coordenada!.latitud, _coordenada!.longitud)
      : const LatLng(
          AppConfig.esmeraldasCenterLat,
          AppConfig.esmeraldasCenterLng,
        );

  LatLng get _coordenadaActiva => _puntoMarcadoEnMapa ?? _ubicacionGps;

  Future<void> _obtenerUbicacionDispositivo({bool centrarMapa = true}) async {
    setState(() => _capturandoGps = true);
    try {
      final CoordenadaCapturada? coord = await widget.locationService
          .capturarUbicacionConRespaldo();
      if (!mounted) return;
      setState(() {
        _coordenada = coord;
        if (centrarMapa) {
          _puntoMarcadoEnMapa = null;
        }
      });
      if (centrarMapa && widget.tieneConexionReal) {
        try {
          _mapController.move(_ubicacionGps, AppConfig.defaultZoom);
        } catch (_) {
          // Ignorado si el mapa aún no terminó de montar
        }
      }
    } finally {
      if (mounted) {
        setState(() => _capturandoGps = false);
      }
    }
  }

  void _alTocarMapa(LatLng punto) {
    setState(() {
      _puntoMarcadoEnMapa = punto;
      if (_paso == _PasoReporte.mapaInicial) {
        _paso = _PasoReporte.confirmarUbicacion;
      }
    });
  }

  Future<void> _capturarDesdeOrigen(ImageSource origen) async {
    setState(() => _capturandoFoto = true);
    try {
      final FotoCapturada? foto = await _photoService.capturarYComprimir(
        origen: origen,
      );
      if (!mounted || foto == null) return;
      setState(() => _fotoCapturada = foto);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto comprimida lista (${foto.etiquetaTamano} · máx ${AppConfig.photoMaxDimensionPx} px).',
          ),
        ),
      );
    } on PermisoCamaraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.colorSemaforoRojo,
          content: Text(e.mensaje),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _capturandoFoto = false);
      }
    }
  }

  void _mostrarSelectorFoto() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Evidencia fotográfica del incidente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El celular solicitará permiso de cámara y comprimirá la foto a 1280 px (JPEG 75%) fuera de Hive.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.colorSemaforoRojo,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.photo_camera_outlined),
                  ),
                  title: const Text(
                    'Tomar foto con la cámara',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Pide permiso de cámara del dispositivo y captura en el sitio',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarDesdeOrigen(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.colorPrimario,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: const Text(
                    'Elegir desde la galería',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Selecciona una foto ya tomada en tu celular',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarDesdeOrigen(ImageSource.gallery);
                  },
                ),
                if (_fotoCapturada != null) ...<Widget>[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.colorCampo,
                      foregroundColor: AppTheme.colorSemaforoRojo,
                      child: Icon(Icons.delete_outline),
                    ),
                    title: const Text(
                      'Quitar foto adjunta',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colorSemaforoRojo,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _fotoCapturada = null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardarReporteEnCola() async {
    // M3: latitud norte positiva en Esmeraldas (~0.9592)
    final CoordenadaCapturada coordenadaFinal = _puntoMarcadoEnMapa != null
        ? CoordenadaCapturada(
            latitud: _puntoMarcadoEnMapa!.latitude,
            longitud: _puntoMarcadoEnMapa!.longitude,
            precisionMetros: 10.0,
            esAproximada: false,
          )
        : (_coordenada ??
              const CoordenadaCapturada(
                latitud: AppConfig.esmeraldasCenterLat,
                longitud: AppConfig.esmeraldasCenterLng,
                precisionMetros: 50.0,
                esAproximada: true,
              ));

    await widget.crearReporteUseCase.ejecutar(
      DatosNuevoReporte(
        tipo: _tipoSeleccionado,
        descripcion: _descripcionController.text,
        gravedad: _gravedadSeleccionada,
        coordenada: coordenadaFinal,
        rutaFotoLocal: _fotoCapturada?.rutaLocal ?? '',
        personasAfectadas: _personasAfectadas,
        ninos: _ninos,
        adultosMayores: _adultosMayores,
        necesidades: _necesidades.toList(),
      ),
    );

    if (!mounted) return;
    final LatLng puntoCreado = LatLng(
      coordenadaFinal.latitud,
      coordenadaFinal.longitud,
    );
    _descripcionController.clear();
    setState(() {
      _personasAfectadas = 0;
      _ninos = 0;
      _adultosMayores = 0;
      _necesidades.clear();
      _fotoCapturada = null;
      _puntoMarcadoEnMapa = null;
      _paso = _PasoReporte.mapaInicial;
    });
    if (widget.tieneConexionReal) {
      try {
        _mapController.move(puntoCreado, AppConfig.defaultZoom);
      } catch (_) {}
    }
    widget.onReporteGuardado();
  }

  List<PinMapaIncidente> _construirPinesIncidentes() {
    final Set<String> idsLocales = <String>{};
    final List<PinMapaIncidente> pines = <PinMapaIncidente>[];

    for (final ReporteColaModel r in widget.reportes) {
      idsLocales.add(r.id);
      pines.add(
        PinMapaIncidente(
          punto: LatLng(r.latitud, r.longitud),
          gravedad: r.gravedad,
          etiqueta: r.tipo.etiqueta,
          onTap: () => _mostrarDetalleReporteMapa(r),
        ),
      );
    }

    for (final PinMapaIncidente extra in widget.incidentesExtra) {
      pines.add(extra);
    }

    return pines;
  }

  void _mostrarDetalleReporteMapa(ReporteColaModel r) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        final bool sincronizado = r.estadoCola.estaSincronizado;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    _iconosTipo[r.tipo] ?? Icons.warning_amber,
                    color: AppTheme.colorGravedad(r.gravedad),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${r.tipo.etiqueta} · Gravedad ${r.gravedad.etiqueta}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: sincronizado
                        ? AppTheme.colorSemaforoVerde.withValues(alpha: 0.14)
                        : AppTheme.colorSemaforoAmbar.withValues(alpha: 0.16),
                    label: Text(
                      r.estadoCola.etiqueta,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sincronizado
                            ? AppTheme.colorSemaforoVerde
                            : AppTheme.colorSemaforoAmbar,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (r.descripcion.trim().isNotEmpty) ...<Widget>[
                Text(r.descripcion, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
              ],
              Text(
                'Coordenadas: ${r.latitud.toStringAsFixed(4)}, ${r.longitud.toStringAsFixed(4)} '
                '· Personas: ${r.personasAfectadas}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorTextoSecundario,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Fondo: Mapa interactivo y seleccionable de Esmeraldas con pines de reportes
        Positioned.fill(
          child: MapaFondoEsmeraldas(
            mapController: _mapController,
            tieneConexion: widget.tieneConexionReal,
            ubicacionUsuario: _ubicacionGps,
            ubicacionIncidenteMarcado: _puntoMarcadoEnMapa,
            puntosServicio: widget.puntosServicio,
            incidentes: _construirPinesIncidentes(),
            onTapMapa: _alTocarMapa,
          ),
        ),

        // Paso 1: Mapa despejado + botón pequeño lateral de ubicación + botón rojo abajo
        if (_paso == _PasoReporte.mapaInicial)
          _construirVistaMapaInicial()
        // Paso 2: Confirmación de la ubicación marcada
        else if (_paso == _PasoReporte.confirmarUbicacion)
          _construirVistaConfirmacion()
        // Paso 3: Formulario flotante del reporte
        else
          _construirVistaFormulario(),
      ],
    );
  }

  Widget _construirBotonGpsLateral() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 14, bottom: 12),
        child: FloatingActionButton.small(
          heroTag: 'btn_gps_dispositivo',
          tooltip: 'Obtener mi ubicación actual',
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.colorPrimario,
          onPressed: _capturandoGps
              ? null
              : () => _obtenerUbicacionDispositivo(centrarMapa: true),
          child: _capturandoGps
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ),
    );
  }

  static const Map<String, LatLng> _sectoresEsmeraldas = <String, LatLng>{
    'Las Palmas': LatLng(0.9850, -79.6540),
    'Centro': LatLng(0.9650, -79.6540),
    'Barrio 50 Casas': LatLng(0.9450, -79.6680),
    'Isla Piedad': LatLng(0.9765, -79.6582),
    'El Arenal': LatLng(0.9700, -79.6490),
    'Barrio 20 de Noviembre': LatLng(0.9548, -79.6695),
    'Tachina / Aeropuerto': LatLng(0.9824, -79.6385),
    'San Rafael': LatLng(0.9428, -79.6812),
    'Ribera del río Teaone (Tabiazo)': LatLng(0.9120, -79.6320),
  };

  void _mostrarSelectorSectores() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Elige tu sector (Reporte sin GPS)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _sectoresEsmeraldas.entries.map((MapEntry<String, LatLng> e) {
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(e.key),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _puntoMarcadoEnMapa = e.value;
                          _paso = _PasoReporte.confirmarUbicacion;
                        });
                        try {
                          _mapController.move(e.value, AppConfig.defaultZoom);
                        } catch (_) {}
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirVistaMapaInicial() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _construirBotonGpsLateral(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.colorSemaforoRojo,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                setState(() {
                  _puntoMarcadoEnMapa ??= _ubicacionGps;
                  _paso = _PasoReporte.confirmarUbicacion;
                });
              },
              icon: const Icon(Icons.local_fire_department_outlined),
              label: const Text('Reportar emergencia'),
            ),
            const SizedBox(height: 8),
            ActionChip(
              backgroundColor: Colors.white,
              avatar: const Icon(Icons.location_city, size: 14, color: AppTheme.colorPrimario),
              label: const Text('¿Sin señal GPS? Toca aquí para elegir tu sector', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: _mostrarSelectorSectores,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.colorBorde),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Toca en el mapa para marcar la ubicación',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.gps_fixed, size: 14, color: AppTheme.colorTexto),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVistaConfirmacion() {
    final LatLng c = _coordenadaActiva;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _construirBotonGpsLateral(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.gps_fixed,
                          size: 18,
                          color: AppTheme.colorSemaforoRojo,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confirmar la ubicación de la emergencia',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Cantón Esmeraldas, Provincia de Esmeraldas\n'
                        'Coordenadas: ${c.latitude.toStringAsFixed(4)}, ${c.longitude.toStringAsFixed(4)}\n'
                        'Precisión estimada: ±${(_coordenada?.precisionMetros ?? 12).toStringAsFixed(0)} m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.colorTextoSecundario,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.colorTexto,
                              minimumSize: const Size.fromHeight(42),
                            ),
                            onPressed: () {
                              setState(() => _paso = _PasoReporte.formulario);
                            },
                            child: const Text('Confirmar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.colorCampo,
                              minimumSize: const Size.fromHeight(42),
                            ),
                            onPressed: () {
                              setState(() {
                                _puntoMarcadoEnMapa = null;
                                _paso = _PasoReporte.mapaInicial;
                              });
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ActionChip(
              backgroundColor: Colors.white,
              avatar: const Icon(Icons.location_city, size: 14, color: AppTheme.colorPrimario),
              label: const Text('¿Sin señal GPS? Toca aquí para elegir tu sector', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: _mostrarSelectorSectores,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.colorBorde),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Toca otro punto en el mapa si deseas corregir',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.gps_fixed, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVistaFormulario() {
    final bool tieneFoto = _fotoCapturada != null;
    final LatLng coordMostrada = _coordenadaActiva;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 90, 14, 16),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.colorTexto,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              setState(() => _paso = _PasoReporte.mapaInicial);
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              'Cambiar punto en el mapa',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 1. ¿Qué está pasando?
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '¿Qué está pasando?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Selecciona el tipo de emergencia y su gravedad.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.18,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: TipoIncidente.values.map((TipoIncidente tipo) {
                    final bool sel = _tipoSeleccionado == tipo;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _tipoSeleccionado = tipo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : AppTheme.colorCampo,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? AppTheme.colorPrimario
                                : AppTheme.colorBorde,
                            width: sel ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              _iconosTipo[tipo] ?? Icons.warning_amber,
                              size: 23,
                              color: sel
                                  ? AppTheme.colorPrimario
                                  : AppTheme.colorTextoApagado,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipo.etiqueta,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel
                                    ? AppTheme.colorTexto
                                    : AppTheme.colorTextoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SegmentedButton<GravedadIncidente>(
                  segments: GravedadIncidente.values
                      .map(
                        (GravedadIncidente g) =>
                            ButtonSegment<GravedadIncidente>(
                              value: g,
                              label: Text(
                                g.etiqueta,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                      )
                      .toList(),
                  selected: <GravedadIncidente>{_gravedadSeleccionada},
                  onSelectionChanged: (Set<GravedadIncidente> nueva) {
                    setState(() => _gravedadSeleccionada = nueva.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Foto + GPS
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                onTap: _capturandoFoto ? null : _mostrarSelectorFoto,
                leading: _capturandoFoto
                    ? const SizedBox(
                        width: 38,
                        height: 38,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : (tieneFoto && _fotoCapturada!.bytesEnMemoria != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _fotoCapturada!.bytesEnMemoria!,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tieneFoto
                              ? AppTheme.colorSemaforoVerde
                              : AppTheme.colorSemaforoRojo,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tieneFoto ? Icons.check : Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                title: Text(
                  _capturandoFoto
                      ? 'Abriendo cámara y comprimiendo foto...'
                      : tieneFoto
                      ? 'Foto comprimida · 1280 px · ${_fotoCapturada!.etiquetaTamano}'
                      : '¿Puedes tomar una foto del incidente?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  tieneFoto
                      ? 'Toca para cambiar o quitar la evidencia fotográfica'
                      : 'Pide permiso de cámara y guarda fuera de Hive',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Icon(
                  tieneFoto ? Icons.edit_outlined : Icons.add_a_photo_outlined,
                  size: 18,
                  color: AppTheme.colorTextoSecundario,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.gps_fixed,
                  color: AppTheme.colorPrimario,
                ),
                title: Text(
                  '${coordMostrada.latitude.toStringAsFixed(4)}, '
                  '${coordMostrada.longitude.toStringAsFixed(4)} '
                  '· ±${(_coordenada?.precisionMetros ?? 12).toStringAsFixed(0)} m',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _puntoMarcadoEnMapa != null
                      ? 'Punto seleccionado en el mapa de Esmeraldas'
                      : 'Ubicación GPS del dispositivo (latitud norte positiva)',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Familia afectada
        BloqueFamiliaWidget(
          personasAfectadas: _personasAfectadas,
          ninos: _ninos,
          adultosMayores: _adultosMayores,
          necesidadesSeleccionadas: _necesidades,
          onPersonasChanged: (int v) => setState(() => _personasAfectadas = v),
          onNinosChanged: (int v) => setState(() => _ninos = v),
          onAdultosMayoresChanged: (int v) =>
              setState(() => _adultosMayores = v),
          onToggleNecesidad: (NecesidadFamiliar nec) {
            setState(() {
              if (_necesidades.contains(nec)) {
                _necesidades.remove(nec);
              } else {
                _necesidades.add(nec);
              }
            });
          },
        ),
        const SizedBox(height: 10),

        // 4. Descripción + botón rojo de envío
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _descripcionController,
                  maxLength: 280,
                  decoration: const InputDecoration(
                    hintText:
                        'Explica un poco más (sector o referencia, opcional)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.colorSemaforoRojo,
                  ),
                  onPressed: _guardarReporteEnCola,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Enviar reporte de emergencia'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
