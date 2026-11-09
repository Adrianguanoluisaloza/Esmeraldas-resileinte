import { Hono } from "hono";
import { z } from "zod";
import { ErrorDominio } from "../../dominio/errores.js";
import { leerJson, type Dependencias, type Entorno } from "../contexto.js";
import { LoginEntrada, RegistroEntrada } from "../esquemas.js";

/** Límite simple contra fuerza bruta: 10 intentos por correo cada 10 minutos (por instancia). */
const VENTANA_MS = 10 * 60 * 1000;
const MAX_INTENTOS = 10;
const intentos = new Map<string, { n: number; desde: number }>();

function controlarIntentos(correo: string) {
  const ahora = Date.now();
  const clave = correo.toLowerCase();
  const actual = intentos.get(clave);
  if (!actual || ahora - actual.desde > VENTANA_MS) {
    intentos.set(clave, { n: 1, desde: ahora });
    return;
  }
  actual.n += 1;
  if (actual.n > MAX_INTENTOS) throw new ErrorDominio("SIN_PERMISO", "Demasiados intentos. Espera unos minutos.");
}

export function rutasAuth(deps: Dependencias) {
  const r = new Hono<Entorno>();

  r.post("/login", async (c) => {
    const { correo, password } = await leerJson(c, LoginEntrada);
    controlarIntentos(correo);
    return c.json(await deps.auth.iniciarSesion(correo, password));
  });

  r.post("/registro", async (c) => {
    const { nombre, correo, password } = await leerJson(c, RegistroEntrada);
    return c.json(await deps.auth.registrar(nombre, correo, password), 201);
  });

  /**
   * POST /auth/firebase
   * Recibe un idToken de Firebase (emitido por el cliente tras Google Sign-In u otro proveedor).
   * Lo verifica con Firebase Admin, busca o crea el usuario en la base propia,
   * y devuelve un JWT propio para todas las llamadas REST posteriores.
   */
  r.post("/firebase", async (c) => {
    const { idToken } = await leerJson(c, z.object({ idToken: z.string().min(10) }));
    const sesionFirebase = await deps.tokens.verificar(idToken);
    if (!sesionFirebase) throw new ErrorDominio("NO_AUTENTICADO", "Token de Firebase inválido o vencido");
    // Si el usuario no existe en la base local, lo creamos sin clave (usa Firebase como proveedor)
    const resultado = await deps.auth.iniciarSesionFirebase(sesionFirebase);
    return c.json(resultado);
  });

  return r;
}
