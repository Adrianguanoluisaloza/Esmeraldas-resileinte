import { useEffect, useState } from 'react';
import { Minus, Navigation, Phone, Plus } from 'lucide-react';
import { obtenerSesionActual } from '../lib/auth';
import type { PuntoServicioMapa } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_PUNTO, semaforoCupo } from '../lib/catalogos';
import { Aviso, AvisoRespaldo, BarraCapacidad, Boton, Cargando } from './ui/Basicos';
import { InsigniaCupo } from './ui/Insignias';

type Cercano = PuntoServicioMapa & { distancia_m?: number; paso_bloqueado?: boolean };

/**
 * Albergues y centros de salud con semáforo de cupo (pregunta 6 del escenario).
 * "Cerca de mí" usa la ubicación del navegador y el endpoint PostGIS /puntos-servicio/cercanos.
 */
export function ListaAlbergues() {
  const [puntos, setPuntos] = useState<Cercano[] | null>(null);
  const [respaldo, setRespaldo] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);
  const [personas, setPersonas] = useState(1);
  const [buscando, setBuscando] = useState(false);
  const [esCoe, setEsCoe] = useState(false);

  useEffect(() => {
    const rol = obtenerSesionActual()?.rol;
    setEsCoe(rol === 'operador_911' || rol === 'admin');
  }, []);

  async function ajustar(p: Cercano, delta: number) {
    const ocupacion = Math.max(0, p.ocupacion + delta);
    try {
      const actualizado = await api.actualizarOcupacion(p.id, ocupacion);
      setPuntos((l) => l?.map((x) => (x.id === p.id ? { ...x, ...actualizado, estado_cupo: semaforoCupo(actualizado.capacidad, actualizado.ocupacion) } : x)) ?? null);
    } catch (e) {
      setAviso(e instanceof api.ErrorApi ? e.message : 'No se pudo actualizar la ocupación.');
    }
  }

  useEffect(() => {
    api
      .listarPuntos()
      .then((r) => {
        setPuntos(r.datos);
        setRespaldo(r.respaldo);
      })
      .catch((e) => setAviso(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar los albergues.'));
  }, []);

  function buscarCercanos() {
    if (!('geolocation' in navigator)) {
      setAviso('Este navegador no permite obtener la ubicación.');
      return;
    }
    setBuscando(true);
    setAviso(null);
    navigator.geolocation.getCurrentPosition(
      async ({ coords }) => {
        try {
          setPuntos(await api.puntosCercanos(coords.latitude, coords.longitude, personas));
        } catch (e) {
          setAviso(e instanceof api.ErrorApi && e.codigo === 'VALIDACION'
            ? 'Tu ubicación está fuera de la provincia de Esmeraldas.'
            : e instanceof api.ErrorApi ? e.message : 'No se pudo buscar.');
        } finally {
          setBuscando(false);
        }
      },
      () => {
        setBuscando(false);
        setAviso('No se pudo obtener tu ubicación. Revisa el permiso del navegador.');
      },
      { timeout: 15000, maximumAge: 60000 },
    );
  }

  if (!puntos && !aviso) return <Cargando texto="Cargando albergues..." />;

  return (
    <div className="pn-bloque">
      {respaldo && <AvisoRespaldo />}
      {aviso && <Aviso tipo="aviso">{aviso}</Aviso>}

      <div className="pn-barra-filtros">
        <label className="er-campo">
          <span className="er-etiqueta">Personas a ubicar</span>
          <input className="er-entrada" type="number" min={1} max={50} value={personas} onChange={(e) => setPersonas(Math.max(1, Number(e.target.value) || 1))} />
        </label>
        <Boton variante="primario" onClick={buscarCercanos} disabled={buscando || respaldo}>
          <Navigation aria-hidden="true" />
          {buscando ? 'Buscando...' : 'Albergues cerca de mí'}
        </Boton>
      </div>

      <ul className="pn-rejilla-tarjetas">
        {puntos?.map((p) => (
          <li key={p.id} className="er-tarjeta er-tarjeta__cuerpo pn-punto">
            <div className="op-item__fila">
              <span className="er-rotulo">{ETIQUETA_PUNTO[p.tipo]}</span>
              <InsigniaCupo valor={p.estado_cupo} />
            </div>
            <strong>{p.nombre}</strong>
            {p.paso_bloqueado && <span className="er-insignia er-insignia--estado-pendiente" style={{ justifySelf: 'start' }}>El camino cruza una vía bloqueada</span>}
            {p.direccion && <span className="pn-sub">{p.direccion}</span>}
            <BarraCapacidad ocupacion={p.ocupacion} capacidad={p.capacidad} estado={p.estado_cupo} />
            <div className="op-item__fila pn-sub er-num">
              <span>{p.ocupacion} de {p.capacidad} ocupados</span>
              {p.distancia_m !== undefined && <span>{p.distancia_m < 1000 ? `${p.distancia_m} m` : `${(p.distancia_m / 1000).toFixed(1)} km`}</span>}
            </div>
            {esCoe && !respaldo && (
              <div className="pn-form__fila" role="group" aria-label={`Ocupación de ${p.nombre}`}>
                <Boton tamano="sm" onClick={() => ajustar(p, -1)} aria-label="Restar una persona"><Minus aria-hidden="true" /></Boton>
                <Boton tamano="sm" onClick={() => ajustar(p, 1)} aria-label="Sumar una persona"><Plus aria-hidden="true" /></Boton>
                <Boton tamano="sm" onClick={() => ajustar(p, 5)}>+5</Boton>
              </div>
            )}
            {p.telefono && (
              <a className="er-btn er-btn--secundario er-btn--sm" href={`tel:${p.telefono.replace(/[^\d+]/g, '')}`}>
                <Phone aria-hidden="true" /> {p.telefono}
              </a>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
