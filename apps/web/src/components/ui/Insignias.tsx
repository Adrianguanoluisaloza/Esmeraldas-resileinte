import type { EstadoCupo, EstadoReporte, Gravedad, OrigenDato } from '../../types/mapa';
import { ETIQUETA_CUPO, ETIQUETA_ESTADO, ETIQUETA_GRAVEDAD, ETIQUETA_ORIGEN } from '../../lib/catalogos';

/**
 * Insignias que muestran DATOS (gravedad, estado, origen, cupo). Siempre con texto, nunca solo color,
 * para que se entiendan en blanco y negro y con daltonismo. Estilos en src/styles/ui.css.
 */

export function InsigniaGravedad({ valor }: { valor: Gravedad }) {
  return (
    <span className={`er-insignia er-insignia--grav-${valor}`}>
      <span className="er-insignia__punto" aria-hidden="true" />
      {ETIQUETA_GRAVEDAD[valor]}
    </span>
  );
}

export function InsigniaEstado({ valor }: { valor: EstadoReporte }) {
  return <span className={`er-insignia er-insignia--estado-${valor}`}>{ETIQUETA_ESTADO[valor]}</span>;
}

export function InsigniaOrigen({ valor }: { valor: OrigenDato }) {
  return <span className={`er-insignia er-insignia--origen-${valor}`}>{ETIQUETA_ORIGEN[valor]}</span>;
}

export function InsigniaCupo({ valor }: { valor: EstadoCupo }) {
  return (
    <span className={`er-insignia er-insignia--cupo-${valor}`}>
      <span className="er-insignia__punto" aria-hidden="true" />
      {ETIQUETA_CUPO[valor]}
    </span>
  );
}
