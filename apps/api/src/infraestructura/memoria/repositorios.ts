import type { Rol, TipoPuntoServicio } from "../../dominio/catalogos.js";
import { randomUUID } from "node:crypto";
import { cruzaViaBloqueada, esSuministro, type Alerta, type Entrega, type EstadoVia, type HistorialEstado, type ItemInventario, type Suministro } from "../../dominio/operacion.js";
import type {
  Cercania,
  FiltroReportes,
  RepositorioAlertas,
  RepositorioAsistencia,
  RepositorioReportes,
  RepositorioRestablecimientos,
  RepositorioTerritorio,
  RepositorioUsuarios,
  SolicitudRestablecimiento,
  UsuarioConClave,
} from "../../dominio/puertos.js";
import type { PuntoServicio } from "../../dominio/puntoServicio.js";
import type { Reporte } from "../../dominio/reporte.js";
import { ALERTAS, INVENTARIO, PUNTOS, REPORTES, VIAS, ZONAS, zonasGeoJson } from "./semilla.js";

/** Implementaciones en RAM. Sirven para pruebas y para una demo sin Docker; se pierden al reiniciar. */

const copia = <T>(v: T): T => structuredClone(v);

export class UsuariosEnMemoria implements RepositorioUsuarios {
  private readonly porCorreo = new Map<string, UsuarioConClave>();
  async buscarPorCorreo(correo: string) {
    const u = this.porCorreo.get(correo.toLowerCase());
    return u ? copia(u) : null;
  }
  async crear(u: UsuarioConClave) {
    this.porCorreo.set(u.correo.toLowerCase(), copia(u));
  }
  async listar() {
    return [...this.porCorreo.values()].map(({ clave_hash: _omitir, ...u }) => copia(u));
  }
  async cambiarRol(id: string, rol: Rol) {
    for (const u of this.porCorreo.values()) {
      if (u.id === id) {
        u.rol = rol;
        const { clave_hash: _omitir, ...resto } = u;
        return copia(resto);
      }
    }
    return null;
  }
  fijarClave(id: string, clave_hash: string) {
    for (const u of this.porCorreo.values()) if (u.id === id) u.clave_hash = clave_hash;
  }
}

export class RestablecimientosEnMemoria implements RepositorioRestablecimientos {
  private readonly datos = new Map<string, SolicitudRestablecimiento & { usado: boolean }>();
  constructor(private readonly usuarios: UsuariosEnMemoria) {}
  async crear(s: SolicitudRestablecimiento) {
    for (const previa of this.datos.values()) if (previa.usuario_id === s.usuario_id) previa.usado = true;
    this.datos.set(s.token_hash, { ...s, usado: false });
  }
  async consumir(token_hash: string, ahora: string, clave_hash: string) {
    const s = this.datos.get(token_hash);
    if (!s || s.usado || Date.parse(s.expira_en) <= Date.parse(ahora)) return false;
    s.usado = true;
    this.usuarios.fijarClave(s.usuario_id, clave_hash);
    return true;
  }
}

export class ReportesEnMemoria implements RepositorioReportes {
  private readonly datos = new Map<string, Reporte>();
  private readonly cambios = new Map<string, HistorialEstado[]>();
  constructor(semilla: Reporte[] = REPORTES) {
    for (const r of semilla) this.datos.set(r.id, copia(r));
  }
  async insertar(r: Reporte) {
    if (this.datos.has(r.id)) return false;
    this.datos.set(r.id, copia(r));
    return true;
  }
  async buscar(id: string) {
    const r = this.datos.get(id);
    return r ? copia(r) : null;
  }
  async listar(f: FiltroReportes) {
    const todos = [...this.datos.values()]
      .filter((r) => (!f.estado || r.estado === f.estado) && (!f.tipo || r.tipo === f.tipo) && (!f.tipos || f.tipos.includes(r.tipo)) && (!f.gravedad || r.gravedad === f.gravedad))
      .filter((r) => (f.verificado === undefined || r.verificado === f.verificado) && (!f.usuario_id || r.usuario_id === f.usuario_id))
      .sort((a, b) => b.recibido_en.localeCompare(a.recibido_en));
    const inicio = (f.pagina - 1) * f.limite;
    return { total: todos.length, items: todos.slice(inicio, inicio + f.limite).map(copia) };
  }
  async actualizarEstado(id: string, cambios: Pick<Reporte, "estado" | "verificado">, nota: string | null, operador: { id: string; nombre: string }) {
    const r = this.datos.get(id);
    if (!r) return null;
    const previo = r.estado;
    Object.assign(r, cambios);
    this.cambios.set(id, [
      ...(this.cambios.get(id) ?? []),
      { id: randomUUID(), estado_anterior: previo, estado_nuevo: cambios.estado, operador_nombre: operador.nombre, nota, fecha: new Date().toISOString() },
    ]);
    return copia(r);
  }
  async historial(id: string) {
    return copia(this.cambios.get(id) ?? []);
  }
  async guardarFoto(id: string, url: string, miniaturaUrl: string) {
    const r = this.datos.get(id);
    if (!r) return null;
    Object.assign(r, { foto_url: url, foto_miniatura_url: miniaturaUrl });
    return copia(r);
  }
}

/** Distancia en metros sobre la esfera (equivale a ST_Distance sobre geography para estas escalas). */
export function haversineM(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad;
  const dLon = (lon2 - lon1) * rad;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLon / 2) ** 2;
  return 2 * 6371008.8 * Math.asin(Math.sqrt(a));
}

export class TerritorioEnMemoria implements RepositorioTerritorio {
  private readonly puntos = new Map<string, PuntoServicio>(PUNTOS.map((p) => [p.id, copia(p)]));
  private readonly vias = new Map<string, { id: string; nombre: string; estado: EstadoVia; linea: number[][] }>(
    VIAS.map((v) => [v.id, { id: v.id, nombre: v.nombre, estado: v.estado, linea: v.linea.map((p) => [...p]) }]),
  );

  async crearPunto(p: PuntoServicio) {
    this.puntos.set(p.id, copia(p));
    return copia(p);
  }

  async zonasGeoJson() {
    return zonasGeoJson();
  }
  async viasGeoJson() {
    return {
      type: "FeatureCollection" as const,
      features: [...this.vias.values()].map((v) => ({
        type: "Feature" as const,
        id: v.id,
        geometry: { type: "LineString", coordinates: v.linea },
        properties: { id: v.id, nombre: v.nombre, estado: v.estado, origen: "simulado" },
      })),
    };
  }
  async actualizarVia(id: string, estado: EstadoVia) {
    const v = this.vias.get(id);
    if (!v) return null;
    v.estado = estado;
    return { id: v.id, nombre: v.nombre, estado: v.estado, origen: "simulado", actualizado_en: new Date().toISOString() };
  }
  async sectorDe(lat: number, lon: number) {
    // Las zonas semilla son rectángulos, así que basta comparar contra sus límites.
    for (const z of ZONAS) {
      const lons = z.anillo.map((p) => p[0]);
      const lats = z.anillo.map((p) => p[1]);
      if (lon >= Math.min(...lons) && lon <= Math.max(...lons) && lat >= Math.min(...lats) && lat <= Math.max(...lats)) {
        return z.nombre_sector;
      }
    }
    return null;
  }
  async listarPuntos(tipo?: TipoPuntoServicio, soloActivos = true) {
    return [...this.puntos.values()].filter((p) => (!tipo || p.tipo === tipo) && (!soloActivos || p.activo)).map(copia);
  }
  async puntosCercanos(c: Cercania) {
    const bloqueadas = [...this.vias.values()].filter((v) => v.estado === "bloqueada").map((v) => v.linea);
    return [...this.puntos.values()]
      .filter((p) => p.activo && p.capacidad - p.ocupacion >= c.personas && (!c.tipo || p.tipo === c.tipo))
      .map((p) => ({
        ...copia(p),
        distancia_m: haversineM(c.latitud, c.longitud, p.latitud, p.longitud),
        paso_bloqueado: cruzaViaBloqueada([c.longitud, c.latitud], [p.longitud, p.latitud], bloqueadas),
      }))
      .sort((a, b) => Number(a.paso_bloqueado) - Number(b.paso_bloqueado) || a.distancia_m - b.distancia_m)
      .slice(0, c.limite);
  }
  async actualizarOcupacion(id: string, ocupacion: number) {
    const p = this.puntos.get(id);
    if (!p) return null;
    p.ocupacion = ocupacion;
    return copia(p);
  }
}

export class AlertasEnMemoria implements RepositorioAlertas {
  private readonly datos: Alerta[] = ALERTAS.map(copia);
  async listar(soloVigentes: boolean) {
    return this.datos.filter((a) => !soloVigentes || a.vigente).sort((a, b) => b.creado_en.localeCompare(a.creado_en)).map(copia);
  }
  async crear(a: Alerta) {
    this.datos.push(copia(a));
  }
  async cerrar(id: string) {
    const a = this.datos.find((x) => x.id === id);
    if (!a) return null;
    a.vigente = false;
    return copia(a);
  }
}

export class AsistenciaEnMemoria implements RepositorioAsistencia {
  private readonly datos: Entrega[] = [];
  private readonly stock = new Map<Suministro, ItemInventario>(INVENTARIO.map((i) => [i.necesidad, copia(i)]));
  async registrar(e: Entrega) {
    if (esSuministro(e.necesidad)) {
      const item = this.stock.get(e.necesidad);
      if (!item || item.cantidad < e.cantidad) return "sin_stock" as const;
      item.cantidad -= e.cantidad;
      item.actualizado_en = new Date().toISOString();
    }
    this.datos.push(copia(e));
    return "ok" as const;
  }
  async inventario() {
    return [...this.stock.values()].map(copia);
  }
  async ajustarInventario(necesidad: Suministro, delta: number) {
    const item = this.stock.get(necesidad);
    if (!item) return null;
    item.cantidad = Math.max(0, item.cantidad + delta);
    item.actualizado_en = new Date().toISOString();
    return copia(item);
  }
  async listar() {
    return this.datos.map(copia);
  }
}
