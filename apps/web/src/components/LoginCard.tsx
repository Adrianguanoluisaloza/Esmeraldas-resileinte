import { useEffect, useState, type FormEvent } from 'react';
import { Eye, EyeOff } from 'lucide-react';
import { BASE, ErrorApi, login as loginApi, registro as registroApi } from '../lib/api';
import { inicioSegunRol } from '../config/navegacion';
import { USUARIOS_DEMO, guardarSesion, obtenerSesionActual, type RolUsuario } from '../lib/auth';
import { Aviso, Boton } from './ui/Basicos';

const DEMOS: Array<[RolUsuario, string]> = [
  ['operador_911', 'Operador'],
  ['admin', 'Admin'],
  ['ciudadano', 'Ciudadano'],
];

/** Ingreso y registro. El rol lo decide el servidor; las cuentas demo solo rellenan el formulario. */
export function LoginCard() {
  const [registro, setRegistro] = useState(false);
  const [nombre, setNombre] = useState('');
  const [correo, setCorreo] = useState('');
  const [password, setPassword] = useState('');
  const [verClave, setVerClave] = useState(false);
  const [demo, setDemo] = useState<RolUsuario | null>(null);
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const sesion = obtenerSesionActual();
    if (sesion) window.location.replace(inicioSegunRol(sesion.rol));
  }, []);

  function usarDemo(rol: RolUsuario) {
    setDemo(rol);
    setRegistro(false);
    setCorreo(USUARIOS_DEMO[rol].correo);
    setPassword(USUARIOS_DEMO[rol].pass);
    setError(null);
  }

  async function enviar(e: FormEvent) {
    e.preventDefault();
    setCargando(true);
    setError(null);
    try {
      // Siempre contra la API: sin servidor no se entra (antes se entraba "a medias" y nada funcionaba).
      const respuesta = registro ? await registroApi(nombre, correo, password) : await loginApi(correo, password);
      guardarSesion(respuesta);
      const volver = new URLSearchParams(window.location.search).get('volver');
      window.location.href = volver && volver.startsWith('/panel') ? volver : inicioSegunRol(respuesta.usuario.rol);
    } catch (err) {
      if (err instanceof ErrorApi && err.codigo === 'SIN_CONEXION') setError(`Sin conexión con el servidor (${BASE}).`);
      else setError(err instanceof ErrorApi ? (err.codigo === 'NO_AUTENTICADO' ? 'Correo o contraseña incorrectos.' : err.message) : 'No se pudo ingresar.');
    } finally {
      setCargando(false);
    }
  }

  return (
    <div className="st-acceso">
      <h1 className="st-acceso__titulo">{registro ? 'Crear cuenta' : 'Ingresar'}</h1>

      {error && <Aviso tipo="peligro">{error}</Aviso>}

      <form className="pn-form" onSubmit={enviar}>
        {registro && (
          <label className="er-campo">
            <span className="er-etiqueta">Nombre</span>
            <input className="er-entrada" required minLength={2} maxLength={120} autoComplete="name" value={nombre} onChange={(e) => setNombre(e.target.value)} />
          </label>
        )}
        <label className="er-campo">
          <span className="er-etiqueta">Correo</span>
          <input className="er-entrada" type="email" required autoComplete="email" value={correo} onChange={(e) => { setCorreo(e.target.value); setDemo(null); }} />
        </label>
        <label className="er-campo">
          <span className="er-etiqueta">Contraseña</span>
          <span className="st-clave">
            <input
              className="er-entrada"
              type={verClave ? 'text' : 'password'}
              required
              minLength={registro ? 8 : 1}
              autoComplete={registro ? 'new-password' : 'current-password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <button type="button" className="er-btn er-btn--fantasma er-btn--icono st-clave__ver" onClick={() => setVerClave((v) => !v)}>
              {verClave ? <EyeOff aria-hidden="true" /> : <Eye aria-hidden="true" />}
              <span className="er-sr">{verClave ? 'Ocultar contraseña' : 'Mostrar contraseña'}</span>
            </button>
          </span>
        </label>
        <Boton type="submit" variante="primario" tamano="lg" bloque disabled={cargando}>
          {cargando ? 'Ingresando...' : registro ? 'Crear cuenta' : 'Ingresar'}
        </Boton>
      </form>

      <button type="button" className="st-cambiar" onClick={() => { setRegistro((r) => !r); setError(null); }}>
        {registro ? 'Ya tengo cuenta' : 'Crear cuenta ciudadana'}
      </button>

      {!registro && (
        <div className="st-demo">
          <span className="er-rotulo">Demo</span>
          <div className="er-segmentos" role="group" aria-label="Cuentas de demostración">
            {DEMOS.map(([rol, texto]) => (
              <button key={rol} type="button" className="er-segmento" aria-pressed={demo === rol} onClick={() => usarDemo(rol)}>{texto}</button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
