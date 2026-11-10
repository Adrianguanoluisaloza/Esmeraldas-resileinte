import { useEffect, useRef, useState } from 'react';
import { X } from 'lucide-react';
import type { EstadoReporte, ReporteMapa } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_ESTADO, ETIQUETA_NECESIDAD, ETIQUETA_TIPO, fechaHoraLocal, tituloReporte } from '../lib/catalogos';
import { Aviso, Boton, Cargando } from './ui/Basicos';
import { EditarReporte } from './EditarReporte';
import { SugerenciaIa } from './SugerenciaIa';
import { InsigniaEstado, InsigniaGravedad, InsigniaOrigen } from './ui/Insignias';

const BASE_API = (import.meta.env.PUBLIC_API_URL as string | undefined)?.replace(/\/+$/, '') ?? 'http://localhost:3000';

/** Cajón lateral con el detalle, la foto, el historial y (para el COE) las acciones de estado. */
export function DetalleReporte({ id, puedeGestionar, alCerrar, alCambiar }: {
  id: string;
  puedeGestionar: boolean;
  alCerrar: () => void;
  alCambiar: (r: ReporteMapa) => void;
}) {
  const [r, setR] = useState<Awaited<ReturnType<typeof api.obtenerReporte>> | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [nota, setNota] = useState('');
  const [guardando, setGuardando] = useState(false);
  const [editando, setEditando] = useState(false);
  const cerrarRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    setR(null);
    api.obtenerReporte(id).then(setR).catch((e) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudo cargar.'));
  }, [id]);

  useEffect(() => {
    cerrarRef.current?.focus();
    const tecla = (e: KeyboardEvent) => e.key === 'Escape' && alCerrar();
    document.addEventListener('keydown', tecla);
    return () => document.removeEventListener('keydown', tecla);
  }, [alCerrar]);

  async function cambiar(estado: EstadoReporte) {
    if (!r) return;
    setGuardando(true);
    setError(null);
    try {
      const actualizado = await api.cambiarEstadoReporte(r.id, estado, nota.trim() || undefined);
      setNota('');
      alCambiar(actualizado);
      setR(await api.obtenerReporte(r.id));
    } catch (e) {
      setError(e instanceof api.ErrorApi ? e.message : 'No se pudo cambiar el estado.');
    } finally {
      setGuardando(false);
    }
  }

  return (
    <>
      <div className="pn-velo" onClick={alCerrar} />
      <aside className="pn-cajon" role="dialog" aria-modal="true" aria-label="Detalle del reporte">
        <div className="pn-cajon__cabecera">
          <h2 className="er-tarjeta__titulo">{r ? tituloReporte(r) : 'Reporte'}</h2>
          <button ref={cerrarRef} className="er-btn er-btn--fantasma er-btn--icono" onClick={alCerrar}>
            <X aria-hidden="true" />
            <span className="er-sr">Cerrar</span>
          </button>
        </div>
        <div className="pn-cajon__cuerpo">
          {error && <Aviso tipo="peligro">{error}</Aviso>}
          {!r && !error && <Cargando />}
          {r && (
            <>
              <div className="op-item__fila pn-izquierda">
                <InsigniaGravedad valor={r.gravedad} />
                <InsigniaEstado valor={r.estado} />
                {r.origen && <InsigniaOrigen valor={r.origen} />}
              </div>
              <p className="pn-sub">{ETIQUETA_TIPO[r.tipo]}{r.sector ? ` · ${r.sector}` : ''} · {fechaHoraLocal(r.capturado_en)}</p>
              {editando ? (
                <EditarReporte
                  reporte={r}
                  alCancelar={() => setEditando(false)}
                  alGuardar={async (nuevo) => {
                    alCambiar(nuevo);
                    setEditando(false);
                    setR(await api.obtenerReporte(r.id));
                  }}
                />
              ) : (
                <p>{r.descripcion}</p>
              )}
              {r.foto_url && <img className="pn-foto" src={`${BASE_API}${r.foto_url}`} alt={`Foto del reporte: ${tituloReporte(r)}`} loading="lazy" />}

              <dl className="op-datos">
                <div><dt>Personas</dt><dd className="er-num">{r.personas_afectadas}</dd></div>
                <div><dt>Niños</dt><dd className="er-num">{r.ninos}</dd></div>
                <div><dt>Adultos mayores</dt><dd className="er-num">{r.adultos_mayores}</dd></div>
                <div><dt>GPS</dt><dd className="er-num">{r.latitud.toFixed(4)}, {r.longitud.toFixed(4)}</dd></div>
              </dl>

              {r.necesidades.length > 0 && (
                <div className="op-necesidades">
                  {r.necesidades.map((n) => <span key={n} className="er-insignia">{ETIQUETA_NECESIDAD[n]}</span>)}
                </div>
              )}

              {puedeGestionar && <SugerenciaIa key={r.id} reporteId={r.id} />}

              {puedeGestionar && (
                <div className="op-acciones">
                  {!editando && <Boton variante="fantasma" tamano="sm" bloque onClick={() => setEditando(true)}>Editar reporte</Boton>}
                  <label className="er-campo">
                    <span className="er-etiqueta">Nota</span>
                    <input className="er-entrada" maxLength={500} value={nota} onChange={(e) => setNota(e.target.value)} />
                  </label>
                  <div className="pn-form__fila">
                    <Boton variante="primario" disabled={guardando || r.estado === 'en_proceso'} onClick={() => cambiar('en_proceso')}>Despachar</Boton>
                    <Boton disabled={guardando || r.estado === 'atendido'} onClick={() => cambiar('atendido')}>Atendido</Boton>
                    <Boton variante="fantasma" disabled={guardando || r.estado === 'descartado' || r.estado === 'atendido'} onClick={() => cambiar('descartado')}>Descartar</Boton>
                  </div>
                </div>
              )}

              {r.historial.length > 0 && (
                <section>
                  <h3 className="er-rotulo">Historial</h3>
                  <ol className="pn-historial">
                    {r.historial.map((h) => (
                      <li key={h.id}>
                        <strong>{ETIQUETA_ESTADO[h.estado_nuevo]}</strong>
                        <span className="pn-sub er-num">{fechaHoraLocal(h.fecha)}{h.operador_nombre ? ` · ${h.operador_nombre}` : ''}</span>
                        {h.nota && <span>{h.nota}</span>}
                      </li>
                    ))}
                  </ol>
                </section>
              )}
            </>
          )}
        </div>
      </aside>
    </>
  );
}
