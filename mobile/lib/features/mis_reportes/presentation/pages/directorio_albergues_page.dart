import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mapa_fondo_esmeraldas.dart';
import '../../../../data/models/punto_servicio_model.dart';
import '../../../../data/repositories/cola_reportes_repository.dart';

/// Pantalla de Albergues y Centros de Salud (M5 de `TAREAS_MOVIL_FRANCO.md`):
/// - Descarga `GET /puntos-servicio` cuando hay red y lo guarda en la caja de Hive.
/// - Muestra el semáforo con texto ("Con cupo", "Casi lleno", "Lleno"), nunca solo color.
/// - Ofrece "Más cercano" con `/puntos-servicio/cercanos?lat=&lng=&personas=`.
class DirectorioAlberguesPage extends StatefulWidget {
  const DirectorioAlberguesPage({
    super.key,
    required this.puntos,
    required this.locationService,
    required this.tieneConexionReal,
    this.apiClient,
    this.colaRepository,
  });

  final List<PuntoServicioModel> puntos;
  final LocationService locationService;
  final bool tieneConexionReal;
  final ApiClient? apiClient;
  final ColaReportesRepository? colaRepository;

  @override
  State<DirectorioAlberguesPage> createState() =>
      _DirectorioAlberguesPageState();
}

class _DirectorioAlberguesPageState extends State<DirectorioAlberguesPage> {
  List<PuntoServicioModel>? _puntosActualizados;
  bool _ordenarMasCercano = false;
  int _tamanoFamilia = 1;
  bool _cargando = false;

  List<PuntoServicioModel> get _listaActiva =>
      _puntosActualizados ?? widget.puntos;

  @override
  void initState() {
    super.initState();
    if (widget.tieneConexionReal) {
      _sincronizarDirectorio();
    }
  }

  Future<void> _sincronizarDirectorio() async {
    if (widget.apiClient == null) return;
    setState(() => _cargando = true);
    try {
      final List<PuntoServicioModel> remotos = await widget.apiClient!
          .obtenerPuntosServicio();
      if (remotos.isNotEmpty) {
        await widget.colaRepository?.guardarDirectorioPuntosServicio(remotos);
        if (mounted) {
          setState(() => _puntosActualizados = remotos);
        }
      }
    } catch (_) {
      // Mantiene la copia local de Hive cuando no responde el servidor
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _buscarMasCercanos() async {
    setState(() {
      _ordenarMasCercano = true;
      _cargando = true;
    });
    try {
      final CoordenadaCapturada coord =
          await widget.locationService.capturarUbicacionConRespaldo() ??
          const CoordenadaCapturada(
            latitud: AppConfig.esmeraldasCenterLat,
            longitud: AppConfig.esmeraldasCenterLng,
            precisionMetros: 15,
            esAproximada: false,
          );
      if (widget.tieneConexionReal && widget.apiClient != null) {
        final List<PuntoServicioModel> cercanos = await widget.apiClient!
            .obtenerPuntosCercanos(
              lat: coord.latitud,
              lng: coord.longitud,
              personas: _tamanoFamilia,
            );
        if (cercanos.isNotEmpty && mounted) {
          setState(() => _puntosActualizados = cercanos);
          return;
        }
      }
      // Respaldo local por fórmula de Haversine y cupo disponible
      final List<PuntoServicioModel> copia = List<PuntoServicioModel>.from(
        _listaActiva,
      );
      copia.sort((PuntoServicioModel a, PuntoServicioModel b) {
        final bool aCabe = a.cuposDisponibles >= _tamanoFamilia;
        final bool bCabe = b.cuposDisponibles >= _tamanoFamilia;
        if (aCabe != bCabe) return aCabe ? -1 : 1;
        final double da = widget.locationService.calcularDistanciaKm(
          lat1: coord.latitud,
          lon1: coord.longitud,
          lat2: a.latitud,
          lon2: a.longitud,
        );
        final double db = widget.locationService.calcularDistanciaKm(
          lat1: coord.latitud,
          lon1: coord.longitud,
          lat2: b.latitud,
          lon2: b.longitud,
        );
        return da.compareTo(db);
      });
      if (mounted) setState(() => _puntosActualizados = copia);
    } catch (_) {
      // Conserva el orden actual si ocurre un error
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PuntoServicioModel> items = _listaActiva;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: MapaFondoEsmeraldas(
            tieneConexion: widget.tieneConexionReal,
            ubicacionUsuario: const LatLng(
              AppConfig.esmeraldasCenterLat,
              AppConfig.esmeraldasCenterLng,
            ),
            puntosServicio: items,
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 140, 14, 16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.night_shelter,
                          size: 18,
                          color: AppTheme.colorPrimario,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Albergues y centros de salud',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_cargando)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Personas en tu familia:',
                          style: TextStyle(fontSize: 12),
                        ),
                        IconButton(
                          onPressed: _tamanoFamilia > 1
                              ? () => setState(() => _tamanoFamilia--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_tamanoFamilia',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: _tamanoFamilia < 15
                              ? () => setState(() => _tamanoFamilia++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: _buscarMasCercanos,
                          icon: const Icon(Icons.near_me, size: 16),
                          label: Text(
                            _ordenarMasCercano
                                ? 'Ordenado por cercanía'
                                : 'Más cercano',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((PuntoServicioModel p) {
              final Color colorEstado = AppTheme.colorCupo(p.ratioOcupacion);
              final String textoCupo = AppTheme.etiquetaCupo(p.ratioOcupacion);
              final double distanciaKm = widget.locationService
                  .calcularDistanciaKm(
                    lat1: AppConfig.esmeraldasCenterLat,
                    lon1: AppConfig.esmeraldasCenterLng,
                    lat2: p.latitud,
                    lon2: p.longitud,
                  );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorEstado.withValues(alpha: 0.14),
                      child: Icon(
                        p.tipo.valor == 'albergue'
                            ? Icons.night_shelter
                            : Icons.local_hospital,
                        color: colorEstado,
                      ),
                    ),
                    title: Text(
                      p.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      '${p.tipo.etiqueta} · Libres: ${p.cuposDisponibles}/${p.capacidad}\n'
                      'A ${distanciaKm.toStringAsFixed(1)} km · Tel: ${p.telefono}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorEstado),
                      ),
                      child: Text(
                        textoCupo,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: colorEstado,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
