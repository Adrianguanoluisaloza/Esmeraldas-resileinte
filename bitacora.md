# Bitácora del proyecto

Este documento registra decisiones, avances, bloqueos y pendientes importantes. Debe mantenerse breve y orientado a hechos verificables.

## Formato de entrada

```markdown
## AAAA-MM-DD
- **Área:** mobile | web | infraestructura | producto
- **Cambio:** qué se hizo.
- **Decisión:** qué se decidió y por qué, si aplica.
- **Validación:** comandos, pruebas o revisión realizada.
- **Pendientes:** siguiente acción o bloqueo.
```

## 2026-11-09
- **Área:** arquitectura
- **Cambio:** Se definieron las reglas iniciales para Flutter, Astro, React, OpenStreetMap y Cloudflare.
- **Decisión:** La aplicación móvil seguirá Clean Architecture con principios SOLID; la web usará Astro con React como islas interactivas.
- **Validación:** Workspace revisado; inicialmente solo contiene el archivo de configuración `.code-workspace`.
- **Pendientes:** Crear los proyectos `apps/mobile` y `apps/web`, definir el proveedor de teselas, elegir estrategia de estado en Flutter y configurar CI/CD.
