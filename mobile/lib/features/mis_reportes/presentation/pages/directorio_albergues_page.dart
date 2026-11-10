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
  List<Map<String, dynamic>> _alertasActivas = const <Map<String, dynamic>>[];
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
      final List<Map<String, dynamic>> alertas = await widget.apiClient!
          .obtenerAlertasActivas();
      if (mounted) {
        setState(() => _alertasActivas = alertas);
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
      final CoordenadaCapturada? coord = await widget.locationService
          .capturarUbicacionConRespaldo();
      if (coord == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sin señal GPS. Intenta junto a una ventana o al aire libre.',
              ),
            ),
          );
        }
        return;
      }
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
            ..._alertasActivas.map((Map<String, dynamic> alerta) {
              final bool esSimulacro =
                  alerta['es_simulacro'] == true ||
                  alerta['origen'] == 'simulacro' ||
                  alerta['origen'] == 'simulada';
              final Color colorAlerta = esSimulacro
                  ? AppTheme.colorOrigenSimulado
                  : AppTheme.colorSemaforoRojo;
              final String encabezado =
                  (alerta['titulo'] ?? alerta['sector'] ?? 'Alerta COE')
                      .toString();
              String mensaje = '${alerta['mensaje'] ?? ''}'.trim();
              if (esSimulacro &&
                  mensaje.toLowerCase().startsWith('simulacro:')) {
                mensaje = mensaje.substring('simulacro:'.length).trim();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esSimulacro
                        ? const Color(0xFFF7F5FE)
                        : const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: esSimulacro
                          ? const Color(0xFFE9E4F8)
                          : const Color(0xFFF9D5D5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.campaign, size: 18, color: colorAlerta),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              encabezado,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: colorAlerta,
                              ),
                            ),
                          ),
                          Text(
                            esSimulacro ? 'Simulacro' : 'Alerta oficial',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorAlerta,
                            ),
                          ),
                        ],
                      ),
                      if (mensaje.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          mensaje,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
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
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${p.tipo.etiqueta} · Libres: ${p.cuposDisponibles}/${p.capacidad}\n'
                          'A ${distanciaKm.toStringAsFixed(1)} km${p.telefono.trim().isNotEmpty ? ' · Tel: ${p.telefono.trim()}' : ''}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        if (p.pasoBloqueado)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: AppTheme.colorSemaforoAmbar,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'El camino cruza una vía bloqueada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.colorSemaforoAmbar,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
