import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { beforeEach, test } from "node:test";
import { componer } from "../src/componer.js";
import { leerConfig } from "../src/config.js";
import { crearApp } from "../src/http/app.js";

const config = leerConfig({ JWT_SECRET: "x".repeat(40), APP_ENV: "test", ALMACEN: "memoria" });
let ctx: ReturnType<typeof componer>;
let app: ReturnType<typeof crearApp>;

beforeEach(() => {
  console.log = () => {};
  ctx = componer(config);
  app = crearApp(ctx.deps);
});

async function pedir(metodo: string, ruta: string, token?: string, json?: unknown) {
  const res = await app.request(ruta, {
    method: metodo,
    headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(json ? { "Content-Type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  });
  const texto = await res.text();
  return { status: res.status, json: texto ? JSON.parse(texto) : null };
}

async function cuenta(rol: "ciudadano" | "operador_911" | "admin") {
  const correo = `${randomUUID()}@prueba.ec`;
  const clave = "clave-segura-123";
  const id = randomUUID();
  await ctx.usuarios.crear({ id, nombre: "Prueba", correo, rol, creado_en: new Date().toISOString(), clave_hash: await ctx.claves.cifrar(clave) });
  const r = await pedir("POST", "/auth/login", undefined, { correo, password: clave });
  return { id, token: r.json.token as string };
}

const albergue = { nombre: "Escuela Nueva", tipo: "albergue", capacidad: 50, latitud: 0.96, longitud: -79.65 };

test("albergues: el COE registra uno y aparece con origen coe", async () => {
  const { token } = await cuenta("operador_911");
  const r = await pedir("POST", "/puntos-servicio", token, albergue);
  assert.equal(r.status, 201);
  assert.equal(r.json.origen, "coe");
  assert.equal(r.json.estado_cupo, "verde");
  const lista = await pedir("GET", "/puntos-servicio");
  assert.ok(lista.json.some((p: { nombre: string }) => p.nombre === "Escuela Nueva"));
});

test("albergues: el ciudadano no puede registrar y sin sesión tampoco", async () => {
  const { token } = await cuenta("ciudadano");
  assert.equal((await pedir("POST", "/puntos-servicio", token, albergue)).status, 403);
  assert.equal((await pedir("POST", "/puntos-servicio", undefined, albergue)).status, 401);
});

test("albergues: rechaza ocupación mayor a la capacidad y coordenadas fuera de la provincia", async () => {
  const { token } = await cuenta("admin");
  assert.equal((await pedir("POST", "/puntos-servicio", token, { ...albergue, ocupacion: 51 })).status, 400);
  assert.equal((await pedir("POST", "/puntos-servicio", token, { ...albergue, latitud: -2 })).status, 400);
});

test("usuarios: solo el administrador lista y cambia roles", async () => {
  const admin = await cuenta("admin");
  const operador = await cuenta("operador_911");
  const ciudadano = await cuenta("ciudadano");
  assert.equal((await pedir("GET", "/usuarios", operador.token)).status, 403);
  assert.equal((await pedir("PATCH", `/usuarios/${ciudadano.id}/rol`, operador.token, { rol: "admin" })).status, 403);
  const lista = await pedir("GET", "/usuarios", admin.token);
  assert.equal(lista.status, 200);
  assert.equal("clave_hash" in lista.json[0], false);
  const cambio = await pedir("PATCH", `/usuarios/${ciudadano.id}/rol`, admin.token, { rol: "operador_911" });
  assert.equal(cambio.status, 200);
  assert.equal(cambio.json.rol, "operador_911");
});

test("usuarios: el administrador no puede cambiar su propio rol", async () => {
  const admin = await cuenta("admin");
  assert.equal((await pedir("PATCH", `/usuarios/${admin.id}/rol`, admin.token, { rol: "ciudadano" })).status, 409);
});

test("fotos: sirve la foto y la miniatura guardadas y rechaza nombres inválidos", async () => {
  const { FotosEnDisco } = await import("../src/infraestructura/fotosDisco.js");
  const { mkdtemp } = await import("node:fs/promises");
  const { tmpdir } = await import("node:os");
  const { join } = await import("node:path");
  ctx.deps.fotos = new FotosEnDisco(await mkdtemp(join(tmpdir(), "fotos-")), "/fotos");
  app = crearApp(ctx.deps);
  const id = randomUUID();
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=", "base64");
  const g = await ctx.deps.fotos.guardar(id, png, "png");
  const foto = await app.request(g.url);
  assert.equal(foto.status, 200);
  assert.equal(foto.headers.get("content-type"), "image/png");
  assert.equal((await app.request(g.miniaturaUrl)).status, 200);
  assert.equal((await app.request("/fotos/..%2F..%2Fetc%2Fpasswd")).status, 404);
  assert.equal((await app.request(`/fotos/${randomUUID()}.jpg`)).status, 404);
});
