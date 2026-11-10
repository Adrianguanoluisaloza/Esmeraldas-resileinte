import { useState, type FormEvent } from 'react';
import { LocateFixed } from 'lucide-react';
import type { PuntoServicioMapa, TipoPuntoServicio } from '../types/mapa';
import * as api from '../lib/api';
import { marcadorUbicacion, obtenerUbicacion } from '../lib/ubicacion';
import { Aviso, Boton } from './ui/Basicos';
import { MapaEsmeraldas } from './MapaEsmeraldas';

const INICIAL = { nombre: '', tipo: 'albergue' as TipoPuntoServicio, direccion: '', telefono: '', capacidad: 50, ocupacion: 0 };

/** Registro de un albergue o centro de salud por el personal del COE. */
export function FormularioAlbergue({ alCrear, alCancelar }: { alCrear: (p: PuntoServicioMapa) => void; alCancelar: () => void }) {
  const [datos, setDatos] = useState(INICIAL);
  const [lugar, setLugar] = useState<{ latitud: number; longitud: number } | null>(null);
  const [buscando, setBuscando] = useState(false);
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function usarMiUbicacion() {
    setBuscando(true);
    setError(null);
    try {
      const c = await obtenerUbicacion();
      setLugar({ latitud: c.latitude, longitud: c.longitude });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBuscando(false);
    }
  }

  async function enviar(e: FormEvent) {
    e.preventDefault();
    if (!lugar) return setError('Marca el lugar en el mapa.');
    if (datos.ocupacion > datos.capacidad) return setError('La ocupación no puede superar la capacidad.');
    setEnviando(true);
    setError(null);
    try {
      alCrear(await api.crearPunto({ ...datos, nombre: datos.nombre.trim(), direccion: datos.direccion.trim(), telefono: datos.telefono.trim(), ...lugar }));
    } catch (err) {
      setError(err instanceof api.ErrorApi && err.codigo === 'VALIDACION'
        ? 'Revisa los datos. El lugar debe estar en la provincia de Esmeraldas.'
        : err instanceof api.ErrorApi ? err.message : 'No se pudo registrar.');
    } finally {
      setEnviando(false);
    }
  }

  const numero = (campo: 'capacidad' | 'ocupacion', etiqueta: string, min: number) => (
    <label className="er-campo">
      <span className="er-etiqueta">{etiqueta}</span>
      <input className="er-entrada er-num" type="number" required min={min} max={100000} value={datos[campo]} onChange={(e) => setDatos({ ...datos, [campo]: Math.max(0, Number(e.target.value) || 0) })} />
    </label>
  );

  return (
    <form className="er-tarjeta er-tarjeta__cuerpo pn-form pn-alta-punto" onSubmit={enviar}>
      <h2 className="er-tarjeta__titulo">Nuevo punto de servicio</h2>
      {error && <Aviso tipo="peligro">{error}</Aviso>}

      <div className="pn-form__fila">
        <label className="er-campo">
          <span className="er-etiqueta">Nombre</span>
          <input className="er-entrada" required minLength={3} maxLength={160} value={datos.nombre} onChange={(e) => setDatos({ ...datos, nombre: e.target.value })} />
        </label>
        <label className="er-campo">
          <span className="er-etiqueta">Tipo</span>
          <select className="er-select" value={datos.tipo} onChange={(e) => setDatos({ ...datos, tipo: e.target.value as TipoPuntoServicio })}>
            <option value="albergue">Albergue</option>
            <option value="centro_salud">Centro de salud</option>
          </select>
        </label>
      </div>
      <div className="pn-form__fila">
        <label className="er-campo">
          <span className="er-etiqueta">Dirección</span>
          <input className="er-entrada" maxLength={200} value={datos.direccion} onChange={(e) => setDatos({ ...datos, direccion: e.target.value })} />
        </label>
        <label className="er-campo">
          <span className="er-etiqueta">Teléfono</span>
          <input className="er-entrada" type="tel" maxLength={30} value={datos.telefono} onChange={(e) => setDatos({ ...datos, telefono: e.target.value })} />
        </label>
        {numero('capacidad', 'Capacidad', 1)}
        {numero('ocupacion', 'Ocupación actual', 0)}
      </div>

      <div className="pn-form__fila pn-entre">
        <span className="er-etiqueta er-num">{lugar ? `${lugar.latitud.toFixed(5)}, ${lugar.longitud.toFixed(5)}` : 'Toca el mapa para marcar el lugar'}</span>
        <Boton tamano="sm" onClick={usarMiUbicacion} disabled={buscando}><LocateFixed aria-hidden="true" /> {buscando ? 'Buscando...' : 'Usar mi ubicación'}</Boton>
      </div>
      <div className="er-tarjeta op-mapa-tarjeta pn-mapa-marcar">
        <MapaEsmeraldas
          reportes={lugar ? [marcadorUbicacion(lugar, 'Lugar del nuevo punto')] : []}
          puntosServicio={[]}
          onSeleccionarReporte={() => {}}
          mostrarZonas={false}
          mostrarVias={false}
          alTocarMapa={(latitud, longitud) => { setLugar({ latitud, longitud }); setError(null); }}
        />
      </div>

      <div className="pn-form__fila pn-entre">
        <Boton variante="fantasma" onClick={alCancelar}>Cancelar</Boton>
        <Boton type="submit" variante="primario" disabled={enviando}>{enviando ? 'Guardando...' : 'Registrar'}</Boton>
      </div>
    </form>
  );
}
