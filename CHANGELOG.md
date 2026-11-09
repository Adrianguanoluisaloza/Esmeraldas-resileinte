# Changelog

Todos los cambios relevantes del proyecto se registran aquí. Se sigue una estructura compatible con versionado semántico cuando el proyecto tenga versiones publicadas.

## [Unreleased]

### Added

- API `apps/api` (Hono + TypeScript) con PostgreSQL + PostGIS: autenticación JWT, reportes idempotentes, fotos, zonas y vías en GeoJSON, albergues cercanos por distancia real y WebSocket para el COE.
- Esquema y semilla del escenario Jueves 06:00 en `database/` y `docker-compose.yml` para local y Oracle Cloud.
- Sistema de diseño web (`src/styles/tokens.css`, `ui.css`) con la paleta de la app móvil, modo oscuro y componentes reutilizables.
- Panel con barra lateral por rol en `/panel`: mapa operativo, reportes, albergues y las pantallas ciudadanas.
- Documentación de diseño, despliegue y tareas por carril en `docs/`.

- Reglas de colaboración y arquitectura en `AGENTS.md`.
- Bitácora inicial del proyecto en `bitacora.md`.
- Definición base del stack: Flutter, OpenStreetMap, Astro, React y Cloudflare.
- Proyecto Astro inicial en `apps/web` con React y Vite configurados.
- Dependencias de mapas y ubicación para web y Flutter.
- Proyecto Flutter inicial en `apps/mobile`.
- Guía de teselas, atribución y conexión OAuth 2.0 de OpenStreetMap en `docs/OPENSTREETMAP.md`.
- Plantillas de variables de entorno para desarrollo, Cloudflare y distribución móvil.
- Estructura del monorepo y responsabilidades de las ramas documentadas en `AGENTS.md` y `estructura-esmeraldas-resiliente.md`.
- Librería `lucide-react` y sustitución de emojis por iconos accesibles en la interfaz web.
- Rediseño de la portada web en `apps/web/src/pages/index.astro` con estética SaaS minimalista (Remote.com): red de nodos territoriales, llamadas a la acción e instituciones aliadas.
- Centro de Mando y gestión de emergencias en `apps/web/src/pages/mapa.astro` con mapa interactivo Leaflet/OpenStreetMap, KPIs, filtros y lista de incidentes en tema claro y limpio.
- Módulo de autenticación en `apps/web/src/pages/login.astro` con diseño unificado blanco, roles para demostración y persistencia de sesión.

### Changed

- `/mapa` redirige a `/panel`. El login usa la API real y redirige según el rol.
- Contrato OpenAPI: YAML corregido; se agregan origen del dato, `/vias`, `/puntos-servicio/cercanos`, WebSocket y formato de error.
- Cuentas demo con dominio `@demo.esmeraldas-resiliente.ec`.

### Security

- Popups del mapa escapan el texto de los reportes (evita XSS).

### Planned

- Crear la aplicación Flutter con Clean Architecture.
- Crear la web Astro con componentes React puntuales.
- Configurar mapas, atribuciones y proveedor de teselas OpenStreetMap.
- Configurar despliegue web en Cloudflare Pages.
- Configurar builds y distribución para Android e iOS.
