import { useEffect, useState } from 'react';
import { Siren } from 'lucide-react';
import type { PuntoServicioMapa } from '../types/mapa';
import * as api from '../lib/api';
import { MapaEsmeraldas } from './MapaEsmeraldas';
import { Aviso } from './ui/Basicos';

/**
 * Pantalla 1 del prototipo móvil de Franco ("Inicio y mapa") en versión web:
 * mapa con zonas de riesgo y albergues, y el botón rojo de emergencia.
 */
export function InicioCiudadano() {
  const [puntos, setPuntos] = useState<PuntoServicioMapa[]>([]);
  const [zonas, setZonas] = useState<GeoJSON.FeatureCollection | null>(null);
  const [vias, setVias] = useState<GeoJSON.FeatureCollection | null>(null);

  useEffect(() => {
    api.listarPuntos().then((r) => setPuntos(r.datos)).catch(() => setPuntos([]));
    api.zonasGeoJson().then(setZonas).catch(() => setZonas(null));
    api.viasGeoJson().then(setVias).catch(() => setVias(null));
  }, []);

  return (
    <div className="pn-bloque">
      <Aviso tipo="info" titulo="Esta plataforma no reemplaza al 911">
        En peligro inmediato llama al ECU 911. Aquí puedes reportar lo que ves y encontrar albergues con cupo.
      </Aviso>
      <div className="er-tarjeta op-mapa-tarjeta pn-mapa-ciudadano">
        <MapaEsmeraldas reportes={[]} puntosServicio={puntos} zonas={zonas} vias={vias} onSeleccionarReporte={() => {}} />
      </div>
      <a className="er-btn er-btn--emergencia er-btn--lg er-btn--bloque" href="/panel/reportar">
        <Siren aria-hidden="true" /> Reportar emergencia
      </a>
      <p className="pn-sub pn-centrado">Desde la app móvil funciona sin internet: el reporte se guarda y se envía al volver la señal.</p>
    </div>
  );
}
