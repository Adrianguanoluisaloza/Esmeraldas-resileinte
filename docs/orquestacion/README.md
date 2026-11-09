# Organización del equipo

Cada integrante trabaja en su carril con tareas cortas y verificables. El contrato
`contrato/openapi.yaml` es el punto de unión: nadie lo cambia sin acuerdo de los tres carriles.

| Carril | Responsable | Rama | Tareas |
|---|---|---|---|
| Web (`apps/web`) | Adrian | `desarrollo-adrian` | `TAREAS_WEB.md` |
| Móvil (`mobile`) | Franco | `desarrollofranco` | `TAREAS_MOVIL_FRANCO.md` |
| Backend (`apps/api`, `database`) | Adrian | `backend` | `TAREAS_BACKEND.md` |

## Cómo se toma una tarea

1. Leer `AGENTS.md`, `docs/DISENO.md` y el archivo de tareas del carril.
2. Hacer solo la tarea elegida y tocar solo los archivos que indica.
3. Correr los comandos de verificación de la tarea antes de subir.
4. Un commit pequeño por tarea, con mensaje claro.

## Reglas

1. Sin refactors de paso.
2. Contrato primero: si falta un campo, se pide el cambio en `contrato/openapi.yaml`; no se inventa en el cliente.
3. Nada de secretos en el repo. Nada inventado presentado como real (marcar "simulado").
4. Cero emojis en la interfaz. Iconos: Lucide en web, `Icons` de Material en Flutter.
5. Si la verificación falla, no se sube.
6. Al terminar una tarea grande: una línea en `CHANGELOG.md` y una entrada en `bitacora.md`.
