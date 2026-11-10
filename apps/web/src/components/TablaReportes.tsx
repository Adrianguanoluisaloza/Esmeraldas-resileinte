import { useCallback, useEffect, useMemo, useState } from 'react';
import { Camera } from 'lucide-react';
import type { EstadoReporte, Gravedad, ReporteMapa } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_TIPO, compararPorFeed, fechaHoraLocal, haceTiempo, tituloReporte } from '../lib/catalogos';
import { Aviso, AvisoRespaldo, Cargando, EstadoVacio } from './ui/Basicos';
import { DetalleReporte } from './DetalleReporte';
import { InsigniaEstado, InsigniaGravedad, InsigniaOrigen } from './ui/Insignias';

type FiltroOrigen = 'todos' | 'ciudadano' | 'simulado';

/**
 * Tabla de reportes. La misma pieza sirve al COE (todos los reportes) y al ciudadano (solo los suyos):
 * el backend decide qué devuelve según el token, la web no filtra por seguridad.
 * Los reportes reales, que llegan desde el celular, van primero: las fechas del escenario son futuras.
 */
export function TablaReportes({ modo = 'coe' }: { modo?: 'coe' | 'ciudadano' }) {
  const [items, setItems] = useState<ReporteMapa[] | null>(null);
  const [respaldo, setRespaldo] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [gravedad, setGravedad] = useState<Gravedad | ''>('');
  const [estado, setEstado] = useState<EstadoReporte | ''>('');
  const [origen, setOrigen] = useState<FiltroOrigen>('todos');
  const [abierto, setAbierto] = useState<string | null>(null);

  const cargar = useCallback(() => {
    return api
      .listarReportes({ gravedad, estado })
      .then((r) => {
        // En modo ciudadano sin servidor no mostramos la semilla del COE como si fuera suya.
        setItems(r.respaldo && modo === 'ciudadano' ? [] : r.datos.items);
        setRespaldo(r.respaldo);
      })
      .catch((e) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar los reportes.'));
  }, [gravedad, estado, modo]);

  useEffect(() => {
    setItems(null);
    void cargar();
  }, [cargar]);

  // Un reporte del celular llega en dos pasos: datos y, segundos después, la foto.
  useEffect(() => {
    const url = api.urlTiempoReal();
    if (!url || respaldo || modo !== 'coe') return;
    const ws = new WebSocket(url);
    let espera: ReturnType<typeof setTimeout>;
    ws.onmessage = (m) => {
      if (!String(m.data).includes('"reporte.')) return;
      void cargar();
      clearTimeout(espera);
      espera = setTimeout(() => void cargar(), 6000);
    };
    return () => {
      clearTimeout(espera);
      ws.close();
    };
  }, [cargar, respaldo, modo]);

  const visibles = useMemo(
    () => items?.filter((r) => origen === 'todos' || r.origen === origen).sort(compararPorFeed) ?? null,
    [items, origen],
  );

  return (
    <div className="pn-bloque">
      {respaldo && <AvisoRespaldo />}
      {error && <Aviso tipo="peligro" titulo="Algo falló">{error}</Aviso>}

      <div className="pn-barra-filtros pn-barra-filtros--base">
        {modo === 'coe' && (
          <div className="er-campo">
            <span className="er-etiqueta">Origen</span>
            <div className="er-segmentos" role="group" aria-label="Origen del reporte">
              {([['todos', 'Todos'], ['ciudadano', 'Ciudadanos'], ['simulado', 'Simulados']] as const).map(([v, t]) => (
                <button key={v} type="button" className="er-segmento" aria-pressed={origen === v} onClick={() => setOrigen(v)}>{t}</button>
              ))}
            </div>
          </div>
        )}
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

      {visibles?.length === 0 && (
        <EstadoVacio titulo={modo === 'ciudadano' ? 'Aún no tienes reportes' : 'Sin resultados'}>
          {modo === 'ciudadano' && <a className="er-btn er-btn--emergencia" href="/panel/reportar">Nuevo reporte</a>}
        </EstadoVacio>
      )}

      {visibles && visibles.length > 0 && (
        <div className="er-tabla-contenedor">
          <table className="er-tabla">
            <thead>
              <tr>
                <th scope="col">Incidente</th>
                <th scope="col">Gravedad</th>
                <th scope="col">Estado</th>
                {modo === 'coe' && <th scope="col">Origen</th>}
                <th scope="col" className="er-derecha">Personas</th>
                <th scope="col">Recibido</th>
              </tr>
            </thead>
            <tbody>
              {visibles.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div className="pn-reporte">
                      {r.foto_miniatura_url || r.foto_url ? (
                        <img className="pn-miniatura" src={`${api.BASE}${r.foto_miniatura_url ?? r.foto_url}`} alt="" loading="lazy" />
                      ) : (
                        <span className="pn-miniatura pn-miniatura--vacia" title="Sin foto"><Camera aria-hidden="true" /></span>
                      )}
                      <div>
                        <button className="pn-enlace-fila" onClick={() => !respaldo && setAbierto(r.id)}>{tituloReporte(r)}</button>
                        <div className="pn-sub">
                          {ETIQUETA_TIPO[r.tipo]} · {r.sector ?? `${r.latitud.toFixed(4)}, ${r.longitud.toFixed(4)}`}
                          {r.ubicacion_aproximada ? ' · ubicación aproximada' : ''}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td><InsigniaGravedad valor={r.gravedad} /></td>
                  <td><InsigniaEstado valor={r.estado} /></td>
                  {modo === 'coe' && <td>{r.origen && <InsigniaOrigen valor={r.origen} />}</td>}
                  <td className="er-num er-derecha">{r.personas_afectadas}</td>
                  <td className="er-num pn-tiempo" title={fechaHoraLocal(r.recibido_en)}>{haceTiempo(r.recibido_en)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {abierto && (
        <DetalleReporte
          id={abierto}
          puedeGestionar={modo === 'coe'}
          alCerrar={() => setAbierto(null)}
          alCambiar={(r) => setItems((l) => l?.map((x) => (x.id === r.id ? { ...x, ...r } : x)) ?? null)}
        />
      )}
    </div>
  );
}
