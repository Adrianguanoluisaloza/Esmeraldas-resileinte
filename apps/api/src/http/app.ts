import { randomUUID } from "node:crypto";
import { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { ErrorDominio, type CodigoError } from "../dominio/errores.js";
import type { Dependencias, Entorno } from "./contexto.js";
import { rutasAuth } from "./rutas/auth.js";
import { rutasPendientes } from "./rutas/pendientes.js";
import { rutasReportes } from "./rutas/reportes.js";
import { rutasTerritorio } from "./rutas/territorio.js";

const ESTADO_HTTP: Record<CodigoError, 400 | 401 | 403 | 404 | 409 | 422 | 501> = {
  VALIDACION: 400,
  NO_AUTENTICADO: 401,
  SIN_PERMISO: 403,
  NO_ENCONTRADO: 404,
  CONFLICTO: 409,
  TRANSICION_INVALIDA: 422,
  NO_IMPLEMENTADO: 501,
};

/**
 * Fábrica de la app HTTP. No crea conexiones ni lee variables de entorno: todo llega en `deps`.
 * Así las pruebas arman la app con repositorios en memoria y la misma app corre en Docker con PostGIS.
 */
export function crearApp(deps: Dependencias) {
  const app = new Hono<Entorno>();

  app.use("*", async (c, next) => {
    c.set("idPeticion", randomUUID());
    c.header("X-Request-Id", c.get("idPeticion"));
    const inicio = performance.now();
    await next();
    // Registro mínimo: sin cuerpo, sin query (puede llevar coordenadas), sin IP.
    console.log(JSON.stringify({ id: c.get("idPeticion"), metodo: c.req.method, ruta: c.req.routePath, estado: c.res.status, ms: Math.round(performance.now() - inicio) }));
  });
  app.use("*", secureHeaders());
  app.use("*", cors({
    origin: (origen) => (deps.corsOrigenes.includes(origen) ? origen : null),
    allowHeaders: ["Authorization", "Content-Type"],
    allowMethods: ["GET", "POST", "PATCH", "OPTIONS"],
    maxAge: 600,
  }));
  // Tope general; la foto tiene su propio límite de 2 MB dentro de su ruta.
  app.use("*", bodyLimit({ maxSize: 3 * 1024 * 1024, onError: (c) => c.json({ codigo: "VALIDACION", mensaje: "Cuerpo demasiado grande" }, 413) }));
  app.use("*", async (c, next) => {
    await next();
    if (!c.res.headers.has("Cache-Control")) c.header("Cache-Control", "no-store");
  });

  app.get("/salud", async (c) => {
    const almacen = await deps.comprobarAlmacen().catch(() => false);
    return c.json({ estado: almacen ? "ok" : "degradado", timestamp: new Date().toISOString() }, almacen ? 200 : 503);
  });

  app.route("/auth", rutasAuth(deps));
  app.route("/reportes", rutasReportes(deps));
  app.route("/", rutasTerritorio(deps));
  app.route("/", rutasPendientes(deps));

  app.notFound((c) => c.json({ codigo: "NO_ENCONTRADO", mensaje: "Ruta no existe" }, 404));

  app.onError((error, c) => {
    if (error instanceof ErrorDominio) {
      return c.json({ codigo: error.codigo, mensaje: error.message, errores: error.detalles }, ESTADO_HTTP[error.codigo]);
    }
    // Errores inesperados: se registran con el id de la petición, al cliente no se le muestra el detalle.
    console.error(JSON.stringify({ id: c.get("idPeticion"), error: error instanceof Error ? error.message : String(error) }));
    return c.json({ codigo: "ERROR_INTERNO", mensaje: "Error interno", id: c.get("idPeticion") }, 500);
  });

  return app;
}
