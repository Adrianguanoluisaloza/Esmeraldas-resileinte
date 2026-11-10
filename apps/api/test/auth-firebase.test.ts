import assert from "node:assert/strict";
import { test } from "node:test";
import { CasosAuth } from "../src/aplicacion/auth.js";
import type { RepositorioRestablecimientos, RepositorioUsuarios, ServicioClaves, ServicioCorreo, ServicioTokens, Usuario } from "../src/dominio/puertos.js";

type Guardado = Usuario & { clave_hash: string };

function armar(existentes: Guardado[] = []) {
  const usuarios = [...existentes];
  const repo = {
    buscarPorCorreo: async (correo: string) => usuarios.find((u) => u.correo === correo) ?? null,
    crear: async (u: Guardado) => { usuarios.push(u); },
  } as unknown as RepositorioUsuarios;
  const tokens = { emitir: async (u: Usuario) => `jwt-${u.id}`, verificar: async () => null } as unknown as ServicioTokens;
  const casos = new CasosAuth(repo, {} as ServicioClaves, tokens, { ahora: () => new Date("2026-11-10T00:00:00Z") }, {} as RepositorioRestablecimientos, {} as ServicioCorreo, "http://web.test");
  return { casos, usuarios };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

test("firebase: usuario nuevo recibe UUID propio aunque el uid no lo sea", async () => {
  const { casos, usuarios } = armar();
  const r = await casos.iniciarSesionFirebase({ id: "AbC123uidDeFirebase", nombre: "Ana", rol: "ciudadano", correo: "Ana@Gmail.com" });
  assert.match(r.usuario.id, UUID);
  assert.equal(r.usuario.correo, "ana@gmail.com");
  assert.equal(usuarios[0]?.clave_hash, "");
});

test("firebase: un usuario nuevo siempre entra como ciudadano", async () => {
  const { casos } = armar();
  const r = await casos.iniciarSesionFirebase({ id: "uid", nombre: "Ana", rol: "admin", correo: "ana@gmail.com" });
  assert.equal(r.usuario.rol, "ciudadano");
});

test("firebase: correo ya registrado reutiliza la cuenta y su rol", async () => {
  const { casos, usuarios } = armar([{ id: "11111111-1111-4111-8111-111111111111", nombre: "Op", correo: "op@gmail.com", rol: "operador_911", creado_en: "2026-11-01T00:00:00Z", clave_hash: "x" }]);
  const r = await casos.iniciarSesionFirebase({ id: "uid", nombre: "Otro", rol: "ciudadano", correo: "op@gmail.com" });
  assert.equal(r.usuario.rol, "operador_911");
  assert.equal(usuarios.length, 1);
  assert.equal("clave_hash" in r.usuario, false);
});

test("firebase: sin correo verificado no se enlaza con ninguna cuenta", async () => {
  const { casos, usuarios } = armar();
  const r = await casos.iniciarSesionFirebase({ id: "uid123", nombre: "Ana", rol: "ciudadano" });
  assert.equal(r.usuario.correo, "uid123@firebase.local");
  assert.equal(usuarios.length, 1);
});
