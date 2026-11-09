# Reglas del proyecto

## Leer primero (en este orden, solo lo que tu tarea pida)

1. Este archivo.
2. `docs/orquestacion/README.md`: quién hace qué y cómo se toma una tarea.
3. Tu carril: `docs/orquestacion/TAREAS_WEB.md`, `TAREAS_MOVIL_FRANCO.md` o `TAREAS_BACKEND.md`.
4. Diseño: `docs/DISENO.md`. Despliegue: `docs/DESPLIEGUE.md`. Seguridad: `docs/SEGURIDAD.md`. Contrato: `contrato/openapi.yaml`.

Reto oficial: https://educaysoft.org/Hackathon/reto.html (rúbrica: funcionalidad 25, innovación 15,
arquitectura 15, mapas 15, IA 10, usabilidad 10, impacto 10). Escenario de prueba: "Jueves 06:00 AM".

## Reglas que nunca se rompen

1. Con Adrian se habla en español, frases cortas.
2. Cero emojis en la interfaz (web y app). Iconos Lucide en web, Material en Flutter.
3. Nunca publicar ni hacer merge a `main` sin orden de Adrian.
4. Contrato primero: ningún cliente inventa campos que no estén en `contrato/openapi.yaml`.
5. Diferenciar siempre en la interfaz: reporte ciudadano, dato simulado y alerta oficial.
6. Nada inventado presentado como real (teléfonos, cifras, instituciones). Si es de demo, se marca "simulado".
7. Sin secretos en el repo. Solo variables `PUBLIC_*` llegan al navegador.
8. Diseño sólido y limpio: tokens `--er-*`, sin degradados ni hex sueltos (ver `docs/DISENO.md`).
9. Registrar cada tarea grande en `CHANGELOG.md` y `bitacora.md`.

## Objetivo

Construir una plataforma escalable con una aplicación móvil en Flutter y una página web en Astro con componentes React. La solución debe priorizar mantenibilidad, accesibilidad, rendimiento, seguridad y una experiencia consistente entre web y móvil.

## Stack aprobado

- **Aplicación móvil:** Flutter y Dart.
- **Arquitectura móvil:** Clean Architecture, separación por funcionalidades y principios SOLID.
- **Mapa:** OpenStreetMap mediante una biblioteca Flutter compatible. Debe respetarse la atribución requerida por OpenStreetMap y por cada proveedor de teselas.
- **Página web:** Astro.
- **Componentes interactivos:** React dentro de Astro, únicamente donde aporten estado o interacción real.
- **Infraestructura web:** Cloudflare Pages para el despliegue web; Cloudflare Workers solo para lógica de servidor o integraciones que lo necesiten.
- **Backend:** Hono + TypeScript en Node 22 (`apps/api`), Clean Architecture, validación con zod, JWT, WebSocket. Soporta doble modo: PostgreSQL 16 + PostGIS para producción/Docker, y modo memoria (`ALMACEN=memoria`) para desarrollo y demos inmediatas.
- **Base de datos:** PostgreSQL 16 + PostGIS (`database/`), con `docker-compose.yml` en la raíz.
- **Servidor:** VM de Oracle Cloud con Docker; HTTPS con Cloudflare Tunnel. Detalle en `docs/DESPLIEGUE.md`.
- **Distribución de la aplicación:** automatizar builds firmadas para Android e iOS mediante CI/CD y publicar en Google Play y App Store Connect según los entornos configurados.

## Estructura esperada

Cuando se incorporen fuentes al repositorio, mantener una separación similar a esta:

```text
apps/
  api/                    # Backend Hono + PostGIS (dominio, aplicacion, infraestructura, http)
  web/                    # Proyecto Astro
  mobile/                 # Proyecto Flutter inicial (se unifica con mobile/, ver tareas móvil)
mobile/                   # App Flutter de Franco
database/                 # 01 esquema, 02 semilla del escenario, 03 usuario de la API
docker-compose.yml        # PostGIS + API (Oracle Cloud y local)
contrato/                 # Contratos compartidos, incluido OpenAPI
packages/
  design-system/          # Tokens y componentes compartidos cuando sea viable
  contracts/              # Contratos, modelos serializables y esquemas compartidos
infra/                    # Configuración de Cloudflare y CI/CD
docs/
  arquitectura/           # Estructura y decisiones (mapas, Hive, PostGIS)
  movil/                  # Indicaciones de la app Flutter
  SEGURIDAD.md            # Hoja de seguridad
  OPENSTREETMAP.md        # Teselas, atribución y OAuth
  DISENO.md               # Sistema de diseño y piezas reutilizables
  DESPLIEGUE.md           # Oracle Cloud + Cloudflare
  orquestacion/           # Tareas por carril (web, móvil, backend)
bitacora.md
CHANGELOG.md
AGENTS.md
```

La estructura puede evolucionar, pero cada módulo debe tener una responsabilidad clara y dependencias dirigidas hacia adentro, nunca hacia detalles de infraestructura.

## Clean Architecture

Organizar la aplicación Flutter en capas:

```text
feature/
  presentation/           # Widgets, páginas, estado y navegación
  domain/                 # Entidades, casos de uso y contratos de repositorio
  data/                   # DTOs, fuentes remotas/locales y adaptadores
core/
  error/
  network/
  location/
  routing/
  theme/
```

Reglas de dependencia:

1. `presentation` depende de `domain`, nunca de implementaciones concretas de `data`.
2. `domain` no importa Flutter, HTTP, bases de datos ni SDKs externos.
3. `data` implementa los contratos definidos en `domain`.
4. La composición de dependencias se realiza en un punto de entrada, no dentro de las entidades o casos de uso.
5. Cada funcionalidad debe poder probarse sin red, mapas ni servicios reales.

## SOLID y escalabilidad

- **Responsabilidad única:** una clase, widget o función debe tener un motivo principal para cambiar.
- **Abierto/cerrado:** extender mediante interfaces, estrategias y composición antes que modificar código estable.
- **Sustitución de Liskov:** las implementaciones deben respetar completamente los contratos.
- **Segregación de interfaces:** contratos pequeños y orientados a casos de uso.
- **Inversión de dependencias:** el dominio define interfaces; infraestructura las implementa.

Evitar singletons globales, lógica de negocio en widgets, repositorios que mezclen UI con persistencia, y utilidades genéricas sin dueño claro.

## Mapas y OpenStreetMap

- Mostrar atribución visible y legible de OpenStreetMap y del proveedor de teselas.
- No asumir que los servidores públicos de teselas son una API ilimitada: respetar políticas de uso, caché y límites.
- Encapsular mapas, geocodificación, permisos y ubicación detrás de interfaces del dominio.
- Gestionar estados de permiso denegado, ubicación no disponible, error de red y mapa sin datos.
- No registrar coordenadas sensibles en logs de producción.
- Verificar licencias de datos, teselas, iconos y cualquier proveedor de geocodificación antes de publicar.

## Astro, React y Cloudflare

- Preferir HTML generado por Astro y cargar React solo como isla interactiva cuando sea necesario.
- Mantener componentes React pequeños, accesibles y agnósticos de infraestructura.
- No duplicar en React una página que Astro puede renderizar estáticamente.
- Validar SEO, navegación por teclado, estados de carga y diseño responsive.
- Mantener secretos fuera del cliente y fuera del repositorio.
- Configurar variables por entorno para desarrollo, staging y producción.
- Usar Cloudflare Pages para la entrega de la web y documentar cualquier Worker, binding o regla de caché.
- Las funciones en el borde deben ser stateless cuando sea posible y tener límites, timeouts y manejo explícito de errores.

## Calidad y pruebas

Antes de integrar cambios:

- Flutter: `dart format`, `flutter analyze` y pruebas unitarias/widget relevantes.
- Web: formateo, lint, typecheck y build de Astro.
- API: `cd apps/api && npm run ci` (typecheck + pruebas) y `npm run test:db` contra PostGIS cuando se toque SQL.
- Probar primero casos de uso y adaptadores; después la integración visual.
- Añadir pruebas para errores, estados vacíos, permisos y pérdida de conectividad.
- No aceptar warnings nuevos sin documentar la razón.

## Git y cambios

- Ramas y commits pequeños, descriptivos y enfocados.
- `main` es la rama protegida de integración.
- `backend` contiene el trabajo de API y servidor.
- `desarrollo-adrian` contiene el trabajo frontend y Cloudflare Pages.
- `desarrollofranco` contiene el trabajo de la aplicación Flutter.
- No mezclar refactors amplios con cambios funcionales.
- Actualizar `bitacora.md` con avances, decisiones y bloqueos relevantes.
- Actualizar `CHANGELOG.md` cuando un cambio sea visible para usuarios o afecte contratos.
- No incluir secretos, tokens, certificados ni archivos de firma en Git.
- Revisar licencias y atribuciones antes de incorporar dependencias o recursos.

## Definición de terminado

Un cambio está terminado cuando:

1. El comportamiento está implementado en la capa correcta.
2. Tiene pruebas proporcionales al riesgo.
3. Pasa análisis, formato y build del módulo afectado.
4. Maneja estados de error y accesibilidad relevantes.
5. Documenta decisiones, configuración o migraciones necesarias.
6. No rompe los contratos públicos ni los entornos existentes.
