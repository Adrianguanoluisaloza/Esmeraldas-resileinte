import type { EventoTiempoReal, PublicadorEventos, Reloj } from "../dominio/puertos.js";

export const relojSistema: Reloj = { ahora: () => new Date() };

/** Bus en memoria. El WebSocket se suscribe aquí; en pruebas se inspeccionan los eventos emitidos. */
export class BusEventos implements PublicadorEventos {
  private readonly oyentes = new Set<(e: EventoTiempoReal) => void>();

  publicar(evento: EventoTiempoReal): void {
    for (const oyente of this.oyentes) {
      try {
        oyente(evento);
      } catch {
        // Un cliente caído no debe tumbar la petición que generó el evento.
      }
    }
  }

  suscribir(oyente: (e: EventoTiempoReal) => void): () => void {
    this.oyentes.add(oyente);
    return () => this.oyentes.delete(oyente);
  }
}
