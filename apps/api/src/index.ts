import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { createNodeWebSocket } from "@hono/node-ws";
import { CARPETA_FOTOS, componer } from "./componer.js";
import { leerConfig } from "./config.js";
import { asegurarCuentasDemo } from "./demo.js";
import { crearApp } from "./http/app.js";
import { montarTiempoReal } from "./http/tiempoReal.js";

const config = leerConfig();
const { deps, bus, cerrar, usuarios, claves } = componer(config);

// En modo memoria (demo sin base) las cuentas se pierden al reiniciar: se recrean si hay DEMO_PASSWORD.
if (config.ALMACEN === "memoria" && process.env.DEMO_PASSWORD) {
  await asegurarCuentasDemo(usuarios, claves, process.env.DEMO_PASSWORD);
}
const app = crearApp(deps);

// Fotos subidas: solo lectura y nombres = UUID. Caché corta porque reenviar la foto la reemplaza.
mkdirSync(CARPETA_FOTOS, { recursive: true });
app.use("/fotos/*", serveStatic({ root: dirname(CARPETA_FOTOS), onFound: (_ruta, c) => c.header("Cache-Control", "private, max-age=300") }));

const { injectWebSocket, upgradeWebSocket } = createNodeWebSocket({ app });
montarTiempoReal(app, upgradeWebSocket, bus, deps.tokens);

const servidor = serve({ fetch: app.fetch, port: config.PORT }, (info) => {
  console.log(JSON.stringify({ evento: "api_iniciada", puerto: info.port, almacen: config.ALMACEN, entorno: config.APP_ENV }));
});
injectWebSocket(servidor);

// Apagado ordenado (Docker manda SIGTERM): termina peticiones en curso y cierra la base.
for (const senal of ["SIGINT", "SIGTERM"] as const) {
  process.on(senal, () => {
    servidor.close(() => {
      void cerrar().finally(() => process.exit(0));
    });
  });
}
