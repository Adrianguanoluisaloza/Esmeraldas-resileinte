import type { Context, MiddlewareHandler } from "hono";
import type { z } from "zod";
import type { CasosAuth } from "../aplicacion/auth.js";
import type { CasosOperacion } from "../aplicacion/operacion.js";
import type { CasosClasificacion } from "../aplicacion/clasificacion.js";
import type { CasosReportes } from "../aplicacion/reportes.js";
import type { CasosTerritorio } from "../aplicacion/territorio.js";
import type { Rol } from "../dominio/catalogos.js";
import { ErrorDominio } from "../dominio/errores.js";
import type { AlmacenFotos, RepositorioReportes, ServicioTokens } from "../dominio/puertos.js";

/** Todo lo que las rutas necesitan, ya armado en index.ts (raíz de composición). */
export interface Dependencias {
  auth: CasosAuth;
  reportes: CasosReportes;
  territorio: CasosTerritorio;
  operacion: CasosOperacion;
  clasificacion: CasosClasificacion;
  repoReportes: RepositorioReportes;
  fotos: AlmacenFotos;
  tokens: ServicioTokens;
  corsOrigenes: string[];
  confiarEnProxy: boolean;
  /** true fuera de producción: acepta http://localhost:* en CORS. */
  permitirLocalhost: boolean;
  limiteEscriturasMinuto: number;
  /** Comprueba la base de datos para GET /salud. */
  comprobarAlmacen: () => Promise<boolean>;
}

export interface Sesion {
  id: string;
  rol: Rol;
  nombre: string;
}

export type Entorno = { Variables: { sesion: Sesion; idPeticion: string } };

/** Sesión del contexto o null si la ruta acepta peticiones sin cuenta. */
export const sesionDe = (c: { get(k: "sesion"): Sesion | undefined }) => c.get("sesion") ?? null;

/** Exige Bearer JWT válido. Si se pasan roles, además exige uno de ellos. */
export function requiereSesion(tokens: ServicioTokens, roles?: readonly Rol[]): MiddlewareHandler<Entorno> {
  return async (c, next) => {
    const cabecera = c.req.header("Authorization") ?? "";
    const coincide = /^Bearer ([A-Za-z0-9._~-]{20,4096})$/.exec(cabecera);
    const sesion = coincide?.[1] ? await tokens.verificar(coincide[1]) : null;
    if (!sesion) throw new ErrorDominio("NO_AUTENTICADO", "Sesión requerida");
    if (roles && !roles.includes(sesion.rol)) throw new ErrorDominio("SIN_PERMISO", "Tu rol no permite esta acción");
    c.set("sesion", sesion);
    await next();
  };
}

/** Si viene un token válido, deja la sesión en el contexto; si no viene, sigue sin sesión. Un token inválido es 401. */
export function sesionOpcional(tokens: ServicioTokens): MiddlewareHandler<Entorno> {
  return async (c, next) => {
    const cabecera = c.req.header("Authorization");
    if (cabecera) {
      const coincide = /^Bearer ([A-Za-z0-9._~-]{20,4096})$/.exec(cabecera);
      const sesion = coincide?.[1] ? await tokens.verificar(coincide[1]) : null;
      // Token vencido: el celular debe volver a iniciar sesión; no se convierte en anónimo en silencio.
      if (!sesion) throw new ErrorDominio("NO_AUTENTICADO", "Sesión vencida o inválida");
      c.set("sesion", sesion);
    }
    await next();
  };
}

/** Lee y valida JSON con límite de tamaño. Devuelve los datos ya tipados. */
export async function leerJson<T extends z.ZodType>(c: Context, esquema: T, maxBytes = 16_384): Promise<z.infer<T>> {
  const texto = await c.req.text();
  if (Buffer.byteLength(texto) > maxBytes) throw new ErrorDominio("VALIDACION", "Cuerpo demasiado grande");
  let crudo: unknown;
  try {
    crudo = JSON.parse(texto);
  } catch {
    throw new ErrorDominio("VALIDACION", "JSON inválido");
  }
  return validar(esquema, crudo);
}

export function validar<T extends z.ZodType>(esquema: T, datos: unknown): z.infer<T> {
  const r = esquema.safeParse(datos);
  if (!r.success) {
    throw new ErrorDominio("VALIDACION", "Datos inválidos", r.error.issues.map((i) => `${i.path.join(".") || "cuerpo"}: ${i.message}`));
  }
  return r.data;
}
