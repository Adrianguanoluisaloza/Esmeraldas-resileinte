import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { beforeEach, test } from "node:test";
import { componer } from "../src/componer.js";
import { leerConfig } from "../src/config.js";
import type { Rol } from "../src/dominio/catalogos.js";
import type { EventoTiempoReal } from "../src/dominio/puertos.js";
import { crearApp } from "../src/http/app.js";
import { puedeVer } from "../src/http/tiempoReal.js";

const config = leerConfig({ JWT_SECRET: "x".repeat(40), APP_ENV: "test", ALMACEN: "memoria" });
let ctx: ReturnType<typeof componer>;
let app: ReturnType<typeof crearApp>;

beforeEach(() => {
  console.log = () => {};
  ctx = componer(config);
  app = crearApp(ctx.deps);
});

async function pedir(metodo: string, ruta: string, token: string, json?: unknown) {
  const res = await app.request(ruta, {
    method: metodo,
    headers: { Authorization: `Bearer ${token}`, ...(json ? { "Content-Type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  });
  const texto = await res.text();
  return { status: res.status, json: texto ? JSON.parse(texto) : null };
}

async function token(rol: Rol) {
  const correo = `${randomUUID()}@prueba.ec`;
  const clave = "clave-segura-123";
  await ctx.usuarios.crear({ id: randomUUID(), nombre: "Prueba", correo, rol, creado_en: new Date().toISOString(), clave_hash: await ctx.claves.cifrar(clave) });
  const res = await app.request("/auth/login", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ correo, password: clave }) });
  return ((await res.json()) as { token: string }).token;
}

const reportes = async (t: string) => (await pedir("GET", "/reportes?limite=200", t)).json.items as Array<{ id: string; tipo: string }>;

test("roles: bomberos solo ve y atiende su competencia", async () => {
  const t = await token("bomberos");
  const lista = await reportes(t);
  assert.ok(lista.length > 0);
  assert.ok(lista.every((r) => ["inundacion", "deslizamiento", "personas_atrapadas", "dano_vivienda"].includes(r.tipo)));
  const propio = lista.find((r) => r.tipo === "inundacion")!;
  assert.equal((await pedir("GET", `/reportes/${propio.id}`, t)).status, 200);
  assert.equal((await pedir("PATCH", `/reportes/${propio.id}/estado`, t, { estado: "en_proceso" })).status, 200);
  const ajeno = (await reportes(await token("operador_911"))).find((r) => r.tipo === "via_bloqueada")!;
  assert.equal((await pedir("GET", `/reportes/${ajeno.id}`, t)).status, 404);
  assert.equal((await pedir("PATCH", `/reportes/${ajeno.id}/estado`, t, { estado: "en_proceso" })).status, 403);
});

test("roles: policía ve vías bloqueadas y personas atrapadas, y actualiza vías", async () => {
  const t = await token("policia");
  const lista = await reportes(t);
  assert.ok(lista.length > 0);
  assert.ok(lista.every((r) => ["via_bloqueada", "personas_atrapadas"].includes(r.tipo)));
  const via = (await (await app.request("/vias")).json() as { features: Array<{ properties: { id: string } }> }).features[0]!;
  assert.equal((await pedir("PATCH", `/vias/${via.properties.id}/estado`, t, { estado: "parcial" })).status, 200);
});

test("roles: las instituciones no emiten alertas ni ven estadísticas ni asistencia", async () => {
  for (const rol of ["bomberos", "policia"] as const) {
    const t = await token(rol);
    assert.equal((await pedir("POST", "/alertas", t, { sector: "Centro", mensaje: "Mensaje de prueba", nivel: "alta" })).status, 403);
    assert.equal((await pedir("GET", "/estadisticas", t)).status, 403);
    assert.equal((await pedir("GET", "/asistencia/inventario", t)).status, 403);
    assert.equal((await pedir("GET", "/usuarios", t)).status, 403);
    assert.equal((await pedir("POST", "/puntos-servicio", t, { nombre: "Escuela", tipo: "albergue", capacidad: 10, latitud: 0.96, longitud: -79.65 })).status, 403);
  }
});

test("roles: bomberos no cambia vías", async () => {
  const t = await token("bomberos");
  const via = (await (await app.request("/vias")).json() as { features: Array<{ properties: { id: string } }> }).features[0]!;
  assert.equal((await pedir("PATCH", `/vias/${via.properties.id}/estado`, t, { estado: "parcial" })).status, 403);
});

test("roles: en tiempo real cada institución recibe solo su competencia", () => {
  const evento = (tipo: string) => ({ tipo: "reporte.creado", datos: { tipo, usuario_id: null } }) as unknown as EventoTiempoReal;
  assert.equal(puedeVer({ id: "b", rol: "bomberos", nombre: "" }, evento("inundacion")), true);
  assert.equal(puedeVer({ id: "b", rol: "bomberos", nombre: "" }, evento("via_bloqueada")), false);
  assert.equal(puedeVer({ id: "p", rol: "policia", nombre: "" }, evento("via_bloqueada")), true);
  assert.equal(puedeVer({ id: "p", rol: "policia", nombre: "" }, evento("otro")), false);
  assert.equal(puedeVer({ id: "c", rol: "ciudadano", nombre: "" }, evento("inundacion")), false);
});

test("edición: ECU 911 corrige y queda en el historial", async () => {
  const t = await token("operador_911");
  const r = (await reportes(t)).find((x) => x.tipo === "inundacion")!;
  const e = await pedir("PATCH", `/reportes/${r.id}`, t, { gravedad: "baja", descripcion: "Descripcion corregida" });
  assert.equal(e.status, 200);
  assert.equal(e.json.gravedad, "baja");
  const d = await pedir("GET", `/reportes/${r.id}`, t);
  assert.match(d.json.historial.at(-1).nota, /gravedad/);
});

test("edición: bomberos corrige lo suyo pero no reclasifica el tipo", async () => {
  const t = await token("bomberos");
  const r = (await reportes(t)).find((x) => x.tipo === "inundacion")!;
  assert.equal((await pedir("PATCH", `/reportes/${r.id}`, t, { gravedad: "media" })).status, 200);
  assert.equal((await pedir("PATCH", `/reportes/${r.id}`, t, { tipo: "otro" })).status, 403);
  const ajeno = (await reportes(await token("operador_911"))).find((x) => x.tipo === "via_bloqueada")!;
  assert.equal((await pedir("PATCH", `/reportes/${ajeno.id}`, t, { gravedad: "media" })).status, 403);
});

test("edición: el ciudadano no edita y un cuerpo vacío se rechaza", async () => {
  const ecu = await token("operador_911");
  const r = (await reportes(ecu))[0]!;
  assert.equal((await pedir("PATCH", `/reportes/${r.id}`, await token("ciudadano"), { gravedad: "media" })).status, 403);
  assert.equal((await pedir("PATCH", `/reportes/${r.id}`, ecu, {})).status, 400);
});
