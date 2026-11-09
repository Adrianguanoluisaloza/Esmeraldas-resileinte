# Changelog

Todos los cambios relevantes del proyecto se registran aquí. Se sigue una estructura compatible con versionado semántico cuando el proyecto tenga versiones publicadas.

## [Unreleased]

### Added

- Mapa offline en formato MBTiles 1.3 (`mobile/assets/mapas/esmeraldas.mbtiles`, 155 teselas OpenMapTiles/OpenStreetMap de la Provincia de Esmeraldas `z=8..15`) con proveedor híbrido `EsmeraldasHybridTileProvider` y `sqflite`.
- Envío de punto GPS de emergencia por SMS (`TelephonyService` con `another_telephony`) y captura GPS forzada de hardware (`AndroidSettings(forceLocationManager: true)`) en `LocalLocationService` y `CrearReportePage`.
- Verificación de máquina de estados de la cola offline (`SyncWorkerService` y `MisReportesPage`): eliminación de todos los datos demo/semillas falsas, validación estricta del contrato Zod (`ReporteEntrada`), reintento manual con `forzar: true` y visualización de errores en la cola.
- Inventario de agua, alimentos y medicinas: la entrega descuenta stock en la misma transacción y no permite entregar más de lo que hay.
- Ruta de evacuación: los albergues cuyo camino cruza una vía bloqueada se marcan y van al final (PostGIS `ST_Intersects`).
- Nuevo reporte web: marcar la ubicación tocando el mapa cuando no hay GPS.

- Alertas por sector, estado de vías, estadísticas del COE, sectores priorizados y asistencia humanitaria (pendientes y entregas) en API y web.
- Detalle de reporte con historial de atención, formulario web de nuevo reporte y ajuste de ocupación de albergues.
- Usuario de base de datos con permisos mínimos, auditoría de solo inserción y hoja de seguridad (`docs/SEGURIDAD.md`).
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
- Modo de ejecución local en memoria para `apps/api` con seed automático de cuentas demo (`@demo.esmeraldas-resiliente.ec`) y 6 eventos del escenario oficial "Jueves 06:00 AM". Integradación total local web↔API.
- Esqueleto de la aplicación Flutter en `mobile/` con Clean Architecture, cola offline en `hive_ce`, flujo de sincronización en dos pasos (`POST /reportes` y `POST /reportes/:id/foto`) y directorio de albergues con respaldo sin internet.
- Integración de `TAREAS_MOVIL_FRANCO.md` (M1–M5) en `mobile/`: `DioApiClient` real con interceptor JWT y mapeo de `Failure`s, login/registro y botón de Google OAuth con PKCE, mapa de Esmeraldas (`FlutterMap`) de fondo con respaldo vectorial offline, navegación inferior por rol (ciudadano, operador 911 y administrador), paleta de `docs/DISENO.md` sin emojis y búsqueda de albergue más cercano.
- Corrección de mapa offline en Flutter (`MapaFondoEsmeraldas`): ahora mantiene marcadores de incidentes, albergues y pin de reporte visibles sobre el mapa vectorial sin conexión.
- Admisión de reportes de emergencia offline en la API (`POST /reportes`) para ciudadanos sin sesión previa, permitiendo sincronización inmediata al recuperar cobertura.
- Guía de conectividad y credenciales demo empaquetadas para Franco (`mobile/GUIA_RAPIDA_FRANCO.md`, `mobile/acceso_franco_demo.zip`).

### Changed

- Interfaz compacta estilo Vercel (Geist, tamaños menores, sin sombras); mapa operativo sin contadores y en una sola pantalla.
- El login ya no entra en modo local sin servidor: muestra el error de conexión con la URL de la API.

- Portada y acceso rehechos con el sistema de diseño; menú sin marcas "Pronto"; sin subtítulos ni textos de relleno.
- Repositorio ordenado: documentos en `docs/arquitectura` y `docs/movil`; se quitan `backend/` y `frontend/` vacíos.
- La clasificación automática queda fuera de alcance (`/reportes/{id}/clasificar` responde 501).
- Esqueleto de la aplicación Flutter en `mobile/` con Clean Architecture, cola offline en `hive_ce`, flujo de sincronización en dos pasos (`POST /reportes` y `POST /reportes/:id/foto`) y directorio de albergues con respaldo sin internet.
- Integración de `TAREAS_MOVIL_FRANCO.md` (M1–M5) en `mobile/`: `DioApiClient` real con interceptor JWT y mapeo de `Failure`s, login/registro y botón de Google OAuth con PKCE, mapa de Esmeraldas (`FlutterMap`) de fondo con respaldo vectorial offline, navegación inferior por rol (ciudadano, operador 911 y administrador), paleta de `docs/DISENO.md` sin emojis y búsqueda de albergue más cercano.
- Flujo de inicio ciudadano en 3 pasos sobre el mapa de Esmeraldas (`CrearReportePage`): mapa interactivo y seleccionable con botón lateral de ubicación GPS (`Geolocator`) y botón inferior de reporte, tarjeta de confirmación de coordenadas y formulario flotante.
- Configuración de autenticación OAuth de Google desde `google-services.json` (`esmeralsrelesiente`) en `mobile/android/app/`, exclusión en `.gitignore` y compilación de `app-release.apk` con Android SDK 36 y OpenJDK 21.
- Sincronización automática inmediata al crear reportes ciudadanos en `mobile/`, visualización de pines de incidentes interactivos en el mapa inicial (`MapaFondoEsmeraldas`) tanto online como en modo offline vectorial, e integración de la cola local de Hive con `OperacionesRepository`.
- Flujo real de captura fotográfica y permisos nativos en `mobile/` (`PhotoCaptureService` con `image_picker`, `flutter_image_compress` y `path_provider`): selector de cámara o galería, manejo de permisos (`CAMERA`, `READ_MEDIA_IMAGES`, `NSCameraUsageDescription`), compresión a 1280 px (JPEG 75%) fuera de Hive y previsualización de miniatura con tamaño en KB.
- Integración de tareas `M6`, `M10` y `M11` de `TAREAS_MOVIL_FRANCO.md` en `mobile/` con el backend oficial (`origin/backend`): envío de reportes de emergencia anónimos sin cabecera `Authorization` cuando no hay sesión activa, omisión del Paso 2 de foto cuando no existe archivo real (sin subir JPEG de relleno), manejo de `401` conservando la cola de Hive y visualización de alertas activas (`GET /alertas`) en `DirectorioAlberguesPage`.
- Sincronización de incidentes georreferenciados (`GET /reportes?limite=100`), albergues/centros de salud (`GET /puntos-servicio`) y alertas (`GET /alertas`) desde el backend en vivo hacia `OperacionesRepository` y `MapaFondoEsmeraldas`, más envío de acciones de operador (`PATCH /reportes/:id/estado`, `PATCH /albergues/:id/ocupacion`, `POST /alertas`) y semilla local idéntica a `database/02_seed_escenario_06am.sql`.

### Changed

- `/mapa` redirige a `/panel`. El login usa la API real y redirige según el rol.
- Contrato OpenAPI: YAML corregido; se agregan origen del dato, `/vias`, `/puntos-servicio/cercanos`, WebSocket y formato de error.
- Cuentas demo con dominio `@demo.esmeraldas-resiliente.ec`.

### Security

- CORS sin coincidencias parciales: lista exacta y localhost solo fuera de producción.
- Reporte de emergencia sin cuenta guardado como anónimo (antes fallaba en PostGIS); foto anónima una vez y dentro de 2 horas.
- Se retiran del repo el zip y el txt de accesos; `.gitignore` los bloquea.
- Popups del mapa escapan el texto de los reportes (evita XSS).

### Planned

- Crear la aplicación Flutter con Clean Architecture.
- Crear la web Astro con componentes React puntuales.
- Configurar mapas, atribuciones y proveedor de teselas OpenStreetMap.
- Configurar despliegue web en Cloudflare Pages.
- Configurar builds y distribución para Android e iOS.
