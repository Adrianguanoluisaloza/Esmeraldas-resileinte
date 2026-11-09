import type { EstadoReporte, Gravedad, Necesidad } from "./catalogos.js";
import { NECESIDADES } from "./catalogos.js";
import type { PuntoServicio } from "./puntoServicio.js";
import { semaforoCupo } from "./puntoServicio.js";
import type { Reporte } from "./reporte.js";

/** Reglas puras de operación del COE. Sin base de datos ni HTTP: se prueban con datos en memoria. */

export type NivelAlerta = Gravedad;
export type OrigenAlerta = "oficial" | "simulada";

export interface Alerta {
  id: string;
  sector: string;
  mensaje: string;
  nivel: NivelAlerta;
  origen: OrigenAlerta;
  creado_por: string | null;
  creado_en: string;
  vigente: boolean;
}

export interface HistorialEstado {
  id: string;
  estado_anterior: EstadoReporte;
  estado_nuevo: EstadoReporte;
  operador_nombre: string | null;
  nota: string | null;
  fecha: string;
}

export interface Entrega {
  id: string;
  reporte_id: string;
  necesidad: Necesidad;
  cantidad: number;
  nota: string | null;
  entregado_por: string | null;
  entregado_en: string;
}

export type EstadoVia = "habilitada" | "parcial" | "bloqueada";

const PESO: Record<Gravedad, number> = { baja: 1, media: 2, alta: 3, critica: 4 };
const abierto = (r: Reporte) => r.estado === "pendiente" || r.estado === "en_proceso";

/**
 * Puntaje de prioridad explicable (no es caja negra): gravedad, personas, vulnerables y pedido de rescate.
 * Sirve para ordenar la atención; la decisión final es del operador.
 */
export function puntajePrioridad(r: Reporte): number {
  const vulnerables = r.ninos + r.adultos_mayores;
  return PESO[r.gravedad] * 10 + Math.min(r.personas_afectadas, 100) * 0.5 + vulnerables + (r.necesidades.includes("rescate") ? 15 : 0);
}

export function estadisticas(reportes: Reporte[], puntos: PuntoServicio[], viasBloqueadas: number) {
  const abiertos = reportes.filter(abierto);
  const necesidades = Object.fromEntries(NECESIDADES.map((n) => [n, 0])) as Record<Necesidad, number>;
  for (const r of abiertos) for (const n of r.necesidades) necesidades[n] += 1;
  const cuenta = (e: EstadoReporte) => reportes.filter((r) => r.estado === e).length;
  return {
    total_reportes: reportes.length,
    pendientes: cuenta("pendiente"),
    en_proceso: cuenta("en_proceso"),
    atendidos: cuenta("atendido"),
    criticos: abiertos.filter((r) => r.gravedad === "critica").length,
    personas_afectadas_total: abiertos.reduce((s, r) => s + r.personas_afectadas, 0),
    ninos_total: abiertos.reduce((s, r) => s + r.ninos, 0),
    adultos_mayores_total: abiertos.reduce((s, r) => s + r.adultos_mayores, 0),
    vias_bloqueadas_total: viasBloqueadas,
    albergues_disponibles: puntos.filter((p) => p.tipo === "albergue" && p.activo && semaforoCupo(p.capacidad, p.ocupacion) !== "rojo").length,
    necesidades_acumuladas: necesidades,
  };
}

/** Sectores ordenados por prioridad: suma de puntajes abiertos + recurrencia de eventos. */
export function prioridadSectores(reportes: Reporte[]) {
  const porSector = new Map<string, Reporte[]>();
  for (const r of reportes) {
    const clave = r.sector ?? "Sin sector";
    porSector.set(clave, [...(porSector.get(clave) ?? []), r]);
  }
  return [...porSector.entries()]
    .map(([sector, lista]) => {
      const abiertos = lista.filter(abierto);
      const promedio = lista.reduce((s, r) => s + PESO[r.gravedad], 0) / lista.length;
      return {
        sector,
        cantidad: lista.length,
        abiertos: abiertos.length,
        personas_afectadas: abiertos.reduce((s, r) => s + r.personas_afectadas, 0),
        gravedad_promedio: (["baja", "media", "alta", "critica"] as const)[Math.max(0, Math.round(promedio) - 1)]!,
        puntaje: Math.round(abiertos.reduce((s, r) => s + puntajePrioridad(r), 0) + lista.length * 5),
      };
    })
    .sort((a, b) => b.puntaje - a.puntaje);
}

/** Necesidades de reportes abiertos que aún no tienen entrega registrada. */
export function necesidadesPendientes(reportes: Reporte[], entregas: Entrega[]) {
  const entregadas = new Set(entregas.map((e) => `${e.reporte_id}:${e.necesidad}`));
  return reportes
    .filter((r) => abierto(r) || r.estado === "atendido")
    .flatMap((r) =>
      r.necesidades
        .filter((n) => !entregadas.has(`${r.id}:${n}`))
        .map((n) => ({
          reporte_id: r.id,
          necesidad: n,
          sector: r.sector,
          personas: r.personas_afectadas,
          gravedad: r.gravedad,
          prioridad: Math.round(puntajePrioridad(r)),
        })),
    )
    .sort((a, b) => b.prioridad - a.prioridad);
}
