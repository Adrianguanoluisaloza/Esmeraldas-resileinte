# Tareas web

Carril: `apps/web`. Leer antes `docs/DISENO.md`. Todas las tareas usan lo que ya existe:
`PanelLayout`, `src/lib/api.ts`, `src/lib/catalogos.ts`, `src/components/ui/*`, clases `er-*`.

## Lo que NO se toca (para no romper nada)

- `src/styles/tokens.css` (paleta), `src/lib/api.ts`, `src/config/navegacion.ts`, `src/layouts/*`,
  `contrato/openapi.yaml`, `apps/api/**`, `database/**`. Si hace falta cambiarlos, se coordina con el carril backend.
- No instalar librerías nuevas (ni Tailwind, ni UI kits). Con lo que hay alcanza.
- No usar `fetch` directo: siempre funciones de `api.ts`.
- No escribir textos de catálogo a mano: `ETIQUETA_*` de `catalogos.ts`.
- No hex en CSS de componentes: solo `var(--er-*)`.
- No `innerHTML` con datos de la API sin `escaparHtml`.

## Verificación (obligatoria en cada tarea)

```bash
cd apps/web && npm run build
```

```bash
cd apps/web && npx -y -p typescript@5.9.3 tsc --noEmit -p .
```

```bash
grep -rnE "#[0-9a-fA-F]{6}" apps/web/src/components apps/web/src/pages --include=*.astro --include=*.tsx | grep -v catalogos
```

La tercera debe salir vacía en los archivos que tocaste. Revisar la pantalla en claro, oscuro y 375 px.
Probar con la API apagada: debe aparecer el aviso morado de datos simulados y nada debe romperse.

---

## W1. Portada y login con el sistema de diseño

**Objetivo:** que `index.astro` y `login.astro` dejen su CSS propio (azul `#2563eb`) y usen `BaseLayout` + tokens.
**Archivos:** `src/pages/index.astro`, `src/pages/login.astro`, `src/components/LoginCard.tsx`,
nuevo `src/styles/sitio.css` (prefijo `st-`).
**Pasos:**
1. Envolver ambas páginas en `BaseLayout`. Borrar el bloque `<style is:global>` y pasar lo necesario a `sitio.css`
   usando solo tokens.
2. Navbar pública mínima: marca (mismo escudo verde del panel), enlaces Inicio y "Ingresar".
3. Quitar "EN VIVO · 06:00 UTC" y las flechas "→" de los botones.
4. `LoginCard`: botones `er-btn`, campos `er-campo`/`er-entrada`, selector de rol demo con `er-segmentos`.
5. Portada: texto real del reto (lema "Programar hoy para proteger vidas mañana"), 3 bloques (Reportar, Coordinar,
   Albergues) y CTA "Ingresar al panel". Sin cifras inventadas.
**Hecho cuando:** ningún hex en esos archivos, se ve bien en claro/oscuro/móvil y el login lleva al panel por rol.

## W2. Detalle de reporte con historial

**Objetivo:** `/panel/reportes` abre un panel lateral con el detalle y el historial de estados.
**Archivos:** `src/components/TablaReportes.tsx`, nuevo `src/components/DetalleReporte.tsx`.
**Pasos:** fila clicable (botón accesible) -> `DetalleReporte` con insignias, datos, foto (`foto_url` si existe,
`<img loading="lazy">` con texto alternativo) y botones de estado reutilizando la lógica de `PanelOperaciones`.
Agregar `api.obtenerReporte(id)` en coordinación con backend.
**Hecho cuando:** se puede despachar y marcar atendido desde la tabla, y el teclado (Tab/Enter/Escape) funciona.

## W3. Ajustar ocupación de albergues (COE)

**Objetivo:** en `/panel/albergues`, el operador suma o resta personas a un albergue.
**Archivos:** `src/components/ListaAlbergues.tsx`.
**Pasos:** solo si el rol es `operador_911` o `admin` (leer `obtenerSesionActual()`), mostrar botones `-1`, `+1`, `+5`
que llaman `api.actualizarOcupacion`. Mostrar el semáforo actualizado. Aviso ámbar si pasa de 90 %.
**Hecho cuando:** el cambio llega a la API y a otra pestaña abierta del mapa (WebSocket) sin recargar.

## W4. Formulario web "Nuevo reporte" (versión navegador del prototipo)

**Objetivo:** reemplazar `PaginaPendiente` en `/panel/reportar` por el formulario del prototipo de Franco.
**Archivos:** `src/pages/panel/reportar.astro`, nuevo `src/components/FormularioReporte.tsx`.
**Pasos:** rejilla de 6 tipos (botones con icono Lucide + `ETIQUETA_TIPO`), gravedad, descripción, ubicación con
`navigator.geolocation` (mostrar latitud, longitud y ± metros), bloque opcional de familia (personas, niños, adultos
mayores, necesidades como casillas). `id = crypto.randomUUID()`. Enviar con una función nueva `api.crearReporte`
(coordinar con backend). Botón `er-btn--emergencia` "Enviar reporte".
**Hecho cuando:** el reporte aparece en el mapa del COE en otra pestaña al instante, y en "Mis reportes".

## W5. Revisión de accesibilidad

**Objetivo:** pasar el panel con teclado y lector de pantalla.
**Archivos:** solo los que fallen.
**Pasos:** recorrer todas las pantallas con Tab; foco visible siempre; cada botón con texto; contraste AA
en claro y oscuro. Anotar en `bitacora.md` qué se corrigió.
