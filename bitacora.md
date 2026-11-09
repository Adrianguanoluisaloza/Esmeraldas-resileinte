# Bitácora del proyecto

Este documento registra decisiones, avances, bloqueos y pendientes importantes. Debe mantenerse breve y orientado a hechos verificables.

## Formato de entrada

```markdown
## AAAA-MM-DD
- **Área:** mobile | web | infraestructura | producto
- **Cambio:** qué se hizo.
- **Decisión:** qué se decidió y por qué, si aplica.
- **Validación:** comandos, pruebas o revisión realizada.
- **Pendientes:** siguiente acción o bloqueo.
```

## 2026-11-09
- **Área:** arquitectura
- **Cambio:** Se definieron las reglas iniciales para Flutter, Astro, React, OpenStreetMap y Cloudflare.
- **Decisión:** La aplicación móvil seguirá Clean Architecture con principios SOLID; la web usará Astro con React como islas interactivas.
- **Validación:** Workspace revisado; inicialmente solo contiene el archivo de configuración `.code-workspace`.
- **Pendientes:** Crear los proyectos `apps/mobile` y `apps/web`, definir el proveedor de teselas, elegir estrategia de estado en Flutter y configurar CI/CD.

## 2026-11-09
- **Área:** web
- **Cambio:** Se inicializó `apps/web` con Astro y la plantilla mínima; se añadió la integración oficial de React.
- **Versiones:** Node.js `v26.13.0`, npm `11.20.0`, Astro `7.4.7`, React `19.3.1` y Vite `8.3.7`.
- **Validación:** `npm run build` completado correctamente; se generó la salida estática en `apps/web/dist`.
- **Pendientes:** Crear la primera isla React, definir tokens del sistema visual y configurar despliegue en Cloudflare Pages.

## 2026-11-09
- **Área:** mapas | mobile | web
- **Cambio:** Se instalaron `leaflet` y `react-leaflet` para la web; `flutter_map`, `latlong2`, `geolocator` y `flutter_appauth` para Flutter. Se creó `apps/mobile`.
- **Decisión:** El OAuth de OpenStreetMap se gestionará con PKCE en móvil y mediante un Cloudflare Worker en web; los secretos no se distribuirán al cliente.
- **Validación:** `flutter pub get` y `flutter analyze` completados correctamente. El análisis se ejecutó mediante una unidad virtual porque el servidor LSP falla al interpretar la `ñ` de la ruta del workspace. Se documentaron teselas, atribución, OAuth, callbacks y permisos en `docs/OPENSTREETMAP.md`.
- **Pendientes:** Implementar los componentes de mapa, registrar las URI OAuth definitivas y activar Developer Mode de Windows para compilar plugins Flutter localmente.

## 2026-11-09
- **Área:** seguridad | infraestructura
- **Cambio:** Se crearon `.env.example` y `.env` local con variables para OpenStreetMap, teselas, sesiones, Cloudflare y distribución móvil.
- **Decisión:** El archivo `.env` permanece ignorado por Git; las variables `PUBLIC_` son las únicas aptas para exponerse al cliente. Los secretos de Cloudflare se configurarán con Wrangler.
- **Validación:** Se comprobó el `.gitignore` raíz y se documentó el procedimiento en `docs/OPENSTREETMAP.md`.
- **Pendientes:** Completar los valores reales después de registrar la aplicación OAuth de OSM y crear los secretos de Cloudflare.

## 2026-11-09
- **Área:** infraestructura | git
- **Cambio:** Se instalaron las herramientas CLI (Git, GitHub CLI, Firebase CLI, Oracle OCI CLI, Cloudflare Wrangler y cloudflared, Flutter SDK). Se normalizó la estructura de carpetas moviendo `apps/mobile` a la raíz. Se configuró el autor `Adrian Guanoluisa Loza` y se subieron las 4 ramas al repositorio remoto.
- **Validación:** Comprobadas versiones de todas las herramientas CLI, git status limpio y ramas publicadas en `https://github.com/Adrianguanoluisaloza/Esmeraldas-resileinte.git`.
- **Pendientes:** Comenzar con la implementación de componentes de mapa y endpoints en las respectivas ramas de desarrollo.

## 2026-11-09
- **Área:** infraestructura | web | cloudflare
- **Cambio:** Se configuró y autenticó Cloudflare Wrangler (`wrangler login`). Se generó la configuración `wrangler.jsonc` para el despliegue de `apps/web/dist` y se publicó en Cloudflare Pages / Workers.
- **Validación:** Despliegue completado con éxito. URL activa: `https://esmeraldas-resiliente.eliasadrianlozadaguanoluisa.workers.dev` respondiendo HTTP 200 OK.
- **Pendientes:** Integrar componentes interactivos React y mapa Leaflet en la web.

## 2026-11-09
- **Área:** arquitectura | documentación | git
- **Cambio:** Se actualizó la estructura documentada para reflejar `apps/web`, `apps/mobile`, `backend`, `frontend`, `mobile` y `contrato`.
- **Decisión:** `backend`, `desarrollo-adrian` y `desarrollofranco` funcionan como espacios de trabajo por rama; el código ejecutable permanece en `apps/` hasta su revisión.
- **Validación:** Revisados `AGENTS.md` y `estructura-esmeraldas-resiliente.md` contra el árbol actual del repositorio.
- **Pendientes:** Completar la implementación de cada módulo y mantener los contratos OpenAPI sincronizados antes de integrar a `main`.

## 2026-11-09
- **Área:** mobile
- **Cambio:** Se armó el esqueleto completo del proyecto Flutter en `mobile/` siguiendo Clean Architecture y `indicaciones-flutter-franco.md` (`core/`, `data/`, `features/auth`, `features/reporte`, `features/mis_reportes`, `features/sync`) e instalando las dependencias aprobadas (`hive_ce`, `hive_ce_flutter`, `flutter_map`, `latlong2`, `geolocator`, `connectivity_plus`, `image_picker`, `flutter_image_compress`, `path_provider`, `dio`, `uuid`, `flutter_secure_storage`, `flutter_appauth`).
- **Decisión:** Todo el acceso a las cajas locales de Hive (`cola_reportes_box` y `directorio_puntos_servicio_box`) se encapsuló en una única clase (`HiveColaReportesRepository`) y la pantalla de albergues usa respaldo en lista cuando no hay conexión real.
- **Validación:** Ejecutados `dart format`, `flutter analyze` y `flutter test` en `mobile/`.
- **Pendientes:** Conectar la cámara/compresión física en dispositivo real y los endpoints definitivos del backend (`POST /reportes` y `POST /reportes/:id/foto`).

## 2026-11-09
- **Área:** mobile
- **Cambio:** Se implementaron las tareas M1–M5 de `docs/orquestacion/TAREAS_MOVIL_FRANCO.md` en `mobile/`: `DioApiClient` con interceptor Bearer y mapeo de errores (`400/409` a `error`, `401` a re-login sin borrar la cola), login/registro con validación y botón de Google (`flutter_appauth` PKCE), `MapaFondoEsmeraldas` centrado en Esmeraldas (`0.9592, -79.6539`) con respaldo vectorial offline, barra de navegación por rol (ciudadano, operador 911 y admin), paleta de `docs/DISENO.md` sin emojis e insignia de origen con borde discontinuo, y directorio de albergues con semáforo textual y consulta `/puntos-servicio/cercanos`.
- **Validación:** `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues) y `flutter test` (100% pass).
- **Pendientes:** Probar el APK generado en dispositivo físico Android en modo avión.

## 2026-11-09
- **Área:** web | mapas | UI
- **Cambio:** Se implementó el Centro de Operaciones 911 en `apps/web`: componente de mapa interactivo con Leaflet y OpenStreetMap enfocado en Esmeraldas (`MapaEsmeraldas.tsx`), pines por gravedad con `L.divIcon`, semáforo de albergues y centros de salud, panel de detalle y métricas clave en tiempo real (`PanelOperaciones.tsx`).
- **Validación:** Compilación `npm run build` exitosa en 1.01s. Despliegue en vivo en Cloudflare: `https://esmeraldas-resiliente.eliasadrianlozadaguanoluisa.workers.dev` respondiendo 200 OK.
- **Pendientes:** Conectar con la API del backend una vez que se implementen los endpoints de Hono.

## 2026-11-09
- **Área:** web | autenticación | UI
- **Cambio:** Se diseñó e implementó el módulo de autenticación e inicio de sesión en `apps/web`: página `/login` (`login.astro`), componente React `LoginCard.tsx` con estética moderna SaaS, selector rápido de roles para la demo (Operador 911, Admin, Ciudadano), persistencia de sesión en `auth.ts` y acceso directo desde el navbar principal.
- **Validación:** Compilación `npm run build` exitosa (2 páginas: `/` y `/login`). Despliegue en vivo en Cloudflare: `https://esmeraldas-resiliente.eliasadrianlozadaguanoluisa.workers.dev/login` respondiendo 200 OK.
- **Pendientes:** Conectar la autenticación con el endpoint JWT real de la API de Hono en el backend.

## 2026-11-09
- **Área:** web | UI
- **Cambio:** Se instaló `lucide-react` y se reemplazaron los emojis de login, panel, mapa y portada por iconos Lucide o etiquetas textuales.
- **Decisión:** La interfaz web no usará emojis como iconografía; los iconos interactivos deben ser accesibles y mantener etiquetas o títulos cuando corresponda.
- **Validación:** `npm run build` completado correctamente y búsqueda de emojis sin resultados en `apps/web/src`.
- **Pendientes:** Revisar el tamaño visual de los iconos durante la prueba responsive.

## 2026-11-09
- **Área:** web | UI / UX
- **Cambio:** Se homogenizó toda la plataforma web con un tema visual limpio, blanco y moderno estilo SaaS (inspirado en Remote.com y Stripe). Tanto la página del Centro de Mando / Mapa (`/mapa`) como la de autenticación (`/login`) fueron actualizadas con fondos blancos `#f8fafc`, tarjetas `#ffffff` con sombras suaves, bordes finos `#e2e8f0`, selects y botones limpios (pill y redondeados modernos).
- **Validación:** Astro dev server activo, HMR instantáneo en 4ms en `/` y `/mapa`. Comprobación de contraste y legibilidad con OpenStreetMap y capas operacionales.
- **Pendientes:** Verificar responsive y publicar actualización en Cloudflare Pages.

## 2026-11-09
- **Área:** backend | base de datos | infraestructura
- **Cambio:** Esqueleto de `apps/api` con Hono y TypeScript en Clean Architecture (dominio, aplicación, infraestructura, http). Repositorios en memoria y en PostgreSQL + PostGIS. Esquema y semilla del escenario Jueves 06:00 en `database/`. `docker-compose.yml` con PostGIS y la API. WebSocket `/ws` para el COE.
- **Decisión:** Se siguen las recomendaciones del reto (PostgreSQL + PostGIS, Docker Compose, REST + WebSockets, JWT). Endpoints que la app de Franco ya usa (`/salud`, `/reportes`, `/reportes/{id}/foto`) quedan funcionando; alertas, estadísticas y clasificación IA responden 501 con código estable para integrar sin romper. La API vive en Oracle Cloud; la web sigue en Cloudflare.
- **Validación:** `npm run ci` (18 pruebas) y la misma suite contra PostGIS 16 local (14 pruebas). Servidor real probado: `/salud`, `ST_Distance` en albergues cercanos y WebSocket rechazando token inválido. El build de la imagen Docker no se pudo probar en la sesión (sin demonio Docker).
- **Pendientes:** B1 a B8 en `docs/orquestacion/TAREAS_BACKEND.md`.

## 2026-11-09
- **Área:** backend | web | integración local
- **Cambio:** Se configuró y levantó localmente la API en Node 22 (`apps/api`) en modo memoria con soporte para cuentas demo y el escenario simulado "Jueves 06:00 AM" (los 6 eventos oficiales del reto). Se conectó el frontend Astro (`http://localhost:4321`) con la API (`http://localhost:3000`).
- **Decisión:** Debido a que las llaves SSH de la VM de Oracle Cloud se encuentran en la máquina de casa de Adrian, se priorizó habilitar la API localmente para iteración y pruebas inmedias en el laboratorio sin bloqueos.
- **Validación:** Comprobados endpoints `/salud`, `/auth/login` (generación de JWT con rol operador COE), `/reportes` (retorna los 6 eventos del escenario), `/zonas` y `/vias` (GeoJSON con 5 y 4 features respectivamente). Web sirviendo en puerto 4321 y API en puerto 3000.
- **Pendientes:** Al llegar a casa, ejecutar `docker compose up -d --build` en la VM de Oracle con la llave SSH local para dejar la infraestructura en la nube activa 24/7.

## 2026-11-09
- **Área:** infraestructura | túnel | conectividad móvil
- **Cambio:** Se expuso la API local mediante Cloudflare Tunnel (`cloudflared`) generando la URL pública HTTPS `https://seasonal-acceptable-crimes-remember.trycloudflare.com`. Se documentó en `docs/orquestacion/TAREAS_MOVIL_FRANCO.md` para que Franco pueda conectar la app móvil desde su propia computadora y celular mediante `--dart-define=API_BASE_URL=...`.
- **Validación:** Comprobado `curl https://seasonal-acceptable-crimes-remember.trycloudflare.com/salud` respondiendo `{"estado":"ok"}` a través de la red global de Cloudflare.

## 2026-11-09
- **Área:** backend | base de datos | seguridad
- **Cambio:** Alertas, vías, estadísticas, priorización por sector, historial y asistencia humanitaria (módulo 5). La API usa el usuario `resiliente_app` sin DELETE ni DDL; historial y entregas son de solo inserción. Límite de peticiones por IP, CORS estricto, contenedor endurecido y escuchando solo en local.
- **Decisión:** Sin clasificación automática; la priorización usa reglas visibles (gravedad, personas, vulnerables, rescate, recurrencia).
- **Validación:** 25 pruebas en memoria y 21 contra PostGIS con el usuario restringido. Comprobado que ese usuario no puede borrar, eliminar tablas ni reescribir el historial.
- **Pendientes:** Probar `docker compose up` en la VM de Oracle (la imagen no se construyó en esta sesión).

## 2026-11-09
- **Área:** web | repositorio
- **Cambio:** Pantallas reales para alertas y vías, asistencia, estadísticas, detalle con historial, nuevo reporte y ocupación de albergues. Portada y acceso nuevos. Menú sin "Pronto" y sin textos de relleno. Documentos movidos a `docs/` y README nuevo.
- **Validación:** Build de 12 páginas y typecheck sin errores. Recorrido completo en navegador (operador y ciudadano en celular) sin errores de consola.
- **Pendientes:** Tareas W1 a W4 y M1 a M7 en `docs/orquestacion/`.

## 2026-11-09
- **Área:** mobile | backend | mapas
- **Cambio:** Se corrigió la visualización del mapa en modo offline (`MapaFondoEsmeraldas`) manteniendo siempre activos los marcadores de incidentes, albergues y pines de emergencia sobre el lienzo vectorial. Se habilitó en `POST /reportes` la recepción de reportes sin token para emergencias offline (`ciudadano-offline`), sincronizando la cola local de Hive directamente con la base de datos y WebSocket del COE. Se generó guía y archivo comprimido de credenciales para Franco (`mobile/GUIA_RAPIDA_FRANCO.md`, `mobile/acceso_franco_demo.zip`).
- **Validación:** Backend recompilado y verificado con `POST /reportes` anónimo (201 OK). App móvil recompilada para Web en puerto 5000 y configurada para apuntar por defecto al túnel Cloudflare en dispositivos físicos.
- **Pendientes:** Pruebas integradas de sincronización de reportes desde el celular de Franco hacia el panel web del COE.

## 2026-11-09
- **Área:** backend | seguridad | móvil
- **Cambio:** Revisión de la conexión con la app. Se mantiene el reporte sin cuenta, rehecho con `usuario_id` nulo (el valor "ciudadano-offline" rompía la inserción en PostGIS). CORS vuelve a lista exacta: aceptar cualquier origen que contenga "localhost" o "trycloudflare.com" dejaba pasar dominios ajenos. Se retiran `acceso_franco_demo.zip` y `credenciales_demo.txt`.
- **Validación:** 28 pruebas en memoria y 24 contra PostGIS con el usuario restringido.
- **Pendientes:** Franco: M9 (URL fuera del código), M10 (no subir foto de relleno), M11 (flujo sin cuenta). Poner la URL del túnel en `CORS_ORIGENES` si la web la usa.

## 2026-11-09
- **Área:** web | backend | base de datos
- **Cambio:** Interfaz compacta (Geist, tamaños menores, acción principal neutra). Mapa operativo sin contadores, filtros en una línea y todo dentro de la pantalla. Login solo con servidor. Marcar ubicación en el mapa. Inventario con descuento transaccional y ruta de evacuación que detecta vías bloqueadas.
- **Decisión:** La web publicada en workers.dev era una versión anterior y apuntaba a `localhost`: por eso ningún rol funcionaba en internet. Se documenta compilar con `PUBLIC_API_URL` y poner la URL de la web en `CORS_ORIGENES`.
- **Validación:** 30 pruebas en memoria y 26 contra PostGIS con usuario restringido. Recorrido completo en navegador contra PostGIS (operador y ciudadano) sin errores de consola ni del servidor.
- **Pendientes:** Publicar la web con la URL fija de la API; túnel con nombre propio.

- **Área:** mobile | web | backend
- **Cambio:** Se habilitó el reporte de emergencia sin señal GPS tanto en la web (`FormularioReporte.tsx`) como en la app móvil (`CrearReportePage.dart`), permitiendo seleccionar directamente el sector de Esmeraldas y marcando `ubicacion_aproximada: true`. Se actualizaron las alertas del escenario con los 3 eventos vigentes oficiales y simulados en la semilla y en la base de datos SQL.
- **Validación:** 28 pruebas pasando en apps/api (`npm run ci`), compilación limpia de 12 páginas en Astro y build web de Flutter.
- **Pendientes:** Merge del PR hacia `desarrollo-adrian`.

## 2026-11-09
- **Área:** mobile
- **Cambio:** Se implementaron las tareas M1–M5 de `docs/orquestacion/TAREAS_MOVIL_FRANCO.md` en `mobile/`: `DioApiClient` con interceptor Bearer y mapeo de errores (`400/409` a `error`, `401` a re-login sin borrar la cola), login/registro con validación y botón de Google (`flutter_appauth` PKCE), `MapaFondoEsmeraldas` centrado en Esmeraldas (`0.9592, -79.6539`) con respaldo vectorial offline, barra de navegación por rol (ciudadano, operador 911 y admin), paleta de `docs/DISENO.md` sin emojis e insignia de origen con borde discontinuo, y directorio de albergues con semáforo textual y consulta `/puntos-servicio/cercanos`.
- **Validación:** `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues) y `flutter test` (100% pass).
- **Pendientes:** Probar el APK generado en dispositivo físico Android en modo avión.
- **Área:** arquitectura | documentación | git
- **Cambio:** Se actualizó la estructura documentada para reflejar `apps/web`, `apps/mobile`, `backend`, `frontend`, `mobile` y `contrato`.
- **Decisión:** `backend`, `desarrollo-adrian` y `desarrollofranco` funcionan como espacios de trabajo por rama; el código ejecutable permanece en `apps/` hasta su revisión.
- **Validación:** Revisados `AGENTS.md` y `estructura-esmeraldas-resiliente.md` contra el árbol actual del repositorio.
- **Pendientes:** Completar la implementación de cada módulo y mantener los contratos OpenAPI sincronizados antes de integrar a `main`.

## 2026-11-09
- **Área:** web | diseño | orquestación
- **Cambio:** Sistema de diseño con la paleta de la app de Franco (verde `#0B6E4F` y semáforo), claro y oscuro. Componentes reutilizables y `PanelLayout` con barra lateral por rol: COE (mapa operativo, reportes, alertas, estadísticas) y las 4 pantallas ciudadanas del prototipo móvil. Cliente API único con respaldo a datos simulados. Mapa con capas de zonas y vías desde PostGIS. Login contra la API real.
- **Decisión:** Rojo solo para emergencia y peligro. Origen del dato con color y texto propios (simulado con borde discontinuo). Cuentas demo con dominio propio, no `.gob.ec`. Se corrigió un riesgo de XSS en los popups del mapa y el YAML inválido del contrato. `wrangler.jsonc` usa `/` para que funcione fuera de Windows.
- **Validación:** `astro build` (11 páginas) y typecheck sin errores. Recorrido con Playwright contra la API con PostGIS: login operador, despachar unidad (cambio guardado), tabla, albergues, modo oscuro, ciudadano en móvil y bloqueo del ciudadano en pantallas del COE.
- **Pendientes:** Portada y login todavía con su CSS antiguo (tarea W1). Tareas W1 a W5 para Gemini y M1 a M5 para Franco en `docs/orquestacion/`.

## 2026-11-09
- **Área:** mobile | seguridad | infraestructura
- **Cambio:** Se instalaron Android SDK (`cmdline-tools`, `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`, NDK `28.2.13676358`, CMake `3.22.1`) en `C:\src\android-sdk` y OpenJDK 21 (`21.0.13 LTS`) en `C:\src\jdk21`, generando `mobile/build/app/outputs/flutter-apk/app-release.apk`. Se ajustó el inicio del ciudadano (`CrearReportePage`) al flujo en 3 pasos sobre el mapa de Esmeraldas (mapa despejado y seleccionable con botón flotante lateral de GPS y botón inferior "Reportar emergencia" -> confirmación de ubicación -> formulario). Se integró `google-services.json` en `mobile/android/app/google-services.json`, se configuraron `googleClientId` y `appAuthRedirectScheme`, y se añadió `**/google-services.json` a `.gitignore`.
- **Decisión:** Se fijó OpenJDK 21 para las compilaciones de Android porque el JDK 26 preinstalado en el equipo rompe `JdkImageTransform` de Android Gradle Plugin.
- **Validación:** `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues), `flutter test` (pass) y `flutter build apk --release` exitoso (`53.8 MB`).
- **Pendientes:** Registrar la huella SHA-1 del equipo en Firebase Console si se requiere el selector nativo de cliente Android tipo 1 y continuar con los ajustes de las vistas de operador 911 y administrador.

## 2026-11-09
- **Área:** mobile | backend | base de datos
- **Cambio:** Se corrigió la sincronización automática de la cola en `HomeShellPage` al guardar un reporte y al iniciar la app, se agregaron los pines interactivos de reportes en el mapa inicial del ciudadano (`CrearReportePage` y `MapaFondoEsmeraldas` tanto en `FlutterMap` como en el mapa vectorial offline) y se unió la cola local de Hive con `OperacionesRepository`. Se implementó `PhotoCaptureService` para pedir permisos nativos de cámara/galería en Android e iOS, comprimir las fotos a máximo 1280 px (calidad 75%) y guardarlas en la carpeta de documentos de la app fuera de Hive. Se integró `origin/backend` (`650a94b`) conservando la versión oficial de `apps/api` y `database/` según M8.
- **Decisión:** Conservar `apps/api` y `database/` de la rama `backend` según M8 de `TAREAS_MOVIL_FRANCO.md` y sincronizar los reportes ciudadanos en dos pasos al guardar.
- **Validación:** `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues) y `flutter test` (100% pass).
- **Pendientes:** Probar el flujo de cámara y sincronización en dispositivo físico Android conectado al backend.

## 2026-11-09 — Integración de M6, M10 y M11 con `origin/backend`
- **Responsable:** Franco (carril móvil)
- **Resumen:** Se alineó el cliente móvil (`mobile/`) con los contratos actualizados de `origin/backend` (`TAREAS_MOVIL_FRANCO.md` tareas M6, M10 y M11) y se verificó la conexión de extremo a extremo contra PostgreSQL 18 (`localhost:5433`) y `apps/api` (`localhost:3000`).
- **Decisiones:**
  - **M10 (No subir fotos falsas):** Se eliminó `_jpegMinimoDemo` de `DioApiClient` y se actualizó `SyncWorkerService._procesarReportePorPasos` para omitir la subida de foto y marcar el reporte como `enviado` sin foto si no existe archivo real en disco ni en memoria.
  - **M11 (Reporte de emergencia sin cuenta):** Se retiró el auto-login silencioso del interceptor de `DioApiClient` para que los reportes creados en modo emergencia sin cuenta se envíen sin cabecera `Authorization` (aceptados por `sesionOpcional` en `POST /reportes` y `POST /reportes/:id/foto`). Si una sesión autenticada vence (`401`), `HomeShellPage` solicita iniciar sesión nuevamente sin borrar la cola de Hive, y `MisReportesPage` informa que el historial personal solo lista reportes enviados con cuenta.
  - **M6 (Alertas en la app):** Se agregó `obtenerAlertasActivas()` (`GET /alertas` sin token) en `DioApiClient` y su visualización en `DirectorioAlberguesPage` diferenciando alertas oficiales en rojo y simulacros con insignia `Simulacro`.
  - **Incidentes y puntos georreferenciados en el mapa (`OperacionesRepository`):** Se implementó `sincronizarDesdeBackend` en `OperacionesRepository` y su invocación desde `HomeShellPage` para descargar `GET /reportes?limite=100`, `GET /puntos-servicio` y `GET /alertas` del backend público en vivo (`https://seasonal-acceptable-crimes-remember.trycloudflare.com`), pintando todos los incidentes y albergues georreferenciados en `MapaFondoEsmeraldas` y sincronizando las acciones de operador (`PATCH /reportes/:id/estado`, `PATCH /albergues/:id/ocupacion`, `POST /alertas`). Además, se alineó la semilla local con los 6 incidentes y 5 puntos de servicio oficiales de `database/02_seed_escenario_06am.sql`.
- **Archivos tocados:** `mobile/lib/core/config/app_config.dart`, `mobile/lib/core/network/api_client.dart`, `mobile/lib/data/repositories/operaciones_repository.dart`, `mobile/lib/data/repositories/cola_reportes_repository.dart`, `mobile/lib/features/sync/data/services/sync_worker_service.dart`, `mobile/lib/core/routing/app_router.dart`, `mobile/lib/features/mis_reportes/presentation/pages/mis_reportes_page.dart`, `mobile/lib/features/mis_reportes/presentation/pages/directorio_albergues_page.dart`, `mobile/lib/core/theme/app_theme.dart`, `CHANGELOG.md`, `bitacora.md`.
## 2026-11-09 — Punto de Control Laboratorio (Adrian & Franco en vivo)
- **Área:** general | infraestructura | integración
- **Cambio:** Punto de control consolidado del sistema en ejecución simultánea entre Adrian y Franco. Se verificó la sincronización en tiempo real vía Cloudflare Tunnel (`https://seasonal-acceptable-crimes-remember.trycloudflare.com`), backend Hono (`http://localhost:3000`), web Astro (`http://localhost:4321`) y app móvil Flutter (`http://localhost:5000`). Se integró el soporte para emergencias sin señal GPS en web y móvil (selector de sectores de Esmeraldas y `ubicacion_aproximada: true`), 3 alertas vigentes del escenario oficial cargadas en semilla y SQL, 30 de 30 pruebas pasando en la API (`npm run ci`), y PR #2 integrado y mergeado limpiamente.
- **Validación:**
  - `apps/api`: `npm run ci` (30/30 pruebas OK, 0 fallos).
  - `apps/web`: `astro build` (12 páginas compiladas en 1.50s, 0 errores).
  - `mobile`: `flutter build web` exitoso (`√ Built build\web`).
  - Túnel y salud: `GET /salud` y `GET /alertas` respondiendo HTTP 200 en local y túnel público.
- **Pendientes:** Preparar la presentación y guion de demostración ante el jurado del Hackathon.

## 2026-11-09 — Persistencia de Datos de Prueba en Vivo (Final de Sesión)
- **Área:** backend | base de datos | memoria
- **Cambio:** Se persistieron en `database/02_seed_escenario_06am.sql` y en `apps/api/src/infraestructura/memoria/semilla.ts` los 3 reportes ciudadanos reales generados durante las pruebas en vivo entre Adrian y Franco a través del túnel Cloudflare:
  1. `3b4e75ec-669e-4bbd-80b4-1c44bae604f7`: `personas_atrapadas` ("prueba6", Barrio Caliente, crítica).
  2. `cc230d23-318b-47c0-b5e4-5e57d43c253d`: `dano_vivienda` ("pruebasininternet", Centro / Malecón, sincronizado offline con Hive).
  3. `9e5a76ac-5e79-43d1-ba5e-438d7afc6059`: `deslizamiento` ("rrrrrrrrrr", Centro / Malecón, con foto adjunta).
- **Validación:**
  - `apps/api`: suite `npm run ci` ejecutada exitosamente (30 pruebas passing).
  - Base de datos PostGIS y memoria sincronizadas como espejos exactos.
- **Estado final:** Sesión concluida y lista para la defensa del proyecto.

