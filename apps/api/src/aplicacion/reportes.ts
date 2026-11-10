import { COMPETENCIA_INSTITUCION, esPersonalCoe, puedeAtenderTipo, type EstadoReporte } from "../dominio/catalogos.js";
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
  /**
   * actor null = reporte de emergencia sin cuenta (el celular no tiene sesión o no hay señal para iniciarla).
   * Queda con usuario_id null, sin verificar; solo el COE lo ve.
   */
  async crear(actor: Actor | null, datos: ReporteNuevo): Promise<{ reporte: Reporte; nuevo: boolean }> {
    const existente = await this.reportes.buscar(datos.id);
    if (existente) {
      if (existente.usuario_id !== (actor?.id ?? null)) throw new ErrorDominio("CONFLICTO", "El id del reporte ya está en uso");
      return { reporte: existente, nuevo: false };
    }
    const reporte: Reporte = {
      ...datos,
      usuario_id: actor?.id ?? null,
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

  /** El ciudadano solo ve lo suyo (protección de datos), cada institución su competencia y el COE todo. */
  listar(actor: Actor, filtro: FiltroReportes) {
    const tipos = COMPETENCIA_INSTITUCION[actor.rol];
    const alcance = esPersonalCoe(actor.rol) ? filtro : tipos ? { ...filtro, tipos } : { ...filtro, usuario_id: actor.id };
    return this.reportes.listar(alcance);
  }

  async detalle(actor: Actor, id: string): Promise<Reporte> {
    const r = await this.reportes.buscar(id);
    if (!r || (!puedeAtenderTipo(actor.rol, r.tipo) && r.usuario_id !== actor.id)) {
      throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    }
    return r;
  }

  /** Detalle con el historial de atención (quién cambió el estado, cuándo y con qué nota). */
  /**
   * Quién puede subir la foto (paso 2 de la cola offline):
   * - reporte con dueño: solo su dueño con sesión;
   * - reporte anónimo: sin sesión, una sola vez y dentro de 2 horas desde que se recibió.
   */
  async validarSubidaFoto(actor: Actor | null, id: string): Promise<void> {
    const r = await this.reportes.buscar(id);
    if (!r) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    if (r.usuario_id !== null) {
      if (!actor) throw new ErrorDominio("NO_AUTENTICADO", "Sesión requerida");
      if (r.usuario_id !== actor.id) throw new ErrorDominio("SIN_PERMISO", "Solo quien creó el reporte puede subir su foto");
      return;
    }
    const VENTANA_MS = 2 * 60 * 60 * 1000;
    if (r.foto_url || this.reloj.ahora().getTime() - Date.parse(r.recibido_en) > VENTANA_MS) {
      throw new ErrorDominio("SIN_PERMISO", "La foto de un reporte sin cuenta se sube una sola vez y dentro de 2 horas");
    }
  }

  async detalleConHistorial(actor: Actor, id: string) {
    const r = await this.detalle(actor, id);
    return { ...r, historial: await this.reportes.historial(id) };
  }

  async cambiarEstado(actor: Actor & { nombre?: string }, id: string, estado: EstadoReporte, nota: string | null, verificado: boolean): Promise<Reporte> {
    if (!esPersonalCoe(actor.rol) && !COMPETENCIA_INSTITUCION[actor.rol]) throw new ErrorDominio("SIN_PERMISO", "Tu rol no gestiona reportes");
    const actual = await this.reportes.buscar(id);
    if (!actual) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    if (!puedeAtenderTipo(actor.rol, actual.tipo)) throw new ErrorDominio("SIN_PERMISO", "Este reporte no es competencia de tu institución");
    validarTransicion(actual.estado, estado);
    const r = await this.reportes.actualizarEstado(id, { estado, verificado }, nota, { id: actor.id, nombre: actor.nombre ?? "" });
    if (!r) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    this.eventos.publicar({ tipo: "reporte.estado", datos: r });
    return r;
  }
}
