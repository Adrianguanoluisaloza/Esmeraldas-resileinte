import { useState, type FormEvent } from 'react';
import { Camera, CarFront, Home, LocateFixed, Mountain, Siren, Users, Waves, CircleHelp } from 'lucide-react';
import type { Gravedad, Necesidad, TipoIncidente } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_GRAVEDAD, ETIQUETA_NECESIDAD, ETIQUETA_TIPO } from '../lib/catalogos';
import { Aviso, Boton } from './ui/Basicos';
import { MapaEsmeraldas } from './MapaEsmeraldas';
import { marcadorUbicacion, obtenerUbicacion } from '../lib/ubicacion';

const TIPOS: Array<[TipoIncidente, typeof Waves]> = [
  ['inundacion', Waves],
  ['deslizamiento', Mountain],
  ['via_bloqueada', CarFront],
  ['personas_atrapadas', Users],
  ['dano_vivienda', Home],
  ['otro', CircleHelp],
];

/** Centros aproximados de sectores, para reportar sin GPS ni mapa (simulados, no son límites oficiales). */
const SECTORES_ESMERALDAS: Record<string, { latitud: number; longitud: number }> = {
  'Las Palmas (Norte)': { latitud: 0.985, longitud: -79.654 },
  'Centro de Esmeraldas': { latitud: 0.965, longitud: -79.654 },
  'Barrio 50 Casas': { latitud: 0.945, longitud: -79.668 },
  'Isla Piedad': { latitud: 0.9765, longitud: -79.6582 },
  'El Arenal': { latitud: 0.970, longitud: -79.649 },
  'Barrio 20 de Noviembre': { latitud: 0.9548, longitud: -79.6695 },
  'Tachina / Aeropuerto': { latitud: 0.9824, longitud: -79.6385 },
  'San Rafael': { latitud: 0.9428, longitud: -79.6812 },
  'Ribera Río Teaone (Tabiazo)': { latitud: 0.912, longitud: -79.632 },
};

interface Ubicacion {
  latitud: number;
  longitud: number;
  precision: number;
  esAproximada?: boolean;
  nombreSector?: string;
}

/** Nuevo reporte desde el navegador. Mismos pasos que la app móvil: tipo, foto, ubicación y familia. */
export function FormularioReporte() {
  const [tipo, setTipo] = useState<TipoIncidente | null>(null);
  const [gravedad, setGravedad] = useState<Gravedad>('alta');
  const [descripcion, setDescripcion] = useState('');
  const [foto, setFoto] = useState<File | null>(null);
  const [ubicacion, setUbicacion] = useState<Ubicacion | null>(null);
  const [buscandoGps, setBuscandoGps] = useState(false);
  const [familia, setFamilia] = useState({ personas: 0, ninos: 0, adultos_mayores: 0 });
  const [necesidades, setNecesidades] = useState<Necesidad[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);
  const [listo, setListo] = useState(false);

  function seleccionarSector(nombre: string) {
    if (!nombre || !SECTORES_ESMERALDAS[nombre]) return;
    const s = SECTORES_ESMERALDAS[nombre];
    setUbicacion({
      latitud: s.latitud,
      longitud: s.longitud,
      precision: 100,
      esAproximada: true,
      nombreSector: nombre,
    });
    setError(null);
  }

  async function usarGps() {
    setBuscandoGps(true);
    setError(null);
    try {
      const c = await obtenerUbicacion();
      setUbicacion({ latitud: c.latitude, longitud: c.longitude, precision: c.accuracy, esAproximada: false });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBuscandoGps(false);
    }
  }

  async function enviar(e: FormEvent) {
    e.preventDefault();
    if (!tipo || !ubicacion) return;
    setEnviando(true);
    setError(null);
    const id = crypto.randomUUID();
    try {
      await api.crearReporte({
        id,
        tipo,
        gravedad,
        descripcion: descripcion.trim() || ETIQUETA_TIPO[tipo],
        latitud: ubicacion.latitud,
        longitud: ubicacion.longitud,
        precision_m: ubicacion.precision ? Math.round(ubicacion.precision) : null,
        ubicacion_aproximada: ubicacion.esAproximada ?? false,
        capturado_en: new Date().toISOString(),
        personas_afectadas: familia.personas,
        ninos: familia.ninos,
        adultos_mayores: familia.adultos_mayores,
        necesidades,
      });
      if (foto) await api.subirFoto(id, foto);
      setListo(true);
    } catch (err) {
      setError(err instanceof api.ErrorApi && err.codigo === 'VALIDACION'
        ? 'Revisa los datos. La ubicación debe estar en la provincia de Esmeraldas.'
        : err instanceof api.ErrorApi ? err.message : 'No se pudo enviar el reporte.');
    } finally {
      setEnviando(false);
    }
  }

  if (listo) {
    return (
      <Aviso tipo="ok" titulo="Reporte enviado">
        <a href="/panel/mis-reportes">Ver mis reportes</a>
      </Aviso>
    );
  }

  const contador = (campo: keyof typeof familia, etiqueta: string) => (
    <label className="er-campo">
      <span className="er-etiqueta">{etiqueta}</span>
      <input className="er-entrada" type="number" min={0} max={500} value={familia[campo]} onChange={(e) => setFamilia({ ...familia, [campo]: Math.max(0, Number(e.target.value) || 0) })} />
    </label>
  );

  return (
    <form className="pn-bloque pn-formulario-reporte" onSubmit={enviar}>
      {error && <Aviso tipo="peligro">{error}</Aviso>}

      <fieldset className="pn-fieldset">
        <legend className="er-etiqueta">Tipo de emergencia</legend>
        <div className="pn-tipos">
          {TIPOS.map(([t, Icono]) => (
            <button key={t} type="button" className="pn-tipo" aria-pressed={tipo === t} onClick={() => setTipo(t)}>
              <Icono aria-hidden="true" />
              {ETIQUETA_TIPO[t]}
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset className="pn-fieldset">
        <legend className="er-etiqueta">Gravedad</legend>
        <div className="er-segmentos" role="group">
          {(['baja', 'media', 'alta', 'critica'] as const).map((g) => (
            <button key={g} type="button" className="er-segmento" aria-pressed={gravedad === g} onClick={() => setGravedad(g)}>{ETIQUETA_GRAVEDAD[g]}</button>
          ))}
        </div>
      </fieldset>

      <div className="pn-form__fila">
        <Boton onClick={usarGps} disabled={buscandoGps}>
          <LocateFixed aria-hidden="true" /> {buscandoGps ? 'Buscando GPS...' : ubicacion && !ubicacion.esAproximada ? 'Ubicación GPS fijada' : 'Obtener mi GPS'}
        </Boton>
        <label className="er-btn er-btn--secundario">
          <Camera aria-hidden="true" /> {foto ? foto.name : 'Foto'}
          <input className="er-sr" type="file" accept="image/jpeg,image/png" capture="environment" onChange={(e) => setFoto(e.target.files?.[0] ?? null)} />
        </label>
      </div>

      <label className="er-campo">
        <span className="er-etiqueta">Sector</span>
        <select className="er-select" value={ubicacion?.nombreSector ?? ''} onChange={(e) => seleccionarSector(e.target.value)}>
          <option value="">Elegir sector</option>
          {Object.keys(SECTORES_ESMERALDAS).map((nom) => (
            <option key={nom} value={nom}>{nom}</option>
          ))}
        </select>
      </label>

      <div className="er-tarjeta op-mapa-tarjeta pn-mapa-marcar">
        <MapaEsmeraldas
          reportes={ubicacion ? [marcadorUbicacion(ubicacion, 'Ubicación del reporte')] : []}
          puntosServicio={[]}
          onSeleccionarReporte={() => {}}
          alTocarMapa={(latitud, longitud) => setUbicacion({ latitud, longitud, precision: 0, esAproximada: true })}
        />
      </div>
      <p className="pn-sub er-num">
        {ubicacion
          ? `${ubicacion.nombreSector ? `${ubicacion.nombreSector} · ` : ''}${ubicacion.latitud.toFixed(5)}, ${ubicacion.longitud.toFixed(5)}${ubicacion.esAproximada ? ' · aproximada' : ` · ±${Math.round(ubicacion.precision)} m`}`
          : 'Usa tu ubicación, elige el sector o toca el mapa'}
      </p>

      <label className="er-campo">
        <span className="er-etiqueta">Descripción</span>
        <textarea className="er-area" maxLength={1000} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} />
      </label>

      <details className="pn-fieldset">
        <summary className="er-etiqueta">Familia afectada</summary>
        <div className="pn-form__fila">
          {contador('personas', 'Personas')}
          {contador('ninos', 'Niños')}
          {contador('adultos_mayores', 'Adultos mayores')}
        </div>
        <div className="pn-form__fila">
          {(['agua', 'alimentos', 'medicinas', 'rescate'] as const).map((n) => (
            <label key={n} className="op-capa">
              <input type="checkbox" checked={necesidades.includes(n)} onChange={(e) => setNecesidades((l) => (e.target.checked ? [...l, n] : l.filter((x) => x !== n)))} />
              {ETIQUETA_NECESIDAD[n]}
            </label>
          ))}
        </div>
      </details>

      <Boton type="submit" variante="emergencia" tamano="lg" bloque disabled={!tipo || !ubicacion || enviando}>
        <Siren aria-hidden="true" /> {enviando ? 'Enviando...' : 'Enviar reporte'}
      </Boton>
    </form>
  );
}
