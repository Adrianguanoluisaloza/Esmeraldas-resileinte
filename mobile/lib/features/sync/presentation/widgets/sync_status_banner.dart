import 'package:flutter/material.dart';

/// Banner superior que informa el estado de la cola offline y permite disparar "Reintentar" manualmente.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    required this.pendientesCount,
    required this.sincronizando,
    required this.onReintentar,
  });

  final int pendientesCount;
  final bool sincronizando;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (pendientesCount == 0 && !sincronizando) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(
              sincronizando ? Icons.sync : Icons.cloud_off,
              color: Colors.orange.shade900,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sincronizando
                    ? 'Sincronizando cola offline ($pendientesCount pendientes)...'
                    : '$pendientesCount reporte(s) guardados en cola offline.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: sincronizando ? null : onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
