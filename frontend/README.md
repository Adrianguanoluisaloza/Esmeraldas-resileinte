# Frontend

Rama responsable de la experiencia web y de la integración con Astro, React y Cloudflare Pages.

## Reglas de trabajo

- Mantener `apps/web` como la aplicación web existente; esta carpeta no la reemplaza.
- Usar Astro para contenido estático y React solo para interacción y estado real.
- No exponer secretos: solo las variables con prefijo `PUBLIC_` pueden llegar al cliente.
- Mantener la atribución de OpenStreetMap visible y respetar las políticas del proveedor de teselas.
- Validar accesibilidad, responsive, `npm run build` y estados de carga o error antes de publicar.

## Próximo paso

Crear componentes de mapa y autenticación como cambios pequeños, integrándolos en `apps/web` después de revisión.