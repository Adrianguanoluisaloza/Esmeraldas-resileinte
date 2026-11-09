/**
 * Escapa texto antes de meterlo en HTML armado a mano (popups de Leaflet, innerHTML).
 * Los reportes los escriben ciudadanos: sin esto, una descripción con <script> se ejecutaría en el panel del COE.
 * En JSX no hace falta: React ya escapa.
 */
const MAPA: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

export function escaparHtml(valor: unknown): string {
  return String(valor ?? '').replace(/[&<>"']/g, (c) => MAPA[c] ?? c);
}
