# Hoja de seguridad

Qué protege el sistema, cómo y qué falta. Se revisa antes de cada despliegue.

## 1. Controles aplicados

| Área | Control | Dónde |
|---|---|---|
| Autenticación | JWT HS256 con expiración (`JWT_MINUTOS`), secreto de 32+ caracteres; en producción se rechaza un secreto de ejemplo | `infraestructura/seguridad/tokens.ts`, `config.ts` |
| Contraseñas | scrypt con sal aleatoria y comparación en tiempo constante | `infraestructura/seguridad/claves.ts` |
| Registro | Siempre crea ciudadano; campos extra rechazados (nadie se pone `rol: admin`) | `http/esquemas.ts` |
| Login | Mismo mensaje si el correo no existe o la clave falla; 20 intentos por IP cada 10 min | `aplicacion/auth.ts`, `http/limites.ts` |
| Autorización | Rol verificado en el servidor en cada ruta; el ciudadano solo ve sus reportes; ocultar menús en la web no cuenta como seguridad | `http/contexto.ts`, casos de uso |
| Validación | zod estricto, límites de tamaño, coordenadas dentro de la provincia, UUID en rutas | `http/esquemas.ts` |
| Inyección SQL | Solo consultas parametrizadas (`$1, $2`) | `infraestructura/postgres/` |
| XSS | React escapa por defecto; el HTML de los popups del mapa pasa por `escaparHtml` | `apps/web/src/lib/escapar.ts` |
| Fotos | Tipo detectado por bytes reales (JPEG/PNG), 2 MB máximo, nombre = UUID, solo el autor sube | `http/rutas/reportes.ts` |
| CORS | Lista exacta de orígenes; sin comodines; en producción solo `https` | `config.ts`, `http/app.ts` |
| Cabeceras | HSTS, `nosniff`, `X-Frame-Options`, `Referrer-Policy` (secureHeaders); `Cache-Control: no-store` en datos privados | `http/app.ts` |
| Abuso | Límite de escrituras por IP (`LIMITE_ESCRITURAS_MINUTO`), cuerpo máximo 3 MB | `http/limites.ts`, `http/app.ts` |
| Tiempo real | WebSocket exige token; el ciudadano solo recibe alertas, cupos, vías y sus propios reportes; entregas solo COE | `http/tiempoReal.ts` |
| Registros | Sin cuerpo, sin query (puede llevar coordenadas), sin IP; errores internos con id de petición, sin detalle al cliente | `http/app.ts` |
| Base de datos | La API usa `resiliente_app`: sin DELETE, sin DDL, UPDATE solo en columnas necesarias, `statement_timeout` 10 s | `database/03_rol_aplicacion.sh` |
| Auditoría | `reportes_historial` y `entregas` son de solo inserción (trigger que bloquea UPDATE/DELETE incluso al dueño) | `database/01_schema_postgis.sql` |
| Integridad | CHECK de catálogos, coordenadas, cantidades y coherencia de vulnerables; claves foráneas | `database/01_schema_postgis.sql` |
| Contenedores | Base sin puerto publicado; API solo en `127.0.0.1` (entra por Cloudflare Tunnel), solo lectura, sin capacidades, `no-new-privileges`, usuario `node` | `docker-compose.yml`, `apps/api/Dockerfile` |
| Secretos | Solo en `.env` del servidor (ignorado por Git); en la web solo variables `PUBLIC_*` | `.env.example`, `.gitignore` |

## 2. Antes de publicar (lista de verificación)

- [ ] `.env` del servidor con `APP_ENV=production` y claves nuevas: `openssl rand -base64 48` para `JWT_SECRET`,
      `POSTGRES_PASSWORD` y `APP_DB_PASSWORD` distintas entre sí.
- [ ] `CORS_ORIGENES` solo con los dominios https reales de la web.
- [ ] `CONFIAR_EN_PROXY=true` solo si la API está detrás de Cloudflare Tunnel.
- [ ] Puertos abiertos en Oracle: ninguno para 3000 ni 5432 (todo entra por el túnel).
- [ ] Cambiar `DEMO_PASSWORD` o no crear cuentas demo fuera del hackathon.
- [ ] `npm audit --omit=dev` en `apps/api` y `apps/web` sin vulnerabilidades altas.
- [ ] Respaldo de la base programado (`pg_dump`) y probado restaurando en otra base.

## 3. Datos personales

- Los reportes guardan coordenadas, número de personas, niños y adultos mayores. No se guardan cédulas ni teléfonos
  de ciudadanos.
- El listado general de reportes y las entregas son solo para el COE.
- El sistema no reemplaza al ECU 911 ni a las alertas oficiales; las alertas simuladas se marcan como tales.

## 4. Riesgos conocidos y siguiente paso

| Riesgo | Mitigación actual | Siguiente paso |
|---|---|---|
| Token en `localStorage` de la web (robable si hubiera XSS) | Sin `innerHTML` con datos externos, React escapa | Cookie `HttpOnly` + `SameSite=Strict` emitida por la API |
| Token del WebSocket en la URL | Vida corta del JWT, registros sin query | Ticket de un solo uso para abrir el socket |
| Límites de peticiones en memoria (una instancia) | Suficiente para una VM | Contador compartido si se escala a varias instancias |
| Sin cierre de sesión en servidor | Expiración del JWT | Lista de revocación o tokens de refresco |
| Fotos en disco del servidor | Volumen Docker con respaldo | Oracle Object Storage o R2 con URLs firmadas |

## 5. Reportar un problema de seguridad

Escribir directamente al responsable del backend, sin abrir un issue público. Incluir pasos para reproducirlo.
