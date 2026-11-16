# Tareas móvil

Carril: app Flutter (rama `desarrollofranco`). Complementa `docs/movil/indicaciones-flutter.md` y
`docs/arquitectura/decision-mapas-hive-postgis.md`. La API ya responde de verdad: estas tareas conectan la app.

> [!IMPORTANT]
> **API PÚBLICA EN VIVO PARA CONECTARTE DESDE OTRA PC O CELULAR:**
> - **URL base:** `https://api.tu-dominio.com`
> - **Comando para compilar/probar tu app apuntando a esta API:**
>   ```bash
>   flutter run --dart-define=API_BASE_URL=https://api.tu-dominio.com
>   ```
> - **Verificación inmediata en navegador/curl:**
>   `curl https://api.tu-dominio.com/salud` (responde `{"estado":"ok"}`)


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

Cuentas demo: `ciudadano@demo.esmeraldas-resiliente.ec`, clave `demo-resiliente-2026` (solo para demostración).

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

## M6. Alertas y vías en la app

`GET /alertas` (sin token) en la pantalla "Albergues y alertas": oficial en rojo, simulacro con borde discontinuo y la
palabra "Simulacro". Escuchar `alerta.emitida` y `via.estado` por `GET /ws?token=` cuando haya red.

## M7. Una sola carpeta de la app

Hecho (10/11/2026): se borró el proyecto inicial `apps/mobile`. El único proyecto Flutter es `mobile/`, que es
el que usa el CI (`.github/workflows/build-apk.yml`).

## M8. No editar el backend desde esta rama

En `desarrollofranco` hay una copia anterior de `apps/api`. La versión vigente está en las ramas `backend` y
`desarrollo-adrian`. Al integrar, conservar la de esas ramas; si necesitas un cambio en la API, pídelo al carril backend.

## M9. URL de la API fuera del código

`AppConfig.apiBaseUrl` tiene escrita la URL de un túnel rápido (`*.trycloudflare.com`). Esa URL cambia cada vez que
se reinicia el túnel y la app deja de conectar. Volver al valor por defecto (`10.0.2.2:3000` en emulador) y pasar la
URL real siempre con `--dart-define=API_BASE_URL=...`. Para la demo, el backend tendrá un túnel con nombre fijo.

## M10. No subir fotos falsas

Si el archivo de la foto ya no existe, `subirFotoReporte` sube un JPEG mínimo de relleno. Eso deja en el COE una
"foto" que no es real. Si no hay archivo: saltar el paso 2 y marcar el reporte como `enviado` sin foto.

## M11. Reporte de emergencia sin cuenta

- Sin sesión: `POST /reportes` **sin** cabecera `Authorization`. Queda anónimo y solo el COE lo ve.
- Foto de ese reporte: `POST /reportes/{id}/foto` sin token, una sola vez y dentro de 2 horas.
- Con sesión vencida la API responde `401`: no reenviar en silencio como anónimo. Pedir login y conservar la cola.
- "Mis reportes" solo muestra los enviados con cuenta.

## M12. GPS sin internet (urgente, es el corazón de la demo)

Hoy `capturarUbicacionConRespaldo()` en `lib/core/location/location_service.dart`:
- espera solo **6 segundos** (`timeLimit`). Sin datos el GPS no tiene ayuda de antenas y la primera ubicación puede
  tardar de 30 segundos a varios minutos;
- si falla, devuelve **el centro de Esmeraldas con 12 m de precisión y `esAproximada: false`**. Todos los reportes sin
  señal caerían en el centro de la ciudad como si fueran exactos, y el COE iría al lugar equivocado.

Corregir así:
1. Usar `AppConfig.gpsTimeout` (20 s) en lugar de 6 s, y mostrar "Buscando satélites..." mientras espera.
2. Si no llega: `Geolocator.getLastKnownPosition()` y devolverla con `esAproximada: true` y su precisión real.
3. Si tampoco hay: devolver `null` (nunca un punto inventado). La pantalla ofrece elegir el sector o tocar el mapa,
   y ese punto va con `ubicacion_aproximada: true`.
4. Si el GPS está apagado: pedir activarlo (`Geolocator.openLocationSettings()`), no inventar la ubicación.

Prueba: modo avión con ubicación encendida junto a una ventana; el reporte debe salir con la coordenada real o
marcado como aproximado, nunca en el centro con 12 m.

