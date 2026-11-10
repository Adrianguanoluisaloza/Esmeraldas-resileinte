import { useCallback, useEffect, useMemo, useState } from 'react';
import { MapPin, Pencil, Search, Users } from 'lucide-react';
import { EditarReporte } from './EditarReporte';
import type { EstadoReporte, Gravedad, PuntoServicioMapa, ReporteMapa } from '../types/mapa';
import * as api from '../lib/api';
import { COLOR_GRAVEDAD, coincideBusqueda, compararPorFeed, ETIQUETA_ESTADO, ETIQUETA_NECESIDAD, ETIQUETA_TIPO, PESO_GRAVEDAD, horaLocal, semaforoCupo, tituloReporte } from '../lib/catalogos';
import { MapaEsmeraldas } from './MapaEsmeraldas';
import { Aviso, AvisoRespaldo, Boton, Cargando } from './ui/Basicos';
import { InsigniaEstado, InsigniaGravedad, InsigniaOrigen } from './ui/Insignias';

/**
 * Mapa operativo del COE. Responde las preguntas del escenario Jueves 06:00:
 * qué pasa y dónde (lista + mapa), cuántas personas (indicadores), qué vías están cortadas (capa de vías),
 * dónde hay albergues (capa con semáforo) y cómo coordinar (cambio de estado con historial en la API).
 */

type FiltroGravedad = Gravedad | 'todas';
type FiltroEstado = EstadoReporte | 'todos' | 'activos';

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
  const [estado, setEstado] = useState<FiltroEstado>('activos');
  const [busqueda, setBusqueda] = useState('');
  const [editando, setEditando] = useState(false);
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
        .filter((r) => (gravedad === 'todas' || r.gravedad === gravedad) && (estado === 'todos' || (estado === 'activos' ? r.estado === 'pendiente' || r.estado === 'en_proceso' : r.estado === estado)) && coincideBusqueda(r, busqueda))
        .sort((a, b) => PESO_GRAVEDAD[b.gravedad] - PESO_GRAVEDAD[a.gravedad] || compararPorFeed(a, b)),
    [reportes, gravedad, estado, busqueda],
  );

  // Lo atendido sale de la lista y del mapa: el detalle pasa al siguiente incidente activo.
  useEffect(() => {
    if (cargando || filtrados.some((r) => r.id === seleccionadoId)) return;
    setSeleccionadoId(filtrados[0]?.id ?? null);
    setEditando(false);
  }, [cargando, filtrados, seleccionadoId]);

  const seleccionado = reportes.find((r) => r.id === seleccionadoId) ?? null;

  // La foto del celular llega después del reporte: al abrirlo se pide el dato completo.
  useEffect(() => {
    if (!seleccionadoId || respaldo) return;
    let vigente = true;
    api.obtenerReporte(seleccionadoId).then((d) => {
      if (vigente) setReportes((prev) => prev.map((x) => (x.id === d.id ? { ...x, foto_url: d.foto_url, foto_miniatura_url: d.foto_miniatura_url } : x)));
    }).catch(() => {});
    return () => { vigente = false; };
  }, [seleccionadoId, respaldo]);

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


      <section className="op-filtros" aria-label="Filtros y capas">
        <div className="er-segmentos" role="group" aria-label="Gravedad">
          {(['todas', 'critica', 'alta', 'media', 'baja'] as const).map((g) => (
            <button key={g} className="er-segmento" aria-pressed={gravedad === g} onClick={() => setGravedad(g)}>
              {g === 'todas' ? 'Todas' : g === 'critica' ? 'Crítica' : g[0]!.toUpperCase() + g.slice(1)}
            </button>
          ))}
        </div>
        <select className="er-select op-filtros__estado" value={estado} onChange={(e) => setEstado(e.target.value as FiltroEstado)} aria-label="Estado">
          <option value="activos">Activos</option>
          <option value="todos">Todos los estados</option>
          <option value="pendiente">Pendiente</option>
          <option value="en_proceso">En proceso</option>
          <option value="atendido">Atendido</option>
          <option value="descartado">Descartado</option>
        </select>
        <label className="op-buscar">
          <Search aria-hidden="true" />
          <span className="er-sr">Buscar incidentes</span>
          <input className="er-entrada" type="search" placeholder="Buscar" value={busqueda} onChange={(e) => setBusqueda(e.target.value)} />
        </label>
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
            <span className="pn-sub er-num">{filtrados.length}</span>
          </div>
          <ul className="op-lista__items">
            {filtrados.map((r) => (
              <li key={r.id}>
                <button className="op-item" aria-current={r.id === seleccionadoId} onClick={() => { setSeleccionadoId(r.id); setEditando(false); }}>
                  <span className="op-item__punto" style={{ background: COLOR_GRAVEDAD[r.gravedad] }} aria-hidden="true" />
                  <span className="op-item__cuerpo">
                    <strong className="op-item__titulo">{tituloReporte(r)}</strong>
                    <span className="op-item__meta er-num">
                      {ETIQUETA_ESTADO[r.estado]} · {horaLocal(r.recibido_en)}
                      {r.personas_afectadas > 0 && <> · <Users size={12} aria-hidden="true" /> {r.personas_afectadas}</>}
                    </span>
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
            <span><i className="op-leyenda__proceso" /> En atención</span>
            <span><i className="op-leyenda__via" /> Vía cerrada</span>
            <span><i className="op-leyenda__parcial" /> Paso parcial</span>
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
              {editando ? (
                <EditarReporte
                  reporte={seleccionado}
                  alCancelar={() => setEditando(false)}
                  alGuardar={(r) => {
                    setReportes((prev) => prev.map((x) => (x.id === r.id ? { ...x, ...r } : x)));
                    setEditando(false);
                  }}
                />
              ) : (
                <p>{seleccionado.descripcion}</p>
              )}
              {seleccionado.foto_url && (
                <a href={`${api.BASE}${seleccionado.foto_url}`} target="_blank" rel="noopener noreferrer">
                  <img className="pn-foto" src={`${api.BASE}${seleccionado.foto_miniatura_url ?? seleccionado.foto_url}`} alt={`Foto del reporte: ${tituloReporte(seleccionado)}`} loading="lazy" />
                </a>
              )}

              <dl className="op-datos">
                <div><dt>Personas</dt><dd className="er-num">{seleccionado.personas_afectadas}</dd></div>
                <div><dt>Niños</dt><dd className="er-num">{seleccionado.ninos}</dd></div>
                <div><dt>Adultos mayores</dt><dd className="er-num">{seleccionado.adultos_mayores}</dd></div>
                <div>
                  <dt>GPS</dt>
                  <dd className="er-num">
                    {seleccionado.latitud.toFixed(4)}, {seleccionado.longitud.toFixed(4)}
                    {seleccionado.ubicacion_aproximada ? ' · aproximada' : seleccionado.precision_m ? ` ±${Math.round(seleccionado.precision_m)} m` : ''}
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
                {!editando && !respaldo && <Boton variante="fantasma" tamano="sm" bloque onClick={() => setEditando(true)}><Pencil aria-hidden="true" /> Editar reporte</Boton>}
                <Boton variante="primario" tamano="sm" bloque disabled={guardando || seleccionado.estado === 'en_proceso'} onClick={() => cambiarEstado(seleccionado, 'en_proceso')}>
                  Despachar unidad
                </Boton>
                <Boton variante="secundario" tamano="sm" bloque disabled={guardando || seleccionado.estado === 'atendido'} onClick={() => cambiarEstado(seleccionado, 'atendido')}>
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
