# Decisión: mapas, Hive y PostGIS (para Franco y Adrián)

## 1. Dónde vive cada cosa

| Pieza | Dónde corre | Qué hace | ¿Funciona sin internet? |
|---|---|---|---|
| GPS | Celular | Calcula latitud y longitud con los satélites | Sí (en modo avión hay que volver a prender la ubicación) |
| Hive | Celular | Guarda la cola de reportes, la ruta de las fotos y una lista pequeña de albergues y centros de salud | Sí |
| Mapa en Flutter | Celular | Dibuja calles y ríos | **No**, sin internet queda en blanco (los dibujos se descargan al verlo) |
| Mapa en la web (Leaflet + OpenStreetMap) | Panel 911 | Dibuja el mapa con pines | Necesita internet; el panel siempre está conectado |
| PostGIS | Servidor (Postgres) | Responde preguntas espaciales: qué reportes caen en una zona, qué albergue está más cerca | Solo en el servidor |

**Hive no dibuja mapas.** Solo guarda datos. PostGIS no corre en el celular ni en Hive.

## 2. Decisión para el prototipo

1. **La app del ciudadano no depende del mapa.** Al tomar el reporte muestra "Ubicación capturada ✓" con las coordenadas y la precisión en metros.
2. **Offline, albergues y centros de salud se muestran como lista** (nombre, estado del cupo y botón de llamar), leída de Hive. Si se quiere el más cercano, se calcula en el celular con una fórmula de distancia entre dos coordenadas.
3. **El mapa grande vive en la web del 911** (Leaflet), con datos que entrega PostGIS a través de la API en formato GeoJSON.
4. **Solo Hive** para el almacenamiento local. No usar Hive y SQLite a la vez.

## 3. Si Franco igual quiere un mapa en la app

Se puede, con estas reglas:

- **Prioridad baja:** solo después de que la cola offline funcione en un celular real en modo avión.
- **Solo con internet:** el mapa se muestra cuando hay conexión (por ejemplo en "Mis reportes" o en la lista de albergues). Sin conexión, la app cae a la lista y a la tarjeta de coordenadas, sin pantalla en blanco ni errores.
- **Nunca debe bloquear el reporte:** crear un reporte no puede depender de que el mapa cargue.
- **Paquete sugerido:** `flutter_map` con OpenStreetMap (verificar versión en pub.dev). Respetar la política de uso de los servidores públicos de OSM: sirve para una demo, no para tráfico nacional.
- **No incluir paquete offline de teselas en esta versión:** exige un paquete de teselas propio de Esmeraldas guardado en el teléfono. No suma puntos y puede romper la demo.

## 4. Para uso real (mejora futura)

- Paquete de mapa propio de la zona, servido desde nuestro servidor o desde un proveedor que lo permita, y guardado en el celular para uso offline.
- Cambiar el almacenamiento local de Hive a SQLite, tocando solo una capa (la clase "repositorio de la cola"), sin cambiar las pantallas.

## 5. Puntos clave de la arquitectura

- "El GPS no necesita internet: la app guarda las coordenadas en el momento del reporte y las envía al volver la conexión."
- "El reporte no depende del mapa. El mapa offline queda como mejora futura con un paquete de teselas propio de Esmeraldas."
- "PostGIS resuelve las consultas espaciales en el servidor; el celular solo captura y guarda."
