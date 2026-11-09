import type { TipoPuntoServicio } from "../../dominio/catalogos.js";
import type {
  Cercania,
  FiltroReportes,
  RepositorioReportes,
  RepositorioTerritorio,
  RepositorioUsuarios,
  UsuarioConClave,
} from "../../dominio/puertos.js";
import type { PuntoServicio } from "../../dominio/puntoServicio.js";
import type { Reporte } from "../../dominio/reporte.js";
import { PUNTOS, REPORTES, ZONAS, viasGeoJson, zonasGeoJson } from "./semilla.js";

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
}

export class ReportesEnMemoria implements RepositorioReportes {
  private readonly datos = new Map<string, Reporte>();
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
      .filter((r) => (!f.estado || r.estado === f.estado) && (!f.tipo || r.tipo === f.tipo) && (!f.gravedad || r.gravedad === f.gravedad))
      .filter((r) => (f.verificado === undefined || r.verificado === f.verificado) && (!f.usuario_id || r.usuario_id === f.usuario_id))
      .sort((a, b) => b.recibido_en.localeCompare(a.recibido_en));
    const inicio = (f.pagina - 1) * f.limite;
    return { total: todos.length, items: todos.slice(inicio, inicio + f.limite).map(copia) };
  }
  async actualizarEstado(id: string, cambios: Pick<Reporte, "estado" | "verificado">) {
    const r = this.datos.get(id);
    if (!r) return null;
    Object.assign(r, cambios);
    return copia(r);
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

  async zonasGeoJson() {
    return zonasGeoJson();
  }
  async viasGeoJson() {
    return viasGeoJson();
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
    return [...this.puntos.values()]
      .filter((p) => p.activo && p.capacidad - p.ocupacion >= c.personas && (!c.tipo || p.tipo === c.tipo))
      .map((p) => ({ ...copia(p), distancia_m: haversineM(c.latitud, c.longitud, p.latitud, p.longitud) }))
      .sort((a, b) => a.distancia_m - b.distancia_m)
      .slice(0, c.limite);
  }
  async actualizarOcupacion(id: string, ocupacion: number) {
    const p = this.puntos.get(id);
    if (!p) return null;
    p.ocupacion = ocupacion;
    return copia(p);
  }
}
