import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';

/// Bloque plegable opcional de familia afectada y necesidades prioritarias.
/// Diseñado para completarse con toques rápidos, sin escribir texto.
class BloqueFamiliaWidget extends StatelessWidget {
  const BloqueFamiliaWidget({
    super.key,
    required this.personasAfectadas,
    required this.ninos,
    required this.adultosMayores,
    required this.necesidadesSeleccionadas,
    required this.onPersonasChanged,
    required this.onNinosChanged,
    required this.onAdultosMayoresChanged,
    required this.onToggleNecesidad,
  });

  final int personasAfectadas;
  final int ninos;
  final int adultosMayores;
  final Set<NecesidadFamiliar> necesidadesSeleccionadas;
  final ValueChanged<int> onPersonasChanged;
  final ValueChanged<int> onNinosChanged;
  final ValueChanged<int> onAdultosMayoresChanged;
  final ValueChanged<NecesidadFamiliar> onToggleNecesidad;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.family_restroom),
        title: const Text('Familia y asistencia (opcional)'),
        subtitle: const Text('Toca para indicar personas y necesidades'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _ContadorFila(
            etiqueta: 'Personas afectadas',
            valor: personasAfectadas,
            maximo: 15,
            onChanged: onPersonasChanged,
          ),
          _ContadorFila(
            etiqueta: 'Niños / niñas',
            valor: ninos,
            maximo: 10,
            onChanged: onNinosChanged,
          ),
          _ContadorFila(
            etiqueta: 'Adultos mayores',
            valor: adultosMayores,
            maximo: 10,
            onChanged: onAdultosMayoresChanged,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Necesidades urgentes:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NecesidadFamiliar.values.map((NecesidadFamiliar nec) {
              final bool activo = necesidadesSeleccionadas.contains(nec);
              return FilterChip(
                label: Text(nec.etiqueta),
                selected: activo,
                onSelected: (_) => onToggleNecesidad(nec),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ContadorFila extends StatelessWidget {
  const _ContadorFila({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
    required this.onChanged,
  });

  final String etiqueta;
  final int valor;
  final int maximo;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(etiqueta),
        Row(
          children: <Widget>[
            IconButton(
              onPressed: valor > 0 ? () => onChanged(valor - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$valor',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: valor < maximo ? () => onChanged(valor + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
