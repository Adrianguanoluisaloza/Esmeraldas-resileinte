import type { RolUsuario } from '../lib/auth';

/**
 * Menú lateral del panel. Única fuente: para agregar una pantalla se agrega aquí y se crea la página.
 * `roles` define quién la ve. Las opciones del ciudadano son las mismas de la app de Franco
 * (reportar, mis reportes, albergues) para que web y móvil se sientan como un solo producto.
 * Ojo: ocultar un enlace NO es seguridad. El backend vuelve a comprobar el rol en cada petición.
 */

export type IconoNav =
  | 'resumen'
  | 'mapa'
  | 'reportes'
  | 'albergues'
  | 'alertas'
  | 'estadisticas'
  | 'reportar'
  | 'mis-reportes'
  | 'zonas'
  | 'asistencia'
  | 'usuarios';

export interface ItemNav {
  ruta: string;
  etiqueta: string;
  icono: IconoNav;
  roles: RolUsuario[];
}

export interface GrupoNav {
  titulo: string;
  items: ItemNav[];
}

const COE: RolUsuario[] = ['operador_911', 'admin'];
const TODOS: RolUsuario[] = ['ciudadano', 'operador_911', 'admin'];

export const NAVEGACION: GrupoNav[] = [
  {
    titulo: 'Operaciones',
    items: [
      { ruta: '/panel', etiqueta: 'Mapa operativo', icono: 'mapa', roles: COE },
      { ruta: '/panel/reportes', etiqueta: 'Reportes', icono: 'reportes', roles: COE },
      { ruta: '/panel/alertas', etiqueta: 'Alertas y vías', icono: 'alertas', roles: COE },
      { ruta: '/panel/asistencia', etiqueta: 'Asistencia', icono: 'asistencia', roles: COE },
      { ruta: '/panel/estadisticas', etiqueta: 'Estadísticas', icono: 'estadisticas', roles: COE },
    ],
  },
  {
    titulo: 'Ciudadanía',
    items: [
      { ruta: '/panel/inicio', etiqueta: 'Inicio', icono: 'zonas', roles: ['ciudadano'] },
      { ruta: '/panel/reportar', etiqueta: 'Nuevo reporte', icono: 'reportar', roles: ['ciudadano'] },
      { ruta: '/panel/mis-reportes', etiqueta: 'Mis reportes', icono: 'mis-reportes', roles: ['ciudadano'] },
    ],
  },
  {
    titulo: 'Territorio',
    items: [{ ruta: '/panel/albergues', etiqueta: 'Albergues', icono: 'albergues', roles: TODOS }],
  },
  {
    titulo: 'Administración',
    items: [{ ruta: '/panel/usuarios', etiqueta: 'Usuarios y roles', icono: 'usuarios', roles: ['admin'] }],
  },
];

/** Página de inicio según el rol, para redirigir después del login. */
export function inicioSegunRol(rol: RolUsuario): string {
  return rol === 'ciudadano' ? '/panel/inicio' : '/panel';
}
