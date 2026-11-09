# Sistema de diseño de Esmeraldas Resiliente

Una sola fuente para colores, componentes y reglas de la web. La app de Franco usa la misma paleta
(`mobile/lib/core/theme/app_theme.dart`), así la web y el celular se ven como un solo producto.

## 1. Paleta

| Uso | Token CSS | Claro | Flutter |
|---|---|---|---|
| Marca, botón principal, menú activo | `--er-primary` | `#0B6E4F` | `colorPrimario` |
| Semáforo verde (con cupo, atendido) | `--er-ok` | `#2E7D32` | `colorSemaforoVerde` |
| Semáforo ámbar (casi lleno, en proceso) | `--er-warn` | `#EF6C00` | `colorSemaforoAmbar` |
| Semáforo rojo (lleno, pendiente, crítico) | `--er-danger` | `#C62828` | `colorSemaforoRojo` |
| Botón de emergencia ("Reportar emergencia", "Enviar reporte") | `--er-emergencia` | `#C62828` | usar `colorSemaforoRojo` |
| Dato simulado (borde discontinuo) | `--er-origen-simulado` | `#5B4BC4` | agregar |
| Alerta oficial (INAMHI / SNGR) | `--er-origen-oficial` | `#1F4FB8` | agregar |
| Fondo / superficie / borde | `--er-bg` / `--er-surface` / `--er-border` | `#F5F7F5` / `#FFFFFF` / `#DCE3DE` | — |
| Texto / secundario / apagado | `--er-text` / `--er-text-2` / `--er-muted` | `#13201A` / `#36463E` / `#5F6F67` | — |

Gravedad: baja `#546E7A`, media `#B26A00`, alta `#EF6C00`, crítica `#C62828`.
El modo oscuro solo cambia los valores de los tokens (`src/styles/tokens.css`), nunca las reglas.

**Por qué así:** verde de marca de Franco para todo lo normal; rojo SOLO para emergencia y peligro, así el ojo lo
encuentra al instante bajo estrés. El reto exige diferenciar *reporte ciudadano*, *dato simulado* y *alerta oficial*:
cada uno tiene su color y su texto, y el simulado además lleva borde discontinuo (se distingue sin color).

## 2. Reglas que no se rompen

1. **Nada de hex sueltos** en componentes: siempre `var(--er-*)`. Excepción: marcadores de Leaflet, que leen
   `COLOR_*` de `src/lib/catalogos.ts` (mismos valores).
2. **Sólido y limpio:** sin degradados, sin vidrio esmerilado, sin brillos ni sombras grandes. Look de herramienta
   de trabajo, no de plantilla genérica de IA.
3. **Cero emojis.** Iconos solo de `lucide-react`.
4. **Textos de catálogo desde `src/lib/catalogos.ts`** (`ETIQUETA_GRAVEDAD`, `ETIQUETA_ESTADO`...). Nadie escribe
   "Crítica" o "En proceso" a mano.
5. **Insignias solo para datos reales** (gravedad, estado, origen, cupo). Nada de píldoras decorativas sobre títulos.
6. **Color nunca solo:** toda insignia lleva texto (daltonismo, impresión en blanco y negro).
7. **Un botón rojo de emergencia por pantalla**, como máximo.
8. **Todo dato que viene de la API y va a HTML armado a mano pasa por `escaparHtml`** (`src/lib/escapar.ts`).
9. Revisar cada pantalla en **claro, oscuro y 375 px** de ancho antes de darla por terminada.

## 3. Piezas reutilizables

| Necesito... | Uso | Archivo |
|---|---|---|
| Página del panel con menú lateral | `<PanelLayout titulo roles>` | `src/layouts/PanelLayout.astro` |
| Agregar una opción al menú | una línea en `NAVEGACION` | `src/config/navegacion.ts` |
| Llamar a la API | funciones de `api.*` (nunca `fetch` directo) | `src/lib/api.ts` |
| Botón | `<Boton variante="primario">` o `class="er-btn er-btn--primario"` | `ui/Basicos.tsx`, `styles/ui.css` |
| Gravedad / estado / origen / cupo | `<InsigniaGravedad valor>` etc. | `ui/Insignias.tsx` |
| Mensaje | `<Aviso tipo="peligro">`, `<AvisoRespaldo />` | `ui/Basicos.tsx` |
| KPI | `<Indicador etiqueta valor detalle tono>` | `ui/Basicos.tsx` |
| Cupo de albergue | `<BarraCapacidad>` | `ui/Basicos.tsx` |
| Cargando / vacío | `<Cargando>`, `<EstadoVacio>` | `ui/Basicos.tsx` |
| Pantalla cuyo endpoint da 501 | `<PaginaPendiente titulo texto endpoint>` | `components/panel/PaginaPendiente.astro` |
| Tabla | `er-tabla-contenedor` + `er-tabla` | `styles/ui.css` |
| Campo de formulario | `er-campo`, `er-etiqueta`, `er-entrada`, `er-select` | `styles/ui.css` |

## 4. Cómo se crea una pantalla nueva (receta)

1. Crear `src/pages/panel/mi-pantalla.astro` con `<PanelLayout titulo="..." roles={[...]}>`.
2. Si tiene interacción, crear la isla en `src/components/MiPantalla.tsx` y usarla con `client:only="react"`.
3. Datos: agregar la función en `src/lib/api.ts` siguiendo el contrato `contrato/openapi.yaml`.
4. Agregar la entrada en `src/config/navegacion.ts`.
5. `npm run build` en `apps/web` sin errores, y revisar claro, oscuro y móvil.

## 5. Estructura de estilos

```text
src/styles/
  tokens.css       colores, espacios, radios (claro y oscuro)   <- lo único que cambia la paleta
  base.css         reset, tipografía, foco, accesibilidad
  ui.css           componentes er-*
  panel.css        estructura del panel (pn-*)
  operaciones.css  mapa operativo y marcadores (op-*, mk-*)
```

## 6. Crítica del estado anterior (para no repetir)

- Cada página traía 550 a 800 líneas de CSS propio repetido (navbar, footer, colores). Ahora hay un solo sistema.
- El acento era azul genérico (`#2563eb`) y no coincidía con la app de Franco. Ahora todo usa el verde de Franco.
- Los popups del mapa metían la descripción del ciudadano directo en HTML: riesgo de XSS. Corregido en el mapa.
- Las cuentas demo usaban dominios `.gob.ec` reales: podía parecer suplantación. Ahora `@demo.esmeraldas-resiliente.ec`.
- Teléfonos de albergues inventados: con la regla de no inventar datos, en la semilla quedan vacíos.
- Insignias "EN VIVO 06:00 UTC" y flechas "→" en botones: decoración sin dato. El escenario es hora de Ecuador (UTC-5).
- Prototipo móvil (`fire-shield.html`): la coordenada aparece como `-0.9682`. Esmeraldas está en el hemisferio norte,
  la latitud es **+0.9682**. El backend rechaza latitudes fuera de la provincia (responde 400).
- `index.astro` y `login.astro` todavía tienen su CSS propio con el azul antiguo: tarea W1 en `docs/orquestacion/`.
