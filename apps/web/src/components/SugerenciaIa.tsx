import { useState } from 'react';
import { Sparkles } from 'lucide-react';
import * as api from '../lib/api';
import { ETIQUETA_GRAVEDAD, ETIQUETA_TIPO } from '../lib/catalogos';
import { Aviso, Boton } from './ui/Basicos';

/** Sugerencia del asistente "Vigía Esmeraldas". Siempre marcada como no oficial; no cambia el reporte. */
export function SugerenciaIa({ reporteId }: { reporteId: string }) {
  const [s, setS] = useState<api.SugerenciaIA | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(false);

  async function pedir() {
    setCargando(true);
    setError(null);
    try {
      setS(await api.clasificarReporte(reporteId));
    } catch (e) {
      const codigo = e instanceof api.ErrorApi ? e.codigo : '';
      setError(
        codigo === 'NO_IMPLEMENTADO'
          ? 'La IA aún no está activada en el servidor.'
          : codigo === 'NO_DISPONIBLE'
            ? 'El asistente de IA no respondió. Intenta de nuevo en un momento.'
            : e instanceof api.ErrorApi ? e.message : 'No se pudo pedir la sugerencia.',
      );
    } finally {
      setCargando(false);
    }
  }

  return (
    <section className="op-ia" aria-live="polite">
      <div className="op-ia__cabecera">
        <Sparkles aria-hidden="true" size={16} />
        <h3 className="er-rotulo">Asistente Vigía Esmeraldas (IA)</h3>
        <Boton variante="fantasma" tamano="sm" disabled={cargando} onClick={pedir}>
          {cargando ? 'Analizando…' : s ? 'Volver a pedir' : 'Pedir sugerencia'}
        </Boton>
      </div>
      {error && <Aviso tipo="peligro">{error}</Aviso>}
      {s ? (
        <>
          <p className="op-ia__resultado">
            Sugiere: {ETIQUETA_TIPO[s.tipo_sugerido]} · gravedad {ETIQUETA_GRAVEDAD[s.gravedad_sugerida].toLowerCase()} ·
            confianza <span className="er-num">{Math.round(s.confianza * 100)}%</span>{s.analizo_foto ? ' · con foto' : ''}
          </p>
          <p>{s.explicacion}</p>
          <p className="pn-sub">{s.aviso}</p>
        </>
      ) : (
        !error && <p className="pn-sub">Sugerencia de tipo y gravedad. No es oficial: el operador decide.</p>
      )}
    </section>
  );
}
