# API Esmeraldas Resiliente (`apps/api`)

Hono + TypeScript sobre Node 22, PostgreSQL 16 + PostGIS. Contrato: `contrato/openapi.yaml`.

## Capas (Clean Architecture)

```text
src/
  dominio/          reglas puras: catálogos, semáforo, transiciones, puertos (interfaces). Sin HTTP ni SQL.
  aplicacion/       casos de uso (CasosReportes, CasosTerritorio, CasosAuth). Usan solo puertos.
  infraestructura/  implementaciones: memoria/ (demo y pruebas), postgres/ (PostGIS), seguridad/ (scrypt, JWT), fotos.
  http/             Hono: validación zod (esquemas.ts), rutas, errores, WebSocket.
  componer.ts       ÚNICO lugar que elige implementaciones (memoria o postgres).
  index.ts          arranca el servidor.
```

Regla: las dependencias apuntan hacia `dominio/`. Una ruta nunca importa `pg`; un caso de uso nunca importa `hono`.

## Comandos

```bash
npm install
```

```bash
JWT_SECRET=una-clave-larga-de-al-menos-32-caracteres DEMO_PASSWORD=demo-resiliente-2026 npm run dev
```

```bash
npm run ci
```

```bash
TEST_DATABASE_URL=postgres://usuario:clave@localhost:5432/resiliente npm run test:db
```

`npm test` corre en memoria. `test:db` corre la misma suite contra una base con `database/01` y `02` cargados.

## Endpoints

| Módulo del reto | Endpoint | Acceso |
|---|---|---|
| — | `GET /salud` | público |
| — | `POST /auth/login`, `POST /auth/registro` | público (registro siempre crea ciudadano) |
| 1 GIS | `GET /zonas`, `GET /vias` (GeoJSON) | público |
| 1 GIS | `PATCH /vias/{id}/estado` | COE |
| 2 Ciudadanía | `POST /reportes` (idempotente por UUID), `POST /reportes/{id}/foto` | sesión |
| 2 Ciudadanía | `GET /reportes`, `GET /reportes/{id}` (con historial) | sesión (ciudadano solo lo suyo) |
| 3 COE | `PATCH /reportes/{id}/estado` | COE |
| 3 COE | `GET /alertas` (vigentes) | público |
| 3 COE | `POST /alertas`, `PATCH /alertas/{id}/cerrar`, `GET /alertas?todas=true` | COE |
| 3 COE | `GET /estadisticas` | COE |
| 4 Evacuación | `GET /puntos-servicio`, `GET /puntos-servicio/cercanos?lat&lng&personas` (marca `paso_bloqueado`) | público |
| 4 Evacuación | `PATCH /puntos-servicio/{id}/ocupacion` | COE |
| 5 Asistencia | `GET /asistencia/pendientes`, `GET/POST /asistencia/entregas` (descuenta stock) | COE |
| 5 Asistencia | `GET /asistencia/inventario`, `PATCH /asistencia/inventario/{necesidad}` | COE |
| 6 Análisis | `GET /estadisticas/recurrencia` (sectores priorizados con reglas explicables) | COE |
| — | `GET /ws?token=` (tiempo real filtrado por rol) | sesión |
| fuera de alcance | `POST /reportes/{id}/clasificar` | responde 501 |

## Errores

Siempre `{ "codigo": "...", "mensaje": "...", "errores": [] }`. Códigos: `VALIDACION` 400, `NO_AUTENTICADO` 401,
`SIN_PERMISO` 403, `NO_ENCONTRADO` 404, `CONFLICTO` 409, `TRANSICION_INVALIDA` 422, `NO_IMPLEMENTADO` 501,
`DEMASIADAS_PETICIONES` 429, `ERROR_INTERNO` 500 (con `id` de petición para buscar en el registro).

## Seguridad

Ver `docs/SEGURIDAD.md`.
