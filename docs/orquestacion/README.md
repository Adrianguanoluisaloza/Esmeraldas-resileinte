# Cómo organizamos el equipo (Adrian y Franco)

Nos dividimos el proyecto en tres carriles con tareas cortas para no pisarnos archivos. El contrato `contrato/openapi.yaml` es nuestro punto de unión: si hace falta un campo nuevo, primero se acuerda ahí.

| Carril | Responsable | Rama | Tareas |
|---|---|---|---|
| Web (`apps/web`) | Adrian | `desarrollo-adrian` | `TAREAS_WEB.md` |
| Móvil (`mobile`) | Franco | `desarrollofranco` | `TAREAS_MOVIL_FRANCO.md` |
| Backend (`apps/api`, `database`) | Adrian | `backend` | `TAREAS_BACKEND.md` |

## Flujo de trabajo que seguimos

1. Revisar `AGENTS.md`, `docs/DISENO.md` y la tarea del carril correspondiente.
2. Trabajar solo los archivos de la tarea sin mezclar refactors ajenos.
3. Si usamos IA como apoyo en alguna pieza, revisar el código generado, correr las pruebas y validar el contrato antes de subir.
4. Correr las verificaciones del módulo (`npm run ci`, `npm run build`, `flutter test`).
5. Anotar los avances importantes en `CHANGELOG.md` y `bitacora.md`.
