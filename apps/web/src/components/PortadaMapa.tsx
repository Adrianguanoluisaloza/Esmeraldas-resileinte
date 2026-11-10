import { MapaEsmeraldas } from './MapaEsmeraldas';

/** Portada: el mapa de Esmeraldas limpio y quieto. Los datos operativos solo se ven con sesión. */
export function PortadaMapa() {
  return (
    <figure className="st-tablero">
      <div className="st-tablero__mapa op-mapa-tarjeta">
        <MapaEsmeraldas reportes={[]} puntosServicio={[]} onSeleccionarReporte={() => {}} soloVista />
      </div>
    </figure>
  );
}
