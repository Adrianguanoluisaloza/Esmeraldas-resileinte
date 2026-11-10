import { useEffect, useState, type FormEvent } from 'react';
import { Megaphone } from 'lucide-react';
import type { Gravedad } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_GRAVEDAD, fechaHoraLocal } from '../lib/catalogos';
import { Aviso, Boton, Cargando, EstadoVacio } from './ui/Basicos';
import { InsigniaGravedad } from './ui/Insignias';

interface Via {
  id: string;
  nombre: string;
  estado: api.EstadoVia;
}

const ESTADOS_VIA: api.EstadoVia[] = ['habilitada', 'parcial', 'bloqueada'];
const ETIQUETA_VIA: Record<api.EstadoVia, string> = { habilitada: 'Habilitada', parcial: 'Parcial', bloqueada: 'Bloqueada' };

export function AlertasVias() {
  const [alertas, setAlertas] = useState<api.Alerta[] | null>(null);
  const [vias, setVias] = useState<Via[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);
  const [form, setForm] = useState({ sector: '', mensaje: '', nivel: 'alta' as Gravedad, origen: 'oficial' as 'oficial' | 'simulada' });

  const fallo = (e: unknown) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudo completar la acción.');

  useEffect(() => {
    api.listarAlertas(true).then(setAlertas).catch(fallo);
    api
      .viasGeoJson()
      .then((c) => setVias(c.features.map((f) => ({ id: String(f.properties?.id), nombre: String(f.properties?.nombre), estado: f.properties?.estado as api.EstadoVia }))))
      .catch(fallo);
  }, []);

  async function emitir(e: FormEvent) {
    e.preventDefault();
    setEnviando(true);
    setError(null);
    try {
      const nueva = await api.emitirAlerta(form);
      setAlertas((a) => [nueva, ...(a ?? [])]);
      setForm((f) => ({ ...f, sector: '', mensaje: '' }));
    } catch (err) {
      fallo(err);
    } finally {
      setEnviando(false);
    }
  }

  async function cerrar(id: string) {
    try {
      const a = await api.cerrarAlerta(id);
      setAlertas((lista) => lista?.map((x) => (x.id === id ? a : x)) ?? null);
    } catch (err) {
      fallo(err);
    }
  }

  async function cambiarVia(id: string, estado: api.EstadoVia) {
    try {
      await api.cambiarVia(id, estado);
      setVias((lista) => lista?.map((v) => (v.id === id ? { ...v, estado } : v)) ?? null);
    } catch (err) {
      fallo(err);
    }
  }

  return (
    <div className="pn-dos-columnas">
      <div className="pn-bloque">
        {error && <Aviso tipo="peligro">{error}</Aviso>}

        <form className="er-tarjeta er-tarjeta__cuerpo pn-form" onSubmit={emitir}>
          <h2 className="er-tarjeta__titulo">Emitir alerta</h2>
          <label className="er-campo">
            <span className="er-etiqueta">Sector</span>
            <input className="er-entrada" required minLength={2} maxLength={120} value={form.sector} onChange={(e) => setForm({ ...form, sector: e.target.value })} />
          </label>
          <label className="er-campo">
            <span className="er-etiqueta">Mensaje</span>
            <textarea className="er-area" required minLength={5} maxLength={500} value={form.mensaje} onChange={(e) => setForm({ ...form, mensaje: e.target.value })} />
          </label>
          <div className="pn-form__fila">
            <label className="er-campo">
              <span className="er-etiqueta">Nivel</span>
              <select className="er-select" value={form.nivel} onChange={(e) => setForm({ ...form, nivel: e.target.value as Gravedad })}>
                {(['critica', 'alta', 'media', 'baja'] as const).map((g) => <option key={g} value={g}>{ETIQUETA_GRAVEDAD[g]}</option>)}
              </select>
            </label>
            <label className="er-campo">
              <span className="er-etiqueta">Origen</span>
              <select className="er-select" value={form.origen} onChange={(e) => setForm({ ...form, origen: e.target.value as 'oficial' | 'simulada' })}>
                <option value="oficial">Oficial</option>
                <option value="simulada">Simulacro</option>
              </select>
            </label>
          </div>
          <Boton type="submit" variante="primario" disabled={enviando}>
            <Megaphone aria-hidden="true" /> {enviando ? 'Emitiendo...' : 'Emitir'}
          </Boton>
        </form>

        <section className="er-tarjeta">
          <div className="er-tarjeta__cabecera"><h2 className="er-tarjeta__titulo">Vías</h2></div>
          {!vias ? <Cargando /> : (
            <ul className="pn-lista">
              {vias.map((v) => (
                <li key={v.id} className="pn-lista__fila">
                  <span>{v.nombre}</span>
                  <div className="er-segmentos" role="group" aria-label={`Estado de ${v.nombre}`}>
                    {ESTADOS_VIA.map((e) => (
                      <button key={e} className="er-segmento" aria-pressed={v.estado === e} onClick={() => cambiarVia(v.id, e)}>{ETIQUETA_VIA[e]}</button>
                    ))}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      <section className="er-tarjeta">
        <div className="er-tarjeta__cabecera"><h2 className="er-tarjeta__titulo">Alertas</h2></div>
        {!alertas ? <Cargando /> : alertas.length === 0 ? <div className="er-tarjeta__cuerpo"><EstadoVacio titulo="Sin alertas" /></div> : (
          <ul className="pn-lista">
            {alertas.map((a) => (
              <li key={a.id} className="pn-lista__fila pn-alerta" data-cerrada={!a.vigente}>
                <div className="pn-alerta__cuerpo">
                  <div className="op-item__fila">
                    <InsigniaGravedad valor={a.nivel} />
                    <span className={`er-insignia er-insignia--origen-${a.origen === 'oficial' ? 'oficial' : 'simulado'}`}>{a.origen === 'oficial' ? 'Oficial' : 'Simulacro'}</span>
                    {!a.vigente && <span className="er-insignia">Cerrada</span>}
                  </div>
                  <strong>{a.sector}</strong>
                  <span>{a.mensaje}</span>
                  <span className="pn-sub er-num">{fechaHoraLocal(a.creado_en)}</span>
                </div>
                {a.vigente && <Boton tamano="sm" onClick={() => cerrar(a.id)}>Cerrar</Boton>}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

/** Alertas vigentes en modo lectura (ciudadanía y pantallas públicas). */
export function AlertasVigentes() {
  const [alertas, setAlertas] = useState<api.Alerta[] | null>(null);
  useEffect(() => {
    api.listarAlertas().then(setAlertas).catch(() => setAlertas([]));
  }, []);
  if (!alertas?.length) return null;
  return (
    <section className="er-tarjeta pn-alertas" aria-label="Alertas vigentes">
      <ul>
        {alertas.map((a) => (
          <li key={a.id} className="pn-alerta">
            <InsigniaGravedad valor={a.nivel} />
            <div className="pn-alerta__texto">
              <strong>{a.sector}</strong>
              <span>{a.mensaje.replace(/^Simulacro:\s*(.)/i, (_, letra: string) => letra.toUpperCase())}</span>
            </div>
            <span className="pn-alerta__origen">{a.origen === 'oficial' ? 'Alerta oficial' : 'Simulacro'}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
