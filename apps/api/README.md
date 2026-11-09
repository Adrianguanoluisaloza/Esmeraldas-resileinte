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

## Estado de endpoints

| Endpoint | Estado |
|---|---|
| `GET /salud` | listo |
| `POST /auth/login`, `POST /auth/registro` | listo (registro siempre crea ciudadano) |
| `POST /reportes` (idempotente por UUID), `GET /reportes`, `GET /reportes/{id}`, `PATCH /reportes/{id}/estado` | listo |
| `POST /reportes/{id}/foto` | listo (JPEG/PNG por bytes reales, 2 MB, miniatura con sharp si está) |
| `GET /zonas`, `GET /vias` (GeoJSON) | listo |
| `GET /puntos-servicio`, `GET /puntos-servicio/cercanos`, `PATCH .../ocupacion` | listo |
| `GET /ws?token=` | listo (eventos filtrados por rol) |
| `GET/POST /alertas`, `GET /estadisticas`, `GET /estadisticas/recurrencia`, `POST /reportes/{id}/clasificar` | **501**, ver `docs/orquestacion/TAREAS_BACKEND.md` |

## Errores

Siempre `{ "codigo": "...", "mensaje": "...", "errores": [] }`. Códigos: `VALIDACION` 400, `NO_AUTENTICADO` 401,
`SIN_PERMISO` 403, `NO_ENCONTRADO` 404, `CONFLICTO` 409, `TRANSICION_INVALIDA` 422, `NO_IMPLEMENTADO` 501,
`ERROR_INTERNO` 500 (con `id` de petición para buscar en el registro).

## Seguridad aplicada

Consultas parametrizadas, validación estricta con zod (campos extra rechazados), coordenadas limitadas a la
provincia, scrypt para claves, JWT HS256 con expiración, CORS por lista, cabeceras seguras, límite de cuerpo,
límite de intentos de login, registro sin cuerpo ni coordenadas, ciudadano solo ve lo suyo.
