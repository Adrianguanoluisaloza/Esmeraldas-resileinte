import { Hono } from "hono";
import { ROLES_COE } from "../../dominio/catalogos.js";
import { leerJson, requiereSesion, validar, type Dependencias, type Entorno } from "../contexto.js";
import { CercanosEntrada, IdRuta, OcupacionEntrada, PuntosEntrada } from "../esquemas.js";

/** Datos territoriales públicos (mapa) y gestión de cupos (solo COE). */
export function rutasTerritorio(deps: Dependencias) {
  const r = new Hono<Entorno>();
  // Las capas cambian poco: se permite caché corta en navegador y en Cloudflare.
  const cacheCorta = "public, max-age=60";

  r.get("/zonas", async (c) => {
    c.header("Cache-Control", cacheCorta);
    return c.json(await deps.territorio.zonas());
  });

  r.get("/vias", async (c) => {
    c.header("Cache-Control", cacheCorta);
    return c.json(await deps.territorio.vias());
  });

  r.get("/puntos-servicio", async (c) => {
    const q = validar(PuntosEntrada, c.req.query());
    return c.json(await deps.territorio.puntos(q.tipo, q.solo_activos));
  });

  // Albergue con cupo más cercano a una coordenada (ST_Distance en PostGIS).
  r.get("/puntos-servicio/cercanos", async (c) => {
    const q = validar(CercanosEntrada, c.req.query());
    return c.json(await deps.territorio.cercanos({ latitud: q.lat, longitud: q.lng, tipo: q.tipo, personas: q.personas, limite: q.limite }));
  });

  r.patch("/puntos-servicio/:id/ocupacion", requiereSesion(deps.tokens, ROLES_COE), async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    const { ocupacion } = await leerJson(c, OcupacionEntrada);
    return c.json(await deps.territorio.actualizarOcupacion(c.get("sesion"), id, ocupacion));
  });

  return r;
}
