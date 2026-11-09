import { randomUUID } from "node:crypto";
import type { Rol } from "./dominio/catalogos.js";
import type { RepositorioUsuarios, ServicioClaves } from "./dominio/puertos.js";

/**
 * Cuentas de la demo del hackathon. Mismos correos que apps/web/src/lib/auth.ts (USUARIOS_DEMO)
 * y accesos rápidos de la app móvil Flutter.
 */
export const CUENTAS_DEMO: Array<{ id: string; nombre: string; correo: string; rol: Rol; claveFija?: string }> = [
  { id: "b0000000-0000-4000-8000-000000000001", nombre: "Ciudadano demo", correo: "ciudadano@demo.esmeraldas-resiliente.ec", rol: "ciudadano" },
  { id: "b0000000-0000-4000-8000-000000000002", nombre: "Operador COE demo", correo: "operador@demo.esmeraldas-resiliente.ec", rol: "operador_911" },
  { id: "b0000000-0000-4000-8000-000000000003", nombre: "Administrador demo", correo: "admin@demo.esmeraldas-resiliente.ec", rol: "admin" },
  { id: "b0000000-0000-4000-8000-000000000004", nombre: "María Quiñónez", correo: "ciudadano@demo.ec", rol: "ciudadano", claveFija: "Ciudadano#2026" },
  { id: "b0000000-0000-4000-8000-000000000005", nombre: "Operador Turno A", correo: "operador@911.ec", rol: "operador_911", claveFija: "Operador#2026" },
  { id: "b0000000-0000-4000-8000-000000000006", nombre: "Administrador COE", correo: "admin@resiliente.ec", rol: "admin", claveFija: "Admin#2026x" },
];

/** Crea las cuentas que falten. Devuelve los correos creados. */
export async function asegurarCuentasDemo(usuarios: RepositorioUsuarios, claves: ServicioClaves, clave?: string): Promise<string[]> {
  const clavePorDefecto = clave && clave.trim().length > 0 ? clave.trim() : "demo-resiliente-2026";
  const creadas: string[] = [];
  for (const c of CUENTAS_DEMO) {
    if (await usuarios.buscarPorCorreo(c.correo)) continue;
    const claveEfectiva = c.claveFija ?? clavePorDefecto;
    await usuarios.crear({
      id: c.id || randomUUID(),
      nombre: c.nombre,
      correo: c.correo,
      rol: c.rol,
      creado_en: new Date().toISOString(),
      clave_hash: await claves.cifrar(claveEfectiva),
    });
    creadas.push(c.correo);
  }
  return creadas;
}
