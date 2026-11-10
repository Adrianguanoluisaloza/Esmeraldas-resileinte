import { useEffect, useState, type FormEvent } from 'react';
import { ErrorApi, restablecerClave } from '../lib/api';
import { Aviso, Boton } from './ui/Basicos';

/** Crea la contraseña nueva con el token que llega en el fragmento del enlace (#token=...). */
export function RestablecerCard() {
  const [token, setToken] = useState<string | null>(null);
  const [password, setPassword] = useState('');
  const [confirmar, setConfirmar] = useState('');
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [listo, setListo] = useState(false);

  useEffect(() => {
    setToken(new URLSearchParams(window.location.hash.slice(1)).get('token') ?? '');
    // Se quita de la barra de direcciones para que no quede a la vista ni en el historial.
    window.history.replaceState(null, '', window.location.pathname);
  }, []);

  async function enviar(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (password !== confirmar) {
      setError('Las contraseñas no coinciden.');
      return;
    }
    setCargando(true);
    try {
      await restablecerClave(token ?? '', password);
      setListo(true);
    } catch (err) {
      if (err instanceof ErrorApi && err.codigo === 'VALIDACION') setError('El enlace no es válido, ya venció o ya se usó. Pide uno nuevo.');
      else setError(err instanceof ErrorApi ? err.message : 'No se pudo completar. Intenta de nuevo.');
    } finally {
      setCargando(false);
    }
  }

  if (token === null) return <div className="er-cargando"><div className="er-giro"></div></div>;

  return (
    <div className="st-acceso">
      <h1 className="st-acceso__titulo">Nueva contraseña</h1>

      {listo ? (
        <>
          <Aviso tipo="info">Tu contraseña se actualizó. Ya puedes ingresar con ella.</Aviso>
          <a className="st-cambiar" href="/login">Ir a ingresar</a>
        </>
      ) : !token ? (
        <>
          <Aviso tipo="peligro">Este enlace no es válido. Pide uno nuevo desde la pantalla de ingreso.</Aviso>
          <a className="st-cambiar" href="/login">Volver a ingresar</a>
        </>
      ) : (
        <>
          {error && <Aviso tipo="peligro">{error}</Aviso>}
          <form className="pn-form" onSubmit={enviar}>
            <label className="er-campo">
              <span className="er-etiqueta">Contraseña nueva</span>
              <input className="er-entrada" type="password" required minLength={8} maxLength={200} autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} />
              <span className="er-ayuda">Mínimo 8 caracteres.</span>
            </label>
            <label className="er-campo">
              <span className="er-etiqueta">Confirmar contraseña</span>
              <input className="er-entrada" type="password" required minLength={8} maxLength={200} autoComplete="new-password" value={confirmar} onChange={(e) => setConfirmar(e.target.value)} />
            </label>
            <Boton type="submit" variante="primario" tamano="lg" bloque disabled={cargando}>{cargando ? 'Guardando...' : 'Guardar contraseña'}</Boton>
          </form>
          <a className="st-cambiar" href="/login">Volver a ingresar</a>
        </>
      )}
    </div>
  );
}
