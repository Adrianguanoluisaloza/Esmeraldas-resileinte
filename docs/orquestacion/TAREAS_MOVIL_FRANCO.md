# Tareas móvil para Franco y su IA

Carril: app Flutter (rama `desarrollofranco`). Complementa `indicaciones-flutter-franco.md` y
`decision-mapas-hive-postgis.md`. La API ya responde de verdad: estas tareas conectan la app.

## Lo que ya está listo en el backend para ti

| Paso de tu `SyncWorkerService` | Endpoint | Respuesta |
|---|---|---|
| `verificarSaludServidor` | `GET /salud` | `200 {"estado":"ok"}` (503 si la base cayó) |
| Login | `POST /auth/login {correo, password}` | `{token, usuario}`; guardar token en `flutter_secure_storage` |
| Paso 1 datos | `POST /reportes` con `Authorization: Bearer` | **201** nuevo, **200** si ya lo tenía (reenvío seguro) |
| Paso 2 foto | `POST /reportes/{id}/foto` multipart, campo **`foto`** | 201. JPEG o PNG reales, máx 2 MB. Reenviar reemplaza |
| Directorio offline | `GET /puntos-servicio` (sin token) | lista con `estado_cupo` y `cupos_libres` |
| Albergue más cercano | `GET /puntos-servicio/cercanos?lat=&lng=&personas=` | ordenado por distancia real (PostGIS) |
| Mis reportes | `GET /reportes` con token de ciudadano | solo los del usuario |

Errores: siempre `{"codigo": "...", "mensaje": "..."}`. Para la cola:
- `400 VALIDACION` o `409 CONFLICTO` -> estado `error` (no reintentar, el dato está mal).
- `401 NO_AUTENTICADO` -> pedir login otra vez, no borrar la cola.
- Sin respuesta, timeout o `5xx` -> reintentar con tu backoff (5, 15, 30, 60 s).

Cuentas demo: `ciudadano@demo.esmeraldas-resiliente.ec`, clave `demo-resiliente-2026` (solo para el hackathon).

## M1. Implementar `DioApiClient` de verdad

**Archivos:** `lib/core/network/api_client.dart`.
**Pasos:** `Dio` con `baseUrl = AppConfig.apiBaseUrl`, timeouts de 5 s (salud) y 20 s (foto). Interceptor que agrega
`Authorization: Bearer <token>` leyendo de `AuthRepository`. Mapear los códigos de arriba a `Failure`s.
Foto con `FormData.fromMap({'foto': await MultipartFile.fromFile(ruta, filename: '$id.jpg')})`.
**Hecho cuando:** en modo avión el reporte queda `pendiente`; al volver la red pasa a `enviado` y aparece en el
mapa del COE de la web sin recargar.

## M2. Login real

**Archivos:** `features/auth/...`. Llamar `POST /auth/login`, guardar `token` y `usuario` en almacenamiento seguro.
Si la API devuelve 401 en cualquier momento: volver al login sin borrar la cola de Hive.

## M3. Revisar la latitud (bug del prototipo)

El prototipo `fire-shield.html` muestra `-0.9682, -79.6517`. Esmeraldas está al **norte**: la latitud es positiva
(`0.9682`). Verificar que `toApiPayload()` mande `latitud` tal cual la da `geolocator` (sin cambiar el signo).
El backend rechaza latitudes fuera de la provincia con `400 VALIDACION`.

## M4. Paleta y estilo igual que la web

- Mantener `colorPrimario #0B6E4F` y el semáforo. Agregar dos colores para el origen del dato:
  simulado `#5B4BC4` (con borde discontinuo) y oficial `#1F4FB8`.
- Botón "Reportar emergencia" y "Enviar reporte" en rojo `#C62828` (ya está así en el prototipo, bien).
- **Quitar emojis** del prototipo (casita, candado, triángulo): usar `Icons.*` de Material.
- Textos de catálogo iguales a `apps/web/src/lib/catalogos.ts` (Crítica, En proceso, Reporte ciudadano, Dato simulado...).

## M5. Directorio de albergues offline

Descargar `GET /puntos-servicio` cuando hay red y guardarlo en la caja de Hive del directorio. Mostrar el semáforo
con texto ("Con cupo", "Casi lleno", "Lleno"), no solo el color. Si hay red y GPS, ofrecer "Más cercano" con
`/puntos-servicio/cercanos?personas=<tamaño de la familia>`.

## Verificación

```bash
dart format --set-exit-if-changed lib test
```

```bash
flutter analyze
```

```bash
flutter test
```

Y la prueba real: celular en modo avión, crear reporte con foto, cerrar la app, abrirla, quitar modo avión.
