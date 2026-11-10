import { PUNTOS_SERVICIO_INICIALES, REPORTES_INICIALES } from '../data/mockEscenario';
import type { EstadoReporte, Gravedad, Necesidad, PuntoServicioMapa, ReporteMapa, TipoIncidente } from '../types/mapa';
import { obtenerTokenActual } from './auth';
import { semaforoCupo } from './catalogos';

/**
 * Cliente único de la API. Ningún componente llama a fetch directo: todo pasa por aquí.
 * Si la API no responde (sin internet, backend apagado en la demo), las lecturas devuelven los datos
 * simulados del escenario y marcan `respaldo: true` para que la pantalla lo avise.
 * URL: PUBLIC_API_URL (ver .env.example). Contrato: contrato/openapi.yaml.
 */

export const BASE = (import.meta.env.PUBLIC_API_URL as string | undefined)?.replace(/\/+$/, '') ?? 'http://localhost:3000';
const TIEMPO_MAX_MS = 8000;

export type CodigoApi =
  | 'VALIDACION'
  | 'NO_AUTENTICADO'
  | 'SIN_PERMISO'
  | 'NO_ENCONTRADO'
  | 'CONFLICTO'
  | 'TRANSICION_INVALIDA'
  | 'NO_IMPLEMENTADO'
  | 'DEMASIADAS_PETICIONES'
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
  NO_IMPLEMENTADO: 'Función no disponible.',
  DEMASIADAS_PETICIONES: 'Demasiados intentos. Espera un momento.',
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

export function recuperarClave(correo: string) {
  return pedir<null>('/auth/recuperar', { method: 'POST', body: JSON.stringify({ correo }) });
}

export function restablecerClave(token: string, password: string) {
  return pedir<null>('/auth/restablecer', { method: 'POST', body: JSON.stringify({ token, password }) });
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
  return pedir<Array<PuntoServicioMapa & { distancia_m: number; cupos_libres: number; paso_bloqueado: boolean }>>(
    `/puntos-servicio/cercanos?lat=${lat}&lng=${lng}&personas=${personas}`,
  );
}

export function actualizarOcupacion(id: string, ocupacion: number) {
  return pedir<PuntoServicioMapa>(`/puntos-servicio/${encodeURIComponent(id)}/ocupacion`, {
    method: 'PATCH',
    body: JSON.stringify({ ocupacion }),
  });
}

export function crearPunto(datos: Pick<PuntoServicioMapa, 'nombre' | 'tipo' | 'direccion' | 'telefono' | 'capacidad' | 'ocupacion' | 'latitud' | 'longitud'>) {
  return pedir<PuntoServicioMapa>('/puntos-servicio', { method: 'POST', body: JSON.stringify(datos) });
}

export function listarUsuarios() {
  return pedir<import('./auth').UsuarioSesion[]>('/usuarios');
}

export function cambiarRol(id: string, rol: import('./auth').RolUsuario) {
  return pedir<import('./auth').UsuarioSesion>(`/usuarios/${encodeURIComponent(id)}/rol`, { method: 'PATCH', body: JSON.stringify({ rol }) });
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

// ── Reportes: detalle y creación ──────────────────────────────────────────────────────────────────

export interface CambioHistorial {
  id: string;
  estado_anterior: EstadoReporte;
  estado_nuevo: EstadoReporte;
  operador_nombre: string | null;
  nota: string | null;
  fecha: string;
}

export function obtenerReporte(id: string) {
  return pedir<ReporteMapa & { historial: CambioHistorial[] }>(`/reportes/${encodeURIComponent(id)}`);
}

export interface NuevoReporte {
  id: string;
  tipo: TipoIncidente;
  descripcion: string;
  gravedad: Gravedad;
  latitud: number;
  longitud: number;
  precision_m?: number | null;
  ubicacion_aproximada?: boolean;
  capturado_en: string;
  personas_afectadas?: number;
  ninos?: number;
  adultos_mayores?: number;
  necesidades?: Necesidad[];
}

export function crearReporte(datos: NuevoReporte) {
  return pedir<ReporteMapa>('/reportes', { method: 'POST', body: JSON.stringify(datos) });
}

export function subirFoto(id: string, archivo: Blob) {
  const cuerpo = new FormData();
  cuerpo.append('foto', archivo, `${id}.jpg`);
  return pedir<{ ruta: string }>(`/reportes/${encodeURIComponent(id)}/foto`, { method: 'POST', body: cuerpo });
}

// ── Alertas y vías ──────────────────────────────────────────────────────────────────────────────

export interface Alerta {
  id: string;
  sector: string;
  mensaje: string;
  nivel: Gravedad;
  origen: 'oficial' | 'simulada';
  creado_en: string;
  vigente: boolean;
}

export function listarAlertas(todas = false) {
  return pedir<Alerta[]>(`/alertas${todas ? '?todas=true' : ''}`);
}

export function emitirAlerta(datos: Pick<Alerta, 'sector' | 'mensaje' | 'nivel' | 'origen'>) {
  return pedir<Alerta>('/alertas', { method: 'POST', body: JSON.stringify(datos) });
}

export function cerrarAlerta(id: string) {
  return pedir<Alerta>(`/alertas/${encodeURIComponent(id)}/cerrar`, { method: 'PATCH' });
}

export type EstadoVia = 'habilitada' | 'parcial' | 'bloqueada';

export function cambiarVia(id: string, estado: EstadoVia) {
  return pedir<Record<string, unknown>>(`/vias/${encodeURIComponent(id)}/estado`, { method: 'PATCH', body: JSON.stringify({ estado }) });
}

// ── Indicadores y asistencia ────────────────────────────────────────────────────────────────────

export interface Estadisticas {
  total_reportes: number;
  pendientes: number;
  en_proceso: number;
  atendidos: number;
  criticos: number;
  personas_afectadas_total: number;
  ninos_total: number;
  adultos_mayores_total: number;
  vias_bloqueadas_total: number;
  albergues_disponibles: number;
  necesidades_acumuladas: Record<Necesidad, number>;
}

export interface SectorPrioridad {
  sector: string;
  cantidad: number;
  abiertos: number;
  personas_afectadas: number;
  gravedad_promedio: Gravedad;
  puntaje: number;
}

export function estadisticas() {
  return pedir<Estadisticas>('/estadisticas');
}

export function prioridadSectores() {
  return pedir<SectorPrioridad[]>('/estadisticas/recurrencia');
}

export interface NecesidadPendiente {
  reporte_id: string;
  necesidad: Necesidad;
  sector: string | null;
  personas: number;
  gravedad: Gravedad;
  prioridad: number;
}

export interface Entrega {
  id: string;
  reporte_id: string;
  necesidad: Necesidad;
  cantidad: number;
  nota: string | null;
  entregado_en: string;
}

export function necesidadesPendientes() {
  return pedir<NecesidadPendiente[]>('/asistencia/pendientes');
}

export function listarEntregas() {
  return pedir<Entrega[]>('/asistencia/entregas');
}

export function registrarEntrega(datos: { reporte_id: string; necesidad: Necesidad; cantidad: number; nota?: string }) {
  return pedir<Entrega>('/asistencia/entregas', { method: 'POST', body: JSON.stringify(datos) });
}

export interface ItemInventario {
  necesidad: 'agua' | 'alimentos' | 'medicinas';
  cantidad: number;
  unidad: string;
  actualizado_en: string;
}

export function inventario() {
  return pedir<ItemInventario[]>('/asistencia/inventario');
}

export function ajustarInventario(necesidad: ItemInventario['necesidad'], delta: number) {
  return pedir<ItemInventario>(`/asistencia/inventario/${necesidad}`, { method: 'PATCH', body: JSON.stringify({ delta }) });
}

// ── Firebase Auth ────────────────────────────────────────────────────────────────────────────────

/** Intercambia un idToken de Firebase por el JWT propio del backend. */
export function loginFirebase(idToken: string) {
  return pedir<{ token: string; usuario: import('./auth').UsuarioSesion }>('/auth/firebase', {
    method: 'POST',
    body: JSON.stringify({ idToken }),
  });
}
