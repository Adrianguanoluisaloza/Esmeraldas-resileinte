/// Estado de una vía, igual que en la API (`habilitada`, `parcial`, `bloqueada`).
enum EstadoVia {
  habilitada('habilitada', 'Habilitada'),
  parcial('parcial', 'Parcial'),
  bloqueada('bloqueada', 'Bloqueada');

  const EstadoVia(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static EstadoVia fromValor(String v) => EstadoVia.values.firstWhere(
    (e) => e.valor == v,
    orElse: () => EstadoVia.habilitada,
  );
}

class Via {
  const Via({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.esSimulada,
  });

  final String id;
  final String nombre;
  final EstadoVia estado;
  final bool esSimulada;
}

/// Red vial del COE: `GET /vias` (público) y `PATCH /vias/{id}/estado` (ECU 911, Policía y admin).
abstract interface class ViasRepository {
  Future<List<Via>> listar();

  Future<void> cambiarEstado(String id, EstadoVia estado);
}
