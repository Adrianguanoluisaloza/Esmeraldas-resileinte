export type TipoIncidente =
  | 'inundacion'
  | 'deslizamiento'
  | 'via_bloqueada'
  | 'personas_atrapadas'
  | 'dano_vivienda'
  | 'otro';

export type Gravedad = 'baja' | 'media' | 'alta' | 'critica';

export type EstadoReporte = 'pendiente' | 'en_proceso' | 'atendido' | 'descartado';

export type TipoPuntoServicio = 'albergue' | 'centro_salud';

export type EstadoCupo = 'verde' | 'ambar' | 'rojo';

export type Necesidad = 'agua' | 'alimentos' | 'medicinas' | 'rescate';

export interface ReporteMapa {
  id: string;
  tipo: TipoIncidente;
  titulo: string;
  descripcion: string;
  gravedad: Gravedad;
  estado: EstadoReporte;
  latitud: number;
  longitud: number;
  precision_m?: number;
  ubicacion_aproximada?: boolean;
  capturado_en: string;
  recibido_en: string;
  verificado: boolean;
  personas_afectadas: number;
  ninos: number;
  adultos_mayores: number;
  necesidades: Necesidad[];
  foto_url?: string;
  sector: string;
}

export interface PuntoServicioMapa {
  id: string;
  nombre: string;
  tipo: TipoPuntoServicio;
  latitud: number;
  longitud: number;
  telefono: string;
  capacidad: number;
  ocupacion: number;
  estado_cupo: EstadoCupo;
  activo: boolean;
  direccion: string;
}

export interface FiltrosMapa {
  gravedad: Gravedad | 'todas';
  tipo: TipoIncidente | 'todos';
  estado: EstadoReporte | 'todos';
  mostrarAlbergues: boolean;
  mostrarCentrosSalud: boolean;
}
