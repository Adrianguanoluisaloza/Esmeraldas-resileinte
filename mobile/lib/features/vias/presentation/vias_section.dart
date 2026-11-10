import 'package:flutter/material.dart';

import '../../../core/error/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rejilla_adaptable.dart';
import '../domain/vias.dart';

/// Estado de la red vial. Quien puede editar (ECU 911, Policía, admin) cambia el estado con un toque.
class ViasSection extends StatefulWidget {
  const ViasSection({
    super.key,
    required this.repositorio,
    required this.puedeEditar,
    required this.tieneConexion,
  });

  final ViasRepository? repositorio;
  final bool puedeEditar;
  final bool tieneConexion;

  @override
  State<ViasSection> createState() => _ViasSectionState();
}

class _ViasSectionState extends State<ViasSection> {
  List<Via> _vias = const <Via>[];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ViasRepository? repo = widget.repositorio;
    if (repo == null || !widget.tieneConexion) {
      setState(
        () => _error = 'Sin conexión: el estado de vías se consulta en línea.',
      );
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final List<Via> v = await repo.listar();
      if (mounted) setState(() => _vias = v);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiar(Via v, EstadoVia e) async {
    if (e == v.estado) return;
    try {
      await widget.repositorio!.cambiarEstado(v.id, e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${v.nombre}: ${e.etiqueta.toLowerCase()}.')),
      );
      await _cargar();
    } on Failure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.mensaje)));
    }
  }

  static Color _color(EstadoVia e) => switch (e) {
    EstadoVia.habilitada => AppTheme.colorSemaforoVerde,
    EstadoVia.parcial => AppTheme.colorSemaforoAmbar,
    EstadoVia.bloqueada => AppTheme.colorSemaforoRojo,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Estado de vías',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _cargando ? null : _cargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_cargando) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.colorTextoApagado,
              ),
            ),
          ),
        const SizedBox(height: 6),
        RejillaAdaptable(
          children: _vias.map((Via v) {
            final Color c = _color(v.estado);
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.alt_route, color: c, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (v.esSimulada)
                          const InsigniaOrigenDato(esOficial: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.puedeEditar)
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<EstadoVia>(
                          showSelectedIcon: false,
                          segments: EstadoVia.values
                              .map(
                                (EstadoVia e) => ButtonSegment<EstadoVia>(
                                  value: e,
                                  label: Text(
                                    e.etiqueta,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ),
                              )
                              .toList(),
                          selected: <EstadoVia>{v.estado},
                          onSelectionChanged: widget.tieneConexion
                              ? (Set<EstadoVia> s) => _cambiar(v, s.first)
                              : null,
                        ),
                      )
                    else
                      Text(
                        v.estado.etiqueta,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
