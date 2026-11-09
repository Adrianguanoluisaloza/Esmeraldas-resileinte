import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, beforeEach, test } from "node:test";
import { componer } from "../src/componer.js";
import { leerConfig } from "../src/config.js";
import type { EventoTiempoReal } from "../src/dominio/puertos.js";
import { crearApp } from "../src/http/app.js";
import { puedeVer } from "../src/http/tiempoReal.js";
import { FotosEnDisco } from "../src/infraestructura/fotosDisco.js";

// Silencia el registro por petición durante las pruebas.
console.log = () => {};

// Por defecto en memoria. Con TEST_DATABASE_URL la misma suite corre contra PostgreSQL + PostGIS real
// (base cargada con database/01 y 02). Ver npm run test:db.
const urlBase = process.env.TEST_DATABASE_URL;
const config = leerConfig({
  JWT_SECRET: "x".repeat(40),
  APP_ENV: "test",
  CORS_ORIGENES: "http://localhost:4321",
  ...(urlBase ? { ALMACEN: "postgres", DATABASE_URL: urlBase } : { ALMACEN: "memoria" }),
});

let app: ReturnType<typeof crearApp>;
let eventos: EventoTiempoReal[];
let ctx: ReturnType<typeof componer>;
const abiertos: Array<() => Promise<void>> = [];

after(async () => {
  await Promise.all(abiertos.map((cerrar) => cerrar()));
});

beforeEach(async () => {
  ctx = componer(config);
  abiertos.push(ctx.cerrar);
  ctx.deps.fotos = new FotosEnDisco(await mkdtemp(join(tmpdir(), "fotos-")), "/fotos");
  eventos = [];
  ctx.bus.suscribir((e) => eventos.push(e));
  app = crearApp(ctx.deps);
});

async function pedir(metodo: string, ruta: string, opciones: { token?: string; json?: unknown; body?: BodyInit; origen?: string } = {}) {
  const headers: Record<string, string> = {};
  if (opciones.token) headers.Authorization = `Bearer ${opciones.token}`;
  if (opciones.json !== undefined) headers["Content-Type"] = "application/json";
  if (opciones.origen) headers.Origin = opciones.origen;
  const res = await app.request(ruta, { method: metodo, headers, body: opciones.json !== undefined ? JSON.stringify(opciones.json) : opciones.body });
  const texto = await res.text();
  return { status: res.status, headers: res.headers, json: texto ? JSON.parse(texto) : null };
}

async function cuenta(rol: "ciudadano" | "operador_911" = "ciudadano", correo = `${randomUUID()}@prueba.ec`) {
  const clave = "clave-segura-123";
  await ctx.usuarios.crear({ id: randomUUID(), nombre: "Prueba", correo, rol, creado_en: new Date().toISOString(), clave_hash: await ctx.claves.cifrar(clave) });
  const r = await pedir("POST", "/auth/login", { json: { correo, password: clave } });
  assert.equal(r.status, 200);
  return { token: r.json.token as string, id: r.json.usuario.id as string };
}

const reporte = (extra: Record<string, unknown> = {}) => ({
  id: randomUUID(),
  tipo: "inundacion",
  descripcion: "Agua hasta la rodilla en la calle",
  gravedad: "alta",
  latitud: 0.9765,
  longitud: -79.658,
  capturado_en: "2026-11-12T11:00:00Z",
  necesidades: ["agua", "agua", "rescate"],
  ...extra,
});

test("GET /salud responde ok sin sesión", async () => {
  const r = await pedir("GET", "/salud");
  assert.equal(r.status, 200);
  assert.equal(r.json.estado, "ok");
  assert.equal(r.headers.get("Cache-Control"), "no-store");
});

test("login con clave incorrecta da 401 sin revelar si el correo existe", async () => {
  const correo = `${randomUUID()}@prueba.ec`;
  await cuenta("ciudadano", correo);
  const a = await pedir("POST", "/auth/login", { json: { correo, password: "mala" } });
  const b = await pedir("POST", "/auth/login", { json: { correo: `${randomUUID()}@prueba.ec`, password: "mala" } });
  assert.equal(a.status, 401);
  assert.deepEqual(a.json.mensaje, b.json.mensaje);
});

test("registro ignora intentos de elegir rol", async () => {
  const correo = `${randomUUID()}@prueba.ec`;
  const r = await pedir("POST", "/auth/registro", { json: { nombre: "Ana", correo, password: "12345678", rol: "admin" } });
  assert.equal(r.status, 400);
  const ok = await pedir("POST", "/auth/registro", { json: { nombre: "Ana", correo, password: "12345678" } });
  assert.equal(ok.status, 201);
  assert.equal(ok.json.usuario.rol, "ciudadano");
});

test("POST /reportes es idempotente por UUID y etiqueta el sector con la zona", async () => {
  const { token } = await cuenta();
  const datos = reporte();
  const primero = await pedir("POST", "/reportes", { token, json: datos });
  assert.equal(primero.status, 201);
  assert.equal(primero.json.sector, "Isla Piedad");
  assert.equal(primero.json.origen, "ciudadano");
  assert.deepEqual(primero.json.necesidades, ["agua", "rescate"]);
  const segundo = await pedir("POST", "/reportes", { token, json: datos });
  assert.equal(segundo.status, 200);
  assert.equal(eventos.filter((e) => e.tipo === "reporte.creado").length, 1);
});

test("otro usuario no puede reutilizar el UUID de un reporte ajeno", async () => {
  const a = await cuenta();
  const b = await cuenta();
  const datos = reporte();
  await pedir("POST", "/reportes", { token: a.token, json: datos });
  const r = await pedir("POST", "/reportes", { token: b.token, json: datos });
  assert.equal(r.status, 409);
});

test("validación: coordenadas fuera de Esmeraldas y campos extra se rechazan", async () => {
  const { token } = await cuenta();
  assert.equal((await pedir("POST", "/reportes", { token, json: reporte({ latitud: 0, longitud: 0 }) })).status, 400);
  assert.equal((await pedir("POST", "/reportes", { token, json: reporte({ estado: "atendido" }) })).status, 400);
  assert.equal((await pedir("POST", "/reportes", { json: reporte() })).status, 401);
});

test("el ciudadano solo ve sus reportes; el COE ve todos (incluida la semilla)", async () => {
  const ciudadano = await cuenta();
  const coe = await cuenta("operador_911");
  await pedir("POST", "/reportes", { token: ciudadano.token, json: reporte() });
  const propios = await pedir("GET", "/reportes", { token: ciudadano.token });
  assert.equal(propios.json.total, 1);
  const todos = await pedir("GET", "/reportes?gravedad=critica", { token: coe.token });
  assert.ok(todos.json.total >= 3);
  const ajeno = await pedir("GET", `/reportes/${todos.json.items[0].id}`, { token: ciudadano.token });
  assert.equal(ajeno.status, 404);
});

test("PATCH estado: solo COE y con transiciones válidas", async () => {
  const ciudadano = await cuenta();
  const coe = await cuenta("operador_911");
  const { json } = await pedir("POST", "/reportes", { token: ciudadano.token, json: reporte() });
  assert.equal((await pedir("PATCH", `/reportes/${json.id}/estado`, { token: ciudadano.token, json: { estado: "atendido" } })).status, 403);
  const ok = await pedir("PATCH", `/reportes/${json.id}/estado`, { token: coe.token, json: { estado: "atendido", nota: "Bomberos en sitio" } });
  assert.equal(ok.status, 200);
  assert.equal(ok.json.verificado, true);
  const malo = await pedir("PATCH", `/reportes/${json.id}/estado`, { token: coe.token, json: { estado: "descartado" } });
  assert.equal(malo.status, 422);
});

test("foto: acepta JPEG por bytes reales y rechaza archivos disfrazados", async () => {
  const { token } = await cuenta();
  const { json } = await pedir("POST", "/reportes", { token, json: reporte() });
  const falso = new FormData();
  falso.append("foto", new File([new TextEncoder().encode("no soy imagen")], "a.jpg", { type: "image/jpeg" }));
  assert.equal((await pedir("POST", `/reportes/${json.id}/foto`, { token, body: falso })).status, 400);
  const jpeg = new FormData();
  jpeg.append("foto", new File([new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0])], "a.jpg", { type: "image/jpeg" }));
  const ok = await pedir("POST", `/reportes/${json.id}/foto`, { token, body: jpeg });
  assert.equal(ok.status, 201);
  assert.match(ok.json.ruta, /^\/fotos\/.+\.jpg$/);
});

test("albergues cercanos excluye los llenos y ordena por distancia", async () => {
  const r = await pedir("GET", "/puntos-servicio/cercanos?lat=0.9548&lng=-79.6695&limite=5");
  assert.equal(r.status, 200);
  assert.ok(r.json.length >= 2);
  assert.ok(r.json.every((p: { tipo: string; cupos_libres: number }) => p.tipo === "albergue" && p.cupos_libres > 0));
  assert.ok(r.json[0].distancia_m <= r.json[1].distancia_m);
  const familia = await pedir("GET", "/puntos-servicio/cercanos?lat=0.9548&lng=-79.6695&personas=50");
  assert.ok(familia.json.every((p: { cupos_libres: number }) => p.cupos_libres >= 50));
});

test("ocupación: solo COE la cambia y emite evento en tiempo real", async () => {
  const ciudadano = await cuenta();
  const coe = await cuenta("operador_911");
  const ruta = "/puntos-servicio/a3000000-0000-4000-8000-000000000001/ocupacion";
  assert.equal((await pedir("PATCH", ruta, { token: ciudadano.token, json: { ocupacion: 10 } })).status, 403);
  const ok = await pedir("PATCH", ruta, { token: coe.token, json: { ocupacion: 119 } });
  assert.equal(ok.json.estado_cupo, "rojo");
  assert.equal(eventos.at(-1)?.tipo, "punto.ocupacion");
});

test("capas GeoJSON públicas y rutas pendientes con 501", async () => {
  const zonas = await pedir("GET", "/zonas");
  assert.equal(zonas.json.type, "FeatureCollection");
  assert.equal(zonas.json.features[0].geometry.type, "Polygon");
  assert.equal((await pedir("GET", "/vias")).json.features.length, 4);
  assert.equal((await pedir("GET", "/alertas")).json.codigo, "NO_IMPLEMENTADO");
});

test("CORS solo responde al origen permitido", async () => {
  const bueno = await pedir("GET", "/zonas", { origen: "http://localhost:4321" });
  assert.equal(bueno.headers.get("Access-Control-Allow-Origin"), "http://localhost:4321");
  const malo = await pedir("GET", "/zonas", { origen: "https://otro.com" });
  assert.equal(malo.headers.get("Access-Control-Allow-Origin"), null);
});

test("tiempo real: el ciudadano no recibe reportes ajenos", () => {
  const evento = { tipo: "reporte.creado", datos: { usuario_id: "otro" } } as unknown as EventoTiempoReal;
  assert.equal(puedeVer({ id: "yo", rol: "ciudadano", nombre: "" }, evento), false);
  assert.equal(puedeVer({ id: "yo", rol: "operador_911", nombre: "" }, evento), true);
});
