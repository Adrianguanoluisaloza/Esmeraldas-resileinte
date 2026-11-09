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
- **Área:** web | diseño | orquestación
- **Cambio:** Sistema de diseño con la paleta de la app de Franco (verde `#0B6E4F` y semáforo), claro y oscuro. Componentes reutilizables y `PanelLayout` con barra lateral por rol: COE (mapa operativo, reportes, alertas, estadísticas) y las 4 pantallas ciudadanas del prototipo móvil. Cliente API único con respaldo a datos simulados. Mapa con capas de zonas y vías desde PostGIS. Login contra la API real.
- **Decisión:** Rojo solo para emergencia y peligro. Origen del dato con color y texto propios (simulado con borde discontinuo). Cuentas demo con dominio propio, no `.gob.ec`. Se corrigió un riesgo de XSS en los popups del mapa y el YAML inválido del contrato. `wrangler.jsonc` usa `/` para que funcione fuera de Windows.
- **Validación:** `astro build` (11 páginas) y typecheck sin errores. Recorrido con Playwright contra la API con PostGIS: login operador, despachar unidad (cambio guardado), tabla, albergues, modo oscuro, ciudadano en móvil y bloqueo del ciudadano en pantallas del COE.
- **Pendientes:** Portada y login todavía con su CSS antiguo (tarea W1). Tareas W1 a W5 para Gemini y M1 a M5 para Franco en `docs/orquestacion/`.

