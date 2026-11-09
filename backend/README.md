# Backend

Rama responsable de la API, autenticación, persistencia e integraciones de servidor.

## Reglas de trabajo

- Mantener secretos en Cloudflare Secrets o en variables de entorno; nunca en el repositorio.
- Definir contratos y validaciones antes de conectar persistencia o servicios externos.
- Respetar Clean Architecture: dominio independiente de HTTP, base de datos y Cloudflare.
- No mover ni modificar `apps/mobile` o `apps/web` desde esta rama sin una decisión documentada.
- Añadir pruebas para autenticación, permisos, errores de red y datos inválidos.

## Próximo paso

Elegir el runtime del backend, crear los contratos compartidos y documentar los endpoints antes de implementar infraestructura.