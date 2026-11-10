import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/punto_servicio_model.dart';

/// Tarjeta de albergue o centro de salud. Se usa en el directorio del ciudadano y en el panel
/// de operadores. Nombre arriba, barra de ocupación y acciones abajo: nada queda apretado.
class TarjetaAlbergue extends StatelessWidget {
  const TarjetaAlbergue({
    super.key,
    required this.punto,
    this.distanciaKm,
    this.acciones,
  });

  final PuntoServicioModel punto;
  final double? distanciaKm;

  /// Botones opcionales (por ejemplo, ajustar ocupación).
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    final PuntoServicioModel p = punto;
    final Color color = AppTheme.colorCupo(p.ratioOcupacion);
    final String telefono = p.telefono.trim();
    final List<String> datos = <String>[
      p.tipo.etiqueta,
      if (distanciaKm != null) 'A ${distanciaKm!.toStringAsFixed(1)} km',
      if (telefono.isNotEmpty) 'Tel: $telefono',
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  p.tipo.valor == 'albergue'
                      ? Icons.night_shelter_outlined
                      : Icons.local_hospital_outlined,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    AppTheme.etiquetaCupo(p.ratioOcupacion),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              datos.join(' · '),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.colorTextoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.ratioOcupacion,
                minHeight: 6,
                color: color,
                backgroundColor: AppTheme.colorCampo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Libres: ${p.cuposDisponibles} de ${p.capacidad}',
              style: const TextStyle(fontSize: 11.5),
            ),
            if (p.pasoBloqueado)
              const Padding(
                padding: EdgeInsets.only(top: 6),
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
            if (acciones != null) ...<Widget>[
              const SizedBox(height: 4),
              acciones!,
            ],
          ],
        ),
      ),
    );
  }
}
