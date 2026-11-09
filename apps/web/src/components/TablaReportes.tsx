import { useEffect, useState } from 'react';
import type { EstadoReporte, Gravedad, ReporteMapa } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_TIPO, fechaHoraLocal, tituloReporte } from '../lib/catalogos';
import { Aviso, AvisoRespaldo, Cargando, EstadoVacio } from './ui/Basicos';
import { InsigniaEstado, InsigniaGravedad, InsigniaOrigen } from './ui/Insignias';

/**
 * Tabla de reportes. La misma pieza sirve al COE (todos los reportes) y al ciudadano (solo los suyos):
 * el backend decide qué devuelve según el token, la web no filtra por seguridad.
 */
export function TablaReportes({ modo = 'coe' }: { modo?: 'coe' | 'ciudadano' }) {
  const [items, setItems] = useState<ReporteMapa[] | null>(null);
  const [respaldo, setRespaldo] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [gravedad, setGravedad] = useState<Gravedad | ''>('');
  const [estado, setEstado] = useState<EstadoReporte | ''>('');

  useEffect(() => {
    setItems(null);
    api
      .listarReportes({ gravedad, estado })
      .then((r) => {
        // En modo ciudadano sin servidor no mostramos la semilla del COE como si fuera suya.
        setItems(r.respaldo && modo === 'ciudadano' ? [] : r.datos.items);
        setRespaldo(r.respaldo);
      })
      .catch((e) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar los reportes.'));
  }, [gravedad, estado, modo]);

  return (
    <div className="pn-bloque">
      {respaldo && <AvisoRespaldo />}
      {error && <Aviso tipo="peligro" titulo="Algo falló">{error}</Aviso>}

      <div className="pn-barra-filtros">
        <label className="er-campo">
          <span className="er-etiqueta">Gravedad</span>
          <select className="er-select" value={gravedad} onChange={(e) => setGravedad(e.target.value as Gravedad | '')}>
            <option value="">Todas</option>
            <option value="critica">Crítica</option>
            <option value="alta">Alta</option>
            <option value="media">Media</option>
            <option value="baja">Baja</option>
          </select>
        </label>
        <label className="er-campo">
          <span className="er-etiqueta">Estado</span>
          <select className="er-select" value={estado} onChange={(e) => setEstado(e.target.value as EstadoReporte | '')}>
            <option value="">Todos</option>
            <option value="pendiente">Pendiente</option>
            <option value="en_proceso">En proceso</option>
            <option value="atendido">Atendido</option>
            <option value="descartado">Descartado</option>
          </select>
        </label>
      </div>

      {items === null && !error && <Cargando texto="Cargando reportes..." />}

      {items?.length === 0 && (
        <EstadoVacio
          titulo={modo === 'ciudadano' ? 'Aún no tienes reportes' : 'Sin reportes con esos filtros'}
          texto={modo === 'ciudadano' ? 'Los reportes que envíes desde la app aparecerán aquí con su estado de atención.' : undefined}
        />
      )}

      {items && items.length > 0 && (
        <div className="er-tabla-contenedor">
          <table className="er-tabla">
            <thead>
              <tr>
                <th scope="col">Incidente</th>
                <th scope="col">Gravedad</th>
                <th scope="col">Estado</th>
                {modo === 'coe' && <th scope="col">Origen</th>}
                <th scope="col">Personas</th>
                <th scope="col">Recibido</th>
              </tr>
            </thead>
            <tbody>
              {items.map((r) => (
                <tr key={r.id}>
                  <td>
                    <strong>{tituloReporte(r)}</strong>
                    <div className="pn-sub">{ETIQUETA_TIPO[r.tipo]}{r.sector ? ` · ${r.sector}` : ''}</div>
                  </td>
                  <td><InsigniaGravedad valor={r.gravedad} /></td>
                  <td><InsigniaEstado valor={r.estado} /></td>
                  {modo === 'coe' && <td>{r.origen && <InsigniaOrigen valor={r.origen} />}</td>}
                  <td className="er-num">{r.personas_afectadas}</td>
                  <td className="er-num">{fechaHoraLocal(r.recibido_en)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
