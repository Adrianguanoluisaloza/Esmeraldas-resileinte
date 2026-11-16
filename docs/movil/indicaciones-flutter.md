# Indicaciones para Franco — App móvil (Flutter)

Documento de trabajo para implementar la app del ciudadano: cola offline con Hive, GPS, subida de fotos y mapa con respaldo sin internet.

## 1. Versiones y paquetes

Versiones vistas en pub.dev al buscar (confirmar al instalar, porque pueden haber subido):

| Paquete | Versión vista | Para qué |
|---|---|---|
| `hive_ce` | 2.19.3 | Almacenamiento local (el Hive de la comunidad, mantenido) |
| `hive_ce_flutter` | (la que resuelva `pub add`) | Inicialización en Flutter |
| `hive_ce_generator` (dev) | 1.11.1 (pide Dart 3.4 o mayor) | Genera los adaptadores |
| `build_runner` (dev) | (la que resuelva `pub add`) | Corre el generador |
| `flutter_map` | 8.3.0 | Mapa con OpenStreetMap |
| `latlong2` | (la que pida flutter_map) | Coordenadas |

Paquetes sin versión fijada (instalar con `flutter pub add` y dejar que resuelva): `geolocator`, `connectivity_plus`, `image_picker`, `flutter_image_compress`, `path_provider`, `dio`, `uuid`, `flutter_secure_storage`.

Reglas:
- **No mezclar** el paquete original `hive` con `hive_ce`. Solo `hive_ce`, y los imports van como `hive_ce/hive.dart` y `hive_ce_flutter/hive_flutter.dart`.
- Instalar con `flutter pub add <paquete>` y **subir `pubspec.lock` al repositorio**, para que todo el equipo use exactamente las mismas versiones.
- Usar Flutter en canal estable y que todos tengan la misma versión (`flutter --version`).
- Evitar versiones prerelease y paquetes con alertas de abandono.

## 2. Estructura de la app

- `core/`: cliente de la API (dio), configuración (URL del servidor), enums (tipo, estado, gravedad, necesidades) copiados de `contrato/openapi.yaml`.
- `data/`: modelos, adaptadores de Hive y el **repositorio de la cola** (una sola clase).
- `features/auth`, `features/reporte`, `features/mis_reportes`, `features/sync`.

**Regla de oro:** ninguna pantalla habla con Hive directo. Todo pasa por el repositorio de la cola. Así, si después se migra a SQLite, solo cambia ese archivo.

## 3. Hive: qué se guarda y qué no

- **Se inicializa una sola vez** al arrancar la app, antes de abrir cajas, y se registran los adaptadores generados.
- **Caja de la cola:** un registro por reporte con: ID (UUID v4 creado en el celular), tipo, descripción, gravedad indicada, latitud, longitud, precisión en metros, bandera de ubicación aproximada, hora de captura en UTC, ruta del archivo de la foto, datos de familia (personas, niños, adultos mayores, necesidades), estado de la cola, número de intentos y hora del próximo intento.
- **Caja del directorio:** lista pequeña de albergues y centros de salud (nombre, tipo, coordenadas, teléfono, cupo) descargada cuando hay conexión.
- **La foto NO va dentro de Hive.** Va como archivo en la carpeta de documentos de la app (`path_provider`), y en Hive solo la ruta.
- **El token de login NO va en Hive.** Va en `flutter_secure_storage`.
- Cifrado opcional de la caja de la cola: guardar la clave en `flutter_secure_storage`. Hacerlo solo si sobra tiempo.

## 4. Estados de un reporte en la cola

`pendiente` → `enviando_datos` → `datos_enviados` → `enviando_foto` → `enviado`, y `error` cuando el servidor rechaza el reporte.

La app muestra estos estados en "Mis reportes" (pendiente, enviando, enviado) para que el usuario sepa qué pasó. Si la app se cierra en medio, al reabrir la cola continúa desde el último paso completado.

## 5. Captura del reporte (sin internet)

1. Tomar la foto con `image_picker`.
2. Comprimir con `flutter_image_compress`: lado largo de unos 1280 px, calidad 70 a 80%. Meta: 150 a 400 KB.
3. Guardar la foto comprimida en la carpeta de la app.
4. Pedir el GPS con `geolocator`, con un tiempo máximo de espera (por ejemplo 20 segundos). Si no llega, usar la última ubicación conocida y marcarla como **aproximada**. Guardar siempre la precisión en metros.
5. Si es el caso, leer el bloque opcional de familia (personas de 1 a 8 o más, niños, adultos mayores, necesidades: agua, alimentos, medicinas, rescate). Debe poder completarse con toques, sin escribir.
6. Crear el UUID, guardar el registro en la cola con la hora de captura y estado `pendiente`. La pantalla confirma "Reporte guardado" aunque no haya internet.

El reporte completo debe tomar menos de 15 segundos.

## 6. Servicio de sincronización

**Cuándo se dispara:** al abrir la app, cuando `connectivity_plus` avisa un cambio de red, con un botón manual de "Reintentar" y con un temporizador periódico.

**Importante:** que haya wifi o datos no significa que haya internet. Antes de enviar, hacer una petición corta al servidor (por ejemplo `GET /salud`). Si falla, no es una caída del reporte: se reintenta luego.

**Paso 1, datos livianos:** `POST /reportes` con el UUID. Es idempotente: si el servidor ya lo tenía, responde bien y la app lo trata como éxito. Al terminar, estado `datos_enviados`.

**Paso 2, foto:** `POST /reportes/:id/foto` como formulario con archivo adjunto (`dio` con datos de formulario), con el token en la cabecera. Al recibir "ok", estado `enviado` y se borra la foto local.

**Fallos:**
- Sin red o error 5xx: reintentar con espera creciente (5, 15, 30 y 60 segundos, y luego cada minuto).
- Error 401: renovar sesión o pedir login, sin perder la cola.
- Error 4xx de validación: marcar `error`, no reintentar infinitamente, y mostrar el motivo.
- Corte a mitad de la foto: la foto sigue pendiente y se reenvía completa.
- Nunca enviar dos reportes en paralelo con el mismo UUID.

## 7. Mapa con flutter_map (y qué hacer sin internet)

**Condiciones, no negociables:**
- **Primero la cola offline.** El mapa solo se arma cuando el reporte en modo avión ya funciona en un celular real.
- **El mapa nunca bloquea un reporte.** La pantalla de crear reporte no lleva mapa; muestra "Ubicación capturada ✓" con coordenadas y precisión.
- **Solo con internet.** Los dibujos del mapa (teselas) se descargan al verlo, así que sin conexión quedaría en blanco.

**Dónde sí va:** una pantalla de "Mis reportes en el mapa" y otra de albergues y centros de salud cercanos.

**Implementación:**
- `flutter_map` con capa de teselas de OpenStreetMap. Configurar siempre el identificador de la app (`userAgentPackageName`, por ejemplo el id del paquete Android), porque OpenStreetMap lo pide.
- Limitar la cámara a Esmeraldas (centro y límites) y un zoom máximo razonable.
- Pines desde la caja del directorio y desde los reportes propios. Color por estado o cupo: verde, ámbar y rojo.
- **Respaldo offline:** antes de mostrar el mapa, comprobar conexión real. Si no hay, mostrar la **lista** (nombre, cupo, botón de llamar, distancia calculada en el celular con la fórmula de distancia entre dos coordenadas) y un aviso claro: "Sin conexión: mostrando lista".
- Si las teselas fallan a mitad de camino, mostrar el mismo respaldo y no un cuadro vacío.

**Fuera del alcance actual:** mapa offline con paquete de teselas propio, ni descarga masiva de teselas de los servidores públicos de OpenStreetMap (su política lo prohíbe). Para uso real, se arma un paquete de mapa propio de Esmeraldas.

**Para la demo:** no poner el mapa en la pantalla donde se activa el modo avión, para que no se vea un cuadro en blanco en el momento clave.

## 8. Permisos (Android)

Internet, ubicación precisa, cámara y acceso a archivos temporales. Pedir cada permiso en el momento en que se usa y explicar para qué. Si el usuario niega la ubicación, permitir el reporte igual con ubicación manual o sin ella, avisando que no tendrá pin exacto.

## 9. Pruebas obligatorias en celular real

- [ ] Modo avión: crear 3 reportes con foto y GPS. Ver que quedan en la cola.
- [ ] Cerrar la app por completo y reabrir: la cola sigue ahí.
- [ ] Reconectar con **datos móviles** (no el wifi de la universidad): sincronizan los datos y luego las fotos.
- [ ] Cortar la conexión a mitad de la foto: reintenta sin duplicar.
- [ ] Enviar el mismo reporte dos veces: el servidor no lo duplica.
- [ ] GPS bajo techo: usa la ubicación aproximada y la marca.
- [ ] Sin internet, abrir la pantalla de albergues: muestra la lista y no un mapa en blanco.
- [ ] Una foto de unos 5 MB queda por debajo de 400 KB antes de enviarse.

## 10. Reglas de trabajo

- Trabajar en la rama `mobile/franco` y abrir Pull Request a `main`; Adrián revisa.
- No cambiar nombres de campos ni endpoints sin que Adrián actualice antes `contrato/openapi.yaml`.
- Cada tarea termina con una línea en `BITACORA.md` (fecha, qué cambió, qué falta) y con cómo verificarla.
- No subir claves ni la URL de producción dentro del código; usar configuración por entorno.
