import { Hono } from "hono";
import { ROLES_COE } from "../../dominio/catalogos.js";
import { ErrorDominio } from "../../dominio/errores.js";
import { requiereSesion, type Dependencias, type Entorno } from "../contexto.js";

/**
 * Rutas del contrato que todavía no tienen caso de uso. Responden 501 con código estable para que la web
 * y la app puedan integrarse ya y mostrar "próximamente" sin romperse. Al implementarlas: crear el caso de
 * uso en aplicacion/, el puerto en dominio/puertos.ts, y mover la ruta a su propio archivo.
 * Tareas detalladas en docs/orquestacion/TAREAS_BACKEND.md.
 */
export function rutasPendientes(deps: Dependencias) {
  const r = new Hono<Entorno>();
  const pendiente = (que: string) => () => {
    throw new ErrorDominio("NO_IMPLEMENTADO", `${que}: pendiente de implementar`);
  };
  const coe = requiereSesion(deps.tokens, ROLES_COE);

  r.get("/alertas", pendiente("Listado de alertas"));
  r.post("/alertas", coe, pendiente("Emisión de alertas"));
  r.get("/estadisticas", coe, pendiente("Estadísticas del COE"));
  r.get("/estadisticas/recurrencia", coe, pendiente("Recurrencia por sector"));
  r.post("/reportes/:id/clasificar", requiereSesion(deps.tokens), pendiente("Clasificación con IA"));

  return r;
}
