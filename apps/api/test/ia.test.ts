import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { beforeEach, test } from "node:test";
import { CasosClasificacion } from "../src/aplicacion/clasificacion.js";
import { componer } from "../src/componer.js";
import { leerConfig } from "../src/config.js";
import type { Rol } from "../src/dominio/catalogos.js";
import type { ClasificadorIa, EntradaClasificacion } from "../src/dominio/puertos.js";
import { crearApp } from "../src/http/app.js";
import { ClasificadorGemini, validar } from "../src/infraestructura/ia/clasificadorGemini.js";

const config = leerConfig({ JWT_SECRET: "x".repeat(40), APP_ENV: "test", ALMACEN: "memoria" });
let ctx: ReturnType<typeof componer>;
let recibido: EntradaClasificacion | null;

const falso: ClasificadorIa = {
  async clasificar(e) {
    recibido = e;
    return { tipo_sugerido: "inundacion", gravedad_sugerida: "critica", explicacion: "Agua sobre viviendas.", confianza: 0.81 };
  },
};

beforeEach(() => {
  console.log = () => {};
  console.error = () => {};
  recibido = null;
  ctx = componer(config);
});

function app(conIa: boolean) {
  const deps = { ...ctx.deps, clasificacion: new CasosClasificacion(ctx.deps.reportes, ctx.deps.fotos, conIa ? falso : null) };
  return crearApp(deps);
}

async function token(a: ReturnType<typeof crearApp>, rol: Rol) {
  const correo = `${randomUUID()}@prueba.ec`;
  const clave = "clave-segura-123";
  await ctx.usuarios.crear({ id: randomUUID(), nombre: "Prueba", correo, rol, creado_en: new Date().toISOString(), clave_hash: await ctx.claves.cifrar(clave) });
  const res = await a.request("/auth/login", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ correo, password: clave }) });
  return ((await res.json()) as { token: string }).token;
}

async function primerReporte(a: ReturnType<typeof crearApp>, t: string) {
  const res = await a.request("/reportes?limite=1", { headers: { Authorization: `Bearer ${t}` } });
  return ((await res.json()) as { items: Array<{ id: string }> }).items[0]!.id;
}

const clasificar = (a: ReturnType<typeof crearApp>, id: string, t: string) =>
  a.request(`/reportes/${id}/clasificar`, { method: "POST", headers: { Authorization: `Bearer ${t}` } });

test("ECU 911 recibe la sugerencia con el aviso de no oficial", async () => {
  const a = app(true);
  const t = await token(a, "operador_911");
  const id = await primerReporte(a, t);
  const res = await clasificar(a, id, t);
  assert.equal(res.status, 200);
  const cuerpo = (await res.json()) as Record<string, unknown>;
  assert.equal(cuerpo.reporte_id, id);
  assert.equal(cuerpo.gravedad_sugerida, "critica");
  assert.match(String(cuerpo.aviso), /no oficial/);
  assert.ok(recibido && typeof recibido.descripcion === "string");
});

test("El ciudadano no puede pedir la sugerencia", async () => {
  const a = app(true);
  const operador = await token(a, "operador_911");
  const id = await primerReporte(a, operador);
  const res = await clasificar(a, id, await token(a, "ciudadano"));
  assert.equal(res.status, 403);
  assert.equal(recibido, null);
});

test("Sin clave de IA en el servidor responde 501", async () => {
  const a = app(false);
  const t = await token(a, "admin");
  const res = await clasificar(a, await primerReporte(a, t), t);
  assert.equal(res.status, 501);
});

test("Id que no es UUID se rechaza", async () => {
  const a = app(true);
  const res = await clasificar(a, "no-es-uuid", await token(a, "admin"));
  assert.equal(res.status, 400);
});

test("Se rechaza una respuesta del modelo fuera del catálogo", () => {
  assert.throws(() => validar('{"tipo_sugerido":"tsunami","gravedad_sugerida":"alta","explicacion":"x","confianza":0.5}'));
  assert.throws(() => validar("no es json"));
  const ok = validar('{"tipo_sugerido":"deslizamiento","gravedad_sugerida":"alta","explicacion":"  Tierra sobre la vía. ","confianza":1.7}');
  assert.equal(ok.confianza, 1);
  assert.equal(ok.explicacion, "Tierra sobre la vía.");
});

test("Gemini: arma la petición con nivel de razonamiento bajo y lee la respuesta", async () => {
  let cuerpo: Record<string, any> = {};
  let cabeceras: Record<string, string> = {};
  const fetchFalso = (async (_url: string, init: RequestInit) => {
    cuerpo = JSON.parse(String(init.body));
    cabeceras = init.headers as Record<string, string>;
    const texto = JSON.stringify({ tipo_sugerido: "inundacion", gravedad_sugerida: "alta", explicacion: "Agua en la calle.", confianza: 0.7 });
    return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: texto }] } }] }), { status: 200 });
  }) as unknown as typeof fetch;
  const g = new ClasificadorGemini("clave-de-prueba-123", "gemini-3.8-flash", fetchFalso);
  const r = await g.clasificar({ tipo: "otro", gravedad: "media", descripcion: "Se metió el agua", sector: "Isla Piedad", personas_afectadas: 3, ninos: 1, adultos_mayores: 0, necesidades: ["agua"], foto: null });
  assert.equal(r.tipo_sugerido, "inundacion");
  assert.equal(cuerpo.generationConfig.thinkingConfig.thinkingLevel, "LOW");
  assert.equal(cabeceras["x-goog-api-key"], "clave-de-prueba-123");
});

test("Gemini: un error del servicio se traduce a NO_DISPONIBLE", async () => {
  const fetchFalso = (async () => new Response("{}", { status: 500 })) as unknown as typeof fetch;
  const g = new ClasificadorGemini("clave-de-prueba-123", "gemini-3.8-flash", fetchFalso);
  await assert.rejects(
    g.clasificar({ tipo: "otro", gravedad: "media", descripcion: "x", sector: null, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [], foto: null }),
    (e: { codigo?: string }) => e.codigo === "NO_DISPONIBLE",
  );
});
