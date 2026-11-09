# ESMERALDAS RESILIENTE 2026 — Estructura del proyecto (v2)

Plataforma de reporte y gestión de emergencias por El Niño. **Offline-first**: el ciudadano reporta sin internet y todo se sincroniza al volver la conexión.

## 1. Stack

| Capa | Tecnología | Responsable |
|---|---|---|
| Web (panel 911 + admin) | Astro + React + Leaflet/OpenStreetMap | Adrián |
| Móvil (ciudadano) | Flutter + Hive (cola offline) | Franco |
| Backend / API | Hono (TypeScript) + JWT | Adrián |
| Base de datos | PostgreSQL + PostGIS | Adrián |
| IA (opcional) | Modelo con visión, en el servidor | Adrián |
| Infraestructura | Oracle (VM) + Docker Compose + Cloudflare | Adrián |

## 2. Cobertura de los 6 módulos

Las bases no exigen completar los 6 módulos, pero se tocan todos en tres niveles de profundidad.

| Módulo | Nivel | Qué incluye | Se recorta primero |
|---|---|---|---|
| 1. Mapa de riesgos | **Núcleo** | Mapa de Esmeraldas, pines por gravedad, pocas zonas de riesgo (marcadas como simuladas), capa simple de ríos y vías | Capa de ríos y vías |
| 2. Reporte ciudadano | **Núcleo** | Foto, GPS, tipo, descripción, flujo offline completo | No se recorta |
| 3. Centro de operaciones | **Núcleo** | Lista con filtros, cambio de estado, contadores, aviso por sector escrito por el operador | Gráficos |
| 4. Albergues y vías | **Ligero** | Puntos de servicio (albergue o centro de salud) con cupo en color verde/ámbar/rojo; vías cortadas como tipo de reporte `via_bloqueada` | Rutas de evacuación dibujadas (si existen, marcadas como simuladas) |
| 5. Familias y asistencia | **Ligero** | Bloque plegable opcional en el reporte (personas, niños, adultos mayores, necesidades) y contadores en el panel | Bloque de familias en la app |
| 6. IA y análisis | **Mínimo** |(no implementar) Sugerencia de tipo y gravedad por foto (con explicación en palabras y confianza) y conteo por sector de dónde se repiten los eventos | La IA completa |

Inventarios y control de entregas (módulo 5) se presentan como mejora futura.

**Orden de recorte si falta tiempo:** IA, rutas dibujadas, gráficos, bloque de familias.

## 3. Estructura del repositorio (monorepo)

```
esmeraldas-resiliente/
├── README.md
├── BITACORA.md                 # registro de cambios y pendientes
├── docker-compose.yml          # api + postgres/postgis
├── .env.example                # sin claves reales
├── contrato/
│   └── openapi.yaml            # ÚNICA fuente de verdad de la API
│
├── backend/                    # ~25-30 archivos, ~2.000-2.500 líneas
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── index.ts            # app principal
│       ├── config/env.ts
│       ├── db/
│       │   ├── client.ts
│       │   ├── migrations/     # 001_usuarios ... 007_alertas
│       │   └── seed.sql        # datos del escenario jueves 06:00
│       ├── middleware/         # auth, roles, rateLimit, errores
│       ├── routes/             # auth, reportes, fotos, zonas, puntos_servicio,
│       │                       # alertas, estadisticas, usuarios, ia
│       ├── services/           # fotos (guardar/comprimir/miniatura), clasificador-ia
│       └── lib/                # geo, uuid, validaciones
│
├── web/                        # ~35-45 archivos, ~3.000-3.500 líneas
│   └── src/
│       ├── pages/              # login, panel, reportes, reportes/[id],
│       │                       # puntos-servicio, estadisticas, admin/usuarios
│       ├── components/         # MapaEsmeraldas, PinReporte, PanelReporte,
│       │                       # FotoConEsqueleto, BadgeEstado, Filtros,
│       │                       # Graficos, TarjetaFamilias, GuionDemo
│       ├── lib/                # api (cliente), session, tipos
│       └── public/geo/         # límites de Esmeraldas, zonas (GeoJSON)
│
├── mobile/                     # ~25-30 archivos, ~2.500-3.000 líneas
│   └── lib/
│       ├── main.dart
│       ├── core/               # api_client, config, enums
│       ├── data/               # cola offline en Hive, models
│       └── features/
│           ├── auth/           # login
│           ├── reporte/        # cámara + GPS + tipo + descripción + bloque familias
│           ├── mis_reportes/   # lista con estado (pendiente/enviando/enviado)
│           └── sync/           # reintentos con espera, estado por paso
│
└── docs/                       # ~10-15 archivos
    ├── arquitectura.md         # diagrama de componentes (Mermaid)
    ├── modelo-datos.md         # diagrama ER (Mermaid)
    ├── manual-usuario.md
    └── guion-demo.md           # escenario jueves 06:00 paso a paso
    ├── AGENTS.md                   # reglas de arquitectura y colaboración
    ├── bitacora.md                 # registro de cambios y pendientes
    ├── CHANGELOG.md                # cambios visibles y contratos
**Total estimado:** 90-110 archivos y 8.000-9.500 líneas (±30%), sin código autogenerado.
    ├── contrato/
    │   └── openapi.yaml            # fuente de verdad de la API

    ├── backend/                    # espacio de trabajo de la rama backend
    │   └── README.md
| `historial_estados` | id, reporte_id, estado_anterior, estado_nuevo, operador_id, fecha, nota |
    ├── frontend/                   # espacio de trabajo de la rama desarrollo-adrian
    │   └── README.md
- **Zonas:** `GET /zonas`
    ├── mobile/                     # espacio de trabajo de la rama desarrollofranco
    │   └── README.md
    │
    ├── apps/
    │   ├── web/                    # aplicación Astro + React + Leaflet
    │   └── mobile/                 # aplicación Flutter + flutter_map
| Crear reporte y foto | Sí | Sí | Sí |
    └── docs/                       # documentación técnica
        └── OPENSTREETMAP.md        # teselas, atribución y OAuth

## 8. Flujo offline (el corazón de la demo)
    Las carpetas `backend/`, `frontend/` y `mobile/` son espacios de trabajo por rama. El código ejecutable actual permanece en `apps/` hasta que una integración sea revisada.
1. Sin conexión, el ciudadano toma la foto. La app la comprime (lado largo ~1280 px, calidad 70-80%), la guarda como archivo en la carpeta de la app y escribe en Hive: ID único, ruta de la foto, GPS, precisión, hora **del momento de captura** y estado *pendiente*. La foto no se guarda dentro de Hive.
2. Vuelve la conexión (datos móviles o wifi). La app no se fía solo de "hay wifi": intenta enviar y reintenta con espera si falla.
3. **Paso 1:** envía los datos livianos. En el mapa aparece el pin con el **esqueleto** de foto.
4. **Paso 2:** envía la foto comprimida. El servidor valida el archivo, genera miniatura y el esqueleto se reemplaza por la imagen.
5. La IA sugiere tipo y gravedad con explicación en palabras (marcada como "sugerencia, no oficial"). El operador 911 confirma o corrige.
6. Reintentos seguros: el UUID evita duplicados, y la cola recuerda en qué paso se quedó.

**GPS sin internet:** el celular solo recibe de los satélites; lo que se envía son las coordenadas ya calculadas. En modo avión hay que volver a prender la ubicación, y bajo techo el primer fix puede tardar. Plan B: última ubicación conocida marcada como aproximada, con su precisión en metros.

## 9. Fotos y espacio

- **En el celular:** compresión antes de guardar (4-8 MB baja a 150-400 KB).
- **En el servidor:** validar que sea imagen, tope de ~2 MB, y miniatura de 20-40 KB para pines y listas.
- **Uso real (estimado):** con 300 KB por foto, mil reportes al día con 2 fotos son unos 18 GB al mes. Para escalar, mover a almacenamiento tipo objeto (por ejemplo Cloudflare R2; verificar precios actuales).
- **Después:** máximo 3 fotos por reporte, política de retención y acceso a la foto completa solo para roles autorizados.

## 10. Demo: las 8 preguntas de la sección 7.2

| Pregunta de las bases | Dónde se responde |
|---|---|
| ¿Qué está sucediendo en el territorio? | Panel con contadores y lista de incidentes |
| ¿Dónde se están produciendo las emergencias? | Mapa con pines por gravedad |
| ¿Cuántas personas y familias están afectadas? | Contador de asistencia familiar |
| ¿Qué sectores requieren atención prioritaria? | Gravedad por sector y recurrencia de eventos |
| ¿Qué vías se encuentran interrumpidas? | Pines de tipo `via_bloqueada` |
| ¿Dónde existen albergues disponibles? | Puntos de servicio con cupo en color |
| ¿Qué recursos deben movilizarse? | Necesidades pendientes sumadas |
| ¿Cómo se coordina la atención? | Estados, historial y alertas por sector |

**Guion del jueves 06:00 (4 pasos):**
1. Emergencia: se activa modo avión en el celular.
2. Se genera un reporte con foto, GPS y familia afectada.
3. Vuelve la señal por datos móviles: sincroniza la fase 1 (datos) y la fase 2 (foto).
4. En el panel 911 se responden las preguntas, se actualiza el cupo del albergue y se emite una alerta por sector.

## 11. Ramas y revisión

- `main`: protegida, nadie escribe directo.
- `backend`: backend y contratos de servidor.
- `desarrollo-adrian`: frontend Astro/React y despliegue web.
- `desarrollofranco`: aplicación móvil Flutter.
- Cada rama recibe cambios mediante Pull Request a `main` después de revisión.
- El contrato `contrato/openapi.yaml` se cambia **antes** que el código.
- Cada tarea termina con una línea en `bitacora.md` (fecha, quién, qué cambió, qué falta) y con cómo verificarla.

## 12. Entregables del reto vs. dónde están

| Entregable | Dónde |
|---|---|
| Prototipo funcional | `apps/web/` + `apps/mobile/` |
| Arquitectura de software | `docs/arquitectura.md` |
| Modelo de datos (ER) | `docs/modelo-datos.md` |
| Base de datos con registros de prueba | `backend/src/db/seed.sql` |
| Componente geográfico | `apps/web/` + `apps/mobile/` + PostGIS |
| Servicios de integración | `backend/` + `contrato/openapi.yaml` |
| Documentación técnica y manual | `README.md` + `docs/manual-usuario.md` |
| Presentación demostrativa | `docs/guion-demo.md` |

## 13. Riesgos a vigilar

- La cola offline en el celular real: probar en modo avión desde la primera noche. Debe estar en el Flutter real, no en una maqueta.
- La reconexión de la demo: usar datos móviles, no el wifi de la universidad.
- Dar las mejores horas a: cola offline, consultas del mapa y login con roles.
- Datos oficiales y datos simulados deben verse diferenciados (rutas, zonas y alertas de prueba marcadas como simuladas).
- La IA nunca se presenta como alerta oficial ni con porcentajes que no pueda medir; mostrar explicación en palabras y confianza, con aviso de que es apoyo a la decisión del operador.
- Verificar nombres de lugares y datos de contacto antes de usarlos, aunque sea simulación. La sigla correcta de la universidad es UTLVTE.
- Los mapas offline en el celular quedan como mejora futura (paquete de teselas propio); no entran en el hackathon.
