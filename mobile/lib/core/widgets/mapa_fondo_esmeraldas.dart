import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../data/models/punto_servicio_model.dart';
import '../config/app_config.dart';
import '../enums/app_enums.dart';
import '../services/mbtiles_service.dart';
import '../theme/app_theme.dart';

/// Marcador de incidente para mostrar sobre el mapa de Esmeraldas.
class PinMapaIncidente {
  const PinMapaIncidente({
    required this.punto,
    required this.gravedad,
    required this.etiqueta,
    this.onTap,
  });

  final LatLng punto;
  final GravedadIncidente gravedad;
  final String etiqueta;
  final VoidCallback? onTap;
}

/// Mapa de Esmeraldas (`FlutterMap`) usado como fondo de pantalla completa detrás
/// de las tarjetas flotantes (como en `fire-shield.html`), con respaldo vectorial
/// en modo avión para no mostrar nunca cuadros en blanco sin internet.
class MapaFondoEsmeraldas extends StatelessWidget {
  const MapaFondoEsmeraldas({
    super.key,
    this.mapController,
    this.tieneConexion = true,
    this.ubicacionUsuario,
    this.ubicacionIncidenteMarcado,
    this.puntosServicio = const <PuntoServicioModel>[],
    this.incidentes = const <PinMapaIncidente>[],
    this.onTapMapa,
  });

  final MapController? mapController;
  final bool tieneConexion;
  final LatLng? ubicacionUsuario;
  final LatLng? ubicacionIncidenteMarcado;
  final List<PuntoServicioModel> puntosServicio;
  final List<PinMapaIncidente> incidentes;
  final ValueChanged<LatLng>? onTapMapa;

  @override
  Widget build(BuildContext context) {
    final LatLng centro =
        ubicacionUsuario ??
        const LatLng(
          AppConfig.esmeraldasCenterLat,
          AppConfig.esmeraldasCenterLng,
        );

    final bool usarMbtilesLocal = EsmeraldasMbTilesService.estaListo;

    if (!tieneConexion && !usarMbtilesLocal) {
      return GestureDetector(
        onTapUp: onTapMapa == null
            ? null
            : (TapUpDetails d) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Size s = box.size;
                final double dx = (d.localPosition.dx / s.width) - 0.5;
                final double dy = 0.5 - (d.localPosition.dy / s.height);
                onTapMapa!(
                  LatLng(
                    AppConfig.esmeraldasCenterLat + dy * 0.04,
                    AppConfig.esmeraldasCenterLng + dx * 0.04,
                  ),
                );
              },
        child: CustomPaint(
          painter: _MapaOfflineEsmeraldasPainter(
            ubicacionUsuario: ubicacionUsuario,
            ubicacionIncidenteMarcado: ubicacionIncidenteMarcado,
            incidentes: incidentes,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: centro,
            initialZoom: AppConfig.defaultZoom,
            minZoom: AppConfig.minZoom,
            maxZoom: AppConfig.maxZoom,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(-0.5, -80.3),
                const LatLng(1.6, -78.4),
              ),
            ),
            onTap: onTapMapa == null
                ? null
                : (TapPosition _, LatLng punto) => onTapMapa!(punto),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: AppConfig.osmTileUrlTemplate,
              userAgentPackageName: AppConfig.osmUserAgentPackageName,
              tileProvider: EsmeraldasHybridTileProvider(
                tieneConexion: tieneConexion,
              ),
            ),
            MarkerLayer(
              markers: <Marker>[
                // Puntos de servicio (albergues y centros de salud)
                ...puntosServicio.map(
                  (PuntoServicioModel p) => Marker(
                    point: LatLng(p.latitud, p.longitud),
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.colorCupo(p.ratioOcupacion),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        p.tipo == TipoPuntoServicio.albergue
                            ? Icons.night_shelter
                            : Icons.local_hospital,
                        size: 18,
                        color: AppTheme.colorCupo(p.ratioOcupacion),
                      ),
                    ),
                  ),
                ),
                // Incidentes reportados
                ...incidentes.map(
                  (PinMapaIncidente inc) => Marker(
                    point: inc.punto,
                    width: 118,
                    height: 58,
                    child: GestureDetector(
                      onTap: inc.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.colorGravedad(inc.gravedad),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: AppTheme.colorGravedad(inc.gravedad),
                              ),
                            ),
                            child: Text(
                              inc.etiqueta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.colorGravedad(inc.gravedad),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Ubicación del usuario ("Tu ubicación")
                if (ubicacionUsuario != null)
                  Marker(
                    point: ubicacionUsuario!,
                    width: 120,
                    height: 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF1F4FB8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppTheme.colorBorde),
                          ),
                          child: const Text(
                            'Tu ubicación',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Punto marcado en el mapa para el reporte
                if (ubicacionIncidenteMarcado != null)
                  Marker(
                    point: ubicacionIncidenteMarcado!,
                    width: 130,
                    height: 68,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.colorSemaforoRojo,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            size: 16,
                            color: AppTheme.colorSemaforoRojo,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: AppTheme.colorSemaforoRojo,
                            ),
                          ),
                          child: const Text(
                            'Punto emergencia',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colorSemaforoRojo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.colorBorde),
            ),
            child: Text(
              (!tieneConexion && usarMbtilesLocal)
                  ? 'MBTiles Offline Esmeraldas · ${AppConfig.osmAttribution}'
                  : AppConfig.osmAttribution,
              style: const TextStyle(fontSize: 10, color: AppTheme.colorTexto),
            ),
          ),
        ),
      ],
    );
  }
}

/// Respaldo vectorial del mapa de Esmeraldas (costa, río Esmeraldas y vías)
/// cuando el celular está en modo avión.
class _MapaOfflineEsmeraldasPainter extends CustomPainter {
  const _MapaOfflineEsmeraldasPainter({
    this.ubicacionUsuario,
    this.ubicacionIncidenteMarcado,
    this.incidentes = const <PinMapaIncidente>[],
  });

  final LatLng? ubicacionUsuario;
  final LatLng? ubicacionIncidenteMarcado;
  final List<PinMapaIncidente> incidentes;

  Offset _latLngToOffset(LatLng p, Size size) {
    final double nx =
        ((p.longitude - AppConfig.esmeraldasCenterLng) / 0.04) + 0.5;
    final double ny =
        0.5 - ((p.latitude - AppConfig.esmeraldasCenterLat) / 0.04);
    return Offset(
      (nx.clamp(0.08, 0.92)) * size.width,
      (ny.clamp(0.08, 0.92)) * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEF0F1),
    );

    // Océano Pacífico al norte y Río Esmeraldas
    final Paint agua = Paint()..color = const Color(0xFF8FD2EF);
    final Path costa = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.11)
      ..quadraticBezierTo(w * 0.55, h * 0.08, 0, h * 0.14)
      ..close();
    canvas.drawPath(costa, agua);

    final Path rio = Path()
      ..moveTo(w * 0.56, h * 0.10)
      ..quadraticBezierTo(w * 0.66, h * 0.45, w * 0.54, h)
      ..lineTo(w * 0.62, h)
      ..quadraticBezierTo(w * 0.72, h * 0.45, w * 0.62, h * 0.10)
      ..close();
    canvas.drawPath(rio, agua);

    // Zonas verdes
    final Paint verde = Paint()..color = const Color(0xFFCFE9D6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.22, w * 0.28, h * 0.12),
        const Radius.circular(8),
      ),
      verde,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.68, h * 0.62, w * 0.24, h * 0.14),
        const Radius.circular(8),
      ),
      verde,
    );

    // Vías principales
    final Paint via = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.20), Offset(w, h * 0.16), via);
    canvas.drawLine(Offset(0, h * 0.44), Offset(w, h * 0.37), via);
    canvas.drawLine(Offset(0, h * 0.70), Offset(w, h * 0.63), via);
    canvas.drawLine(Offset(w * 0.24, h * 0.12), Offset(w * 0.34, h), via);
    canvas.drawLine(Offset(w * 0.80, h * 0.10), Offset(w * 0.86, h), via);
    canvas.drawCircle(Offset(w * 0.40, h * 0.42), 26, via);

    // Pines de incidentes en modo offline
    final Paint bordeBlanco = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final PinMapaIncidente inc in incidentes) {
      final Offset pos = _latLngToOffset(inc.punto, size);
      canvas.drawCircle(
        pos,
        11,
        Paint()..color = AppTheme.colorGravedad(inc.gravedad),
      );
      canvas.drawCircle(pos, 11, bordeBlanco);
    }

    if (ubicacionUsuario != null) {
      final Offset pos = _latLngToOffset(ubicacionUsuario!, size);
      canvas.drawCircle(pos, 9, Paint()..color = Colors.white);
      canvas.drawCircle(pos, 5, Paint()..color = const Color(0xFF1F4FB8));
    }

    if (ubicacionIncidenteMarcado != null) {
      final Offset pos = _latLngToOffset(ubicacionIncidenteMarcado!, size);
      canvas.drawCircle(pos, 12, Paint()..color = AppTheme.colorSemaforoRojo);
      canvas.drawCircle(pos, 12, bordeBlanco);
    }
  }

  @override
  bool shouldRepaint(covariant _MapaOfflineEsmeraldasPainter oldDelegate) =>
      oldDelegate.ubicacionUsuario != ubicacionUsuario ||
      oldDelegate.ubicacionIncidenteMarcado != ubicacionIncidenteMarcado ||
      oldDelegate.incidentes.length != incidentes.length;
}
