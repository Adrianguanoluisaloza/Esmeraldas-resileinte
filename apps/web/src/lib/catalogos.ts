import type { EstadoCupo, EstadoReporte, Gravedad, Necesidad, ReporteMapa, TipoIncidente, TipoPuntoServicio } from '../types/mapa';

/**
 * Textos visibles de cada valor del contrato. Ningún componente escribe "Crítica" o "En proceso" a mano:
 * todos leen de aquí, así la web y la app de Franco dicen lo mismo.
 */

export type Origen = 'ciudadano' | 'simulado' | 'oficial';

export const ETIQUETA_GRAVEDAD: Record<Gravedad, string> = {
  baja: 'Baja',
  media: 'Media',
  alta: 'Alta',
  critica: 'Crítica',
};

/** Orden para priorizar: crítica primero. */
export const PESO_GRAVEDAD: Record<Gravedad, number> = { critica: 4, alta: 3, media: 2, baja: 1 };

export const ETIQUETA_ESTADO: Record<EstadoReporte, string> = {
  pendiente: 'Pendiente',
  en_proceso: 'En proceso',
  atendido: 'Atendido',
  descartado: 'Descartado',
};

export const ETIQUETA_TIPO: Record<TipoIncidente, string> = {
  inundacion: 'Inundación',
  deslizamiento: 'Deslizamiento',
  via_bloqueada: 'Vía bloqueada',
  personas_atrapadas: 'Personas atrapadas',
  dano_vivienda: 'Daño en vivienda',
  otro: 'Otro',
};

export const ETIQUETA_NECESIDAD: Record<Necesidad, string> = {
  agua: 'Agua',
  alimentos: 'Alimentos',
  medicinas: 'Medicinas',
  rescate: 'Rescate',
};

export const ETIQUETA_ORIGEN: Record<Origen, string> = {
  ciudadano: 'Reporte ciudadano',
  simulado: 'Dato simulado',
  oficial: 'Alerta oficial',
};

export const ETIQUETA_PUNTO: Record<TipoPuntoServicio, string> = {
  albergue: 'Albergue',
  centro_salud: 'Centro de salud',
};

export const ETIQUETA_CUPO: Record<EstadoCupo, string> = {
  verde: 'Con cupo',
  ambar: 'Casi lleno',
  rojo: 'Casi sin cupo',
};

/** Colores para Leaflet (que no lee variables CSS en SVG/HTML de marcadores). Mismos valores que tokens.css. */
export const COLOR_GRAVEDAD: Record<Gravedad, string> = {
  baja: '#546e7a',
  media: '#b26a00',
  alta: '#ef6c00',
  critica: '#c62828',
};

export const COLOR_CUPO: Record<EstadoCupo, string> = {
  verde: '#2e7d32',
  ambar: '#ef6c00',
  rojo: '#c62828',
};

export const COLOR_RIESGO: Record<'bajo' | 'medio' | 'alto' | 'critico', string> = {
  bajo: '#2e7d32',
  medio: '#b26a00',
  alto: '#ef6c00',
  critico: '#c62828',
};

export const COLOR_VIA: Record<'habilitada' | 'parcial' | 'bloqueada', string> = {
  habilitada: '#0b6e4f',
  parcial: '#ef6c00',
  bloqueada: '#c62828',
};

/** Semáforo del contrato: verde < 70 %, ámbar 70-90 %, rojo > 90 %. Igual que el backend. */
export function semaforoCupo(capacidad: number, ocupacion: number): EstadoCupo {
  if (capacidad <= 0) return 'rojo';
  const pct = (ocupacion / capacidad) * 100;
  if (pct > 90) return 'rojo';
  if (pct >= 70) return 'ambar';
  return 'verde';
}

const formatoHora = new Intl.DateTimeFormat('es-EC', { hour: '2-digit', minute: '2-digit', timeZone: 'America/Guayaquil' });
const formatoFecha = new Intl.DateTimeFormat('es-EC', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit', timeZone: 'America/Guayaquil' });

/** Hora de Ecuador continental, que es la que usa el COE. */
export const horaLocal = (iso: string) => formatoHora.format(new Date(iso));
export const fechaHoraLocal = (iso: string) => formatoFecha.format(new Date(iso));

/** Tiempo transcurrido para reportes recientes. Las fechas del escenario son futuras y se muestran completas. */
export function haceTiempo(iso: string): string {
  const minutos = Math.round((Date.now() - new Date(iso).getTime()) / 60_000);
  if (minutos < 0 || minutos >= 1440) return fechaHoraLocal(iso);
  if (minutos < 1) return 'Ahora';
  return minutos < 60 ? `Hace ${minutos} min` : `Hace ${Math.round(minutos / 60)} h`;
}

/** Búsqueda sin distinguir mayúsculas ni tildes, en título, descripción y sector. */
export function coincideBusqueda(r: ReporteMapa, texto: string): boolean {
  const limpiar = (s: string) => s.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
  const q = limpiar(texto.trim());
  return !q || limpiar([tituloReporte(r), r.descripcion, r.sector ?? '', ETIQUETA_TIPO[r.tipo]].join(' ')).includes(q);
}

const esReal = (r: Pick<ReporteMapa, 'origen'>) => (r.origen === 'simulado' ? 0 : 1);

/** Reportes reales primero y, dentro de cada grupo, el más reciente. */
export const compararPorFeed = (a: ReporteMapa, b: ReporteMapa) =>
  esReal(b) - esReal(a) || b.recibido_en.localeCompare(a.recibido_en);

/** Título visible de un reporte: el de la demo si existe; si no, tipo y sector. */
export function tituloReporte(r: Pick<ReporteMapa, 'titulo' | 'tipo' | 'sector'> & { descripcion?: string }): string {
  if (r.titulo) return r.titulo;
  // "Otro" no describe nada: se usa la primera frase de la descripción.
  if (r.tipo === 'otro' && r.descripcion) {
    const frase = r.descripcion.split(/[.!?]/)[0]!.trim();
    return frase.length > 64 ? `${frase.slice(0, 61)}...` : frase;
  }
  return r.sector ? `${ETIQUETA_TIPO[r.tipo]} en ${r.sector}` : ETIQUETA_TIPO[r.tipo];
}
