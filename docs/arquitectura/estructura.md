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
├── AGENTS.md                   # reglas del proyecto
├── README.md
├── bitacora.md                 # registro de avances y decisiones
├── CHANGELOG.md                # cambios visibles y de contrato
├── docker-compose.yml          # PostGIS + API (Oracle Cloud y local)
├── .env.example                # sin claves reales
├── contrato/
│   └── openapi.yaml            # fuente de verdad de la API
├── database/
│   ├── 01_schema_postgis.sql   # tablas, geometrías e índices
│   ├── 02_seed_escenario_06am.sql  # escenario jueves 06:00 (simulado)
│   └── 03_rol_aplicacion.sh    # usuario de la API con permisos mínimos
├── apps/
│   ├── api/                    # Hono + TypeScript (Clean Architecture)
│   │   └── src/
│   │       ├── dominio/        # entidades, catálogos, puertos, errores
│   │       ├── aplicacion/     # casos de uso: auth, reportes, territorio, operación
│   │       ├── infraestructura/  # postgres, memoria, fotos, correo, seguridad, ia (Gemini)
│   │       └── http/           # rutas, esquemas zod, límites, WebSocket
│   └── web/                    # Astro + islas React + Leaflet
│       └── src/                # pages, components, layouts, lib, styles
├── mobile/                     # Flutter + Hive (cola offline)
│   └── lib/
│       ├── main.dart           # composición de dependencias
│       ├── core/               # config, network, location, routing, theme, security, services, widgets
│       └── features/           # cada función con sus capas
│           ├── auth/           # domain · data · presentation (correo y Google)
│           ├── reporte/        # domain (casos de uso) · data (cola Hive, modelos) · presentation
│           ├── sync/           # data (envío en 2 pasos) · presentation (banner)
│           ├── mis_reportes/   # presentation
│           ├── albergues/      # data (modelo) · presentation (directorio, tarjeta compartida)
│           ├── vias/           # domain · data · presentation (estado de vías)
│           ├── autoproteccion/ # domain · data · presentation (contactos y guía del ciudadano)
│           ├── operaciones/    # data (repositorio) · presentation (situación, incidentes, alertas)
│           ├── analisis/       # domain · data · presentation (indicadores, sectores, asistencia)
│           └── admin/          # presentation (usuarios, auditoría y cuenta)
└── docs/
    ├── ARQUITECTURA.md         # componentes y flujo (Mermaid)
    ├── MODELO_DATOS.md         # diagrama ER (Mermaid)
    ├── MANUAL_USUARIO.md       # uso por rol
    ├── DOCUMENTACION_TECNICA.md
    ├── PRUEBAS_Y_COSTOS.md
    ├── arquitectura/           # este archivo y decisiones
    └── orquestacion/           # tareas por carril
```

## 4. Flujo offline (el corazón de la demo)
    Las carpetas `backend/`, `frontend/` y `mobile/` son espacios de trabajo por rama. El código ejecutable actual permanece en `apps/` hasta que una integración sea revisada.
1. Sin conexión, el ciudadano toma la foto. La app la comprime (lado largo ~1280 px, calidad 70-80%), la guarda como archivo en la carpeta de la app y escribe en Hive: ID único, ruta de la foto, GPS, precisión, hora **del momento de captura** y estado *pendiente*. La foto no se guarda dentro de Hive.
2. Vuelve la conexión (datos móviles o wifi). La app no se fía solo de "hay wifi": intenta enviar y reintenta con espera si falla.
3. **Paso 1:** envía los datos livianos. En el mapa aparece el pin con el **esqueleto** de foto.
4. **Paso 2:** envía la foto comprimida. El servidor valida el archivo, genera miniatura y el esqueleto se reemplaza por la imagen.
5. La IA sugiere tipo y gravedad con explicación en palabras (marcada como "sugerencia, no oficial"). El operador 911 confirma o corrige.
6. Reintentos seguros: el UUID evita duplicados, y la cola recuerda en qué paso se quedó.

**GPS sin internet:** el celular solo recibe de los satélites; lo que se envía son las coordenadas ya calculadas. En modo avión hay que volver a prender la ubicación, y bajo techo el primer fix puede tardar. Plan B: última ubicación conocida marcada como aproximada, con su precisión en metros.

## 5. Fotos y espacio

- **En el celular:** compresión antes de guardar (4-8 MB baja a 150-400 KB).
- **En el servidor:** validar que sea imagen, tope de ~2 MB, y miniatura de 20-40 KB para pines y listas.
- **Uso real (estimado):** con 300 KB por foto, mil reportes al día con 2 fotos son unos 18 GB al mes. Para escalar, mover a almacenamiento tipo objeto (por ejemplo Cloudflare R2; verificar precios actuales).
- **Después:** máximo 3 fotos por reporte, política de retención y acceso a la foto completa solo para roles autorizados.

## 6. Demo: las 8 preguntas de la sección 7.2

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

## 7. Ramas y revisión

- `main`: protegida, nadie escribe directo.
- `backend`: backend y contratos de servidor.
- `desarrollo-adrian`: frontend Astro/React y despliegue web.
- `desarrollofranco`: aplicación móvil Flutter.
- Cada rama recibe cambios mediante Pull Request a `main` después de revisión.
- El contrato `contrato/openapi.yaml` se cambia **antes** que el código.
- Cada tarea termina con una línea en `bitacora.md` (fecha, quién, qué cambió, qué falta) y con cómo verificarla.

## 8. Entregables del reto vs. dónde están

| Entregable | Dónde |
|---|---|
| Prototipo funcional | `apps/web/` + `mobile/` + `apps/api/` |
| Arquitectura de software | `docs/ARQUITECTURA.md` |
| Modelo de datos (ER) | `docs/MODELO_DATOS.md` |
| Base de datos con registros de prueba | `database/02_seed_escenario_06am.sql` |
| Componente geográfico | `apps/web/` + `mobile/` + PostGIS |
| Servicios de integración | `apps/api/` + `contrato/openapi.yaml` |
| Documentación técnica y manual | `docs/DOCUMENTACION_TECNICA.md` + `docs/MANUAL_USUARIO.md` |
| Presentación demostrativa | Presentación en el USB de entrega |

## 9. Riesgos a vigilar

- La cola offline en el celular real: probar en modo avión desde la primera noche. Debe estar en el Flutter real, no en una maqueta.
- La reconexión de la demo: usar datos móviles, no el wifi de la universidad.
- Dar las mejores horas a: cola offline, consultas del mapa y login con roles.
- Datos oficiales y datos simulados deben verse diferenciados (rutas, zonas y alertas de prueba marcadas como simuladas).
- La IA nunca se presenta como alerta oficial ni con porcentajes que no pueda medir; mostrar explicación en palabras y confianza, con aviso de que es apoyo a la decisión del operador.
- Verificar nombres de lugares y datos de contacto antes de usarlos, aunque sea simulación. La sigla correcta de la universidad es UTLVTE.
- Los mapas offline en el celular quedan como mejora futura (paquete de teselas propio); no entran en el hackathon.
