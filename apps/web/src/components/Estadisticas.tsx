import { useEffect, useState } from 'react';
import * as api from '../lib/api';
import { ETIQUETA_NECESIDAD } from '../lib/catalogos';
import type { Necesidad } from '../types/mapa';
import { Aviso, Cargando, Indicador } from './ui/Basicos';
import { InsigniaGravedad } from './ui/Insignias';

export function Estadisticas() {
  const [datos, setDatos] = useState<api.Estadisticas | null>(null);
  const [sectores, setSectores] = useState<api.SectorPrioridad[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([api.estadisticas(), api.prioridadSectores()])
      .then(([e, s]) => {
        setDatos(e);
        setSectores(s);
      })
      .catch((e) => setError(e instanceof api.ErrorApi ? e.message : 'No se pudieron cargar los indicadores.'));
  }, []);

  if (error) return <Aviso tipo="peligro">{error}</Aviso>;
  if (!datos || !sectores) return <Cargando />;

  const maxNecesidad = Math.max(1, ...Object.values(datos.necesidades_acumuladas));

  return (
    <div className="pn-bloque">
      <section className="er-indicadores">
        <Indicador etiqueta="Reportes" valor={datos.total_reportes} detalle={`${datos.pendientes} pendientes · ${datos.en_proceso} en proceso · ${datos.atendidos} atendidos`} tono="primario" />
        <Indicador etiqueta="Críticos abiertos" valor={datos.criticos} tono="peligro" />
        <Indicador etiqueta="Personas afectadas" valor={datos.personas_afectadas_total} detalle={`${datos.ninos_total} niños · ${datos.adultos_mayores_total} adultos mayores`} tono="aviso" />
        <Indicador etiqueta="Albergues con cupo" valor={datos.albergues_disponibles} detalle={`${datos.vias_bloqueadas_total} vías bloqueadas`} tono="ok" />
      </section>

      <div className="pn-dos-columnas">
        <section className="er-tarjeta">
          <div className="er-tarjeta__cabecera"><h2 className="er-tarjeta__titulo">Sectores por prioridad</h2></div>
          <div className="er-tabla-contenedor pn-sin-borde">
            <table className="er-tabla">
              <thead>
                <tr>
                  <th scope="col">Sector</th>
                  <th scope="col">Abiertos</th>
                  <th scope="col">Personas</th>
                  <th scope="col">Gravedad</th>
                  <th scope="col">Puntaje</th>
                </tr>
              </thead>
              <tbody>
                {sectores.map((s) => (
                  <tr key={s.sector}>
                    <td><strong>{s.sector}</strong><div className="pn-sub">{s.cantidad} {s.cantidad === 1 ? 'evento' : 'eventos'}</div></td>
                    <td className="er-num">{s.abiertos}</td>
                    <td className="er-num">{s.personas_afectadas}</td>
                    <td><InsigniaGravedad valor={s.gravedad_promedio} /></td>
                    <td className="er-num"><strong>{s.puntaje}</strong></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section className="er-tarjeta">
          <div className="er-tarjeta__cabecera"><h2 className="er-tarjeta__titulo">Necesidades abiertas</h2></div>
          <ul className="pn-lista">
            {(Object.entries(datos.necesidades_acumuladas) as [Necesidad, number][]).map(([n, v]) => (
              <li key={n} className="pn-barra-dato">
                <span>{ETIQUETA_NECESIDAD[n]}</span>
                <div className="er-barra"><div className="er-barra__relleno" style={{ width: `${(v / maxNecesidad) * 100}%`, background: 'var(--er-primary)' }} /></div>
                <strong className="er-num">{v}</strong>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}
