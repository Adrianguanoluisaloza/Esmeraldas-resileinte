import { useEffect, useState } from 'react';
import * as api from '../lib/api';
import { fechaHoraLocal } from '../lib/catalogos';
import { obtenerSesionActual, type RolUsuario, type UsuarioSesion } from '../lib/auth';
import { Aviso, Cargando, EstadoVacio } from './ui/Basicos';

const ROLES: Array<[RolUsuario, string]> = [['ciudadano', 'Ciudadano'], ['operador_911', 'Operador 911'], ['admin', 'Administrador']];

/** El administrador decide quién opera el COE. El servidor vuelve a exigir el rol en cada petición. */
export function GestionUsuarios() {
  const [usuarios, setUsuarios] = useState<UsuarioSesion[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);
  const [guardando, setGuardando] = useState<string | null>(null);
  const propio = obtenerSesionActual()?.id;

  useEffect(() => {
    api.listarUsuarios().then(setUsuarios).catch((e) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar las cuentas.'));
  }, []);

  async function cambiar(u: UsuarioSesion, rol: RolUsuario) {
    setGuardando(u.id);
    setError(null);
    setAviso(null);
    try {
      const actualizado = await api.cambiarRol(u.id, rol);
      setUsuarios((l) => l?.map((x) => (x.id === u.id ? actualizado : x)) ?? null);
      setAviso(`${u.nombre} ahora es ${ROLES.find(([r]) => r === rol)?.[1]}. El cambio se aplica cuando vuelva a ingresar.`);
    } catch (e) {
      setError(e instanceof api.ErrorApi ? e.message : 'No se pudo cambiar el rol.');
    } finally {
      setGuardando(null);
    }
  }

  return (
    <div className="pn-bloque">
      {error && <Aviso tipo="peligro">{error}</Aviso>}
      {aviso && <Aviso tipo="ok">{aviso}</Aviso>}
      {usuarios === null && !error && <Cargando texto="Cargando cuentas..." />}
      {usuarios?.length === 0 && <EstadoVacio titulo="Sin cuentas" />}
      {usuarios && usuarios.length > 0 && (
        <div className="er-tabla-contenedor">
          <table className="er-tabla">
            <thead>
              <tr><th scope="col">Nombre</th><th scope="col">Correo</th><th scope="col">Rol</th><th scope="col">Registro</th></tr>
            </thead>
            <tbody>
              {usuarios.map((u) => (
                <tr key={u.id}>
                  <td><strong>{u.nombre}</strong></td>
                  <td>{u.correo}</td>
                  <td>
                    <select
                      className="er-select pn-rol"
                      value={u.rol}
                      disabled={u.id === propio || guardando === u.id}
                      aria-label={`Rol de ${u.nombre}`}
                      onChange={(e) => cambiar(u, e.target.value as RolUsuario)}
                    >
                      {ROLES.map(([r, t]) => <option key={r} value={r}>{t}</option>)}
                    </select>
                  </td>
                  <td className="er-num">{fechaHoraLocal(u.creado_en)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
