import { useEffect, useState } from 'react';
import type { PuntoServicioMapa } from '../types/mapa';
import * as api from '../lib/api';
import { MapaEsmeraldas } from './MapaEsmeraldas';
import { InsigniaOrigen } from './ui/Insignias';

type Coleccion = GeoJSON.FeatureCollection | null;

/** Portada: el mapa real del producto con las capas públicas, no una ilustración. */
export function PortadaMapa() {
  const [puntos, setPuntos] = useState<PuntoServicioMapa[]>([]);
  const [zonas, setZonas] = useState<Coleccion>(null);
  const [vias, setVias] = useState<Coleccion>(null);
  const [alertas, setAlertas] = useState<number | null>(null);

  useEffect(() => {
    api.listarPuntos().then((r) => setPuntos(r.datos)).catch(() => {});
    api.zonasGeoJson().then(setZonas).catch(() => {});
    api.viasGeoJson().then(setVias).catch(() => {});
    api.listarAlertas().then((a) => setAlertas(a.length)).catch(() => {});
  }, []);

  const conCupo = puntos.filter((p) => p.tipo === 'albergue' && p.estado_cupo !== 'rojo').length;
  const afectadas = vias?.features.filter((f) => f.properties?.estado !== 'habilitada').length;
  const dato = (v: number | null | undefined) => v ?? '–';

  return (
    <figure className="st-tablero">
      <div className="st-tablero__mapa op-mapa-tarjeta">
        <MapaEsmeraldas reportes={[]} puntosServicio={puntos} zonas={zonas} vias={vias} onSeleccionarReporte={() => {}} soloVista />
      </div>
      <figcaption className="st-tablero__pie">
        <dl className="st-cifras">
          <div><dt>Albergues con cupo</dt><dd className="er-num">{dato(puntos.length ? conCupo : null)}</dd></div>
          <div><dt>Vías afectadas</dt><dd className="er-num">{dato(afectadas)}</dd></div>
          <div><dt>Alertas vigentes</dt><dd className="er-num">{dato(alertas)}</dd></div>
        </dl>
        <InsigniaOrigen valor="simulado" />
      </figcaption>
    </figure>
  );
}
