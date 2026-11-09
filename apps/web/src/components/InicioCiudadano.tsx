import { useEffect, useState } from 'react';
import { Siren } from 'lucide-react';
import type { PuntoServicioMapa } from '../types/mapa';
import * as api from '../lib/api';
import { AlertasVigentes } from './AlertasVias';
import { MapaEsmeraldas } from './MapaEsmeraldas';

/** Inicio del ciudadano: alertas vigentes, mapa con zonas y albergues, y el botón de emergencia. */
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
      <AlertasVigentes />
      <div className="er-tarjeta op-mapa-tarjeta pn-mapa-ciudadano">
        <MapaEsmeraldas reportes={[]} puntosServicio={puntos} zonas={zonas} vias={vias} onSeleccionarReporte={() => {}} />
      </div>
      <a className="er-btn er-btn--emergencia er-btn--lg er-btn--bloque" href="/panel/reportar">
        <Siren aria-hidden="true" /> Reportar emergencia
      </a>
      <p className="pn-sub pn-centrado">Emergencia inmediata: ECU 911</p>
    </div>
  );
}
