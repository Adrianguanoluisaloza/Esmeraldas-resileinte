import assert from "node:assert/strict";
import { test } from "node:test";
import { semaforoCupo, vistaPunto } from "../src/dominio/puntoServicio.js";
import { validarTransicion } from "../src/dominio/reporte.js";
import { haversineM } from "../src/infraestructura/memoria/repositorios.js";

test("semáforo de cupo según el contrato (verde < 70, ámbar 70-90, rojo > 90)", () => {
  assert.equal(semaforoCupo(100, 69), "verde");
  assert.equal(semaforoCupo(100, 70), "ambar");
  assert.equal(semaforoCupo(100, 90), "ambar");
  assert.equal(semaforoCupo(100, 91), "rojo");
  assert.equal(semaforoCupo(0, 0), "rojo");
});

test("vista del punto calcula porcentaje y cupos libres sin negativos", () => {
  const v = vistaPunto({ id: "x", nombre: "A", tipo: "albergue", telefono: "", direccion: "", capacidad: 120, ocupacion: 125, activo: true, origen: "simulado", latitud: 0, longitud: 0 });
  assert.equal(v.cupos_libres, 0);
  assert.equal(v.estado_cupo, "rojo");
  assert.equal(v.porcentaje_ocupacion, 104.2);
});

test("transiciones de estado válidas e inválidas", () => {
  assert.doesNotThrow(() => validarTransicion("pendiente", "en_proceso"));
  assert.doesNotThrow(() => validarTransicion("atendido", "atendido"));
  assert.throws(() => validarTransicion("atendido", "descartado"), /No se puede pasar/);
});

test("haversine: un grado de latitud son unos 111 km", () => {
  const m = haversineM(0, -79.65, 1, -79.65);
  assert.ok(m > 110_000 && m < 112_000);
});
