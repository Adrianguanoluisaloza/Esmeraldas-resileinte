import { z } from "zod";
import { ESTADOS_REPORTE, GRAVEDADES, NECESIDADES, ROLES, TIPOS_INCIDENTE, TIPOS_PUNTO } from "../dominio/catalogos.js";

/**
 * Validación de entrada (lo que llega por HTTP). Espejo de contrato/openapi.yaml.
 * .strict() rechaza campos desconocidos: así nadie puede mandar "rol": "admin" en el registro.
 */

const entero = (max: number) => z.number().int().min(0).max(max);

export const LoginEntrada = z.object({
  correo: z.email().max(254),
  password: z.string().min(1).max(200),
}).strict();

export const RegistroEntrada = z.object({
  nombre: z.string().trim().min(2).max(120),
  correo: z.email().max(254),
  password: z.string().min(8).max(200),
}).strict();

export const RecuperarEntrada = z.object({ correo: z.email().max(254) }).strict();

export const RestablecerEntrada = z.object({
  token: z.string().min(20).max(200),
  password: z.string().min(8).max(200),
}).strict();

export const ReporteEntrada = z.object({
  id: z.uuid(),
  tipo: z.enum(TIPOS_INCIDENTE),
  descripcion: z.string().trim().min(3).max(1000),
  gravedad: z.enum(GRAVEDADES),
  // Caja amplia alrededor de la provincia de Esmeraldas: descarta coordenadas 0,0 o de otro país.
  latitud: z.number().min(-0.5).max(1.6),
  longitud: z.number().min(-80.3).max(-78.4),
  precision_m: z.number().min(0).max(100_000).nullable().optional(),
  ubicacion_aproximada: z.boolean().optional(),
  capturado_en: z.iso.datetime({ offset: true }),
  personas_afectadas: entero(10_000).optional(),
  ninos: entero(10_000).optional(),
  adultos_mayores: entero(10_000).optional(),
  necesidades: z.array(z.enum(NECESIDADES)).max(NECESIDADES.length).optional(),
}).strict();

const booleanoTexto = z.enum(["true", "false"]).transform((v) => v === "true");

export const FiltroReportesEntrada = z.object({
  estado: z.enum(ESTADOS_REPORTE).optional(),
  tipo: z.enum(TIPOS_INCIDENTE).optional(),
  gravedad: z.enum(GRAVEDADES).optional(),
  verificado: booleanoTexto.optional(),
  limite: z.coerce.number().int().min(1).max(200).default(50),
  pagina: z.coerce.number().int().min(1).max(10_000).default(1),
});

export const CambioEstadoEntrada = z.object({
  estado: z.enum(ESTADOS_REPORTE),
  nota: z.string().trim().max(500).optional(),
  verificado: z.boolean().default(true),
}).strict();

export const PuntosEntrada = z.object({
  tipo: z.enum(TIPOS_PUNTO).optional(),
  solo_activos: booleanoTexto.default(true),
});

export const CercanosEntrada = z.object({
  lat: z.coerce.number().min(-0.5).max(1.6),
  lng: z.coerce.number().min(-80.3).max(-78.4),
  tipo: z.enum(TIPOS_PUNTO).default("albergue"),
  personas: z.coerce.number().int().min(1).max(1000).default(1),
  limite: z.coerce.number().int().min(1).max(20).default(3),
});

export const PuntoEntrada = z.object({
  nombre: z.string().trim().min(3).max(160),
  tipo: z.enum(TIPOS_PUNTO),
  direccion: z.string().trim().max(200).default(""),
  telefono: z.string().trim().max(30).default(""),
  capacidad: z.number().int().min(1).max(100_000),
  ocupacion: entero(100_000).default(0),
  latitud: z.number().min(-0.5).max(1.6),
  longitud: z.number().min(-80.3).max(-78.4),
}).strict();

export const CambioRolEntrada = z.object({ rol: z.enum(ROLES) }).strict();

export const OcupacionEntrada = z.object({ ocupacion: entero(100_000) }).strict();

export const IdRuta = z.object({ id: z.uuid() });

export const AlertaEntrada = z.object({
  sector: z.string().trim().min(2).max(120),
  mensaje: z.string().trim().min(5).max(500),
  nivel: z.enum(GRAVEDADES),
  origen: z.enum(["oficial", "simulada"]).default("oficial"),
}).strict();

export const ViaEstadoEntrada = z.object({ estado: z.enum(["habilitada", "parcial", "bloqueada"]) }).strict();

export const EntregaEntrada = z.object({
  reporte_id: z.uuid(),
  necesidad: z.enum(NECESIDADES),
  cantidad: z.number().int().min(1).max(100_000),
  nota: z.string().trim().max(500).optional(),
}).strict();

export const AlertasFiltro = z.object({ todas: booleanoTexto.default(false) });

export const InventarioRuta = z.object({ necesidad: z.enum(["agua", "alimentos", "medicinas"]) });
export const AjusteInventarioEntrada = z.object({ delta: z.number().int().min(-100_000).max(100_000).refine((n) => n !== 0) }).strict();
