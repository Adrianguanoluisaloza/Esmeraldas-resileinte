import type { TipoPuntoServicio } from "./catalogos.js";

export type EstadoCupo = "verde" | "ambar" | "rojo";

export interface PuntoServicio {
  id: string;
  nombre: string;
  tipo: TipoPuntoServicio;
  latitud: number;
  longitud: number;
  telefono: string;
  direccion: string;
  capacidad: number;
  ocupacion: number;
  activo: boolean;
}

export interface PuntoServicioVista extends PuntoServicio {
  porcentaje_ocupacion: number;
  estado_cupo: EstadoCupo;
  cupos_libres: number;
}

/** Semáforo del contrato: verde < 70 %, ámbar 70-90 %, rojo > 90 %. */
export function semaforoCupo(capacidad: number, ocupacion: number): EstadoCupo {
  if (capacidad <= 0) return "rojo";
  const pct = (ocupacion / capacidad) * 100;
  if (pct > 90) return "rojo";
  if (pct >= 70) return "ambar";
  return "verde";
}

export function vistaPunto(p: PuntoServicio): PuntoServicioVista {
  const porcentaje = p.capacidad > 0 ? Math.round((p.ocupacion / p.capacidad) * 1000) / 10 : 100;
  return {
    ...p,
    porcentaje_ocupacion: porcentaje,
    estado_cupo: semaforoCupo(p.capacidad, p.ocupacion),
    cupos_libres: Math.max(0, p.capacidad - p.ocupacion),
  };
}
