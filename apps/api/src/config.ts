import { z } from "zod";

/**
 * Configuración leída una sola vez al arrancar. Si falta algo obligatorio, el proceso no inicia:
 * es mejor fallar al desplegar que a las 06:00 del jueves.
 */
const Esquema = z.object({
  APP_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  /** memoria: datos semilla en RAM, sin base. postgres: PostgreSQL + PostGIS real. */
  ALMACEN: z.enum(["memoria", "postgres"]).default("postgres"),
  DATABASE_URL: z
    .string()
    .default("postgres://resiliente:resiliente_2026_esmeraldas_db@localhost:5433/resiliente"),
  JWT_SECRET: z
    .string()
    .min(32, "JWT_SECRET debe tener al menos 32 caracteres")
    .default("esmeraldas_resiliente_2026_jwt_secret_key_segura_48chars"),
  JWT_MINUTOS: z.coerce.number().int().min(5).max(24 * 60).default(12 * 60),
  /** Orígenes permitidos separados por coma (la web de Astro y el preview de Cloudflare). */
  CORS_ORIGENES: z.string().default("http://localhost:4321"),
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
  return {
    ...r.data,
    corsOrigenes: r.data.CORS_ORIGENES.split(",").map((o) => o.trim()).filter(Boolean),
  };
}
