import { useState, type FormEvent } from 'react';
import type { Gravedad, ReporteMapa, TipoIncidente } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_GRAVEDAD, ETIQUETA_TIPO } from '../lib/catalogos';
import { obtenerSesionActual } from '../lib/auth';
import { Aviso, Boton } from './ui/Basicos';

const TIPOS = Object.keys(ETIQUETA_TIPO) as TipoIncidente[];
const GRAVEDADES: Gravedad[] = ['critica', 'alta', 'media', 'baja'];

/** Corrige un reporte. Cada cambio queda en el historial; reclasificar el tipo es del ECU 911 y la administración. */
export function EditarReporte({ reporte, alGuardar, alCancelar }: { reporte: ReporteMapa; alGuardar: (r: ReporteMapa) => void; alCancelar: () => void }) {
  const rol = obtenerSesionActual()?.rol;
  const cambiaTipo = rol === 'operador_911' || rol === 'admin';
  const [tipo, setTipo] = useState(reporte.tipo);
  const [gravedad, setGravedad] = useState(reporte.gravedad);
  const [descripcion, setDescripcion] = useState(reporte.descripcion);
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function enviar(e: FormEvent) {
    e.preventDefault();
    const cambios = {
      ...(tipo !== reporte.tipo ? { tipo } : {}),
      ...(gravedad !== reporte.gravedad ? { gravedad } : {}),
      ...(descripcion.trim() !== reporte.descripcion ? { descripcion: descripcion.trim() } : {}),
    };
    if (Object.keys(cambios).length === 0) return alCancelar();
    setGuardando(true);
    setError(null);
    try {
      alGuardar(await api.editarReporte(reporte.id, cambios));
    } catch (err) {
      setError(err instanceof api.ErrorApi ? err.message : 'No se pudo guardar.');
    } finally {
      setGuardando(false);
    }
  }

  return (
    <form className="pn-form" onSubmit={enviar}>
      {error && <Aviso tipo="peligro">{error}</Aviso>}
      <label className="er-campo">
        <span className="er-etiqueta">Tipo</span>
        <select className="er-select" value={tipo} disabled={!cambiaTipo} onChange={(e) => setTipo(e.target.value as TipoIncidente)}>
          {TIPOS.map((t) => <option key={t} value={t}>{ETIQUETA_TIPO[t]}</option>)}
        </select>
      </label>
      <label className="er-campo">
        <span className="er-etiqueta">Gravedad</span>
        <select className="er-select" value={gravedad} onChange={(e) => setGravedad(e.target.value as Gravedad)}>
          {GRAVEDADES.map((g) => <option key={g} value={g}>{ETIQUETA_GRAVEDAD[g]}</option>)}
        </select>
      </label>
      <label className="er-campo">
        <span className="er-etiqueta">Descripción</span>
        <textarea className="er-area" required minLength={3} maxLength={1000} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} />
      </label>
      <div className="pn-form__fila pn-entre">
        <Boton tamano="sm" variante="fantasma" onClick={alCancelar}>Cancelar</Boton>
        <Boton tamano="sm" type="submit" variante="primario" disabled={guardando}>{guardando ? 'Guardando...' : 'Guardar'}</Boton>
      </div>
    </form>
  );
}
