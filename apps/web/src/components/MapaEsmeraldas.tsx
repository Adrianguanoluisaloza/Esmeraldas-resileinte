import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { PuntoServicioMapa, ReporteMapa } from '../types/mapa';
import {
  COLOR_CUPO,
  COLOR_GRAVEDAD,
  COLOR_RIESGO,
  COLOR_VIA,
  ETIQUETA_CUPO,
  ETIQUETA_ESTADO,
  ETIQUETA_GRAVEDAD,
  ETIQUETA_ORIGEN,
  ETIQUETA_PUNTO,
  tituloReporte,
} from '../lib/catalogos';
import { escaparHtml as e } from '../lib/escapar';

/**
 * Mapa Leaflet + OpenStreetMap centrado en Esmeraldas. Solo dibuja: no pide datos ni guarda estado de negocio.
 * Todo texto que viene de la API pasa por escaparHtml antes de entrar a un popup (los reportes los escriben
 * ciudadanos). Estilos de marcadores y popups en src/styles/operaciones.css.
 */

interface Props {
  reportes: ReporteMapa[];
  puntosServicio: PuntoServicioMapa[];
  zonas?: GeoJSON.FeatureCollection | null;
  vias?: GeoJSON.FeatureCollection | null;
  reporteSeleccionadoId?: string | null;
  onSeleccionarReporte: (reporte: ReporteMapa) => void;
  mostrarAlbergues?: boolean;
  mostrarCentrosSalud?: boolean;
  mostrarZonas?: boolean;
  mostrarVias?: boolean;
  /** Si viene, tocar el mapa entrega la coordenada (marcar ubicación sin GPS). */
  alTocarMapa?: (latitud: number, longitud: number) => void;
  /** Vista de presentación: no captura el desplazamiento de la página. */
  soloVista?: boolean;
}

// Caja amplia: ciudad y parroquias cercanas (Tachina, Tabiazo, Vuelta Larga).
const LIMITES: L.LatLngBoundsExpression = [[0.80, -79.85], [1.10, -79.50]];
// Centro indicado por el reto.
const CENTRO: L.LatLngExpression = [0.9592, -79.6539];
const TESELAS = (import.meta.env.PUBLIC_MAP_TILE_URL as string | undefined) ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

function iconoReporte(r: ReporteMapa, seleccionado: boolean): L.DivIcon {
  const tam = seleccionado ? 20 : 14;
  const clases = ['mk-reporte', `mk-reporte--${r.gravedad}`, seleccionado && 'mk-reporte--sel', r.origen === 'simulado' && 'mk-reporte--sim']
    .filter(Boolean)
    .join(' ');
  return L.divIcon({
    className: 'mk-contenedor',
    html: `<span class="${clases}" style="--mk-color:${COLOR_GRAVEDAD[r.gravedad]};width:${tam}px;height:${tam}px" aria-hidden="true"></span>`,
    iconSize: [tam, tam],
    iconAnchor: [tam / 2, tam / 2],
  });
}

function iconoPunto(p: PuntoServicioMapa): L.DivIcon {
  const sigla = p.tipo === 'albergue' ? 'A' : 'S';
  return L.divIcon({
    className: 'mk-contenedor',
    html: `<span class="mk-punto" style="--mk-color:${COLOR_CUPO[p.estado_cupo]}"><b>${sigla}</b>${p.ocupacion}/${p.capacidad}</span>`,
    iconSize: [64, 24],
    iconAnchor: [32, 12],
  });
}

function popupReporte(r: ReporteMapa): string {
  return `
    <div class="mk-popup">
      <div class="mk-popup__meta">
        <span style="color:${COLOR_GRAVEDAD[r.gravedad]}">${e(ETIQUETA_GRAVEDAD[r.gravedad])}</span>
        <span>${e(ETIQUETA_ESTADO[r.estado])}</span>
        ${r.origen ? `<span>${e(ETIQUETA_ORIGEN[r.origen])}</span>` : ''}
      </div>
      <strong>${e(tituloReporte(r))}</strong>
      <p>${e(r.descripcion)}</p>
      ${r.personas_afectadas > 0 ? `<div class="mk-popup__dato">${e(r.personas_afectadas)} personas afectadas</div>` : ''}
    </div>`;
}

function popupPunto(p: PuntoServicioMapa): string {
  const pct = p.capacidad > 0 ? Math.round((p.ocupacion / p.capacidad) * 100) : 100;
  return `
    <div class="mk-popup">
      <div class="mk-popup__meta"><span>${e(ETIQUETA_PUNTO[p.tipo])}</span><span style="color:${COLOR_CUPO[p.estado_cupo]}">${e(ETIQUETA_CUPO[p.estado_cupo])}</span></div>
      <strong>${e(p.nombre)}</strong>
      ${p.direccion ? `<p>${e(p.direccion)}</p>` : ''}
      <div class="mk-popup__dato">${e(p.ocupacion)} de ${e(p.capacidad)} ocupados (${pct} %)</div>
      ${p.origen === 'simulado' ? '<div class="mk-popup__dato">Dato simulado</div>' : ''}
      ${p.telefono ? `<div class="mk-popup__dato">Teléfono: ${e(p.telefono)}</div>` : ''}
    </div>`;
}

export function MapaEsmeraldas({
  reportes,
  puntosServicio,
  zonas,
  vias,
  reporteSeleccionadoId,
  onSeleccionarReporte,
  mostrarAlbergues = true,
  mostrarCentrosSalud = true,
  mostrarZonas = true,
  mostrarVias = true,
  alTocarMapa,
  soloVista = false,
}: Props) {
  const tocarRef = useRef(alTocarMapa);
  tocarRef.current = alTocarMapa;
  const contenedor = useRef<HTMLDivElement>(null);
  const mapa = useRef<L.Map | null>(null);
  const capas = useRef<{ reportes: L.LayerGroup; puntos: L.LayerGroup; zonas: L.LayerGroup; vias: L.LayerGroup } | null>(null);

  useEffect(() => {
    if (!contenedor.current || mapa.current) return;
    const m = L.map(contenedor.current, { center: CENTRO, zoom: 13, minZoom: 11, maxZoom: 18, maxBounds: LIMITES, maxBoundsViscosity: 0.8, zoomControl: false, ...(soloVista ? { dragging: false, scrollWheelZoom: false, doubleClickZoom: false, touchZoom: false, boxZoom: false, keyboard: false } : {}) });
    L.tileLayer(TESELAS, {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">OpenStreetMap</a>',
    }).addTo(m);
    if (!soloVista) L.control.zoom({ position: 'topright' }).addTo(m);
    L.control.scale({ imperial: false, position: 'bottomleft' }).addTo(m);
    // Orden de dibujo: zonas abajo, luego vías, puntos y reportes arriba.
    capas.current = {
      zonas: L.layerGroup().addTo(m),
      vias: L.layerGroup().addTo(m),
      puntos: L.layerGroup().addTo(m),
      reportes: L.layerGroup().addTo(m),
    };
    m.on('click', (e: L.LeafletMouseEvent) => tocarRef.current?.(e.latlng.lat, e.latlng.lng));
    mapa.current = m;
    return () => {
      m.remove();
      mapa.current = null;
      capas.current = null;
    };
  }, []);

  useEffect(() => {
    const capa = capas.current?.zonas;
    if (!capa) return;
    capa.clearLayers();
    if (!zonas || !mostrarZonas) return;
    L.geoJSON(zonas, {
      style: (f) => {
        const color = COLOR_RIESGO[(f?.properties?.nivel_riesgo as keyof typeof COLOR_RIESGO) ?? 'medio'] ?? COLOR_RIESGO.medio;
        return { color, weight: 1, opacity: 0.75, fillColor: color, fillOpacity: 0.22, lineJoin: 'round' };
      },
      onEachFeature: (f, l) =>
        l.bindTooltip(`${e(f.properties?.nombre_sector)} · riesgo ${e(f.properties?.nivel_riesgo)}`, { sticky: true }),
    }).addTo(capa);
  }, [zonas, mostrarZonas]);

  useEffect(() => {
    const capa = capas.current?.vias;
    if (!capa) return;
    capa.clearLayers();
    if (!vias || !mostrarVias) return;
    const estadoDe = (f?: GeoJSON.Feature) => (f?.properties?.estado as keyof typeof COLOR_VIA) ?? 'habilitada';
    // Borde blanco debajo: las vías afectadas se leen sobre cualquier color del mapa base.
    L.geoJSON({ ...vias, features: vias.features.filter((f) => estadoDe(f) !== 'habilitada') } as GeoJSON.FeatureCollection, {
      interactive: false,
      style: { color: '#ffffff', weight: 9, opacity: 1, lineCap: 'round', lineJoin: 'round' },
    }).addTo(capa);
    L.geoJSON(vias, {
      style: (f) => {
        const estado = estadoDe(f);
        return estado === 'habilitada'
          ? { color: COLOR_VIA.habilitada, weight: 2, opacity: 0.45, lineCap: 'round', lineJoin: 'round' }
          : { color: COLOR_VIA[estado], weight: 5, opacity: 1, lineCap: 'round', lineJoin: 'round' };
      },
      onEachFeature: (f, l) => {
        l.bindTooltip(`${e(f.properties?.nombre)} · ${e(f.properties?.estado)}`, { sticky: true });
        const estado = estadoDe(f);
        if (estado === 'habilitada' || f.geometry.type !== 'LineString') return;
        const [lng, lat] = f.geometry.coordinates[Math.floor(f.geometry.coordinates.length / 2)] as [number, number];
        L.marker([lat, lng], {
          interactive: false,
          icon: L.divIcon({
            className: 'mk-contenedor',
            html: `<span class="mk-via" style="--mk-color:${COLOR_VIA[estado]}">${estado === 'bloqueada' ? 'Vía cerrada' : 'Paso parcial'}</span>`,
            iconSize: [0, 0],
          }),
        }).addTo(capa);
      },
    }).addTo(capa);
  }, [vias, mostrarVias]);

  useEffect(() => {
    const capa = capas.current?.puntos;
    if (!capa) return;
    capa.clearLayers();
    for (const p of puntosServicio) {
      if ((p.tipo === 'albergue' && !mostrarAlbergues) || (p.tipo === 'centro_salud' && !mostrarCentrosSalud)) continue;
      L.marker([p.latitud, p.longitud], { icon: iconoPunto(p), zIndexOffset: 300, title: p.nombre })
        .bindPopup(popupPunto(p), { offset: [0, -8] })
        .addTo(capa);
    }
  }, [puntosServicio, mostrarAlbergues, mostrarCentrosSalud]);

  useEffect(() => {
    const m = mapa.current;
    const capa = capas.current?.reportes;
    if (!m || !capa) return;
    capa.clearLayers();
    for (const r of reportes) {
      const sel = r.id === reporteSeleccionadoId;
      const marcador = L.marker([r.latitud, r.longitud], {
        icon: iconoReporte(r, sel),
        zIndexOffset: sel ? 1000 : r.gravedad === 'critica' ? 500 : 100,
        title: tituloReporte(r),
        keyboard: true,
      })
        .bindPopup(popupReporte(r), { offset: [0, -8] })
        .on('click', () => onSeleccionarReporte(r))
        .addTo(capa);
      if (sel) {
        m.flyTo([r.latitud, r.longitud], Math.max(m.getZoom(), 14), { duration: 0.6 });
        marcador.openPopup();
      }
    }
  }, [reportes, reporteSeleccionadoId, onSeleccionarReporte]);

  return <div ref={contenedor} className="op-mapa" role="region" aria-label="Mapa de Esmeraldas con incidentes, zonas de riesgo, vías y albergues" />;
}
