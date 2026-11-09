import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/punto_servicio_model.dart';

/// Pantalla de Albergues y Centros de Salud con respaldo automático en lista cuando no hay conexión.
/// Cumple con la atribución obligatoria de OpenStreetMap y nunca muestra un cuadro en blanco sin red.
class DirectorioAlberguesPage extends StatefulWidget {
  const DirectorioAlberguesPage({
    super.key,
    required this.puntos,
    required this.locationService,
    required this.tieneConexionReal,
  });

  final List<PuntoServicioModel> puntos;
  final LocationService locationService;
  final bool tieneConexionReal;

  @override
  State<DirectorioAlberguesPage> createState() =>
      _DirectorioAlberguesPageState();
}

class _DirectorioAlberguesPageState extends State<DirectorioAlberguesPage> {
  bool _verComoMapa = false;

  Color _colorCupo(PuntoServicioModel punto) {
    final double ratio = punto.ratioOcupacion;
    if (ratio >= 0.9) return AppTheme.colorSemaforoRojo;
    if (ratio >= 0.7) return AppTheme.colorSemaforoAmbar;
    return AppTheme.colorSemaforoVerde;
  }

  @override
  Widget build(BuildContext context) {
    final bool puedeMostrarMapa = widget.tieneConexionReal && _verComoMapa;

    return Column(
      children: <Widget>[
        if (!widget.tieneConexionReal)
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Sin conexión: mostrando lista local de albergues y centros de salud.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Puntos de servicio en Esmeraldas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.list),
                      label: Text('Lista'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.map),
                      label: Text('Mapa OSM'),
                    ),
                  ],
                  selected: <bool>{_verComoMapa},
                  onSelectionChanged: (Set<bool> s) {
                    setState(() => _verComoMapa = s.first);
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: puedeMostrarMapa ? _construirMapaOsm() : _construirLista(),
        ),
      ],
    );
  }

  Widget _construirLista() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.puntos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final PuntoServicioModel p = widget.puntos[index];
        final Color colorEstado = _colorCupo(p);
        final double distanciaKm = widget.locationService.calcularDistanciaKm(
          lat1: AppConfig.esmeraldasCenterLat,
          lon1: AppConfig.esmeraldasCenterLng,
          lat2: p.latitud,
          lon2: p.longitud,
        );

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorEstado.withValues(alpha: 0.15),
              child: Icon(
                p.tipo.valor == 'albergue'
                    ? Icons.night_shelter
                    : Icons.local_hospital,
                color: colorEstado,
              ),
            ),
            title: Text(
              p.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${p.tipo.etiqueta} • Cupos libres: ${p.cuposDisponibles}/${p.capacidad}\n'
              'Distancia aprox.: ${distanciaKm.toStringAsFixed(1)} km • Tel: ${p.telefono}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _construirMapaOsm() {
    return Stack(
      children: <Widget>[
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(
              AppConfig.esmeraldasCenterLat,
              AppConfig.esmeraldasCenterLng,
            ),
            initialZoom: AppConfig.defaultZoom,
            minZoom: AppConfig.minZoom,
            maxZoom: AppConfig.maxZoom,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: AppConfig.osmTileUrlTemplate,
              userAgentPackageName: AppConfig.osmUserAgentPackageName,
            ),
            MarkerLayer(
              markers: widget.puntos.map((PuntoServicioModel p) {
                return Marker(
                  point: LatLng(p.latitud, p.longitud),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: _colorCupo(p),
                    size: 36,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              AppConfig.osmAttribution,
              style: TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
