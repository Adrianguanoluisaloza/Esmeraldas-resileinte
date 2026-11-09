import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { AlertTriangle, CheckCircle2, CircleDashed, Info, OctagonAlert } from 'lucide-react';
import type { EstadoCupo } from '../../types/mapa';

/** Componentes base para las islas React. Mismas clases que se usan en los .astro (src/styles/ui.css). */

type VarianteBoton = 'primario' | 'secundario' | 'fantasma' | 'peligro' | 'emergencia';

export function Boton({
  variante = 'secundario',
  tamano,
  bloque,
  className = '',
  type = 'button',
  ...resto
}: ButtonHTMLAttributes<HTMLButtonElement> & { variante?: VarianteBoton; tamano?: 'sm' | 'lg'; bloque?: boolean }) {
  const clases = ['er-btn', `er-btn--${variante}`, tamano && `er-btn--${tamano}`, bloque && 'er-btn--bloque', className]
    .filter(Boolean)
    .join(' ');
  return <button type={type} className={clases} {...resto} />;
}

type TipoAviso = 'info' | 'ok' | 'aviso' | 'peligro' | 'simulado';
const ICONO_AVISO = { info: Info, ok: CheckCircle2, aviso: AlertTriangle, peligro: OctagonAlert, simulado: CircleDashed };

export function Aviso({ tipo = 'info', titulo, children }: { tipo?: TipoAviso; titulo?: string; children?: ReactNode }) {
  const Icono = ICONO_AVISO[tipo];
  return (
    <div className={`er-aviso er-aviso--${tipo}`} role={tipo === 'peligro' ? 'alert' : 'status'}>
      <Icono aria-hidden="true" />
      <div>
        {titulo && <div className="er-aviso__titulo">{titulo}</div>}
        {children}
      </div>
    </div>
  );
}

/** Aviso estándar cuando la pantalla muestra datos simulados porque la API no respondió. */
export function AvisoRespaldo() {
  return (
    <Aviso tipo="simulado" titulo="Mostrando datos simulados del escenario">
      No hay conexión con el servidor. Los cambios no se guardarán hasta que vuelva la conexión.
    </Aviso>
  );
}

type TonoIndicador = 'primario' | 'peligro' | 'aviso' | 'ok';

export function Indicador({ etiqueta, valor, detalle, tono }: { etiqueta: string; valor: ReactNode; detalle?: string; tono?: TonoIndicador }) {
  return (
    <div className={`er-indicador${tono ? ` er-indicador--${tono}` : ''}`}>
      <div className="er-indicador__etiqueta">{etiqueta}</div>
      <div className="er-indicador__valor">{valor}</div>
      {detalle && <div className="er-indicador__detalle">{detalle}</div>}
    </div>
  );
}

export function BarraCapacidad({ ocupacion, capacidad, estado }: { ocupacion: number; capacidad: number; estado: EstadoCupo }) {
  const pct = capacidad > 0 ? Math.min(100, Math.round((ocupacion / capacidad) * 100)) : 100;
  return (
    <div className="er-barra" role="progressbar" aria-valuemin={0} aria-valuemax={capacidad} aria-valuenow={ocupacion} aria-label={`Ocupación ${pct} %`}>
      <div className={`er-barra__relleno${estado === 'verde' ? '' : ` er-barra__relleno--${estado}`}`} style={{ width: `${pct}%` }} />
    </div>
  );
}

export function Cargando({ texto = 'Cargando...' }: { texto?: string }) {
  return (
    <div className="er-cargando" role="status">
      <div className="er-giro" aria-hidden="true" />
      {texto}
    </div>
  );
}

export function EstadoVacio({ titulo, texto, children }: { titulo: string; texto?: string; children?: ReactNode }) {
  return (
    <div className="er-vacio">
      <CircleDashed aria-hidden="true" />
      <div className="er-vacio__titulo">{titulo}</div>
      {texto && <p className="er-vacio__texto">{texto}</p>}
      {children}
    </div>
  );
}
