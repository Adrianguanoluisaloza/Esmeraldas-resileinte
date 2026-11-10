import { ErrorDominio } from "../dominio/errores.js";
import type { AlmacenFotos, ClasificadorIa, Usuario } from "../dominio/puertos.js";
import type { CasosReportes } from "./reportes.js";

type Actor = Pick<Usuario, "id" | "rol">;

export const AVISO_IA = "Sugerencia de apoyo, no oficial. Requiere confirmación humana.";

/**
 * Sugerencia de tipo y gravedad con IA (asistente "Vigía Esmeraldas").
 * Solo personal (ECU 911, Bomberos, Policía, admin) y solo sobre reportes que ya puede ver.
 * No cambia el reporte: el operador decide si aplica la sugerencia.
 */
export class CasosClasificacion {
  constructor(
    private readonly reportes: CasosReportes,
    private readonly fotos: AlmacenFotos,
    private readonly clasificador: ClasificadorIa | null,
  ) {}

  async clasificar(actor: Actor, id: string) {
    if (actor.rol === "ciudadano") throw new ErrorDominio("SIN_PERMISO", "La sugerencia con IA es para el personal de respuesta");
    const r = await this.reportes.detalle(actor, id);
    if (!this.clasificador) throw new ErrorDominio("NO_IMPLEMENTADO", "La IA no está configurada en este servidor");

    const nombreFoto = r.foto_url?.split("/").pop() ?? null;
    const foto = nombreFoto && /^[\w.-]+$/.test(nombreFoto) ? await this.fotos.leer(nombreFoto) : null;

    const s = await this.clasificador.clasificar({
      tipo: r.tipo,
      gravedad: r.gravedad,
      descripcion: r.descripcion,
      sector: r.sector,
      personas_afectadas: r.personas_afectadas,
      ninos: r.ninos,
      adultos_mayores: r.adultos_mayores,
      necesidades: r.necesidades,
      foto,
    });
    return { reporte_id: r.id, ...s, analizo_foto: foto !== null, aviso: AVISO_IA };
  }
}
