# Guía y reglas de nuestro proyecto

## Qué leer antes de tocar código

1. Este archivo (mis acuerdos base con Franco para mantener todo ordenado).
2. `docs/orquestacion/README.md`: cómo nos dividimos los carriles entre Franco y yo.
3. El carril que corresponda: `docs/orquestacion/TAREAS_WEB.md`, `TAREAS_MOVIL_FRANCO.md` o `TAREAS_BACKEND.md`.
4. Diseño y operación: `docs/DISENO.md`, `docs/DESPLIEGUE.md`, `docs/SEGURIDAD.md`, `contrato/openapi.yaml`, `docs/ROLES.md`, `docs/ARQUITECTURA.md`, `docs/MODELO_DATOS.md` y `docs/MANUAL_USUARIO.md`.

Escenario de prueba del proyecto: "Jueves 06:00 AM".

## Acuerdos que no rompemos

1. Cero emojis en la interfaz (web y app). Usamos iconos Lucide en web y Material en Flutter.
2. Nunca subir directo a `main` sin revisar pruebas y compilación primero.
3. Contrato primero: ni la web ni la app inventan campos que no estén en `contrato/openapi.yaml`.
4. Diferenciar siempre en la interfaz: reporte ciudadano, dato simulado y alerta oficial.
5. Nada inventado presentado como real (teléfonos, cifras, instituciones). Si es de demo, se marca "simulado".
6. Cero secretos en el repo. Solo variables `PUBLIC_*` llegan al navegador.
7. Diseño limpio con tokens `--er-*`, sin degradados ni colores sueltos (ver `docs/DISENO.md`).
8. Documentar cada cambio grande en `CHANGELOG.md` y `bitacora.md`.
9. Usamos IA como apoyo puntual de desarrollo y también dentro del producto (asistente de clasificación con Gemini para el operador, siempre con confirmación humana), pero toda la lógica y las pruebas las validamos nosotros antes de integrar.

## Stack del proyecto

- **App móvil (`mobile/`):** Flutter y Dart con Clean Architecture (`presentation`, `domain`, `data`) y Hive para soporte sin conexión.
- **Mapa:** OpenStreetMap con atribución visible y respeto a las políticas de uso de teselas.
- **Web (`apps/web/`):** Astro con islas React solo donde haya estado o interacción real, desplegada en Cloudflare Pages.
- **Backend (`apps/api/`):** Hono + TypeScript en Node 22, Clean Architecture, validación con `zod`, JWT + Firebase Auth, WebSocket. Soporta PostgreSQL 16 + PostGIS (`database/`) y modo memoria (`ALMACEN=memoria`) para pruebas rápidas.
- **Infraestructura:** Docker Compose en VM (ARM) detrás de Cloudflare Tunnel (`https://api.tu-dominio.com`), con los datos reales solo en `.env` fuera del repositorio.
- **Roles:** ciudadano, ECU 911 (`operador_911`), Bomberos, Policía y administrador (`docs/ROLES.md`).

## Estructura del repositorio

```text
apps/
  api/                    # Backend Hono + PostGIS (dominio, aplicacion, infraestructura, http)
  web/                    # Proyecto Astro + islas React
mobile/                   # App Flutter (único proyecto móvil)
database/                 # 01 esquema, 02 semilla del escenario, 03 usuario de la API
docker-compose.yml        # PostGIS + API
contrato/                 # Contrato OpenAPI compartido
docs/                     # Arquitectura, diseño, seguridad, despliegue y orquestación
bitacora.md
CHANGELOG.md
AGENTS.md
```

## Calidad y verificación antes de integrar

- **Flutter:** `dart format`, `flutter analyze` y pruebas en `mobile/test/`.
- **Web:** `cd apps/web && npm run build`.
- **API:** `cd apps/api && npm run ci` (typecheck + pruebas).
- **Ramas:** `main` (integración), `desarrollo-adrian` (web/coordinación), `desarrollofranco` (app móvil) y `backend` (API y base de datos).
