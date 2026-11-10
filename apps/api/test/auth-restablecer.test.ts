import assert from "node:assert/strict";
import { test } from "node:test";
import { CasosAuth } from "../src/aplicacion/auth.js";
import type { ServicioTokens, Usuario } from "../src/dominio/puertos.js";
import { RestablecimientosEnMemoria, UsuariosEnMemoria } from "../src/infraestructura/memoria/repositorios.js";
import { ClavesScrypt } from "../src/infraestructura/seguridad/claves.js";

async function armar() {
  const usuarios = new UsuariosEnMemoria();
  const claves = new ClavesScrypt();
  const repo = new RestablecimientosEnMemoria(usuarios);
  const crearOriginal = repo.crear.bind(repo);
  const hashes: string[] = [];
  repo.crear = async (s) => { hashes.push(s.token_hash); await crearOriginal(s); };
  const enviados: Array<{ destino: string; enlace: string }> = [];
  let ahora = new Date("2026-11-10T00:00:00Z");
  const tokens = { emitir: async (u: Usuario) => `jwt-${u.id}`, verificar: async () => null } as unknown as ServicioTokens;
  const casos = new CasosAuth(usuarios, claves, tokens, { ahora: () => ahora }, repo, {
    enviarRestablecimiento: async (destino, _nombre, enlace) => { enviados.push({ destino, enlace }); },
  }, "https://web.test");
  await casos.registrar("Ana", "ana@correo.test", "clave-original");
  const tokenDe = (i: number) => enviados[i]!.enlace.split("#token=")[1]!;
  return { casos, enviados, hashes, tokenDe, avanzar: (min: number) => { ahora = new Date(ahora.getTime() + min * 60_000); } };
}

test("restablecer: correo sin cuenta no envía nada", async () => {
  const { casos, enviados } = await armar();
  await casos.solicitarRestablecimiento("nadie@correo.test");
  assert.equal(enviados.length, 0);
});

test("restablecer: cuentas demo no envían correo", async () => {
  const { casos, enviados } = await armar();
  await casos.solicitarRestablecimiento("operador@demo.esmeraldas-resiliente.ec");
  assert.equal(enviados.length, 0);
});

test("restablecer: el enlace lleva el token en el fragmento y solo se guarda su hash", async () => {
  const { casos, enviados, hashes, tokenDe } = await armar();
  await casos.solicitarRestablecimiento("ANA@correo.test");
  assert.equal(enviados[0]?.destino, "ana@correo.test");
  assert.match(enviados[0]!.enlace, /^https:\/\/web\.test\/restablecer\/#token=/);
  assert.match(hashes[0]!, /^[0-9a-f]{64}$/);
  assert.notEqual(hashes[0], tokenDe(0));
});

test("restablecer: cambia la clave y el enlace no sirve dos veces", async () => {
  const { casos, tokenDe } = await armar();
  await casos.solicitarRestablecimiento("ana@correo.test");
  await casos.restablecerClave(tokenDe(0), "clave-nueva-123");
  await assert.doesNotReject(casos.iniciarSesion("ana@correo.test", "clave-nueva-123"));
  await assert.rejects(casos.iniciarSesion("ana@correo.test", "clave-original"));
  await assert.rejects(casos.restablecerClave(tokenDe(0), "otra-clave-456"));
});

test("restablecer: el enlace vence a los 30 minutos", async () => {
  const { casos, tokenDe, avanzar } = await armar();
  await casos.solicitarRestablecimiento("ana@correo.test");
  avanzar(31);
  await assert.rejects(casos.restablecerClave(tokenDe(0), "clave-nueva-123"));
  await assert.doesNotReject(casos.iniciarSesion("ana@correo.test", "clave-original"));
});

test("restablecer: un enlace nuevo anula el anterior", async () => {
  const { casos, tokenDe } = await armar();
  await casos.solicitarRestablecimiento("ana@correo.test");
  await casos.solicitarRestablecimiento("ana@correo.test");
  await assert.rejects(casos.restablecerClave(tokenDe(0), "clave-nueva-123"));
  await assert.doesNotReject(casos.restablecerClave(tokenDe(1), "clave-nueva-123"));
});
