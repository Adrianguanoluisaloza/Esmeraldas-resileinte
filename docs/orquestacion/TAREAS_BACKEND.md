# Tareas backend (`apps/api`)

Todos los módulos del reto tienen endpoint funcionando (ver `apps/api/README.md`). Receta para agregar algo:

1. Puerto en `src/dominio/puertos.ts` y regla pura en `src/dominio/` si aplica.
2. Implementación en `infraestructura/memoria/` **y** `infraestructura/postgres/`.
3. Caso de uso en `src/aplicacion/`, ruta en `src/http/rutas/`, validación en `src/http/esquemas.ts`.
4. Pruebas en `test/api.test.ts`. Correr `npm run ci` y `npm run test:db` (con el usuario `resiliente_app`).
5. Si toca SQL: dar el permiso mínimo en `database/03_rol_aplicacion.sh`.
6. Actualizar `contrato/openapi.yaml` y avisar a web y móvil.

## Siguientes mejoras

| Id | Qué | Valor |
|---|---|---|
| B1 | Rutas reales por la red vial (pgRouting) en lugar del tramo recto | GIS |
| B2 | Inventario por bodega (hoy es un stock único) | Módulo 5 |
| B3 | Migraciones numeradas (hoy el esquema se crea solo en la primera carga) | Mantenimiento |
| B4 | Sesión con cookie `HttpOnly` en lugar de token en `localStorage` | Seguridad |
| B5 | Fotos en Oracle Object Storage implementando `AlmacenFotos` | Escala |
