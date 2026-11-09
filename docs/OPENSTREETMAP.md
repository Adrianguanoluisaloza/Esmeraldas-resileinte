# OpenStreetMap: mapas y autenticación

## Dependencias instaladas

### Web (`apps/web`)

```bash
npm install leaflet react-leaflet
```

- `leaflet`: motor del mapa.
- `react-leaflet`: componentes React para Leaflet.
- Astro carga el mapa como isla React cuando la página necesita interacción.

### Flutter (`apps/mobile`)

```bash
flutter pub add flutter_map latlong2 geolocator flutter_appauth
```

- `flutter_map`: widget de mapa.
- `latlong2`: coordenadas y distancias.
- `geolocator`: permisos y ubicación del dispositivo.
- `flutter_appauth`: flujo OAuth 2.0 con Authorization Code + PKCE.

## Teselas de mapa

Para desarrollo se puede usar:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

Siempre mostrar una atribución visible:

```text
© OpenStreetMap contributors
```

El servidor público de teselas de OpenStreetMap no debe tratarse como CDN de producción. Antes de publicar, elegir un proveedor de teselas que permita el volumen esperado, configurar caché y respetar sus políticas de uso. La atribución debe incluir también al proveedor cuando lo exija.

OpenStreetMap y sus teselas no son el sistema de autenticación de la aplicación. Mostrar el mapa no requiere crear una aplicación OAuth.

## Crear la aplicación OAuth de OSM

1. Iniciar sesión en [aplicaciones OAuth de OpenStreetMap](https://www.openstreetmap.org/oauth2/applications/new).
2. Crear una aplicación con un nombre identificable, por ejemplo `Esmeralda Web` o `Esmeralda Mobile`.
3. Registrar las URI de redirección exactas. No usar comodines.
4. Solicitar solo los scopes que realmente necesite la funcionalidad.
5. Guardar el `client_id` y, si OSM lo entrega, el `client_secret` fuera del repositorio.

Endpoints OAuth 2.0 de OSM:

```text
Autorización: https://www.openstreetmap.org/oauth2/authorize
Token:       https://www.openstreetmap.org/oauth2/token
```

Para lectura básica usar el scope mínimo disponible. No solicitar permisos de escritura (`write_api`, `write_notes`, etc.) hasta que exista una función que los necesite.

## Conexión de la web

La web Astro/React no debe contener un `client_secret`. El flujo recomendado es:

1. Astro/React solicita al backend una URL de autorización con `state` y PKCE.
2. El usuario inicia sesión en OSM.
3. OSM redirige al callback de un Cloudflare Worker.
4. El Worker valida `state`, intercambia el `code` por tokens y guarda los tokens en almacenamiento seguro.
5. El Worker crea una sesión propia para la web; el navegador nunca recibe el secreto de OSM.
6. El frontend consume únicamente endpoints propios del Worker.

Variables de entorno del Worker, nunca versionadas:

```text
OSM_CLIENT_ID
OSM_CLIENT_SECRET
OSM_REDIRECT_URI
SESSION_SECRET
```

Para desarrollo web, una URI típica es:

```text
http://localhost:8787/auth/osm/callback
```

Para producción debe ser una URI HTTPS del dominio real y estar registrada exactamente en OSM.

## Conexión de Flutter

La aplicación móvil debe usar Authorization Code + PKCE mediante `flutter_appauth`:

1. Generar `state` y `code_verifier`.
2. Abrir el endpoint de autorización con `client_id`, `redirect_uri`, `response_type=code`, `scope` y `code_challenge`.
3. Recibir el callback mediante un URI scheme o universal/app link registrado.
4. Validar `state`.
5. Intercambiar el código en el endpoint de token usando el `code_verifier`.
6. Guardar tokens en almacenamiento seguro del dispositivo y renovarlos según la respuesta del servidor.
7. Cerrar sesión eliminando tokens locales y revocando la sesión si el proveedor lo permite.

URI móvil de ejemplo, que debe registrarse en OSM y configurarse en Android/iOS:

```text
com.esmeralda.app://oauth/callback
```

Un `client_secret` no debe incluirse en el APK ni en el bundle de iOS, porque una aplicación móvil es un cliente público.

## Permisos móviles

Configurar los permisos de ubicación en las plataformas antes de usar `geolocator`:

- Android: `ACCESS_FINE_LOCATION` y/o `ACCESS_COARSE_LOCATION` en el manifiesto.
- iOS: `NSLocationWhenInUseUsageDescription` en `Info.plist`.
- Explicar al usuario por qué se solicita ubicación y manejar permiso denegado, ubicación desactivada y error de proveedor.

## Checklist antes de publicar

- [ ] Atribución de OpenStreetMap visible en web y móvil.
- [ ] Proveedor de teselas aprobado para el tráfico esperado.
- [ ] URI OAuth de producción registrada con HTTPS.
- [ ] Secretos almacenados en Cloudflare Secrets o en el gestor seguro de CI.
- [ ] No hay tokens, client secrets ni coordenadas sensibles en logs.
- [ ] `state` y PKCE validados en cada callback.
- [ ] Scopes limitados al mínimo necesario.
- [ ] Pruebas de login cancelado, callback inválido, token expirado y pérdida de red.
