import { randomBytes, scrypt as scryptCb, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
import type { ServicioClaves } from "../../dominio/puertos.js";

const scrypt = promisify(scryptCb) as (clave: string, sal: Buffer, largo: number) => Promise<Buffer>;
const LARGO = 64;
const SEPARADOR = "$";

/** scrypt de Node: sin dependencias nativas, funciona igual en Docker y en la PC. Formato: scrypt$sal$hash */
export class ClavesScrypt implements ServicioClaves {
  async cifrar(clave: string): Promise<string> {
    const sal = randomBytes(16);
    const hash = await scrypt(clave, sal, LARGO);
    return ["scrypt", sal.toString("base64"), hash.toString("base64")].join(SEPARADOR);
  }

  async verificar(clave: string, guardado: string): Promise<boolean> {
    const [algoritmo, sal, hash] = guardado.split(SEPARADOR);
    if (algoritmo !== "scrypt" || !sal || !hash) return false;
    const esperado = Buffer.from(hash, "base64");
    const calculado = await scrypt(clave, Buffer.from(sal, "base64"), esperado.length);
    return esperado.length === calculado.length && timingSafeEqual(esperado, calculado);
  }
}
