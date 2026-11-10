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
  { id: "a1000000-0000-4000-8000-000000000001", nombre_sector: "Isla Piedad", tipo_amenaza: "inundacion", nivel_riesgo: "critico", anillo: [[-79.65352,0.97675],[-79.65371,0.97737],[-79.65429,0.97787],[-79.6548,0.97828],[-79.6551,0.97874],[-79.65543,0.97919],[-79.65599,0.97944],[-79.65665,0.97948],[-79.65722,0.97949],[-79.65773,0.97958],[-79.65825,0.97965],[-79.65877,0.9796],[-79.65931,0.97959],[-79.66002,0.97976],[-79.66094,0.97996],[-79.66178,0.97981],[-79.66214,0.9792],[-79.662,0.9784],[-79.66171,0.97772],[-79.66158,0.97721],[-79.66155,0.97675],[-79.66144,0.97631],[-79.66131,0.97589],[-79.66131,0.9754],[-79.66133,0.97481],[-79.66111,0.97427],[-79.66059,0.97396],[-79.66,0.97378],[-79.65948,0.97346],[-79.65894,0.97298],[-79.65825,0.97269],[-79.65755,0.9729],[-79.65703,0.9735],[-79.6567,0.97412],[-79.65641,0.97456],[-79.65611,0.97489],[-79.65581,0.97521],[-79.65542,0.9755],[-79.65476,0.97577],[-79.65397,0.97616],[-79.65352,0.97675]] },
  { id: "a1000000-0000-4000-8000-000000000002", nombre_sector: "Barrio 20 de Noviembre", tipo_amenaza: "inundacion", nivel_riesgo: "alto", anillo: [[-79.66534,0.95475],[-79.66543,0.95535],[-79.66565,0.95591],[-79.66615,0.95633],[-79.66693,0.95649],[-79.66765,0.95647],[-79.66803,0.95663],[-79.66818,0.95716],[-79.66841,0.95786],[-79.66889,0.95831],[-79.6695,0.95842],[-79.67012,0.95838],[-79.67075,0.95831],[-79.67133,0.95809],[-79.67177,0.95765],[-79.67205,0.95712],[-79.67235,0.95667],[-79.6727,0.95626],[-79.67287,0.95577],[-79.67265,0.95521],[-79.67226,0.95475],[-79.67215,0.95436],[-79.67245,0.95386],[-79.67282,0.95318],[-79.67287,0.95248],[-79.67254,0.95192],[-79.67203,0.95152],[-79.67142,0.95125],[-79.67073,0.95125],[-79.67004,0.95158],[-79.6695,0.95199],[-79.66905,0.95214],[-79.66854,0.95199],[-79.66794,0.9519],[-79.66745,0.95214],[-79.66716,0.95257],[-79.66684,0.95296],[-79.66633,0.95325],[-79.66575,0.95362],[-79.6654,0.95415],[-79.66534,0.95475]] },
  { id: "a1000000-0000-4000-8000-000000000003", nombre_sector: "Barrio Caliente (zona alta)", tipo_amenaza: "deslizamiento", nivel_riesgo: "alto", anillo: [[-79.65815,0.962],[-79.65829,0.96251],[-79.65881,0.96288],[-79.65947,0.96307],[-79.65986,0.96327],[-79.6599,0.96371],[-79.65989,0.96436],[-79.66011,0.96497],[-79.66057,0.96535],[-79.66114,0.96557],[-79.66175,0.96567],[-79.66235,0.96552],[-79.66283,0.96507],[-79.66314,0.96452],[-79.66345,0.96416],[-79.6639,0.96398],[-79.66435,0.96375],[-79.66454,0.96331],[-79.66448,0.96282],[-79.66447,0.9624],[-79.66475,0.962],[-79.66514,0.9615],[-79.66532,0.96093],[-79.66523,0.96036],[-79.66497,0.95984],[-79.66457,0.9594],[-79.66397,0.95918],[-79.66322,0.95934],[-79.66257,0.95968],[-79.66212,0.95982],[-79.66175,0.95957],[-79.66127,0.9592],[-79.66071,0.95906],[-79.66021,0.95921],[-79.65974,0.95945],[-79.65923,0.95967],[-79.65874,0.95998],[-79.65844,0.96045],[-79.65834,0.96098],[-79.65824,0.96149],[-79.65815,0.962]] },
  { id: "a1000000-0000-4000-8000-000000000004", nombre_sector: "Ribera del río Teaone (Tabiazo)", tipo_amenaza: "desbordamiento", nivel_riesgo: "critico", anillo: [[-79.62563,0.9125],[-79.62673,0.91341],[-79.62719,0.91423],[-79.62676,0.91542],[-79.6262,0.91708],[-79.6263,0.9187],[-79.62714,0.91988],[-79.62833,0.92069],[-79.62968,0.92117],[-79.63115,0.92103],[-79.6325,0.92012],[-79.63353,0.91902],[-79.63444,0.91848],[-79.63558,0.91855],[-79.63683,0.91846],[-79.63769,0.91769],[-79.63808,0.91655],[-79.63855,0.91558],[-79.63954,0.91479],[-79.64071,0.9138],[-79.64138,0.9125],[-79.64139,0.91109],[-79.64105,0.90972],[-79.6404,0.90848],[-79.63917,0.90766],[-79.63744,0.90756],[-79.63586,0.90787],[-79.63494,0.90771],[-79.63441,0.90662],[-79.63366,0.9052],[-79.6325,0.90438],[-79.63121,0.90435],[-79.62994,0.90462],[-79.62863,0.90491],[-79.62741,0.90549],[-79.62655,0.90655],[-79.62606,0.90782],[-79.62556,0.90897],[-79.62499,0.91006],[-79.62488,0.91129],[-79.62563,0.9125]] },
  { id: "a1000000-0000-4000-8000-000000000005", nombre_sector: "El Arenal", tipo_amenaza: "inundacion", nivel_riesgo: "medio", anillo: [[-79.64665,0.96975],[-79.64665,0.97009],[-79.64634,0.97054],[-79.64607,0.97112],[-79.64609,0.97169],[-79.64639,0.97214],[-79.64683,0.97249],[-79.64736,0.9727],[-79.64797,0.97264],[-79.64856,0.97232],[-79.649,0.97199],[-79.64938,0.97195],[-79.64984,0.97212],[-79.65035,0.97219],[-79.65076,0.97197],[-79.65103,0.97161],[-79.65135,0.97132],[-79.65182,0.97107],[-79.65227,0.97072],[-79.65249,0.97026],[-79.65251,0.96975],[-79.65246,0.96925],[-79.65226,0.96878],[-79.65179,0.96845],[-79.65111,0.96835],[-79.65054,0.96834],[-79.65028,0.96813],[-79.65018,0.96762],[-79.64996,0.96704],[-79.64953,0.9667],[-79.649,0.96661],[-79.64846,0.96662],[-79.64792,0.96669],[-79.64744,0.96694],[-79.64711,0.96736],[-79.64688,0.96781],[-79.6466,0.96815],[-79.64627,0.96848],[-79.64615,0.9689],[-79.64636,0.96937],[-79.64665,0.96975]] },
] as const;

export const VIAS: Array<{ id: string; nombre: string; estado: "habilitada" | "parcial" | "bloqueada"; linea: number[][] }> = [
  { id: "a2000000-0000-4000-8000-000000000001", nombre: "Acceso Puente Tachina", estado: "bloqueada", linea: [[-79.65035,0.97938],[-79.65128,0.98064],[-79.65248,0.98157],[-79.65291,0.98231],[-79.65319,0.98264],[-79.6534,0.98282],[-79.65339,0.98258],[-79.65308,0.98239],[-79.65257,0.98154],[-79.65147,0.98071],[-79.65119,0.9804],[-79.65041,0.97933],[-79.64988,0.97873],[-79.64928,0.97769],[-79.64574,0.97008],[-79.64537,0.96895],[-79.64521,0.96803],[-79.64519,0.96843],[-79.64529,0.96897],[-79.64566,0.97011],[-79.6491,0.97753],[-79.64988,0.97873]] },
  { id: "a2000000-0000-4000-8000-000000000002", nombre: "Vía del Pacífico (sector sur)", estado: "parcial", linea: [[-79.63107,0.95451],[-79.63184,0.95321],[-79.63216,0.95252],[-79.63217,0.95177],[-79.63207,0.95144],[-79.63165,0.95084],[-79.63066,0.9502],[-79.63031,0.94989],[-79.63006,0.94953],[-79.62991,0.94917],[-79.62986,0.94884],[-79.62993,0.94842],[-79.63009,0.948],[-79.63312,0.94327],[-79.63335,0.94304],[-79.63399,0.94259],[-79.63902,0.94032],[-79.63943,0.93991],[-79.63974,0.93923],[-79.63978,0.93888],[-79.63973,0.93846],[-79.63952,0.93778],[-79.6385,0.93542],[-79.63631,0.93],[-79.63614,0.92941],[-79.6361,0.92868],[-79.63616,0.92834],[-79.63644,0.92774],[-79.63961,0.92214],[-79.64192,0.91858],[-79.64221,0.91796],[-79.64266,0.91645],[-79.6428,0.91541],[-79.64283,0.91364],[-79.64293,0.91269],[-79.64427,0.90842],[-79.64437,0.90788],[-79.64441,0.90696],[-79.64417,0.90308],[-79.64411,0.90264],[-79.64396,0.90219],[-79.64356,0.90145]] },
  { id: "a2000000-0000-4000-8000-000000000003", nombre: "Avenida Jaime Roldós Aguilera", estado: "habilitada", linea: [[-79.65309,0.98426],[-79.65309,0.98426]] },
  { id: "a2000000-0000-4000-8000-000000000004", nombre: "Avenida Libertad", estado: "habilitada", linea: [[-79.65577,0.98474],[-79.65624,0.98428],[-79.65631,0.98408],[-79.65627,0.98377],[-79.65316,0.97148],[-79.65303,0.97057],[-79.65642,0.98409],[-79.65633,0.98433],[-79.65609,0.98462],[-79.65564,0.98484],[-79.65312,0.98692],[-79.65358,0.98667],[-79.65582,0.98484]] },
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
  { id: "a3000000-0000-4000-8000-000000000001", nombre: "Albergue temporal UTLVTE", origen: "simulado", tipo: "albergue", telefono: "", direccion: "Campus universitario", capacidad: 120, ocupacion: 112, activo: true, latitud: 0.9515, longitud: -79.6732 },
  { id: "a3000000-0000-4000-8000-000000000002", nombre: "Coliseo Nubia Villacís", origen: "simulado", tipo: "albergue", telefono: "", direccion: "Centro de la ciudad", capacidad: 200, ocupacion: 70, activo: true, latitud: 0.9635, longitud: -79.6542 },
  { id: "a3000000-0000-4000-8000-000000000003", nombre: "Unidad educativa Las Palmas", origen: "simulado", tipo: "albergue", telefono: "", direccion: "Las Palmas", capacidad: 90, ocupacion: 20, activo: true, latitud: 0.988, longitud: -79.647 },
  { id: "a3000000-0000-4000-8000-000000000004", nombre: "Hospital Delfina Torres de Concha", origen: "simulado", tipo: "centro_salud", telefono: "", direccion: "Sector San Rafael", capacidad: 150, ocupacion: 138, activo: true, latitud: 0.9428, longitud: -79.6812 },
  { id: "a3000000-0000-4000-8000-000000000005", nombre: "Centro de salud Las Palmas", origen: "simulado", tipo: "centro_salud", telefono: "", direccion: "Las Palmas", capacidad: 40, ocupacion: 22, activo: true, latitud: 0.9902, longitud: -79.6455 },
];

const base = { usuario_id: null, origen: "simulado", ubicacion_aproximada: false, foto_url: null, foto_miniatura_url: null } as const;

export const REPORTES: Reporte[] = [
  { ...base, id: "a4000000-0000-4000-8000-000000000001", tipo: "inundacion", descripcion: "Acumulación de agua en calles y viviendas de barrios ribereños.", gravedad: "critica", estado: "pendiente", latitud: 0.9765, longitud: -79.6582, precision_m: 6, sector: "Isla Piedad", capturado_en: "2026-11-12T11:00:00.000Z", recibido_en: "2026-11-12T11:02:00.000Z", verificado: false, personas_afectadas: 35, ninos: 12, adultos_mayores: 5, necesidades: ["rescate", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000002", tipo: "inundacion", descripcion: "Desbordamiento del río en comunidad rural con señal limitada.", gravedad: "critica", estado: "pendiente", latitud: 0.912, longitud: -79.632, precision_m: 25, sector: "Ribera del río Teaone (Tabiazo)", capturado_en: "2026-11-12T10:55:00.000Z", recibido_en: "2026-11-12T11:20:00.000Z", verificado: false, personas_afectadas: 60, ninos: 20, adultos_mayores: 9, necesidades: ["rescate", "alimentos", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000003", tipo: "via_bloqueada", descripcion: "Deslizamiento interrumpe la vía. Se requiere ruta alterna.", gravedad: "alta", estado: "en_proceso", latitud: 0.97753, longitud: -79.6491, precision_m: 12, sector: "Acceso Puente Tachina", capturado_en: "2026-11-12T11:01:00.000Z", recibido_en: "2026-11-12T11:05:00.000Z", verificado: true, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [] },
  { ...base, id: "a4000000-0000-4000-8000-000000000004", tipo: "personas_atrapadas", descripcion: "Familias atrapadas en planta alta, piden evacuación.", gravedad: "critica", estado: "pendiente", latitud: 0.9548, longitud: -79.6695, precision_m: 5, sector: "Barrio 20 de Noviembre", capturado_en: "2026-11-12T11:04:00.000Z", recibido_en: "2026-11-12T11:06:00.000Z", verificado: false, personas_afectadas: 14, ninos: 6, adultos_mayores: 3, necesidades: ["rescate", "medicinas"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000005", tipo: "otro", descripcion: "Albergue temporal UTLVTE cerca del límite de capacidad. Se necesita redirigir familias.", gravedad: "alta", estado: "en_proceso", latitud: 0.9515, longitud: -79.6732, precision_m: 4, sector: "Barrio 20 de Noviembre", capturado_en: "2026-11-12T11:08:00.000Z", recibido_en: "2026-11-12T11:08:00.000Z", verificado: true, personas_afectadas: 112, ninos: 40, adultos_mayores: 15, necesidades: ["alimentos", "agua"] },
  { ...base, id: "a4000000-0000-4000-8000-000000000006", tipo: "otro", descripcion: "Solicitud urgente de agua potable, alimentos y medicamentos.", gravedad: "alta", estado: "pendiente", latitud: 0.97, longitud: -79.649, precision_m: 10, sector: "El Arenal", capturado_en: "2026-11-12T11:10:00.000Z", recibido_en: "2026-11-12T11:11:00.000Z", verificado: false, personas_afectadas: 22, ninos: 8, adultos_mayores: 4, necesidades: ["agua", "alimentos", "medicinas"] },
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
