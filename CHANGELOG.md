# Changelog

Todos los cambios relevantes del proyecto se registran aquí. Se sigue una estructura compatible con versionado semántico cuando el proyecto tenga versiones publicadas.

## [Unreleased]

### Added

- Reglas de colaboración y arquitectura en `AGENTS.md`.
- Bitácora inicial del proyecto en `bitacora.md`.
- Definición base del stack: Flutter, OpenStreetMap, Astro, React y Cloudflare.
- Proyecto Astro inicial en `apps/web` con React y Vite configurados.
- Dependencias de mapas y ubicación para web y Flutter.
- Proyecto Flutter inicial en `apps/mobile`.
- Guía de teselas, atribución y conexión OAuth 2.0 de OpenStreetMap en `docs/OPENSTREETMAP.md`.
- Plantillas de variables de entorno para desarrollo, Cloudflare y distribución móvil.
- Esqueleto de la aplicación Flutter en `mobile/` con Clean Architecture, cola offline en `hive_ce`, flujo de sincronización en dos pasos (`POST /reportes` y `POST /reportes/:id/foto`) y directorio de albergues con respaldo sin internet.
- Integración de `TAREAS_MOVIL_FRANCO.md` (M1–M5) en `mobile/`: `DioApiClient` real con interceptor JWT y mapeo de `Failure`s, login/registro y botón de Google OAuth con PKCE, mapa de Esmeraldas (`FlutterMap`) de fondo con respaldo vectorial offline, navegación inferior por rol (ciudadano, operador 911 y administrador), paleta de `docs/DISENO.md` sin emojis y búsqueda de albergue más cercano.
- Flujo de inicio ciudadano en 3 pasos sobre el mapa de Esmeraldas (`CrearReportePage`): mapa interactivo y seleccionable con botón lateral de ubicación GPS (`Geolocator`) y botón inferior de reporte, tarjeta de confirmación de coordenadas y formulario flotante.
- Configuración de autenticación OAuth de Google desde `google-services.json` (`esmeralsrelesiente`) en `mobile/android/app/`, exclusión en `.gitignore` y compilación de `app-release.apk` con Android SDK 36 y OpenJDK 21.
- API TypeScript en `apps/api/` con autenticación, reportes, territorio, pendientes, tiempo real y pruebas de API/dominio.
- Persistencia PostGIS con esquema y datos iniciales en `database/`, además de configuración de desarrollo local con `docker-compose.yml`.
- Repositorios de memoria como respaldo de desarrollo y configuración del backend mediante variables de entorno, sin incluir secretos en Git.
- Sincronización automática inmediata al crear reportes ciudadanos en `mobile/`, visualización de pines de incidentes interactivos en el mapa inicial (`MapaFondoEsmeraldas`) tanto online como en modo offline vectorial, e integración de la cola local de Hive con `OperacionesRepository`.
- Flujo real de captura fotográfica y permisos nativos en `mobile/` (`PhotoCaptureService` con `image_picker`, `flutter_image_compress` y `path_provider`): selector de cámara o galería, manejo de permisos (`CAMERA`, `READ_MEDIA_IMAGES`, `NSCameraUsageDescription`), compresión a 1280 px (JPEG 75%) fuera de Hive y previsualización de miniatura con tamaño en KB.
- Inicialización automática de esquema y semilla en PostgreSQL (`asegurarEsquemaPostgres` en `apps/api`) con compatibilidad para PostGIS nativo y PostgreSQL 18 estándar, y creación automática de cuentas demo web y móvil en `ALMACEN=postgres`.

### Planned

- Crear la aplicación Flutter con Clean Architecture.
- Crear la web Astro con componentes React puntuales.
- Configurar mapas, atribuciones y proveedor de teselas OpenStreetMap.
- Configurar despliegue web en Cloudflare Pages.
- Configurar builds y distribución para Android e iOS.
