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
- **Validación:** `flutter pub get` completado correctamente. Se documentaron teselas, atribución, OAuth, callbacks y permisos en `docs/OPENSTREETMAP.md`.
- **Pendientes:** Implementar los componentes de mapa, registrar las URI OAuth definitivas y activar Developer Mode de Windows para compilar plugins Flutter localmente.

## 2026-11-09
- **Área:** infraestructura | git
- **Cambio:** Se instalaron las herramientas CLI (Git, GitHub CLI, Firebase CLI, Oracle OCI CLI, Cloudflare Wrangler y cloudflared, Flutter SDK). Se normalizó la estructura de carpetas moviendo `apps/mobile` a la raíz. Se configuró el autor `Adrian Guanoluisa Loza` y se subieron las 4 ramas al repositorio remoto.
- **Validación:** Comprobadas versiones de todas las herramientas CLI, git status limpio y ramas publicadas en `https://github.com/Adrianguanoluisaloza/Esmeraldas-resileinte.git`.
- **Pendientes:** Comenzar con la implementación de componentes de mapa y endpoints en las respectivas ramas de desarrollo.
