import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/reporte_cola_model.dart';

/// Pantalla "Mis reportes" que muestra el estado en la cola offline:
/// pendiente, enviando_datos, datos_enviados, enviando_foto, enviado o error.
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
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final ReporteColaModel item = reportes[index];
        final Color colorBadge = _colorPorEstado(item.estadoCola);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorBadge.withValues(alpha: 0.15),
              child: Icon(
                item.estadoCola.estaSincronizado
                    ? Icons.cloud_done
                    : Icons.schedule_send,
                color: colorBadge,
              ),
            ),
            title: Text(
              '${item.tipo.etiqueta} • Gravedad ${item.gravedad.etiqueta}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (item.descripcion.isNotEmpty) Text(item.descripcion),
                Text(
                  'Estado cola: ${item.estadoCola.etiqueta} '
                  '(Intentos: ${item.intentos})',
                  style: TextStyle(
                    color: colorBadge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'UUID: ${item.id.substring(0, 8)}... • '
                  'GPS: ${item.latitud.toStringAsFixed(4)}, ${item.longitud.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: !item.estadoCola.estaSincronizado
                ? IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Reintentar envío',
                    onPressed: onSincronizarManual,
                  )
                : const Icon(Icons.verified, color: Colors.green),
          ),
        );
      },
    );
  }
}
