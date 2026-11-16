import { randomUUID } from "node:crypto";
import type { Rol } from "./dominio/catalogos.js";
import type { RepositorioUsuarios, ServicioClaves } from "./dominio/puertos.js";

/**
 * Cuentas de demostración. Mismos correos que apps/web/src/lib/auth.ts (USUARIOS_DEMO).
 * La clave sale de DEMO_PASSWORD: nunca se guarda en el código del backend.
 */
export const CUENTAS_DEMO: Array<{ nombre: string; correo: string; rol: Rol }> = [
  { nombre: "Operador COE demo", correo: "operador@demo.esmeraldas-resiliente.ec", rol: "operador_911" },
  { nombre: "Bomberos demo", correo: "bomberos@demo.esmeraldas-resiliente.ec", rol: "bomberos" },
  { nombre: "Policía demo", correo: "policia@demo.esmeraldas-resiliente.ec", rol: "policia" },
  { nombre: "Administrador demo", correo: "admin@demo.esmeraldas-resiliente.ec", rol: "admin" },
  { nombre: "Ciudadano demo", correo: "ciudadano@demo.esmeraldas-resiliente.ec", rol: "ciudadano" },
];

/** Crea las cuentas que falten. Devuelve los correos creados. */
export async function asegurarCuentasDemo(usuarios: RepositorioUsuarios, claves: ServicioClaves, clave: string): Promise<string[]> {
  const creadas: string[] = [];
  for (const c of CUENTAS_DEMO) {
    if (await usuarios.buscarPorCorreo(c.correo)) continue;
    await usuarios.crear({ id: randomUUID(), ...c, creado_en: new Date().toISOString(), clave_hash: await claves.cifrar(clave) });
    creadas.push(c.correo);
  }
  return creadas;
}
