import { componer } from "../componer.js";
import { leerConfig } from "../config.js";
import { asegurarCuentasDemo } from "../demo.js";

/**
 * Crea las cuentas de la demo (operador, admin, ciudadano) en la base configurada (ALMACEN=postgres).
 * Uso: DEMO_PASSWORD=... npm run usuarios:demo
 * En Docker: docker compose exec api node dist/scripts/crearUsuariosDemo.js
 */
const clave = process.env.DEMO_PASSWORD;
if (!clave || clave.length < 8) {
  console.error("Define DEMO_PASSWORD (mínimo 8 caracteres).");
  process.exit(1);
}

const { usuarios, claves, cerrar } = componer(leerConfig());
const creadas = await asegurarCuentasDemo(usuarios, claves, clave);
console.log(creadas.length ? `Creadas: ${creadas.join(", ")}` : "Las cuentas demo ya existían.");
await cerrar();
