import { Hono } from "hono";
import { ROLES_COE } from "../../dominio/catalogos.js";
import { leerJson, requiereSesion, validar, type Dependencias, type Entorno } from "../contexto.js";
import { AlertaEntrada, AlertasFiltro, EntregaEntrada, IdRuta, ViaEstadoEntrada } from "../esquemas.js";

/** Alertas, vías, indicadores del COE y asistencia humanitaria. */
export function rutasOperacion(deps: Dependencias) {
  const r = new Hono<Entorno>();
  const coe = requiereSesion(deps.tokens, ROLES_COE);

  // Alertas vigentes: públicas (la ciudadanía debe verlas sin cuenta). ?todas=true incluye cerradas (solo COE).
  r.get("/alertas", async (c, next) => {
    const { todas } = validar(AlertasFiltro, c.req.query());
    if (!todas) return c.json(await deps.operacion.listarAlertas(true));
    return next();
  }, coe, async (c) => c.json(await deps.operacion.listarAlertas(false)));

  r.post("/alertas", coe, async (c) => {
    const e = await leerJson(c, AlertaEntrada);
    return c.json(await deps.operacion.emitirAlerta(c.get("sesion"), e), 201);
  });

  r.patch("/alertas/:id/cerrar", coe, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    return c.json(await deps.operacion.cerrarAlerta(c.get("sesion"), id));
  });

  r.patch("/vias/:id/estado", coe, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    const { estado } = await leerJson(c, ViaEstadoEntrada);
    return c.json(await deps.operacion.cambiarVia(c.get("sesion"), id, estado));
  });

  r.get("/estadisticas", coe, async (c) => c.json(await deps.operacion.estadisticas(c.get("sesion"))));
  r.get("/estadisticas/recurrencia", coe, async (c) => c.json(await deps.operacion.prioridadSectores(c.get("sesion"))));

  r.get("/asistencia/pendientes", coe, async (c) => c.json(await deps.operacion.necesidadesPendientes(c.get("sesion"))));
  r.get("/asistencia/entregas", coe, async (c) => c.json(await deps.operacion.listarEntregas(c.get("sesion"))));
  r.post("/asistencia/entregas", coe, async (c) => {
    const e = await leerJson(c, EntregaEntrada);
    return c.json(await deps.operacion.registrarEntrega(c.get("sesion"), { ...e, nota: e.nota ?? null }), 201);
  });

  return r;
}
