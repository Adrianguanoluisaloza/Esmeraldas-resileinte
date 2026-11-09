import { useEffect, useState } from 'react';
import * as api from '../lib/api';
import { ETIQUETA_NECESIDAD, fechaHoraLocal } from '../lib/catalogos';
import { Aviso, Boton, Cargando, EstadoVacio } from './ui/Basicos';
import { InsigniaGravedad } from './ui/Insignias';

const clave = (p: Pick<api.NecesidadPendiente, 'reporte_id' | 'necesidad'>) => `${p.reporte_id}:${p.necesidad}`;

export function Asistencia() {
  const [pendientes, setPendientes] = useState<api.NecesidadPendiente[] | null>(null);
  const [entregas, setEntregas] = useState<api.Entrega[]>([]);
  const [cantidades, setCantidades] = useState<Record<string, number>>({});
  const [ocupado, setOcupado] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fallo = (e: unknown) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudo completar la acción.');

  useEffect(() => {
    api.necesidadesPendientes().then(setPendientes).catch(fallo);
    api.listarEntregas().then(setEntregas).catch(() => {});
  }, []);

  async function entregar(p: api.NecesidadPendiente) {
    const k = clave(p);
    setOcupado(k);
    setError(null);
    try {
      const e = await api.registrarEntrega({ reporte_id: p.reporte_id, necesidad: p.necesidad, cantidad: cantidades[k] ?? Math.max(1, p.personas) });
      setEntregas((l) => [e, ...l]);
      setPendientes((l) => l?.filter((x) => clave(x) !== k) ?? null);
    } catch (err) {
      fallo(err);
    } finally {
      setOcupado(null);
    }
  }

  if (!pendientes && !error) return <Cargando />;

  return (
    <div className="pn-bloque">
      {error && <Aviso tipo="peligro">{error}</Aviso>}

      {pendientes && pendientes.length === 0 ? (
        <EstadoVacio titulo="Sin necesidades pendientes" />
      ) : pendientes && (
        <div className="er-tabla-contenedor">
          <table className="er-tabla">
            <thead>
              <tr>
                <th scope="col">Necesidad</th>
                <th scope="col">Sector</th>
                <th scope="col">Personas</th>
                <th scope="col">Gravedad</th>
                <th scope="col">Cantidad</th>
                <th scope="col"><span className="er-sr">Acción</span></th>
              </tr>
            </thead>
            <tbody>
              {pendientes.map((p) => {
                const k = clave(p);
                return (
                  <tr key={k}>
                    <td><strong>{ETIQUETA_NECESIDAD[p.necesidad]}</strong></td>
                    <td>{p.sector ?? '—'}</td>
                    <td className="er-num">{p.personas}</td>
                    <td><InsigniaGravedad valor={p.gravedad} /></td>
                    <td>
                      <input
                        className="er-entrada pn-entrada-corta"
                        type="number"
                        min={1}
                        aria-label="Cantidad entregada"
                        value={cantidades[k] ?? Math.max(1, p.personas)}
                        onChange={(e) => setCantidades((c) => ({ ...c, [k]: Math.max(1, Number(e.target.value) || 1) }))}
                      />
                    </td>
                    <td><Boton tamano="sm" variante="primario" disabled={ocupado === k} onClick={() => entregar(p)}>Registrar entrega</Boton></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {entregas.length > 0 && (
        <section className="er-tarjeta">
          <div className="er-tarjeta__cabecera"><h2 className="er-tarjeta__titulo">Entregas registradas</h2></div>
          <ul className="pn-lista">
            {entregas.slice(0, 20).map((e) => (
              <li key={e.id} className="pn-lista__fila">
                <span><strong>{ETIQUETA_NECESIDAD[e.necesidad]}</strong> · {e.cantidad}{e.nota ? ` · ${e.nota}` : ''}</span>
                <span className="pn-sub er-num">{fechaHoraLocal(e.entregado_en)}</span>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
