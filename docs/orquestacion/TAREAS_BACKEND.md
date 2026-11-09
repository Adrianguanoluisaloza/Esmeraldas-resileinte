# Tareas backend pendientes (`apps/api`)

El esqueleto está listo y probado (memoria y PostGIS). Lo pendiente responde `501 NO_IMPLEMENTADO` desde
`src/http/rutas/pendientes.ts`. Receta para cada una:

1. Puerto en `src/dominio/puertos.ts` (si necesita datos nuevos).
2. Implementación en `infraestructura/memoria/` **y** `infraestructura/postgres/` (las dos, para que las pruebas
   y la demo sin Docker sigan funcionando).
3. Caso de uso en `src/aplicacion/`.
4. Ruta en su propio archivo de `src/http/rutas/` y quitarla de `pendientes.ts`.
5. Pruebas en `test/api.test.ts`. Correr `npm run ci` y `npm run test:db`.
6. Actualizar `contrato/openapi.yaml` si cambió algo, y avisar a web y móvil.

| Id | Endpoint | Notas |
|---|---|---|
| B1 | `GET /alertas`, `POST /alertas` | Tabla `alertas` ya existe. POST solo COE. Publicar `alerta.emitida` en el bus (WebSocket). `origen`: oficial o simulada |
| B2 | `GET /estadisticas` | Una consulta SQL con `count(*) FILTER (WHERE ...)` y suma de necesidades con `unnest`. Responde las preguntas 1, 3, 5 y 6 del escenario |
| B3 | `GET /estadisticas/recurrencia` | `GROUP BY sector`, cantidad y gravedad promedio; base para priorizar (pregunta 4) |
| B4 | `GET /reportes/{id}` con `historial` | Unir `reportes_historial` (ya se llena en cada cambio de estado) |
| B5 | `POST /reportes/{id}/clasificar` | Puerto `ClasificadorIA`. Primero reglas explicables (palabras clave + personas + vulnerables); luego microservicio Python/scikit-learn por HTTP. Siempre con aviso "sugerencia, requiere confirmación humana" |
| B6 | `PATCH /vias/{id}/estado` | Marcar vía bloqueada desde el COE; publicar evento para redibujar el mapa |
| B7 | Ruta de evacuación | `cercanos` que descarte albergues cuyo camino cruce una vía bloqueada (`ST_Intersects` con un buffer). Valor GIS alto para el jurado |
| B8 | Módulo 5 asistencia | `03_asistencia.sql`: familias, inventario, entregas con transacción. Datos personales: acceso solo COE |

Límites conocidos del esqueleto (para producción, no para el hackathon):
- Límite de intentos de login en memoria del proceso: si hay varias instancias, moverlo a la base o a Redis.
- `CREATE TABLE` sin herramienta de migraciones: al pasar a uso real, adoptar migraciones numeradas.
- Fotos en disco local: implementar `AlmacenFotos` para Oracle Object Storage o R2.
