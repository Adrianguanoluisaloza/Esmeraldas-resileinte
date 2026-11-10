import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/services/telephony_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reporte/data/models/reporte_cola_model.dart';

/// Pantalla "Mis reportes" con los pasos de sincronización de 2 fases (`1 · Datos`, `2 · Foto`).
/// Cumple M11: en modo emergencia sin cuenta avisa que "Mis reportes" solo lista los enviados con cuenta.
class MisReportesPage extends StatelessWidget {
  const MisReportesPage({
    super.key,
    required this.reportes,
    required this.onSincronizarManual,
    this.onEliminarReporte,
    this.sinCuenta = false,
    this.onIniciarSesion,
  });

  final List<ReporteColaModel> reportes;
  final VoidCallback onSincronizarManual;
  final ValueChanged<String>? onEliminarReporte;
  final bool sinCuenta;
  final VoidCallback? onIniciarSesion;

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
    final List<ReporteColaModel> visibles = sinCuenta
        ? reportes
              .where((ReporteColaModel r) => !r.estadoCola.estaSincronizado)
              .toList()
        : reportes;

    if (visibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                sinCuenta
                    ? 'Modo emergencia sin cuenta: tus reportes anónimos se envían directo al COE.\nInicia sesión para consultar el historial de tus reportes enviados con cuenta.'
                    : 'Aún no tienes reportes en la cola local.\nCrea uno desde la pestaña "Reportar".',
                textAlign: TextAlign.center,
              ),
              if (sinCuenta && onIniciarSesion != null) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onIniciarSesion,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Iniciar sesión con mi cuenta'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: visibles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final ReporteColaModel item = visibles[index];
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
                  '${item.ubicacionAproximada ? " (aprox.)" : ""}'
                  '${item.intentos > 0 && !item.estadoCola.estaSincronizado ? " · Intentos: ${item.intentos}" : ""}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (item.mensajeError != null &&
                    item.mensajeError!.isNotEmpty &&
                    !item.estadoCola.estaSincronizado) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorSemaforoRojo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.colorSemaforoRojo.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: AppTheme.colorSemaforoRojo,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.mensajeError!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.colorSemaforoRojo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    if (!item.estadoCola.estaSincronizado) ...<Widget>[
                      IconButton(
                        tooltip: 'Enviar punto GPS por SMS',
                        onPressed: () async {
                          const TelephonyService telephony = TelephonyService();
                          final bool ok = await telephony
                              .enviarPuntoEmergenciaPorSms(
                                latitud: item.latitud,
                                longitud: item.longitud,
                                tipo: item.tipo,
                                gravedad: item.gravedad,
                                precisionMetros: item.precisionM,
                                personasAfectadas: item.personasAfectadas,
                                descripcion: item.descripcion,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Coordenada GPS (${item.latitud.toStringAsFixed(4)}, ${item.longitud.toStringAsFixed(4)}) enviada por SMS.'
                                    : 'Envío SMS disponible en dispositivos Android.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.sms_outlined,
                          size: 18,
                          color: AppTheme.colorPrimario,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onSincronizarManual,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      if (item.estadoCola == EstadoColaReporte.error &&
                          onEliminarReporte != null)
                        IconButton(
                          tooltip: 'Quitar reporte con error',
                          onPressed: () => onEliminarReporte!(item.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.colorSemaforoRojo,
                          ),
                        ),
                    ],
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
