import type { ReporteMapa } from '../types/mapa';

/** Ubicación del navegador: primero GPS preciso; si no hay señal, la aproximada de la red. */
export function obtenerUbicacion(): Promise<GeolocationCoordinates> {
  return new Promise((resolver, rechazar) => {
    if (!('geolocation' in navigator)) {
      rechazar(new Error('Este navegador no permite obtener la ubicación. Elige el lugar en el mapa.'));
      return;
    }
    const fallo = (e: GeolocationPositionError) => {
      rechazar(new Error(e.code === e.PERMISSION_DENIED
        ? 'El navegador bloqueó la ubicación. Actívala en el candado de la barra de direcciones o elige el lugar en el mapa.'
        : 'Este equipo no pudo dar su ubicación. Elige el lugar en el mapa.'));
    };
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => resolver(coords),
      (e) => {
        if (e.code === e.PERMISSION_DENIED) return fallo(e);
        navigator.geolocation.getCurrentPosition(({ coords }) => resolver(coords), fallo, { enableHighAccuracy: false, timeout: 15000, maximumAge: 60000 });
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 30000 },
    );
  });
}

/** Punto temporal para dibujar en el mapa el lugar que se está marcando. */
export const marcadorUbicacion = (u: { latitud: number; longitud: number }, descripcion = 'Ubicación marcada'): ReporteMapa => ({
  id: 'nuevo', tipo: 'otro', descripcion, gravedad: 'alta', estado: 'pendiente',
  latitud: u.latitud, longitud: u.longitud, capturado_en: new Date().toISOString(), recibido_en: new Date().toISOString(),
  verificado: false, personas_afectadas: 0, ninos: 0, adultos_mayores: 0, necesidades: [], sector: null,
});
