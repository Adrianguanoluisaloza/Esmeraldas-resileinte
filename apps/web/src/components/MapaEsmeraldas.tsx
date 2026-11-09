import React, { useEffect, useRef } from 'react';
import type { ReporteMapa, PuntoServicioMapa } from '../types/mapa';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface Props {
  reportes: ReporteMapa[];
  puntosServicio: PuntoServicioMapa[];
  reporteSeleccionadoId?: string | null;
  onSeleccionarReporte: (reporte: ReporteMapa) => void;
  mostrarAlbergues?: boolean;
  mostrarCentrosSalud?: boolean;
}

// Bounding box para mantener la cámara dentro de Esmeraldas
const ESMERALDAS_BOUNDS: L.LatLngBoundsExpression = [
  [0.85, -79.78],
  [1.05, -79.55],
];

const ESMERALDAS_CENTER: L.LatLngExpression = [0.9681, -79.6517];

function obtenerColorGravedad(gravedad: string): string {
  switch (gravedad) {
    case 'critica':
      return '#dc2626'; // Rojo intenso
    case 'alta':
      return '#ea580c'; // Naranja
    case 'media':
      return '#eab308'; // Amarillo
    case 'baja':
    default:
      return '#2563eb'; // Azul
  }
}

function crearIconoReporte(gravedad: string, isSelected: boolean): L.DivIcon {
  const color = obtenerColorGravedad(gravedad);
  const size = isSelected ? 34 : 28;
  const pulseClass = gravedad === 'critica' ? 'map-marker-pulse' : '';
  const selectedBorder = isSelected ? 'border-2 border-white shadow-lg ring-2 ring-red-400' : 'border border-white/80 shadow-md';

  return L.divIcon({
    className: 'custom-leaflet-marker',
    html: `
      <div style="position: relative; display: flex; align-items: center; justify-content: center; width: ${size}px; height: ${size}px;">
        ${gravedad === 'critica' ? `<div style="position: absolute; inset: -4px; border-radius: 9999px; background-color: ${color}; opacity: 0.4;" class="${pulseClass}"></div>` : ''}
        <div style="background-color: ${color}; width: ${size}px; height: ${size}px; border-radius: 9999px; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 11px; ${selectedBorder}">
          !
        </div>
      </div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function crearIconoServicio(tipo: 'albergue' | 'centro_salud', estadoCupo: 'verde' | 'ambar' | 'rojo'): L.DivIcon {
  const isAlbergue = tipo === 'albergue';
  const colorCupo = estadoCupo === 'verde' ? '#16a34a' : estadoCupo === 'ambar' ? '#d97706' : '#dc2626';
  const iconoTexto = isAlbergue ? 'Albergue' : 'Salud';

  return L.divIcon({
    className: 'custom-service-marker',
    html: `
      <div style="display: flex; flex-direction: column; align-items: center; cursor: pointer;">
        <div style="background-color: #0f172a; border: 2px solid ${colorCupo}; border-radius: 8px; padding: 3px 6px; display: flex; align-items: center; gap: 4px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.4); color: white; font-size: 11px; font-weight: 600;">
          <span>${iconoTexto}</span>
          <span style="font-size: 9px; text-transform: uppercase; color: ${colorCupo};">${estadoCupo}</span>
        </div>
        <div style="width: 0; height: 0; border-left: 5px solid transparent; border-right: 5px solid transparent; border-top: 6px solid #0f172a; margin-top: -1px;"></div>
      </div>
    `,
    iconSize: [36, 32],
    iconAnchor: [18, 32],
  });
}

export const MapaEsmeraldas: React.FC<Props> = ({
  reportes,
  puntosServicio,
  reporteSeleccionadoId,
  onSeleccionarReporte,
  mostrarAlbergues = true,
  mostrarCentrosSalud = true,
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const servicesLayerRef = useRef<L.LayerGroup | null>(null);

  // Inicialización del mapa Leaflet
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: ESMERALDAS_CENTER,
        zoom: 13,
        minZoom: 11,
        maxZoom: 18,
        maxBounds: ESMERALDAS_BOUNDS,
        maxBoundsViscosity: 0.8,
        zoomControl: false,
      });

      // Capa de teselas OpenStreetMap oficial con atribución legal
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">OpenStreetMap</a> contributors',
      }).addTo(map);

      // Control de zoom en esquina superior derecha para no chocar con leyendas
      L.control.zoom({ position: 'topright' }).addTo(map);

      // Grupos de capas
      const markersLayer = L.layerGroup().addTo(map);
      const servicesLayer = L.layerGroup().addTo(map);

      markersLayerRef.current = markersLayer;
      servicesLayerRef.current = servicesLayer;
      mapInstanceRef.current = map;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Actualización de marcadores de reportes
  useEffect(() => {
    const map = mapInstanceRef.current;
    const layer = markersLayerRef.current;
    if (!map || !layer) return;

    layer.clearLayers();

    reportes.forEach((rep) => {
      const isSelected = rep.id === reporteSeleccionadoId;
      const marker = L.marker([rep.latitud, rep.longitud], {
        icon: crearIconoReporte(rep.gravedad, isSelected),
        zIndexOffset: isSelected ? 1000 : rep.gravedad === 'critica' ? 500 : 100,
      });

      const popupContent = `
        <div style="font-family: inherit; font-size: 13px; line-height: 1.4; min-width: 200px;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px;">
            <span style="font-size: 10px; font-weight: bold; text-transform: uppercase; padding: 2px 6px; border-radius: 4px; background: ${obtenerColorGravedad(rep.gravedad)}; color: white;">
              ${rep.gravedad}
            </span>
            <span style="font-size: 10px; color: #64748b; font-weight: 600;">
              ${rep.estado.toUpperCase()}
            </span>
          </div>
          <strong style="color: #0f172a; font-size: 14px; display: block; margin-bottom: 4px;">${rep.titulo}</strong>
          <div style="color: #475569; font-size: 11px; margin-bottom: 6px;">Sector: ${rep.sector}</div>
          <p style="margin: 0 0 6px 0; color: #334155; font-size: 12px;">${rep.descripcion}</p>
          ${rep.personas_afectadas > 0 ? `<div style="font-size: 11px; background: #f1f5f9; padding: 4px 6px; border-radius: 4px; color: #1e293b;"><strong>${rep.personas_afectadas} personas afectadas</strong> (Niños: ${rep.ninos})</div>` : ''}
        </div>
      `;

      marker.bindPopup(popupContent, { offset: [0, -10] });

      marker.on('click', () => {
        onSeleccionarReporte(rep);
      });

      marker.addTo(layer);

      if (isSelected) {
        map.flyTo([rep.latitud, rep.longitud], Math.max(map.getZoom(), 14), { duration: 0.8 });
        marker.openPopup();
      }
    });
  }, [reportes, reporteSeleccionadoId, onSeleccionarReporte]);

  // Actualización de marcadores de puntos de servicio (Albergues y Centros de Salud)
  useEffect(() => {
    const layer = servicesLayerRef.current;
    if (!layer) return;

    layer.clearLayers();

    puntosServicio.forEach((pto) => {
      if (pto.tipo === 'albergue' && !mostrarAlbergues) return;
      if (pto.tipo === 'centro_salud' && !mostrarCentrosSalud) return;

      const marker = L.marker([pto.latitud, pto.longitud], {
        icon: crearIconoServicio(pto.tipo, pto.estado_cupo),
        zIndexOffset: 300,
      });

      const porcentaje = Math.round((pto.ocupacion / pto.capacidad) * 100);
      const tipoTexto = pto.tipo === 'albergue' ? 'Albergue Temporal' : 'Centro de Salud';

      const popupContent = `
        <div style="font-family: inherit; font-size: 13px; line-height: 1.4; min-width: 220px;">
          <div style="color: #0284c7; font-size: 10px; font-weight: bold; text-transform: uppercase; margin-bottom: 2px;">${tipoTexto}</div>
          <strong style="color: #0f172a; font-size: 13px; display: block; margin-bottom: 4px;">${pto.nombre}</strong>
          <div style="font-size: 11px; color: #475569; margin-bottom: 6px;">${pto.direccion}</div>
          <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px; margin-bottom: 6px;">
            <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 3px;">
              <span style="color: #64748b;">Capacidad ocupada:</span>
              <strong style="color: #0f172a;">${pto.ocupacion} / ${pto.capacidad} (${porcentaje}%)</strong>
            </div>
            <div style="width: 100%; height: 6px; background: #e2e8f0; border-radius: 9999px; overflow: hidden;">
              <div style="width: ${Math.min(porcentaje, 100)}%; height: 100%; background: ${pto.estado_cupo === 'verde' ? '#16a34a' : pto.estado_cupo === 'ambar' ? '#d97706' : '#dc2626'};"></div>
            </div>
          </div>
          <div style="font-size: 11px; color: #334155;">Teléfono: <strong>${pto.telefono}</strong></div>
        </div>
      `;

      marker.bindPopup(popupContent, { offset: [0, -20] });
      marker.addTo(layer);
    });
  }, [puntosServicio, mostrarAlbergues, mostrarCentrosSalud]);

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: '520px' }}>
      <div
        ref={mapContainerRef}
        style={{
          width: '100%',
          height: '100%',
          borderRadius: '12px',
          overflow: 'hidden',
          backgroundColor: '#0f172a',
        }}
      />
    </div>
  );
};

