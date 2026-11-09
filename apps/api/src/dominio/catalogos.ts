/**
 * Catálogos copiados de contrato/openapi.yaml (única fuente de verdad).
 * Si cambia el contrato, se cambia aquí y en la app de Franco al mismo tiempo.
 */
export const ROLES = ["ciudadano", "operador_911", "admin"] as const;
export type Rol = (typeof ROLES)[number];

export const TIPOS_INCIDENTE = [
  "inundacion",
  "deslizamiento",
  "via_bloqueada",
  "personas_atrapadas",
  "dano_vivienda",
  "otro",
] as const;
export type TipoIncidente = (typeof TIPOS_INCIDENTE)[number];

export const ESTADOS_REPORTE = ["pendiente", "en_proceso", "atendido", "descartado"] as const;
export type EstadoReporte = (typeof ESTADOS_REPORTE)[number];

export const GRAVEDADES = ["baja", "media", "alta", "critica"] as const;
export type Gravedad = (typeof GRAVEDADES)[number];

export const NECESIDADES = ["agua", "alimentos", "medicinas", "rescate"] as const;
export type Necesidad = (typeof NECESIDADES)[number];

export const TIPOS_PUNTO = ["albergue", "centro_salud"] as const;
export type TipoPuntoServicio = (typeof TIPOS_PUNTO)[number];

/**
 * El reto exige separar en la interfaz el origen del dato:
 * reporte ciudadano, dato simulado del escenario y alerta oficial (INAMHI / SNGR).
 */
export const ORIGENES = ["ciudadano", "simulado", "oficial"] as const;
export type Origen = (typeof ORIGENES)[number];

export const ROLES_COE: readonly Rol[] = ["operador_911", "admin"];
export const esPersonalCoe = (rol: Rol) => ROLES_COE.includes(rol);
