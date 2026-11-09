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



