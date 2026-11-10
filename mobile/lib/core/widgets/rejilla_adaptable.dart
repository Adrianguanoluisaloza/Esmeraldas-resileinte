import 'package:flutter/widgets.dart';

/// Coloca tarjetas en 1, 2 o 3 columnas según el ancho disponible.
/// En teléfono queda una columna; en tableta o pantalla ancha no se estiran de borde a borde.
class RejillaAdaptable extends StatelessWidget {
  const RejillaAdaptable({
    super.key,
    required this.children,
    this.anchoMinimoItem = 340,
    this.maxColumnas = 3,
    this.espacio = 8,
  });

  final List<Widget> children;
  final double anchoMinimoItem;
  final int maxColumnas;
  final double espacio;

  static int columnasPara(double ancho, double anchoMinimo, int maximo) =>
      (ancho / anchoMinimo).floor().clamp(1, maximo);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int columnas = columnasPara(
          c.maxWidth,
          anchoMinimoItem,
          maxColumnas,
        );
        final double ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: children
              .map((Widget w) => SizedBox(width: ancho, child: w))
              .toList(),
        );
      },
    );
  }
}
