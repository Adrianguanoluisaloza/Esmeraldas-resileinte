import type { Rol } from "./catalogos.js";
import type { PuntoServicio } from "./puntoServicio.js";
import type { Reporte } from "./reporte.js";
import type { Alerta, Entrega, EstadoVia, HistorialEstado, ItemInventario, Suministro } from "./operacion.js";
import type { EstadoReporte, Gravedad, TipoIncidente, TipoPuntoServicio } from "./catalogos.js";

/**
 * Puertos (interfaces) que el dominio necesita. Las implementaciones viven en infraestructura/
 * (memoria para pruebas y demo sin base, postgres para producción). Las rutas HTTP nunca
 * importan una implementación concreta: reciben estos contratos ya armados en index.ts.
 */

export interface Usuario {
  id: string;
  nombre: string;
  correo: string;
  rol: Rol;
  creado_en: string;
}

export interface UsuarioConClave extends Usuario {
  clave_hash: string;
}

export interface RepositorioUsuarios {
  buscarPorCorreo(correo: string): Promise<UsuarioConClave | null>;
  crear(usuario: UsuarioConClave): Promise<void>;
}

export interface SolicitudRestablecimiento {
  usuario_id: string;
  token_hash: string;
  expira_en: string;
  creado_en: string;
}

export interface RepositorioRestablecimientos {
  /** Guarda la solicitud y deja sin efecto las anteriores del mismo usuario. */
  crear(solicitud: SolicitudRestablecimiento): Promise<void>;
  /** En una sola operación marca el token como usado y cambia la clave. false si no existe, venció o ya se usó. */
  consumir(token_hash: string, ahora: string, clave_hash: string): Promise<boolean>;
}

export interface ServicioCorreo {
  enviarRestablecimiento(destino: string, nombre: string, enlace: string): Promise<void>;
}

export interface FiltroReportes {
  estado?: EstadoReporte;
  tipo?: TipoIncidente;
  gravedad?: Gravedad;
  verificado?: boolean;
  /** Si viene, solo los reportes de esa persona (vista "Mis reportes" del ciudadano). */
  usuario_id?: string;
  limite: number;
  pagina: number;
}

export interface RepositorioReportes {
  /** Inserta. Devuelve false si el id ya existía (reenvío desde la cola offline). */
  insertar(reporte: Reporte): Promise<boolean>;
  buscar(id: string): Promise<Reporte | null>;
  listar(filtro: FiltroReportes): Promise<{ total: number; items: Reporte[] }>;
  actualizarEstado(id: string, cambios: Pick<Reporte, "estado" | "verificado">, nota: string | null, operador: { id: string; nombre: string }): Promise<Reporte | null>;
  guardarFoto(id: string, url: string, miniaturaUrl: string): Promise<Reporte | null>;
  historial(id: string): Promise<HistorialEstado[]>;
}

export interface RepositorioAlertas {
  listar(soloVigentes: boolean): Promise<Alerta[]>;
  crear(a: Alerta): Promise<void>;
  cerrar(id: string): Promise<Alerta | null>;
}

/** Módulo 5: entregas de asistencia humanitaria ligadas a un reporte. */
export interface RepositorioAsistencia {
  /** Registra la entrega y, si es un suministro, descuenta el stock en la misma transacción. */
  registrar(e: Entrega): Promise<"ok" | "sin_stock">;
  listar(): Promise<Entrega[]>;
  inventario(): Promise<ItemInventario[]>;
  /** Suma (o resta) stock; nunca deja la cantidad negativa. */
  ajustarInventario(necesidad: Suministro, delta: number): Promise<ItemInventario | null>;
}

/** Donde viven los archivos de foto. Hoy disco local (volumen Docker); mañana Object Storage de Oracle o R2. */
export interface AlmacenFotos {
  guardar(reporteId: string, bytes: Uint8Array, extension: "jpg" | "png"): Promise<{ url: string; miniaturaUrl: string; tamano: number }>;
}

export interface Cercania {
  latitud: number;
  longitud: number;
  tipo?: TipoPuntoServicio;
  /** Cupos libres mínimos: no se sugiere un albergue con 1 cupo a una familia de 6. */
  personas: number;
  limite: number;
}

export interface RepositorioTerritorio {
  /** Zonas de riesgo como GeoJSON FeatureCollection (polígonos PostGIS). */
  zonasGeoJson(): Promise<GeoJsonColeccion>;
  /** Red vial con estado (habilitada / parcial / bloqueada) como GeoJSON. */
  viasGeoJson(): Promise<GeoJsonColeccion>;
  /** Sector (barrio) que contiene el punto, para etiquetar reportes automáticamente. */
  sectorDe(latitud: number, longitud: number): Promise<string | null>;
  listarPuntos(tipo?: TipoPuntoServicio, soloActivos?: boolean): Promise<PuntoServicio[]>;
  /** Puntos activos con cupo, ordenados por distancia real (ST_Distance sobre geography). */
  /** paso_bloqueado = el tramo recto hasta el punto cruza una vía bloqueada (ruta de evacuación a revisar). */
  puntosCercanos(c: Cercania): Promise<Array<PuntoServicio & { distancia_m: number; paso_bloqueado: boolean }>>;
  actualizarOcupacion(id: string, ocupacion: number): Promise<PuntoServicio | null>;
  /** Cambia el estado de una vía; devuelve sus propiedades o null si no existe. */
  actualizarVia(id: string, estado: EstadoVia): Promise<Record<string, unknown> | null>;
}

export interface GeoJsonColeccion {
  type: "FeatureCollection";
  features: Array<{ type: "Feature"; id?: string; geometry: unknown; properties: Record<string, unknown> }>;
}

export interface ServicioClaves {
  cifrar(clave: string): Promise<string>;
  verificar(clave: string, hash: string): Promise<boolean>;
}

export interface ServicioTokens {
  emitir(usuario: Usuario): Promise<string>;
  verificar(token: string): Promise<Pick<Usuario, "id" | "rol" | "nombre"> | null>;
}

/** Eventos que se empujan por WebSocket al tablero del COE. */
export type EventoTiempoReal =
  | { tipo: "reporte.creado"; datos: Reporte }
  | { tipo: "reporte.estado"; datos: Reporte }
  | { tipo: "punto.ocupacion"; datos: PuntoServicio }
  | { tipo: "alerta.emitida"; datos: Alerta }
  | { tipo: "via.estado"; datos: Record<string, unknown> }
  | { tipo: "asistencia.entrega"; datos: Entrega };

export interface PublicadorEventos {
  publicar(evento: EventoTiempoReal): void;
}

export interface Reloj {
  ahora(): Date;
}
