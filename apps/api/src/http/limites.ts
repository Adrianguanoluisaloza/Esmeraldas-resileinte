import type { MiddlewareHandler } from "hono";
import { getConnInfo } from "@hono/node-server/conninfo";

/**
 * Límite de peticiones por IP en ventana fija (por instancia). Protege login, registro y escrituras
 * contra fuerza bruta y abuso. Detrás de Cloudflare la IP real viene en CF-Connecting-IP.
 * Para varias instancias, mover el contador a la base o a Redis.
 */
export function limitePorIp(opciones: { maximo: number; ventanaMs: number; confiarEnProxy: boolean }): MiddlewareHandler {
  const contadores = new Map<string, { n: number; desde: number }>();

  // Limpieza periódica para que el mapa no crezca sin control.
  const limpieza = setInterval(() => {
    const ahora = Date.now();
    for (const [ip, c] of contadores) if (ahora - c.desde > opciones.ventanaMs) contadores.delete(ip);
  }, opciones.ventanaMs);
  limpieza.unref();

  return async (c, next) => {
    let ip = "desconocida";
    if (opciones.confiarEnProxy) ip = c.req.header("CF-Connecting-IP") ?? c.req.header("X-Forwarded-For")?.split(",")[0]?.trim() ?? ip;
    if (ip === "desconocida") {
      try {
        ip = getConnInfo(c).remote.address ?? ip;
      } catch {
        // En pruebas (app.request) no hay socket: se usa una sola cubeta.
      }
    }
    const ahora = Date.now();
    const actual = contadores.get(ip);
    if (!actual || ahora - actual.desde > opciones.ventanaMs) {
      contadores.set(ip, { n: 1, desde: ahora });
    } else if (++actual.n > opciones.maximo) {
      c.header("Retry-After", String(Math.ceil((actual.desde + opciones.ventanaMs - ahora) / 1000)));
      return c.json({ codigo: "DEMASIADAS_PETICIONES", mensaje: "Demasiadas peticiones. Intenta en un momento." }, 429);
    }
    await next();
  };
}
