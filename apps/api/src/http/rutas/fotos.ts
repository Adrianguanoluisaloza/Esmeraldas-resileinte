import { Hono } from "hono";
import { ErrorDominio } from "../../dominio/errores.js";
import type { Dependencias, Entorno } from "../contexto.js";

/** Solo nombres generados por la API: id del reporte, miniatura opcional y extensión. Bloquea rutas como ../ */
const NOMBRE_VALIDO = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(\.min)?\.(jpg|png)$/i;

/** Una etiqueta <img> no puede enviar token: el nombre es el UUID del reporte, que no se puede adivinar. */
export function rutasFotos(deps: Dependencias) {
  const r = new Hono<Entorno>();

  r.get("/:nombre", async (c) => {
    const nombre = c.req.param("nombre");
    const foto = NOMBRE_VALIDO.test(nombre) ? await deps.fotos.leer(nombre) : null;
    if (!foto) throw new ErrorDominio("NO_ENCONTRADO", "Foto no encontrada");
    return c.body(foto.bytes as unknown as ArrayBuffer, 200, { "Content-Type": foto.tipo, "Cache-Control": "public, max-age=3600" });
  });

  return r;
}
