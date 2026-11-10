export type RolUsuario = 'ciudadano' | 'operador_911' | 'bomberos' | 'policia' | 'admin';

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

// Cuentas de demostración. Deben coincidir con apps/api/src/demo.ts y con DEMO_PASSWORD del backend.
// Son públicas a propósito (demo del hackathon); en producción se crean con otra clave.
export const CLAVE_DEMO = 'demo-resiliente-2026';

// Usuarios de demostración para el escenario de emergencias
export const USUARIOS_DEMO: Record<RolUsuario, { correo: string; pass: string; usuario: UsuarioSesion }> = {
  operador_911: {
    correo: 'operador@demo.esmeraldas-resiliente.ec',
    pass: CLAVE_DEMO,
    usuario: {
      id: 'usr-911-01',
      nombre: 'Operador COE demo',
      correo: 'operador@demo.esmeraldas-resiliente.ec',
      rol: 'operador_911',
      creado_en: '2026-11-01T08:00:00Z',
    },
  },
  bomberos: {
    correo: 'bomberos@demo.esmeraldas-resiliente.ec',
    pass: CLAVE_DEMO,
    usuario: { id: 'usr-bom-01', nombre: 'Bomberos demo', correo: 'bomberos@demo.esmeraldas-resiliente.ec', rol: 'bomberos', creado_en: '2026-11-01T08:00:00Z' },
  },
  policia: {
    correo: 'policia@demo.esmeraldas-resiliente.ec',
    pass: CLAVE_DEMO,
    usuario: { id: 'usr-pol-01', nombre: 'Policía demo', correo: 'policia@demo.esmeraldas-resiliente.ec', rol: 'policia', creado_en: '2026-11-01T08:00:00Z' },
  },
  admin: {
    correo: 'admin@demo.esmeraldas-resiliente.ec',
    pass: CLAVE_DEMO,
    usuario: {
      id: 'usr-adm-01',
      nombre: 'Administrador demo',
      correo: 'admin@demo.esmeraldas-resiliente.ec',
      rol: 'admin',
      creado_en: '2026-11-01T08:00:00Z',
    },
  },
  ciudadano: {
    correo: 'ciudadano@demo.esmeraldas-resiliente.ec',
    pass: CLAVE_DEMO,
    usuario: {
      id: 'usr-ciu-01',
      nombre: 'Ciudadano demo',
      correo: 'ciudadano@demo.esmeraldas-resiliente.ec',
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

