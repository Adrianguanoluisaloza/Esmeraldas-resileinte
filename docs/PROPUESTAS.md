# Propuestas de evolución

Mejoras identificadas que no forman parte de la versión actual.

## Reportar sin datos móviles

Hoy, sin datos ni wifi, la app obtiene la ubicación por satélite y guarda el reporte y la foto en el celular. El envío
ocurre al volver la conexión. El receptor GPS solo escucha a los satélites: no puede transmitir, así que la coordenada
necesita otro canal para llegar al servidor.

| Canal | Requiere | Alcance | Estado |
|---|---|---|---|
| Datos móviles o wifi | Conexión a internet | Reporte completo con foto | Implementado |
| SMS con pasarela | Señal de telefonía, un número propio y un equipo o servicio que reciba los mensajes y los envíe a la API | Coordenada, tipo y personas, sin foto | Propuesta |
| Satelital | Celular compatible con mensajería satelital o dispositivo dedicado, y un operador que entregue los mensajes a la API | Zonas sin ninguna cobertura | Propuesta |

**SMS.** La app ya arma el mensaje con coordenadas y tipo de emergencia. Faltan el número receptor
(`EMERGENCY_SMS_NUMBER`), una ruta autenticada en la API y validar el remitente. Nunca debe apuntar a una línea de
emergencia real sin un convenio con su operador.

**Satelital.** Antes de adoptarla hay que confirmar la disponibilidad del servicio en Ecuador, el costo por mensaje y
la forma de integrar sus mensajes con la API.

## Otras mejoras

| Mejora | Valor |
|---|---|
| Rutas alternas por la red vial con pgRouting | La ruta actual es un tramo recto que detecta vías bloqueadas. |
| Censo de familias como registro propio | Hoy los datos de la familia viven dentro de cada reporte. |
| Sugerencia de tipo y gravedad con IA, confirmada por una persona | La ruta `/reportes/{id}/clasificar` está definida y por implementar. |
| Mapa offline con teselas propias o de un proveedor que lo permita | La política de OpenStreetMap prohíbe el uso offline de sus teselas. |
| Proveedor de teselas contratado | Necesario con tráfico real. Se cambia con `PUBLIC_MAP_TILE_URL`. |
| Fotos en almacenamiento de objetos | Hoy están en un volumen de la VM, detrás de la interfaz `AlmacenFotos`. |
| Datos oficiales de INAMHI, SNGR y GAD | Las zonas y eventos actuales son simulados. |
