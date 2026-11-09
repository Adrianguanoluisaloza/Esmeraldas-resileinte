import type { EstadoReporte, Gravedad, Necesidad, Origen, TipoIncidente } from "./catalogos.js";
import { ErrorDominio } from "./errores.js";

export interface Reporte {
  id: string;
  usuario_id: string | null;
  origen: Origen;
  tipo: TipoIncidente;
  descripcion: string;
  gravedad: Gravedad;
  estado: EstadoReporte;
  latitud: number;
  longitud: number;
  precision_m: number | null;
  ubicacion_aproximada: boolean;
  sector: string | null;
  capturado_en: string;
  recibido_en: string;
  verificado: boolean;
  personas_afectadas: number;
  ninos: number;
  adultos_mayores: number;
  necesidades: Necesidad[];
  foto_url: string | null;
  foto_miniatura_url: string | null;
}

/** Datos que manda el celular. El id lo genera el celular (UUID v4) para que reenviar no duplique. */
export type ReporteNuevo = Pick<
  Reporte,
  | "id"
  | "tipo"
  | "descripcion"
  | "gravedad"
  | "latitud"
  | "longitud"
  | "precision_m"
  | "ubicacion_aproximada"
  | "capturado_en"
  | "personas_afectadas"
  | "ninos"
  | "adultos_mayores"
  | "necesidades"
>;

/** Flujo permitido de atención. Un reporte atendido o descartado puede reabrirse si vuelve a ocurrir. */
const TRANSICIONES: Record<EstadoReporte, EstadoReporte[]> = {
  pendiente: ["en_proceso", "atendido", "descartado"],
  en_proceso: ["atendido", "descartado", "pendiente"],
  atendido: ["en_proceso"],
  descartado: ["pendiente"],
};

export function validarTransicion(actual: EstadoReporte, nuevo: EstadoReporte): void {
  if (actual === nuevo) return;
  if (!TRANSICIONES[actual].includes(nuevo)) {
    throw new ErrorDominio("TRANSICION_INVALIDA", `No se puede pasar de ${actual} a ${nuevo}`);
  }
}
