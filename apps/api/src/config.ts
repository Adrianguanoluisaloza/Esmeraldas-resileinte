import { z } from "zod";

/**
 * Configuración leída una sola vez al arrancar. Si falta algo obligatorio, el proceso no inicia:
 * es mejor fallar al desplegar que a las 06:00 del jueves.
 */
const Esquema = z.object({
  APP_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  /** memoria: datos semilla en RAM, sin base. postgres: PostgreSQL + PostGIS real. */
  ALMACEN: z.enum(["memoria", "postgres"]).default("memoria"),
  DATABASE_URL: z.string().optional(),
  JWT_SECRET: z.string().min(32, "JWT_SECRET debe tener al menos 32 caracteres"),
  JWT_MINUTOS: z.coerce.number().int().min(5).max(24 * 60).default(12 * 60),
  /** ID del proyecto Firebase para verificar tokens de Google Sign-In (opcional). */
  FIREBASE_PROJECT_ID: z.string().optional(),
  /** Orígenes permitidos separados por coma (la web de Astro y el preview de Cloudflare). */
  CORS_ORIGENES: z.string().default("http://localhost:4321"),
  /** true solo si la API está detrás de Cloudflare o un proxy propio (para leer la IP real). */
  CONFIAR_EN_PROXY: z.enum(["true", "false"]).default("false").transform((v) => v === "true"),
  /** Peticiones de escritura permitidas por IP y minuto. */
  LIMITE_ESCRITURAS_MINUTO: z.coerce.number().int().min(10).max(10_000).default(120),
});

export type Config = z.infer<typeof Esquema> & { corsOrigenes: string[] };

export function leerConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const r = Esquema.safeParse(env);
  if (!r.success) {
    const detalle = r.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Configuración inválida: ${detalle}`);
  }
  if (r.data.ALMACEN === "postgres" && !r.data.DATABASE_URL) {
    throw new Error("Configuración inválida: ALMACEN=postgres requiere DATABASE_URL");
  }
  const corsOrigenes = r.data.CORS_ORIGENES.split(",").map((o) => o.trim()).filter(Boolean);
  // Solo orígenes exactos (esquema + dominio + puerto). Nada de comodines ni rutas.
  const invalidos = corsOrigenes.filter((o) => !/^https?:\/\/[a-z0-9.-]+(:\d{1,5})?$/i.test(o));
  if (invalidos.length) throw new Error(`Configuración inválida: CORS_ORIGENES no válidos: ${invalidos.join(", ")}`);
  if (r.data.APP_ENV === "production") {
    if (/replace|cambiar|ejemplo|secret_of/i.test(r.data.JWT_SECRET)) {
      throw new Error("Configuración inválida: JWT_SECRET de ejemplo en producción");
    }
    const inseguros = corsOrigenes.filter((o) => o.startsWith("http://") && !/^http:\/\/localhost(:\d+)?$/.test(o));
    if (inseguros.length) throw new Error(`Configuración inválida: en producción CORS solo acepta https: ${inseguros.join(", ")}`);
  }
  return { ...r.data, corsOrigenes };
}
