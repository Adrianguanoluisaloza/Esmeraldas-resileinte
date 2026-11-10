import { randomUUID } from "node:crypto";
import { esPersonalCoe, type TipoPuntoServicio } from "../dominio/catalogos.js";
import { ErrorDominio } from "../dominio/errores.js";
import type { Cercania, PublicadorEventos, RepositorioTerritorio, Usuario } from "../dominio/puertos.js";
import { vistaPunto, type PuntoServicio } from "../dominio/puntoServicio.js";

export class CasosTerritorio {
  constructor(
    private readonly territorio: RepositorioTerritorio,
    private readonly eventos: PublicadorEventos,
  ) {}

  zonas() {
    return this.territorio.zonasGeoJson();
  }

  vias() {
    return this.territorio.viasGeoJson();
  }

  async puntos(tipo?: TipoPuntoServicio, soloActivos = true) {
    return (await this.territorio.listarPuntos(tipo, soloActivos)).map(vistaPunto);
  }

  /** Pregunta 6 del escenario: ¿dónde existen albergues disponibles? */
  async cercanos(c: Cercania) {
    return (await this.territorio.puntosCercanos(c)).map((p) => ({ ...vistaPunto(p), distancia_m: Math.round(p.distancia_m) }));
  }

  async crearPunto(actor: Pick<Usuario, "rol">, datos: Omit<PuntoServicio, "id" | "activo" | "origen">) {
    if (!esPersonalCoe(actor.rol)) throw new ErrorDominio("SIN_PERMISO", "Requiere rol operador_911 o admin");
    if (datos.ocupacion > datos.capacidad) throw new ErrorDominio("VALIDACION", "La ocupación no puede superar la capacidad");
    const p = await this.territorio.crearPunto({ ...datos, id: randomUUID(), activo: true, origen: "coe" });
    this.eventos.publicar({ tipo: "punto.ocupacion", datos: p });
    return vistaPunto(p);
  }

  async actualizarOcupacion(actor: Pick<Usuario, "rol">, id: string, ocupacion: number) {
    if (!esPersonalCoe(actor.rol)) throw new ErrorDominio("SIN_PERMISO", "Requiere rol operador_911 o admin");
    const p = await this.territorio.actualizarOcupacion(id, ocupacion);
    if (!p) throw new ErrorDominio("NO_ENCONTRADO", "Punto de servicio no encontrado");
    this.eventos.publicar({ tipo: "punto.ocupacion", datos: p });
    return vistaPunto(p);
  }
}
