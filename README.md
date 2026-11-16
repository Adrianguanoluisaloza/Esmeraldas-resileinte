# Esmeraldas Resiliente

Plataforma de gestión de emergencias por el fenómeno El Niño en Esmeraldas: reportes ciudadanos con GPS y foto,
mapa de riesgos, centro de operaciones (COE), albergues, asistencia humanitaria y priorización por sector.

- Web: https://tu-sitio.pages.dev
- API: https://api.tu-dominio.com

| Parte | Tecnología | Carpeta |
|---|---|---|
| Web (COE y ciudadanía) | Astro + React, Leaflet + OpenStreetMap | `apps/web` |
| API | Hono + TypeScript, JWT, WebSocket | `apps/api` |
| Base de datos | PostgreSQL 16 + PostGIS | `database/` |
| App móvil offline | Flutter + Hive | `mobile/` |
| Contrato | OpenAPI 3 | `contrato/openapi.yaml` |

## Arranque rápido

API en memoria (sin base de datos):

```bash
cd apps/api && npm install && npm run build
```

```bash
JWT_SECRET=una-clave-larga-de-al-menos-32-caracteres DEMO_PASSWORD=demo-resiliente-2026 node dist/index.js
```

Web:

```bash
cd apps/web && npm install && PUBLIC_API_URL=http://localhost:3000 npm run dev
```

Todo con PostGIS: `cp .env.example .env`, completar las claves y `docker compose up -d --build`.

## Documentación

- `AGENTS.md`: reglas del proyecto.
- `docs/orquestacion/`: tareas por carril (web, móvil, backend).
- `docs/ARQUITECTURA.md`, `docs/MODELO_DATOS.md`, `docs/ROLES.md`, `docs/MANUAL_USUARIO.md`.
- `docs/DISENO.md`, `docs/DESPLIEGUE.md`, `docs/SEGURIDAD.md`, `docs/PROPUESTAS.md`.
- `apps/api/README.md`: endpoints por módulo del reto.

## Autores, licencia y apoyo

- **Autores:** Adrian Guanoluisa Loza (`@Adrianguanoluisaloza`) y Franco (`@xGeo123`).
- **Licencia:** [Apache License 2.0](LICENSE). Todo uso o redistribución debe conservar la atribución de autoría indicada en [NOTICE](NOTICE).
- **Apoyo y donaciones:** Si el proyecto te resulta útil o deseas apoyar el mantenimiento de la infraestructura y nuevas mejoras para la comunidad, puedes colaborar en [Ko-fi (cifralabapp)](https://ko-fi.com/cifralabapp) o abrir un *Issue* en el repositorio. Para despliegues institucionales dedicados o soporte técnico, coordina directamente con el equipo autor.
