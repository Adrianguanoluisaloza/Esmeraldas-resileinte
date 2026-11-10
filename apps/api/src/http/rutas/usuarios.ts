import { Hono } from "hono";
import { leerJson, requiereSesion, validar, type Dependencias, type Entorno } from "../contexto.js";
import { CambioRolEntrada, IdRuta } from "../esquemas.js";

/** Administración de cuentas. Es lo que distingue al administrador del operador. */
export function rutasUsuarios(deps: Dependencias) {
  const r = new Hono<Entorno>();
  r.use("*", requiereSesion(deps.tokens, ["admin"]));

  r.get("/", async (c) => c.json(await deps.auth.listarUsuarios()));

  r.patch("/:id/rol", async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    const { rol } = await leerJson(c, CambioRolEntrada);
    return c.json(await deps.auth.cambiarRol(c.get("sesion").id, id, rol));
  });

  return r;
}
