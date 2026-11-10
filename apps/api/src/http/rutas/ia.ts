import { Hono } from "hono";
import { requiereSesion, validar, type Dependencias, type Entorno } from "../contexto.js";
import { IdRuta } from "../esquemas.js";

/** IA de apoyo al operador (agente "Vigía Esmeraldas"). La respuesta siempre lleva el aviso de no oficial. */
export function rutasIa(deps: Dependencias) {
  const r = new Hono<Entorno>();
  r.post("/reportes/:id/clasificar", requiereSesion(deps.tokens), async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    return c.json(await deps.clasificacion.clasificar(c.get("sesion"), id));
  });
  return r;
}
