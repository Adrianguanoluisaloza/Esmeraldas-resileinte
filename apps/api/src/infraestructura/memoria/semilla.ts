import type { PuntoServicio } from "../../dominio/puntoServicio.js";
import type { GeoJsonColeccion } from "../../dominio/puertos.js";
import type { Alerta, ItemInventario } from "../../dominio/operacion.js";
import type { Reporte } from "../../dominio/reporte.js";

/**
 * Espejo de database/02_seed_escenario_06am.sql para el modo ALMACEN=memoria (demo sin Docker y pruebas).
 * Si cambias uno, cambia el otro. Todo es simulado.
 */

type Anillo = Array<[number, number]>;
const caja = (oeste: number, sur: number, este: number, norte: number): Anillo => [
  [oeste, sur], [este, sur], [este, norte], [oeste, norte], [oeste, sur],
];

export const ZONAS = [
  { id: "a1000000-0000-4000-8000-000000000001", nombre_sector: "Isla Piedad", tipo_amenaza: "inundacion", nivel_riesgo: "critico", anillo: caja(-79.662, 0.9735, -79.6545, 0.98) },
  { id: "a1000000-0000-4000-8000-000000000002", nombre_sector: "Barrio 20 de Noviembre", tipo_amenaza: "inundacion", nivel_riesgo: "alto", anillo: caja(-79.673, 0.9515, -79.666, 0.958) },
  { id: "a1000000-0000-4000-8000-000000000003", nombre_sector: "Barrio Caliente (zona alta)", tipo_amenaza: "deslizamiento", nivel_riesgo: "alto", anillo: caja(-79.665, 0.959, -79.6585, 0.965) },
  { id: "a1000000-0000-4000-8000-000000000004", nombre_sector: "Ribera del río Teaone (Tabiazo)", tipo_amenaza: "desbordamiento", nivel_riesgo: "critico", anillo: caja(-79.64, 0.905, -79.625, 0.92) },
  { id: "a1000000-0000-4000-8000-000000000005", nombre_sector: "El Arenal", tipo_amenaza: "inundacion", nivel_riesgo: "medio", anillo: caja(-79.652, 0.967, -79.646, 0.9725) },
] as const;

export const VIAS: Array<{ id: string; nombre: string; estado: "habilitada" | "parcial" | "bloqueada"; linea: number[][] }> = [
  { id: "a2000000-0000-4000-8000-000000000001", nombre: "Acceso Puente Tachina", estado: "bloqueada", linea: [[-79.645, 0.976], [-79.6385, 0.9824], [-79.632, 0.988]] },
  { id: "a2000000-0000-4000-8000-000000000002", nombre: "Vía Esmeraldas - Tabiazo", estado: "parcial", linea: [[-79.655, 0.945], [-79.645, 0.93], [-79.633, 0.912]] },
  { id: "a2000000-0000-4000-8000-000000000003", nombre: "Av. Jaime Roldós (eje sur)", estado: "habilitada", linea: [[-79.654, 0.97], [-79.66, 0.96], [-79.672, 0.952]] },
  { id: "a2000000-0000-4000-8000-000000000004", nombre: "Malecón - Av. Kennedy", estado: "habilitada", linea: [[-79.653, 0.964], [-79.649, 0.978], [-79.6455, 0.9902]] },
];

export function zonasGeoJson(): GeoJsonColeccion {
  return {
    type: "FeatureCollection",
    features: ZONAS.map(({ anillo, id, ...props }) => ({
      type: "Feature",
      id,
      geometry: { type: "Polygon", coordinates: [anillo] },
      properties: { id, ...props, origen: "simulado" },
    })),
  };
}

export function viasGeoJson(): GeoJsonColeccion {
  return {
    type: "FeatureCollection",
    features: VIAS.map(({ linea, id, ...props }) => ({
      type: "Feature",
      id,
      geometry: { type: "LineString", coordinates: linea },
      properties: { id, ...props, origen: "simulado" },
    })),
  };
}

export const PUNTOS: PuntoServicio[] = [
  { id: "a3000000-0000-4000-8000-000000000001", nombre: "Albergue temporal UTLVTE", tipo: "albergue", telefono: "", direccion: "Campus universitario", capacidad: 120, ocupacion: 112, activo: true, latitud: 0.9515, longitud: -79.6732 },
  { id: "a3000000-0000-4000-8000-000000000002", nombre: "Coliseo Nubia Villacís", tipo: "albergue", telefono: "", direccion: "Centro de la ciudad", capacidad: 200, ocupacion: 70, activo: true, latitud: 0.9635, longitud: -79.6542 },
  { id: "a3000000-0000-4000-8000-000000000003", nombre: "Unidad educativa Las Palmas", tipo: "albergue", telefono: "", direccion: "Las Palmas", capacidad: 90, ocupacion: 20, activo: true, latitud: 0.988, longitud: -79.647 },
  { id: "a3000000-0000-4000-8000-000000000004", nombre: "Hospital Delfina Torres de Concha", tipo: "centro_salud", telefono: "", direccion: "Sector San Rafael", capacidad: 150, ocupacion: 138, activo: true, latitud: 0.9428, longitud: -79.6812 },
  { id: "a3000000-0000-4000-8000-000000000005", nombre: "Centro de salud Las Palmas", tipo: "centro_salud", telefono: "", direccion: "Las Palmas", capacidad: 40, ocupacion: 22, activo: true, latitud: 0.9902, longitud: -79.6455 },
];

const base = { usuario_id: null, origen: "simulado", ubicacion_aproximada: false, foto_url: null, foto_miniatura_url: null } as const;

export const REPORTES: Reporte[] = [
  { ...base, id: "a4000000-0000-4000-8000-000000000001", tipo: "inundacion", descripcion: "Acumulación de agua en calles y viviendas de barrios ribereños.", gravedad: "critica", estado: "pendiente", latitud: 0.9765, longitud: -79.6582, precision_m: 6, sector: "Isla Piedad", capturado_en: "2026-11-12T11:00:00.000Z", recibido_en: "2026-11-12T11:02:00.000Z", verificado: false, personas_afectadas: 35, ninos: 12, adultos_mayores: 5, necesidades: ["rescate", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000002", tipo: "inundacion", descripcion: "Desbordamiento del río en comunidad rural con señal limitada.", gravedad: "critica", estado: "pendiente", latitud: 0.912, longitud: -79.632, precision_m: 25, sector: "Ribera del río Teaone (Tabiazo)", capturado_en: "2026-11-12T10:55:00.000Z", recibido_en: "2026-11-12T11:20:00.000Z", verificado: false, personas_afectadas: 60, ninos: 20, adultos_mayores: 9, necesidades: ["rescate", "alimentos", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000003", tipo: "via_bloqueada", descripcion: "Deslizamiento interrumpe la vía. Se requiere ruta alterna.", gravedad: "alta", estado: "en_proceso", latitud: 0.9824, longitud: -79.6385, precision_m: 12, sector: "Acceso Puente Tachina", capturado_en: "2026-11-12T11:01:00.000Z", recibido_en: "2026-11-12T11:05:00.000Z", verificado: true, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [] },
  { ...base, id: "a4000000-0000-4000-8000-000000000004", tipo: "personas_atrapadas", descripcion: "Familias atrapadas en planta alta, piden evacuación.", gravedad: "critica", estado: "pendiente", latitud: 0.9548, longitud: -79.6695, precision_m: 5, sector: "Barrio 20 de Noviembre", capturado_en: "2026-11-12T11:04:00.000Z", recibido_en: "2026-11-12T11:06:00.000Z", verificado: false, personas_afectadas: 14, ninos: 6, adultos_mayores: 3, necesidades: ["rescate", "medicinas"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000005", tipo: "otro", descripcion: "Albergue temporal UTLVTE cerca del límite de capacidad. Se necesita redirigir familias.", gravedad: "alta", estado: "en_proceso", latitud: 0.9515, longitud: -79.6732, precision_m: 4, sector: "Barrio 20 de Noviembre", capturado_en: "2026-11-12T11:08:00.000Z", recibido_en: "2026-11-12T11:08:00.000Z", verificado: true, personas_afectadas: 112, ninos: 40, adultos_mayores: 15, necesidades: ["alimentos", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000006", tipo: "otro", descripcion: "Solicitud urgente de agua potable, alimentos y medicamentos.", gravedad: "alta", estado: "pendiente", latitud: 0.97, longitud: -79.649, precision_m: 10, sector: "El Arenal", capturado_en: "2026-11-12T11:10:00.000Z", recibido_en: "2026-11-12T11:11:00.000Z", verificado: false, personas_afectadas: 22, ninos: 8, adultos_mayores: 4, necesidades: ["agua", "alimentos", "medicinas"] },
  // Reportes ciudadanos de prueba generados en vivo (persistidos para evaluación del jurado)
  { ...base, id: "3b4e75ec-669e-4bbd-80b4-1c44bae604f7", origen: "ciudadano", tipo: "personas_atrapadas", descripcion: "prueba6", gravedad: "critica", estado: "pendiente", latitud: 0.9613845857587157, longitud: -79.66822318499793, precision_m: 10, sector: "Barrio Caliente (zona alta)", capturado_en: "2026-11-09T20:38:14.380Z", recibido_en: "2026-11-09T20:38:15.819Z", verificado: false, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [] },
  { ...base, id: "cc230d23-318b-47c0-b5e4-5e57d43c253d", origen: "ciudadano", tipo: "dano_vivienda", descripcion: "pruebasininternet", gravedad: "critica", estado: "pendiente", latitud: 0.9725452421305314, longitud: -79.66629187416659, precision_m: 94, sector: "Centro / Malecón", capturado_en: "2026-11-09T20:30:58.099Z", recibido_en: "2026-11-09T20:32:29.230Z", verificado: false, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [] },
  { ...base, id: "9e5a76ac-5e79-43d1-ba5e-438d7afc6059", origen: "ciudadano", tipo: "deslizamiento", descripcion: "rrrrrrrrrr", gravedad: "alta", estado: "pendiente", latitud: 0.972640436488756, longitud: -79.66610764278175, precision_m: 82, sector: "Centro / Malecón", capturado_en: "2026-11-09T20:28:19.706Z", recibido_en: "2026-11-09T20:28:19.725Z", verificado: false, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [], foto_url: "/fotos/9e5a76ac-5e79-43d1-ba5e-438d7afc6059.png", foto_miniatura_url: "/fotos/9e5a76ac-5e79-43d1-ba5e-438d7afc6059.min.jpg" },
];

export const ALERTAS: Alerta[] = [
  {
    id: "a5000000-0000-4000-8000-000000000001",
    sector: "Ribera del río Teaone (Tabiazo)",
    mensaje: "Simulacro: crecida del río. Dirigirse a zonas altas y seguir indicaciones de las autoridades.",
    nivel: "critica",
    origen: "simulada",
    creado_por: null,
    creado_en: "2026-11-12T11:15:00.000Z",
    vigente: true,
  },
  {
    id: "a5000000-0000-4000-8000-000000000002",
    sector: "Isla Piedad",
    mensaje: "Simulacro: desbordamiento inminente por marea alta. Evacuar familias vulnerables al Coliseo Nubia Villacís.",
    nivel: "alta",
    origen: "simulada",
    creado_por: null,
    creado_en: "2026-11-12T11:20:00.000Z",
    vigente: true,
  },
  {
    id: "a5000000-0000-4000-8000-000000000003",
    sector: "Vía Esmeraldas - Atacames",
    mensaje: "Simulacro: paso vehicular restringido a un solo carril por árbol caído. Maquinaria en camino.",
    nivel: "media",
    origen: "simulada",
    creado_por: null,
    creado_en: "2026-11-12T11:25:00.000Z",
    vigente: true,
  },
];

export const INVENTARIO: ItemInventario[] = [
  { necesidad: "agua", cantidad: 400, unidad: "bidones de 20 L", actualizado_en: "2026-11-12T11:00:00.000Z" },
  { necesidad: "alimentos", cantidad: 250, unidad: "kits familiares", actualizado_en: "2026-11-12T11:00:00.000Z" },
  { necesidad: "medicinas", cantidad: 80, unidad: "botiquines", actualizado_en: "2026-11-12T11:00:00.000Z" },
];
