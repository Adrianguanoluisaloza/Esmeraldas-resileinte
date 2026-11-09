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

## Hecho

Portada y acceso, mapa operativo, reportes con detalle e historial, alertas y vías, asistencia, estadísticas,
albergues con ajuste de ocupación, nuevo reporte web, inicio y mis reportes del ciudadano.

## W1. Detalle de reporte desde el mapa operativo

**Archivos:** `src/components/PanelOperaciones.tsx`. Botón "Ver detalle" en el panel derecho que abre `DetalleReporte`.

## W2. Mapa en la pantalla de asistencia

**Archivos:** `src/components/Asistencia.tsx`. Al elegir una fila, centrar un `MapaEsmeraldas` pequeño en el reporte.

## W3. Accesibilidad

Recorrer todas las pantallas con Tab; foco visible siempre; contraste AA en claro y oscuro. Anotar en `bitacora.md`.

## W4. Prueba en celular de gama baja

Abrir `/panel/inicio` y `/panel/reportar` en un celular real con datos móviles. Medir tiempo de carga y anotar.
