import { PUNTOS_SERVICIO_INICIALES, REPORTES_INICIALES } from '../data/mockEscenario';
import type { EstadoReporte, PuntoServicioMapa, ReporteMapa } from '../types/mapa';
import { obtenerTokenActual } from './auth';
import { semaforoCupo } from './catalogos';

/**
 * Cliente único de la API. Ningún componente llama a fetch directo: todo pasa por aquí.
 * Si la API no responde (sin internet, backend apagado en la demo), las lecturas devuelven los datos
 * simulados del escenario y marcan `respaldo: true` para que la pantalla lo avise.
 * URL: PUBLIC_API_URL (ver .env.example). Contrato: contrato/openapi.yaml.
 */

const BASE = (import.meta.env.PUBLIC_API_URL as string | undefined)?.replace(/\/+$/, '') ?? 'http://localhost:3000';
const TIEMPO_MAX_MS = 8000;

export type CodigoApi =
  | 'VALIDACION'
  | 'NO_AUTENTICADO'
  | 'SIN_PERMISO'
  | 'NO_ENCONTRADO'
  | 'CONFLICTO'
  | 'TRANSICION_INVALIDA'
  | 'NO_IMPLEMENTADO'
  | 'ERROR_INTERNO'
  | 'SIN_CONEXION';

export class ErrorApi extends Error {
  constructor(public readonly codigo: CodigoApi, mensaje: string, public readonly estado = 0) {
    super(mensaje);
  }
}

/** Texto para la persona según el código. Nunca mostrar el mensaje técnico del servidor tal cual. */
export const MENSAJE_ERROR: Record<CodigoApi, string> = {
  VALIDACION: 'Revisa los datos ingresados.',
  NO_AUTENTICADO: 'Tu sesión terminó. Vuelve a ingresar.',
  SIN_PERMISO: 'Tu rol no permite esta acción.',
  NO_ENCONTRADO: 'No encontramos ese registro.',
  CONFLICTO: 'Ese registro ya existe.',
  TRANSICION_INVALIDA: 'Ese cambio de estado no está permitido.',
  NO_IMPLEMENTADO: 'Esta función estará disponible pronto.',
  ERROR_INTERNO: 'El servidor tuvo un problema. Intenta otra vez.',
  SIN_CONEXION: 'Sin conexión con el servidor.',
};

export interface Resultado<T> {
  datos: T;
  /** true si son datos simulados locales porque la API no respondió. */
  respaldo: boolean;
}

async function pedir<T>(ruta: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  const token = obtenerTokenActual();
  if (token) headers.set('Authorization', `Bearer ${token}`);
  if (init.body && !(init.body instanceof FormData)) headers.set('Content-Type', 'application/json');
  let res: Response;
  try {
    res = await fetch(`${BASE}${ruta}`, { ...init, headers, signal: AbortSignal.timeout(TIEMPO_MAX_MS) });
  } catch {
    throw new ErrorApi('SIN_CONEXION', MENSAJE_ERROR.SIN_CONEXION);
  }
  const cuerpo = await res.json().catch(() => null);
  if (!res.ok) {
    const codigo = (cuerpo?.codigo as CodigoApi | undefined) ?? 'ERROR_INTERNO';
    throw new ErrorApi(codigo, MENSAJE_ERROR[codigo] ?? MENSAJE_ERROR.ERROR_INTERNO, res.status);
  }
  return cuerpo as T;
}

/** Lectura con respaldo: solo cae a datos simulados si NO hay conexión, no si hay error de permisos. */
async function conRespaldo<T>(lectura: () => Promise<T>, respaldo: () => T): Promise<Resultado<T>> {
  try {
    return { datos: await lectura(), respaldo: false };
  } catch (e) {
    if (e instanceof ErrorApi && e.codigo === 'SIN_CONEXION') return { datos: respaldo(), respaldo: true };
    throw e;
  }
}

// ── Endpoints ──────────────────────────────────────────────────────────────────────────────────────

export interface Pagina<T> {
  total: number;
  pagina: number;
  items: T[];
}

export function salud() {
  return pedir<{ estado: string; timestamp: string }>('/salud');
}

export function login(correo: string, password: string) {
  return pedir<{ token: string; usuario: import('./auth').UsuarioSesion }>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ correo, password }),
  });
}

export function registro(nombre: string, correo: string, password: string) {
  return pedir<{ token: string; usuario: import('./auth').UsuarioSesion }>('/auth/registro', {
    method: 'POST',
    body: JSON.stringify({ nombre, correo, password }),
  });
}

export function listarReportes(filtros: Partial<Record<'estado' | 'tipo' | 'gravedad', string>> = {}) {
  const q = new URLSearchParams(Object.entries(filtros).filter(([, v]) => v) as [string, string][]);
  return conRespaldo(
    () => pedir<Pagina<ReporteMapa>>(`/reportes?${q}`),
    () => ({ total: REPORTES_INICIALES.length, pagina: 1, items: REPORTES_INICIALES }),
  );
}

export function cambiarEstadoReporte(id: string, estado: EstadoReporte, nota?: string) {
  return pedir<ReporteMapa>(`/reportes/${encodeURIComponent(id)}/estado`, {
    method: 'PATCH',
    body: JSON.stringify(nota ? { estado, nota } : { estado }),
  });
}

export function listarPuntos(tipo?: 'albergue' | 'centro_salud') {
  return conRespaldo(
    () => pedir<PuntoServicioMapa[]>(`/puntos-servicio${tipo ? `?tipo=${tipo}` : ''}`),
    () => PUNTOS_SERVICIO_INICIALES
      .filter((p) => !tipo || p.tipo === tipo)
      .map((p) => ({ ...p, estado_cupo: semaforoCupo(p.capacidad, p.ocupacion) })),
  );
}

export function puntosCercanos(lat: number, lng: number, personas = 1) {
  return pedir<Array<PuntoServicioMapa & { distancia_m: number; cupos_libres: number }>>(
    `/puntos-servicio/cercanos?lat=${lat}&lng=${lng}&personas=${personas}`,
  );
}

export function actualizarOcupacion(id: string, ocupacion: number) {
  return pedir<PuntoServicioMapa>(`/puntos-servicio/${encodeURIComponent(id)}/ocupacion`, {
    method: 'PATCH',
    body: JSON.stringify({ ocupacion }),
  });
}

export function zonasGeoJson() {
  return pedir<GeoJSON.FeatureCollection>('/zonas');
}

export function viasGeoJson() {
  return pedir<GeoJSON.FeatureCollection>('/vias');
}

/** URL del WebSocket del COE. El token va en la query porque el navegador no permite cabeceras en WS. */
export function urlTiempoReal(): string | null {
  const token = obtenerTokenActual();
  if (!token) return null;
  return `${BASE.replace(/^http/, 'ws')}/ws?token=${encodeURIComponent(token)}`;
}
