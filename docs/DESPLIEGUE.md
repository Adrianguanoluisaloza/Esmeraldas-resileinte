# Despliegue: Oracle Cloud (API + PostGIS) y Cloudflare (web)

```text
 Celular (Flutter, Hive offline) ──┐
                                   ├── HTTPS ──> Cloudflare ──> VM Oracle: docker compose
 Navegador (Astro en CF Pages) ────┘                             ├── api (Hono, puerto 3000)
                                                                  └── db  (PostgreSQL 16 + PostGIS)
```

| Pieza | Dónde | Por qué |
|---|---|---|
| Web `apps/web` | Cloudflare Pages / Workers assets (`wrangler.jsonc`) | Estática, gratis, CDN cerca del usuario |
| API `apps/api` | VM de Oracle Cloud con Docker | Necesita proceso largo (WebSocket) y acceso a PostGIS |
| Base | Mismo `docker compose` en la VM, sin puerto público | Solo la API la ve |
| Fotos | Volumen Docker `fotos` | Pasar a Oracle Object Storage o R2 implementando `AlmacenFotos` |

## 1. Local (PC del equipo)

Sin Docker, demo rápida en memoria:

```bash
cd apps/api && npm install
```

```bash
JWT_SECRET=una-clave-larga-de-al-menos-32-caracteres DEMO_PASSWORD=demo-resiliente-2026 npm run dev
```

Con PostGIS real:

```bash
cp .env.example .env
```

Completar `POSTGRES_PASSWORD`, `JWT_SECRET` (`openssl rand -base64 48`) y `CORS_ORIGENES`, luego:

```bash
docker compose up -d --build
```

```bash
docker compose exec -e DEMO_PASSWORD=demo-resiliente-2026 api node dist/scripts/crearUsuariosDemo.js
```

Web apuntando a la API:

```bash
cd apps/web && PUBLIC_API_URL=http://localhost:3000 npm run dev
```

Celular (emulador Android) contra la PC: `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (ya es el valor por defecto en `AppConfig`).

## 2. Oracle Cloud (VM)

1. VM Ubuntu (la Always Free ARM sirve). Instalar Docker y el plugin compose.
2. Clonar el repo, crear `.env` en la raíz (nunca subirlo). `APP_ENV=production`.
3. `docker compose up -d --build`. Verificar `curl localhost:3000/salud`.
4. **No abrir el puerto 5432.** En la lista de seguridad de Oracle solo 80/443 (o nada si se usa túnel).
5. HTTPS, una de dos:
   - **Cloudflare Tunnel** (recomendado, sin abrir puertos): `cloudflared tunnel` hacia `http://localhost:3000`
     con el subdominio `api.<dominio>`. Activar WebSockets en Cloudflare (vienen activos por defecto).
   - Caddy o Nginx con certificado, delante del puerto 3000.
6. `CORS_ORIGENES` con la URL exacta de la web (la de Cloudflare Pages y el dominio propio).
7. Copias de la base: `docker compose exec db pg_dump -U resiliente resiliente > respaldo.sql` (programarlo con cron).

## 3. Cloudflare (web)

La URL de la API queda **fija dentro de la web al compilar**. Si se publica sin `PUBLIC_API_URL`, la web apunta a
`localhost:3000` y en internet no funciona ningún rol. Por eso:

```bash
cd apps/web && PUBLIC_API_URL=https://api.<dominio> npm run build
```

```bash
cd ../.. && npx wrangler deploy
```

En el `.env` de la API, `CORS_ORIGENES` debe incluir la URL exacta de la web publicada. Si cambia la URL de la API
(por ejemplo un túnel rápido nuevo), hay que volver a compilar y publicar la web. Un túnel con nombre fijo evita eso.
Nunca publicar sin orden de Adrian. Primero a una rama de prueba.

## 4. Variables

Todas documentadas en `.env.example`. Reglas:

- Solo las `PUBLIC_*` llegan al navegador. Nada secreto con ese prefijo.
- `JWT_SECRET`, `POSTGRES_PASSWORD`, `DEMO_PASSWORD`: solo en el `.env` de la VM o en secretos de CI.
- Cambiar `DEMO_PASSWORD` después del hackathon y borrar las cuentas demo si el sistema pasa a uso real.

## 5. Antes de la demo (checklist)

- [ ] `curl https://api.<dominio>/salud` responde `{"estado":"ok"}`.
- [ ] Login con las 3 cuentas demo desde la web.
- [ ] El celular sincroniza un reporte en modo avión -> conexión -> aparece en el mapa del COE sin recargar.
- [ ] `docker compose down -v && docker compose up -d` recarga la semilla del escenario 06:00 limpia.
- [ ] Plan B: si la VM falla, la web funciona con datos simulados (aviso morado "Mostrando datos simulados").
