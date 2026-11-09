import React, { useState, useMemo } from 'react';
import type { ReporteMapa, PuntoServicioMapa, Gravedad, TipoIncidente, EstadoReporte } from '../types/mapa';
import { REPORTES_INICIALES, PUNTOS_SERVICIO_INICIALES } from '../data/mockEscenario';
import { MapaEsmeraldas } from './MapaEsmeraldas';

export const PanelOperaciones: React.FC = () => {
  const [reportes, setReportes] = useState<ReporteMapa[]>(REPORTES_INICIALES);
  const [puntosServicio, setPuntosServicio] = useState<PuntoServicioMapa[]>(PUNTOS_SERVICIO_INICIALES);
  const [reporteSeleccionado, setReporteSeleccionado] = useState<ReporteMapa | null>(REPORTES_INICIALES[0]);

  // Filtros
  const [filtroGravedad, setFiltroGravedad] = useState<Gravedad | 'todas'>('todas');
  const [filtroTipo, setFiltroTipo] = useState<TipoIncidente | 'todos'>('todos');
  const [filtroEstado, setFiltroEstado] = useState<EstadoReporte | 'todos'>('todos');
  const [mostrarAlbergues, setMostrarAlbergues] = useState(true);
  const [mostrarCentrosSalud, setMostrarCentrosSalud] = useState(true);

  // Filtrado de reportes
  const reportesFiltrados = useMemo(() => {
    return reportes.filter((rep) => {
      if (filtroGravedad !== 'todas' && rep.gravedad !== filtroGravedad) return false;
      if (filtroTipo !== 'todos' && rep.tipo !== filtroTipo) return false;
      if (filtroEstado !== 'todos' && rep.estado !== filtroEstado) return false;
      return true;
    });
  }, [reportes, filtroGravedad, filtroTipo, filtroEstado]);

  // Métricas rápidas
  const metricas = useMemo(() => {
    const total = reportes.length;
    const criticos = reportes.filter((r) => r.gravedad === 'critica').length;
    const pendientes = reportes.filter((r) => r.estado === 'pendiente').length;
    const atendidos = reportes.filter((r) => r.estado === 'atendido').length;
    const totalAfectados = reportes.reduce((acc, r) => acc + r.personas_afectadas, 0);
    const alberguesDisponibles = puntosServicio.filter((p) => p.tipo === 'albergue' && p.estado_cupo !== 'rojo').length;

    return { total, criticos, pendientes, atendidos, totalAfectados, alberguesDisponibles };
  }, [reportes, puntosServicio]);

  // Acción para cambiar estado
  const cambiarEstadoReporte = (id: string, nuevoEstado: EstadoReporte) => {
    setReportes((prev) =>
      prev.map((r) => (r.id === id ? { ...r, estado: nuevoEstado, verificado: true } : r))
    );
    if (reporteSeleccionado?.id === id) {
      setReporteSeleccionado((prev) => (prev ? { ...prev, estado: nuevoEstado, verificado: true } : null));
    }
  };

  return (
    <div className="panel-container">
      {/* 1. Barra de Alerta del Sector */}
      <div className="alerta-banner">
        <span className="alerta-badge">ALERTA OFICIAL 06:00 UTC</span>
        <span className="alerta-texto">
          <strong>Sector Isla Piedad y Río Teaone:</strong> Crecida de caudal por combinación de marea alta y lluvias intensas. Operativo de evacuación en marcha.
        </span>
      </div>

      {/* 2. Métricas y KPIs */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div className="kpi-label">Total Emergencias</div>
          <div className="kpi-value">{metricas.total}</div>
          <div className="kpi-sub">{metricas.pendientes} pendientes de atención</div>
        </div>
        <div className="kpi-card kpi-critico">
          <div className="kpi-label">Incidentes Críticos</div>
          <div className="kpi-value">{metricas.criticos}</div>
          <div className="kpi-sub">Prioridad de rescate 1</div>
        </div>
        <div className="kpi-card">
          <div className="kpi-label">Personas Afectadas</div>
          <div className="kpi-value">{metricas.totalAfectados}</div>
          <div className="kpi-sub">En sectores inundados</div>
        </div>
        <div className="kpi-card kpi-albergue">
          <div className="kpi-label">Albergues con Cupo</div>
          <div className="kpi-value">{metricas.alberguesDisponibles}</div>
          <div className="kpi-sub">UTLVTE y Coliseo habilitados</div>
        </div>
      </div>

      {/* 3. Barra de Controles y Filtros */}
      <div className="filtros-bar">
        <div className="filtros-grupo">
          <label className="filtro-label">Gravedad:</label>
          <select
            value={filtroGravedad}
            onChange={(e) => setFiltroGravedad(e.target.value as any)}
            className="filtro-select"
          >
            <option value="todas">Todas las gravedades</option>
            <option value="critica">🔴 Crítica</option>
            <option value="alta">🟠 Alta</option>
            <option value="media">🟡 Media</option>
            <option value="baja">🔵 Baja</option>
          </select>
        </div>

        <div className="filtros-grupo">
          <label className="filtro-label">Estado:</label>
          <select
            value={filtroEstado}
            onChange={(e) => setFiltroEstado(e.target.value as any)}
            className="filtro-select"
          >
            <option value="todos">Todos los estados</option>
            <option value="pendiente">Pendiente</option>
            <option value="en_proceso">En Proceso</option>
            <option value="atendido">Atendido</option>
          </select>
        </div>

        <div className="filtros-capas">
          <label className="capa-toggle">
            <input
              type="checkbox"
              checked={mostrarAlbergues}
              onChange={(e) => setMostrarAlbergues(e.target.checked)}
            />
            <span>⛺ Albergues ({puntosServicio.filter((p) => p.tipo === 'albergue').length})</span>
          </label>
          <label className="capa-toggle">
            <input
              type="checkbox"
              checked={mostrarCentrosSalud}
              onChange={(e) => setMostrarCentrosSalud(e.target.checked)}
            />
            <span>🏥 Centros de Salud ({puntosServicio.filter((p) => p.tipo === 'centro_salud').length})</span>
          </label>
        </div>
      </div>

      {/* 4. Grid Principal: Lista lateral + Mapa + Panel de Detalle */}
      <div className="contenido-grid">
        {/* Lista Lateral de Incidentes */}
        <div className="sidebar-incidentes">
          <div className="sidebar-header">
            <h3>Reportes en Tiempo Real</h3>
            <span className="sidebar-contador">{reportesFiltrados.length}</span>
          </div>
          <div className="lista-scroll">
            {reportesFiltrados.map((rep) => {
              const isSelected = rep.id === reporteSeleccionado?.id;
              return (
                <div
                  key={rep.id}
                  onClick={() => setReporteSeleccionado(rep)}
                  className={`tarjeta-incidente ${isSelected ? 'tarjeta-activa' : ''}`}
                >
                  <div className="tarjeta-top">
                    <span className={`badge-gravedad badge-${rep.gravedad}`}>
                      {rep.gravedad.toUpperCase()}
                    </span>
                    <span className="tarjeta-tiempo">
                      {new Date(rep.recibido_en).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <strong className="tarjeta-titulo">{rep.titulo}</strong>
                  <div className="tarjeta-sector">📍 {rep.sector}</div>
                  <div className="tarjeta-footer">
                    <span className={`badge-estado estado-${rep.estado}`}>{rep.estado}</span>
                    {rep.personas_afectadas > 0 && (
                      <span className="tarjeta-afectados">👥 {rep.personas_afectadas}</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Mapa Leaflet Central */}
        <div className="mapa-wrapper">
          <div className="mapa-header-info">
            <span className="mapa-tag">MAPA OPERATIVO DE ESMERALDAS</span>
            <span className="mapa-atribucion-nota">Tiles © OpenStreetMap</span>
          </div>
          <MapaEsmeraldas
            reportes={reportesFiltrados}
            puntosServicio={puntosServicio}
            reporteSeleccionadoId={reporteSeleccionado?.id}
            onSeleccionarReporte={(rep) => setReporteSeleccionado(rep)}
            mostrarAlbergues={mostrarAlbergues}
            mostrarCentrosSalud={mostrarCentrosSalud}
          />
        </div>

        {/* Panel de Detalle / Gestión del Reporte Seleccionado */}
        <div className="panel-detalle">
          {reporteSeleccionado ? (
            <div className="detalle-content">
              <div className="detalle-header">
                <span className={`badge-gravedad badge-${reporteSeleccionado.gravedad}`}>
                  GRAVEDAD {reporteSeleccionado.gravedad.toUpperCase()}
                </span>
                <span className="detalle-id">{reporteSeleccionado.id}</span>
              </div>

              <h2 className="detalle-titulo">{reporteSeleccionado.titulo}</h2>
              <div className="detalle-sector">
                📍 <strong>Sector:</strong> {reporteSeleccionado.sector}
              </div>

              <div className="detalle-coords">
                <div>Lat: <code>{reporteSeleccionado.latitud.toFixed(4)}</code> | Long: <code>{reporteSeleccionado.longitud.toFixed(4)}</code></div>
                {reporteSeleccionado.precision_m && (
                  <div className="gps-precision">Precisión GPS: ±{reporteSeleccionado.precision_m}m</div>
                )}
              </div>

              <div className="detalle-seccion">
                <div className="seccion-label">Descripción del hecho:</div>
                <p className="seccion-texto">{reporteSeleccionado.descripcion}</p>
              </div>

              {reporteSeleccionado.personas_afectadas > 0 && (
                <div className="detalle-familias">
                  <div className="seccion-label">Familia y Asistencia:</div>
                  <div className="familia-stats">
                    <div className="f-item"><span>Total:</span> <strong>{reporteSeleccionado.personas_afectadas}</strong></div>
                    <div className="f-item"><span>Niños:</span> <strong>{reporteSeleccionado.ninos}</strong></div>
                    <div className="f-item"><span>Adultos M.:</span> <strong>{reporteSeleccionado.adultos_mayores}</strong></div>
                  </div>
                  {reporteSeleccionado.necesidades.length > 0 && (
                    <div className="necesidades-tags">
                      {reporteSeleccionado.necesidades.map((n) => (
                        <span key={n} className="tag-necesidad">🚨 {n.toUpperCase()}</span>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Botones de Despacho 911 */}
              <div className="acciones-operador">
                <div className="seccion-label">Acción de Operador 911:</div>
                <div className="botones-accion">
                  <button
                    disabled={reporteSeleccionado.estado === 'en_proceso'}
                    onClick={() => cambiarEstadoReporte(reporteSeleccionado.id, 'en_proceso')}
                    className="btn-despachar"
                  >
                    Despachar Unidad
                  </button>
                  <button
                    disabled={reporteSeleccionado.estado === 'atendido'}
                    onClick={() => cambiarEstadoReporte(reporteSeleccionado.id, 'atendido')}
                    className="btn-atendido"
                  >
                    Marcar Atendido
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="detalle-vacio">
              Selecciona un incidente en la lista o en el mapa para ver sus detalles.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

