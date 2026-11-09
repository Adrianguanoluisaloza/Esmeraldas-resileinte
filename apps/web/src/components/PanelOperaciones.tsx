import { useCallback, useEffect, useMemo, useState } from 'react';
import { MapPin, Users } from 'lucide-react';
import type { EstadoReporte, Gravedad, PuntoServicioMapa, ReporteMapa } from '../types/mapa';
import * as api from '../lib/api';
import { ETIQUETA_NECESIDAD, ETIQUETA_TIPO, PESO_GRAVEDAD, horaLocal, semaforoCupo, tituloReporte } from '../lib/catalogos';
import { MapaEsmeraldas } from './MapaEsmeraldas';
import { Aviso, AvisoRespaldo, Boton, Cargando, Indicador } from './ui/Basicos';
import { InsigniaEstado, InsigniaGravedad, InsigniaOrigen } from './ui/Insignias';

/**
 * Mapa operativo del COE. Responde las preguntas del escenario Jueves 06:00:
 * qué pasa y dónde (lista + mapa), cuántas personas (indicadores), qué vías están cortadas (capa de vías),
 * dónde hay albergues (capa con semáforo) y cómo coordinar (cambio de estado con historial en la API).
 */

type FiltroGravedad = Gravedad | 'todas';
type FiltroEstado = EstadoReporte | 'todos';

export function PanelOperaciones() {
  const [reportes, setReportes] = useState<ReporteMapa[]>([]);
  const [puntos, setPuntos] = useState<PuntoServicioMapa[]>([]);
  const [zonas, setZonas] = useState<GeoJSON.FeatureCollection | null>(null);
  const [vias, setVias] = useState<GeoJSON.FeatureCollection | null>(null);
  const [respaldo, setRespaldo] = useState(false);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [seleccionadoId, setSeleccionadoId] = useState<string | null>(null);
  const [guardando, setGuardando] = useState(false);

  const [gravedad, setGravedad] = useState<FiltroGravedad>('todas');
  const [estado, setEstado] = useState<FiltroEstado>('todos');
  const [capas, setCapas] = useState({ albergues: true, salud: true, zonas: true, vias: true });

  const cargar = useCallback(async () => {
    setError(null);
    try {
      const [r, p] = await Promise.all([api.listarReportes(), api.listarPuntos()]);
      setReportes(r.datos.items);
      setPuntos(p.datos);
      setRespaldo(r.respaldo || p.respaldo);
      setSeleccionadoId((actual) => actual ?? r.datos.items[0]?.id ?? null);
      // Capas territoriales: si fallan, el mapa sigue funcionando sin ellas.
      api.zonasGeoJson().then(setZonas).catch(() => setZonas(null));
      api.viasGeoJson().then(setVias).catch(() => setVias(null));
    } catch (e) {
      setError(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar los datos.');
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    void cargar();
  }, [cargar]);

  // Tiempo real: el backend empuja reportes nuevos, cambios de estado y cupos.
  useEffect(() => {
    const url = api.urlTiempoReal();
    if (!url || respaldo) return;
    let ws: WebSocket | null = null;
    try {
      ws = new WebSocket(url);
    } catch {
      return;
    }
    ws.onmessage = (m) => {
      try {
        const evento = JSON.parse(String(m.data));
        if (evento.tipo === 'reporte.creado' || evento.tipo === 'reporte.estado') {
          const r = evento.datos as ReporteMapa;
          setReportes((prev) => [r, ...prev.filter((x) => x.id !== r.id)]);
        } else if (evento.tipo === 'via.estado') {
          api.viasGeoJson().then(setVias).catch(() => {});
        } else if (evento.tipo === 'punto.ocupacion') {
          const p = evento.datos as PuntoServicioMapa;
          setPuntos((prev) => prev.map((x) => (x.id === p.id ? { ...p, estado_cupo: semaforoCupo(p.capacidad, p.ocupacion) } : x)));
        }
      } catch {
        // Mensaje mal formado: se ignora.
      }
    };
    return () => ws?.close();
  }, [respaldo]);

  const filtrados = useMemo(
    () =>
      reportes
        .filter((r) => (gravedad === 'todas' || r.gravedad === gravedad) && (estado === 'todos' || r.estado === estado))
        .sort((a, b) => PESO_GRAVEDAD[b.gravedad] - PESO_GRAVEDAD[a.gravedad] || b.recibido_en.localeCompare(a.recibido_en)),
    [reportes, gravedad, estado],
  );

  const metricas = useMemo(() => {
    const abiertos = reportes.filter((r) => r.estado === 'pendiente' || r.estado === 'en_proceso');
    return {
      abiertos: abiertos.length,
      pendientes: reportes.filter((r) => r.estado === 'pendiente').length,
      criticos: abiertos.filter((r) => r.gravedad === 'critica').length,
      personas: abiertos.reduce((s, r) => s + r.personas_afectadas, 0),
      vulnerables: abiertos.reduce((s, r) => s + r.ninos + r.adultos_mayores, 0),
      albergues: puntos.filter((p) => p.tipo === 'albergue' && p.estado_cupo !== 'rojo').length,
      viasCortadas: (vias?.features ?? []).filter((f) => f.properties?.estado === 'bloqueada').length,
    };
  }, [reportes, puntos, vias]);

  const seleccionado = reportes.find((r) => r.id === seleccionadoId) ?? null;

  async function cambiarEstado(r: ReporteMapa, nuevo: EstadoReporte) {
    setGuardando(true);
    setError(null);
    try {
      // Sin servidor (demo) el cambio es solo local y se avisa con el aviso de respaldo.
      const actualizado = respaldo ? { ...r, estado: nuevo, verificado: true } : await api.cambiarEstadoReporte(r.id, nuevo);
      setReportes((prev) => prev.map((x) => (x.id === r.id ? { ...x, ...actualizado } : x)));
    } catch (e) {
      setError(e instanceof api.ErrorApi ? e.message : 'No se pudo cambiar el estado.');
    } finally {
      setGuardando(false);
    }
  }

  if (cargando) return <Cargando texto="Cargando mapa operativo de Esmeraldas..." />;

  return (
    <div className="op">
      {respaldo && <AvisoRespaldo />}
      {error && <Aviso tipo="peligro" titulo="Algo falló">{error}</Aviso>}

      <section className="er-indicadores" aria-label="Indicadores del escenario">
        <Indicador etiqueta="Incidentes abiertos" valor={metricas.abiertos} detalle={`${metricas.pendientes} sin atender`} tono="primario" />
        <Indicador etiqueta="Críticos" valor={metricas.criticos} detalle="Prioridad de rescate" tono="peligro" />
        <Indicador etiqueta="Personas afectadas" valor={metricas.personas} detalle={`${metricas.vulnerables} niños y adultos mayores`} tono="aviso" />
        <Indicador etiqueta="Albergues con cupo" valor={metricas.albergues} detalle={metricas.viasCortadas === 1 ? '1 vía bloqueada' : `${metricas.viasCortadas} vías bloqueadas`} tono="ok" />
      </section>

      <section className="op-filtros" aria-label="Filtros y capas">
        <div className="er-segmentos" role="group" aria-label="Gravedad">
          {(['todas', 'critica', 'alta', 'media', 'baja'] as const).map((g) => (
            <button key={g} className="er-segmento" aria-pressed={gravedad === g} onClick={() => setGravedad(g)}>
              {g === 'todas' ? 'Todas' : g === 'critica' ? 'Crítica' : g[0]!.toUpperCase() + g.slice(1)}
            </button>
          ))}
        </div>
        <select className="er-select op-filtros__estado" value={estado} onChange={(e) => setEstado(e.target.value as FiltroEstado)} aria-label="Estado">
          <option value="todos">Todos los estados</option>
          <option value="pendiente">Pendiente</option>
          <option value="en_proceso">En proceso</option>
          <option value="atendido">Atendido</option>
          <option value="descartado">Descartado</option>
        </select>
        <div className="op-capas">
          {([
            ['zonas', 'Zonas de riesgo'],
            ['vias', 'Vías'],
            ['albergues', 'Albergues'],
            ['salud', 'Salud'],
          ] as const).map(([clave, texto]) => (
            <label key={clave} className="op-capa">
              <input type="checkbox" checked={capas[clave]} onChange={(e) => setCapas((c) => ({ ...c, [clave]: e.target.checked }))} />
              {texto}
            </label>
          ))}
        </div>
      </section>

      <div className="op-rejilla">
        <section className="er-tarjeta op-lista" aria-label="Incidentes">
          <div className="er-tarjeta__cabecera">
            <h2 className="er-tarjeta__titulo">Incidentes</h2>
            <span className="er-insignia er-num">{filtrados.length}</span>
          </div>
          <ul className="op-lista__items">
            {filtrados.map((r) => (
              <li key={r.id}>
                <button className="op-item" aria-current={r.id === seleccionadoId} onClick={() => setSeleccionadoId(r.id)}>
                  <span className="op-item__fila">
                    <InsigniaGravedad valor={r.gravedad} />
                    <span className="op-item__hora er-num">{horaLocal(r.recibido_en)}</span>
                  </span>
                  <strong className="op-item__titulo">{tituloReporte(r)}</strong>
                  <span className="op-item__fila">
                    <InsigniaEstado valor={r.estado} />
                    {r.personas_afectadas > 0 && (
                      <span className="op-item__personas er-num">
                        <Users size={14} aria-hidden="true" /> {r.personas_afectadas}
                      </span>
                    )}
                  </span>
                </button>
              </li>
            ))}
            {filtrados.length === 0 && <li className="op-lista__vacia">Sin incidentes con esos filtros.</li>}
          </ul>
        </section>

        <section className="er-tarjeta op-mapa-tarjeta" aria-label="Mapa">
          <MapaEsmeraldas
            reportes={filtrados}
            puntosServicio={puntos}
            zonas={zonas}
            vias={vias}
            reporteSeleccionadoId={seleccionadoId}
            onSeleccionarReporte={(r) => setSeleccionadoId(r.id)}
            mostrarAlbergues={capas.albergues}
            mostrarCentrosSalud={capas.salud}
            mostrarZonas={capas.zonas}
            mostrarVias={capas.vias}
          />
          <div className="op-leyenda" aria-hidden="true">
            <span><i className="op-leyenda__sim" /> Simulado</span>
            <span><i className="op-leyenda__ciu" /> Ciudadano</span>
            <span><i className="op-leyenda__via" /> Vía bloqueada</span>
          </div>
        </section>

        <section className="er-tarjeta op-detalle" aria-label="Detalle del incidente">
          {seleccionado ? (
            <div className="er-tarjeta__cuerpo op-detalle__cuerpo">
              <div className="op-item__fila">
                <InsigniaGravedad valor={seleccionado.gravedad} />
                {seleccionado.origen && <InsigniaOrigen valor={seleccionado.origen} />}
              </div>
              <h2 className="op-detalle__titulo">{tituloReporte(seleccionado)}</h2>
              <p className="op-detalle__sector">
                <MapPin size={14} aria-hidden="true" /> {seleccionado.sector ?? 'Fuera de zonas registradas'} · {ETIQUETA_TIPO[seleccionado.tipo]}
              </p>
              <p>{seleccionado.descripcion}</p>

              <dl className="op-datos">
                <div><dt>Personas</dt><dd className="er-num">{seleccionado.personas_afectadas}</dd></div>
                <div><dt>Niños</dt><dd className="er-num">{seleccionado.ninos}</dd></div>
                <div><dt>Adultos mayores</dt><dd className="er-num">{seleccionado.adultos_mayores}</dd></div>
                <div>
                  <dt>GPS</dt>
                  <dd className="er-num">
                    {seleccionado.latitud.toFixed(4)}, {seleccionado.longitud.toFixed(4)}
                    {seleccionado.precision_m ? ` ±${Math.round(seleccionado.precision_m)} m` : ''}
                  </dd>
                </div>
              </dl>

              {seleccionado.necesidades.length > 0 && (
                <div>
                  <div className="er-rotulo">Necesidades</div>
                  <div className="op-necesidades">
                    {seleccionado.necesidades.map((n) => (
                      <span key={n} className="er-insignia">{ETIQUETA_NECESIDAD[n]}</span>
                    ))}
                  </div>
                </div>
              )}

              <div className="op-acciones">
                <div className="op-item__fila">
                  <span className="er-rotulo">Estado</span>
                  <InsigniaEstado valor={seleccionado.estado} />
                </div>
                <Boton variante="primario" bloque disabled={guardando || seleccionado.estado === 'en_proceso'} onClick={() => cambiarEstado(seleccionado, 'en_proceso')}>
                  Despachar unidad
                </Boton>
                <Boton variante="secundario" bloque disabled={guardando || seleccionado.estado === 'atendido'} onClick={() => cambiarEstado(seleccionado, 'atendido')}>
                  Marcar atendido
                </Boton>
              </div>
            </div>
          ) : (
            <p className="op-lista__vacia">Selecciona un incidente en la lista o en el mapa.</p>
          )}
        </section>
      </div>
    </div>
  );
}
