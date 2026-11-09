export type RolUsuario = 'ciudadano' | 'operador_911' | 'admin';

export interface UsuarioSesion {
  id: string;
  nombre: string;
  correo: string;
  rol: RolUsuario;
  creado_en: string;
}

export interface RespuestaAuth {
  token: string;
  usuario: UsuarioSesion;
}

// Usuarios de demostración para el escenario de emergencias
export const USUARIOS_DEMO: Record<RolUsuario, { correo: string; pass: string; usuario: UsuarioSesion }> = {
  operador_911: {
    correo: 'operador@coe911.gob.ec',
    pass: 'operador2026',
    usuario: {
      id: 'usr-911-01',
      nombre: 'Capitán Carlos Mendoza',
      correo: 'operador@coe911.gob.ec',
      rol: 'operador_911',
      creado_en: '2026-11-01T08:00:00Z',
    },
  },
  admin: {
    correo: 'admin@resiliente.gob.ec',
    pass: 'admin2026',
    usuario: {
      id: 'usr-adm-01',
      nombre: 'Ing. Adrián Guanoluisa',
      correo: 'admin@resiliente.gob.ec',
      rol: 'admin',
      creado_en: '2026-11-01T08:00:00Z',
    },
  },
  ciudadano: {
    correo: 'ciudadano@esmeraldas.ec',
    pass: 'ciudadano2026',
    usuario: {
      id: 'usr-ciu-01',
      nombre: 'María Estupiñán',
      correo: 'ciudadano@esmeraldas.ec',
      rol: 'ciudadano',
      creado_en: '2026-11-09T05:30:00Z',
    },
  },
};

const STORAGE_KEY_TOKEN = 'esm_resiliente_token';
const STORAGE_KEY_USER = 'esm_resiliente_user';

export function obtenerSesionActual(): UsuarioSesion | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY_USER);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function obtenerTokenActual(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(STORAGE_KEY_TOKEN);
}

export function guardarSesion(respuesta: RespuestaAuth): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_KEY_TOKEN, respuesta.token);
  localStorage.setItem(STORAGE_KEY_USER, JSON.stringify(respuesta.usuario));
}

export function cerrarSesion(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(STORAGE_KEY_TOKEN);
  localStorage.removeItem(STORAGE_KEY_USER);
}

