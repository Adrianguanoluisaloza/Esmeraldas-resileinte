import { esPersonalCoe, type EstadoReporte } from "../dominio/catalogos.js";
import { ErrorDominio } from "../dominio/errores.js";
import type { FiltroReportes, PublicadorEventos, Reloj, RepositorioReportes, RepositorioTerritorio, Usuario } from "../dominio/puertos.js";
import { validarTransicion, type Reporte, type ReporteNuevo } from "../dominio/reporte.js";

type Actor = Pick<Usuario, "id" | "rol">;

export class CasosReportes {
  constructor(
    private readonly reportes: RepositorioReportes,
    private readonly territorio: RepositorioTerritorio,
    private readonly eventos: PublicadorEventos,
    private readonly reloj: Reloj,
  ) {}

  /**
   * Idempotente: el celular puede reenviar el mismo reporte varias veces por mala señal.
   * Mismo id y misma persona = se devuelve el existente sin duplicar.
   */
  async crear(actor: Actor, datos: ReporteNuevo): Promise<{ reporte: Reporte; nuevo: boolean }> {
    const existente = await this.reportes.buscar(datos.id);
    if (existente) {
      if (existente.usuario_id !== actor.id) throw new ErrorDominio("CONFLICTO", "El id del reporte ya está en uso");
      return { reporte: existente, nuevo: false };
    }
    const reporte: Reporte = {
      ...datos,
      usuario_id: actor.id,
      origen: "ciudadano",
      estado: "pendiente",
      verificado: false,
      sector: await this.territorio.sectorDe(datos.latitud, datos.longitud),
      recibido_en: this.reloj.ahora().toISOString(),
      foto_url: null,
      foto_miniatura_url: null,
    };
    const insertado = await this.reportes.insertar(reporte);
    if (!insertado) return this.crear(actor, datos);
    this.eventos.publicar({ tipo: "reporte.creado", datos: reporte });
    return { reporte, nuevo: true };
  }

  /** El ciudadano solo ve lo suyo (protección de datos); el COE ve todo. */
  listar(actor: Actor, filtro: FiltroReportes) {
    const alcance = esPersonalCoe(actor.rol) ? filtro : { ...filtro, usuario_id: actor.id };
    return this.reportes.listar(alcance);
  }

  async detalle(actor: Actor, id: string): Promise<Reporte> {
    const r = await this.reportes.buscar(id);
    if (!r || (!esPersonalCoe(actor.rol) && r.usuario_id !== actor.id)) {
      throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    }
    return r;
  }

  async cambiarEstado(actor: Actor, id: string, estado: EstadoReporte, nota: string | null, verificado: boolean): Promise<Reporte> {
    if (!esPersonalCoe(actor.rol)) throw new ErrorDominio("SIN_PERMISO", "Requiere rol operador_911 o admin");
    const actual = await this.reportes.buscar(id);
    if (!actual) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    validarTransicion(actual.estado, estado);
    const r = await this.reportes.actualizarEstado(id, { estado, verificado }, nota, actor.id);
    if (!r) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    this.eventos.publicar({ tipo: "reporte.estado", datos: r });
    return r;
  }
}
