import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/reporte_cola_model.dart';

/// Pantalla "Mis reportes" con los pasos de sincronización de 2 fases (`1 · Datos`, `2 · Foto`).
class MisReportesPage extends StatelessWidget {
  const MisReportesPage({
    super.key,
    required this.reportes,
    required this.onSincronizarManual,
  });

  final List<ReporteColaModel> reportes;
  final VoidCallback onSincronizarManual;

  Color _colorPorEstado(EstadoColaReporte estado) {
    switch (estado) {
      case EstadoColaReporte.enviado:
        return AppTheme.colorSemaforoVerde;
      case EstadoColaReporte.error:
        return AppTheme.colorSemaforoRojo;
      case EstadoColaReporte.pendiente:
      case EstadoColaReporte.enviandoDatos:
      case EstadoColaReporte.datosEnviados:
      case EstadoColaReporte.enviandoFoto:
        return AppTheme.colorSemaforoAmbar;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reportes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes reportes en la cola local.\nCrea uno desde la pestaña "Reportar".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: reportes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final ReporteColaModel item = reportes[index];
        final Color colorBadge = _colorPorEstado(item.estadoCola);
        final bool paso1Listo =
            item.estadoCola == EstadoColaReporte.datosEnviados ||
            item.estadoCola == EstadoColaReporte.enviandoFoto ||
            item.estadoCola == EstadoColaReporte.enviado;
        final bool paso2Listo = item.estadoCola == EstadoColaReporte.enviado;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${item.tipo.etiqueta} · ${item.gravedad.etiqueta}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorBadge.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.estadoCola.etiqueta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorBadge,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.descripcion.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(item.descripcion, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(
                  'ID ${item.id.substring(0, 8)}… · '
                  'GPS ${item.latitud.toStringAsFixed(4)}, ${item.longitud.toStringAsFixed(4)}'
                  '${item.ubicacionAproximada ? " (aprox.)" : ""}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _PasoChip(
                      texto: '1 · Datos',
                      completado: paso1Listo,
                      activo:
                          item.estadoCola == EstadoColaReporte.enviandoDatos,
                    ),
                    const SizedBox(width: 6),
                    _PasoChip(
                      texto: '2 · Foto',
                      completado: paso2Listo,
                      activo: item.estadoCola == EstadoColaReporte.enviandoFoto,
                    ),
                    const Spacer(),
                    if (!item.estadoCola.estaSincronizado)
                      TextButton.icon(
                        onPressed: onSincronizarManual,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PasoChip extends StatelessWidget {
  const _PasoChip({
    required this.texto,
    required this.completado,
    required this.activo,
  });

  final String texto;
  final bool completado;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final Color bg = completado
        ? const Color(0xFFDCFCE7)
        : activo
        ? const Color(0xFFFEF9C3)
        : const Color(0xFFEEEEEE);
    final Color fg = completado
        ? const Color(0xFF166534)
        : activo
        ? const Color(0xFF854D0E)
        : Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
