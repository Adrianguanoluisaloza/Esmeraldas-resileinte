import { Hono } from "hono";
import { ErrorDominio } from "../../dominio/errores.js";
import { requiereSesion, type Dependencias, type Entorno } from "../contexto.js";

/**
 * Rutas del contrato fuera del alcance actual. Responden 501 con código estable para que ningún cliente se rompa.
 * La clasificación automática quedó fuera por decisión del equipo; la priorización se hace con
 * GET /estadisticas/recurrencia (reglas transparentes).
 */
export function rutasPendientes(deps: Dependencias) {
  const r = new Hono<Entorno>();
  r.post("/reportes/:id/clasificar", requiereSesion(deps.tokens), () => {
    throw new ErrorDominio("NO_IMPLEMENTADO", "Clasificación automática fuera del alcance actual");
  });
  return r;
}
