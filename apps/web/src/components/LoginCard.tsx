import { useEffect, useState, type FormEvent } from 'react';
import { Eye, EyeOff } from 'lucide-react';
import { signInWithPopup } from 'firebase/auth';
import { auth, proveedorGoogle } from '../lib/firebase';
import { BASE, ErrorApi, login as loginApi, registro as registroApi, loginFirebase } from '../lib/api';
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

  async function enviarGoogle() {
    setCargando(true);
    setError(null);
    try {
      const resultado = await signInWithPopup(auth, proveedorGoogle);
      const idToken = await resultado.user.getIdToken();
      const respuesta = await loginFirebase(idToken);
      guardarSesion(respuesta);
      const volver = new URLSearchParams(window.location.search).get('volver');
      window.location.href = volver && volver.startsWith('/panel') ? volver : inicioSegunRol(respuesta.usuario.rol);
    } catch (err) {
      setError(err instanceof ErrorApi ? err.message : 'No se pudo ingresar con Google.');
    } finally {
      setCargando(false);
    }
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

      <div className="st-separador"><span>o</span></div>

      <Boton type="button" variante="secundario" tamano="lg" bloque disabled={cargando} onClick={enviarGoogle}>
        <svg aria-hidden="true" width="18" height="18" viewBox="0 0 48 48" style={{marginRight: '8px', verticalAlign: 'middle'}}>
          <path fill="#4285F4" d="M44.5 20H24v8.5h11.8C34.7 33.9 29.8 37 24 37c-7.2 0-13-5.8-13-13s5.8-13 13-13c3.1 0 5.9 1.1 8.1 2.9l6.4-6.4C34.6 4.1 29.6 2 24 2 11.8 2 2 11.8 2 24s9.8 22 22 22c11 0 21-8 21-22 0-1.3-.2-2.7-.5-4z"/>
          <path fill="#34A853" d="M6.3 14.7l7 5.1C15.1 16 19.2 13 24 13c3.1 0 5.9 1.1 8.1 2.9l6.4-6.4C34.6 4.1 29.6 2 24 2 16.1 2 9.3 7.4 6.3 14.7z"/>
          <path fill="#FBBC05" d="M24 46c5.5 0 10.5-1.8 14.4-4.9l-6.7-5.5C29.6 37.6 26.9 38.5 24 38.5c-5.7 0-10.6-3.8-12.4-9l-7 5.4C8.1 41.7 15.4 46 24 46z"/>
          <path fill="#EA4335" d="M44.5 20H24v8.5h11.8c-1 2.8-2.9 5.1-5.3 6.6l6.7 5.5C41.4 37.3 44.5 31.1 44.5 24c0-1.3-.2-2.7-.5-4z"/>
        </svg>
        Ingresar con Google
      </Boton>

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
