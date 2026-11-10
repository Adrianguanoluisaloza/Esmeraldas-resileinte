import 'package:flutter/material.dart';

import '../../../core/error/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/sugerencia_ia.dart';

/// Botón "Pedir sugerencia a Vigía" y el resultado, marcado siempre como no oficial.
class PanelSugerenciaIa extends StatefulWidget {
  const PanelSugerenciaIa({
    super.key,
    required this.repositorio,
    required this.reporteId,
  });

  final SugerenciaIaRepository? repositorio;
  final String reporteId;

  @override
  State<PanelSugerenciaIa> createState() => _PanelSugerenciaIaState();
}

class _PanelSugerenciaIaState extends State<PanelSugerenciaIa> {
  bool _cargando = false;
  SugerenciaIa? _sugerencia;
  String? _error;

  Future<void> _pedir() async {
    final SugerenciaIaRepository? repo = widget.repositorio;
    if (repo == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final SugerenciaIa s = await repo.pedir(widget.reporteId);
      if (mounted) setState(() => _sugerencia = s);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SugerenciaIa? s = _sugerencia;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.colorOrigenSimulado.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.colorOrigenSimulado.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: AppTheme.colorOrigenSimulado,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Asistente Vigía Esmeraldas (IA)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: widget.repositorio == null || _cargando
                    ? null
                    : _pedir,
                child: Text(s == null ? 'Pedir sugerencia' : 'Volver a pedir'),
              ),
            ],
          ),
          if (_cargando) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.colorSemaforoRojo,
              ),
            ),
          if (s != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Sugiere: ${s.tipo.etiqueta} · gravedad ${s.gravedad.etiqueta.toLowerCase()} · '
              'confianza ${(s.confianza * 100).round()}%${s.analizoFoto ? ' · con foto' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(s.explicacion, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              s.aviso,
              style: const TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: AppTheme.colorTextoApagado,
              ),
            ),
          ],
          if (s == null && _error == null && !_cargando)
            const Text(
              'Sugerencia de tipo y gravedad. No es oficial: tú decides.',
              style: TextStyle(fontSize: 11, color: AppTheme.colorTextoApagado),
            ),
        ],
      ),
    );
  }
}
