# Orquestación del equipo y de las IAs

Claude orquesta: define contrato, arquitectura, diseño y revisa. Cada IA trabaja en su carril, con tareas
cortas y verificables. Nadie trabaja fuera de su carril sin pasar por aquí.

| Carril | Quién | Rama | Tareas |
|---|---|---|---|
| Web (`apps/web`) | Adrian + Gemini en la PC | `desarrollo-adrian` | `TAREAS_WEB_GEMINI.md` |
| Móvil (`apps/mobile` / `mobile`) | Franco + su IA | `desarrollofranco` | `TAREAS_MOVIL_FRANCO.md` |
| Backend (`apps/api`, `database`) | Adrian + Claude | `backend` | `TAREAS_BACKEND.md` |
| Contrato (`contrato/openapi.yaml`) | Solo con acuerdo de los tres carriles | — | — |

## Cómo pasarle una tarea a una IA

Copiar y pegar este bloque al inicio del chat, y debajo la tarea (por ejemplo "W2"):

```text
Lee primero AGENTS.md, docs/DISENO.md y docs/orquestacion/TAREAS_WEB_GEMINI.md (o el de tu carril).
Haz SOLO la tarea indicada. No toques archivos fuera de la lista "Archivos" de la tarea.
No cambies contrato/openapi.yaml, tokens.css, api.ts ni navegacion.ts salvo que la tarea lo diga.
Antes de terminar corre los comandos de "Verificación" y pégame la salida.
Al final dime: archivos cambiados, qué probaste y qué quedó pendiente.
```

## Reglas para todas las IAs

1. Una tarea = un commit pequeño con mensaje claro. Sin refactors de paso.
2. Contrato primero: si falta un campo, se pide el cambio en `contrato/openapi.yaml`; no se inventa en el cliente.
3. Nada de secretos en el repo. Nada de datos inventados presentados como reales (marcar "simulado").
4. Cero emojis en la interfaz. Iconos: Lucide en web, `Icons` de Material en Flutter.
5. Si la verificación falla, no se entrega: se arregla o se reporta el bloqueo.
6. Al terminar una tarea grande: una línea en `CHANGELOG.md` y una entrada en `bitacora.md`.
