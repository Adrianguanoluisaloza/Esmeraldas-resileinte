# Pruebas de carga y costos

Este documento responde dos preguntas: cuánto aguanta la plataforma y cuánto cuesta. Los precios se consultaron el 10 de noviembre de 2026, en dólares y sin impuestos.

## Cuánto aguanta

La prueba se hizo el 10 de noviembre de 2026 con `autocannon`, en el mismo servidor de producción.

| Elemento | Valor |
| --- | --- |
| Servidor | Oracle Cloud `VM.Standard.A1.Flex` ARM, 4 OCPU y 24 GB, compartido con otros proyectos |
| API | Límite de 1.5 CPU y 1 GB |
| Base PostGIS | Límite de 1.5 CPU y 2 GB |
| Generador de carga | Contenedor en la misma VM, 1.5 CPU y 1 GB |
| Duración | 15 segundos por etapa, con 4 segundos de pausa |

### Resultados

Ninguna etapa tuvo errores, respuestas fallidas ni tiempos agotados.

| Operación | Conexiones | Solicitudes por segundo | Mediana (ms) | p97.5 (ms) | p99 (ms) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Albergues cercanos (PostGIS) | 25 | 1652 | 13 | 29 | 39 |
| Albergues cercanos (PostGIS) | 100 | 1572 | 62 | 75 | 81 |
| Albergues cercanos (PostGIS) | 250 | 1544 | 161 | 180 | 183 |
| Albergues cercanos (PostGIS) | 500 | 1554 | 318 | 342 | 358 |
| Albergues cercanos (PostGIS) | 1000 | 1492 | 659 | 759 | 856 |
| Zonas de riesgo GeoJSON | 25 | 1924 | 12 | 15 | 17 |
| Zonas de riesgo GeoJSON | 100 | 1662 | 58 | 72 | 75 |
| Zonas de riesgo GeoJSON | 250 | 1619 | 154 | 170 | 173 |
| Zonas de riesgo GeoJSON | 500 | 1619 | 304 | 336 | 349 |
| Reportes del COE con token | 25 | 1010 | 24 | 28 | 30 |
| Reportes del COE con token | 100 | 893 | 111 | 125 | 132 |
| Reportes del COE con token | 250 | 899 | 275 | 296 | 311 |
| Reportes del COE con token | 500 | 849 | 577 | 629 | 682 |
| Crear reporte | 25 | 827 | 26 | 45 | 49 |
| Crear reporte | 100 | 835 | 111 | 169 | 181 |
| Crear reporte | 250 | 799 | 297 | 430 | 448 |

Tiempo real: 1000 de 1000 conexiones WebSocket abiertas, y todas recibieron el evento.

Al terminar, la API y la base seguían sanas, con 0 reinicios y sin falta de memoria. En las muestras más cargadas, la API usó cerca de 130 % de CPU y 88 MB, y la base hasta 91 % de CPU y 107 MB. Los demás contenedores de la VM siguieron arriba.

### Cómo leerlo

- Con 1000 conexiones simultáneas, el 99 % de las consultas respondió en menos de 0.9 segundos.
- El rendimiento se mantiene casi plano al subir conexiones. Eso indica saturación cerca de 1500 solicitudes por segundo en lectura: más conexiones esperan más, pero no fallan.
- Cálculo teórico: 799 reportes por segundo son unos 47 900 por minuto, sin fotos.
- **No se encontró el punto de quiebre.** La prueba paró en 1000 conexiones de lectura y 250 de escritura.

### Lo que esta prueba no mide

- Va directo a la API dentro de Docker. No incluye Cloudflare Tunnel ni la latencia de internet.
- No incluye subida de fotos ni teselas del mapa.
- Se usaron IP simuladas para medir la base y no el límite por IP. Muchos usuarios detrás de una misma IP pueden topar ese límite.
- Duró 15 segundos por etapa, así que no prueba horas de carga sostenida.
- La base tenía datos de semilla y de la propia prueba, no un volumen real de meses.
- El generador corrió en la misma VM, con CPU limitada, y pudo influir en el techo medido.
- No se reporta latencia de WebSocket, porque el script de la prueba la midió mal.

## Cuánto cuesta hoy

| Servicio | Uso | Costo mensual | Límite o nota |
| --- | --- | ---: | --- |
| Oracle Cloud A1 | API, base y otros proyectos | USD 0 a 26.98 | Ver el aviso de abajo |
| Cloudflare Pages | Web | USD 0 | 500 compilaciones al mes, 20 000 archivos |
| Cloudflare Tunnel | HTTPS de la API | USD 0 | Plan gratuito |
| Firebase Authentication | Ingreso con Google | USD 0 | 50 000 usuarios activos al mes en plan Spark |
| Gmail SMTP | Correo de restablecer | USD 0 | Unos 500 correos al día en cuenta personal |
| OpenStreetMap | Teselas del mapa | USD 0 | Uso justo, no es para tráfico masivo |
| Dominio `cifralabapp.com` | Subdominio de la API | Sin dato | Compartido con otro proyecto. Revisar la factura |

**Total hoy: USD 0 a 26.98 al mes, más el dominio.**

### Aviso sobre Oracle

La VM se creó el 29 de octubre de 2026 con 4 OCPU y 24 GB. Sigue con ese tamaño.

Oracle redujo la cuota gratuita de A1 de 4 OCPU y 24 GB a 2 OCPU y 12 GB desde el 15 de junio de 2026. Sus fuentes no coinciden:

- La documentación dice 1500 horas OCPU y 9000 horas GB gratis al mes para todas las cuentas.
- La lista de precios de Oracle sigue mostrando 3000 horas OCPU y 18 000 horas GB sin costo.

Cálculo con 730 horas al mes:

| Caso | OCPU | Memoria | Total |
| --- | ---: | ---: | ---: |
| Aplica la lista de precios | 2920 h, dentro de la cuota | 17 520 h, dentro de la cuota | USD 0 |
| Aplica la documentación | 1420 h extra por USD 0.01 = USD 14.20 | 8520 h extra por USD 0.0015 = USD 12.78 | USD 26.98 |

Hay que confirmarlo en Facturación de la consola de Oracle. La VM la comparten varios proyectos, y Esmeraldas solo tiene reservadas 3 CPU y 3 GB como máximo.

## Cuánto costaría después

Son estimaciones para un piloto con una institución. No incluyen impuestos, personal, soporte, respaldos ni dominio.

| Escenario | Componentes | Costo mensual |
| --- | --- | ---: |
| Piloto en Oracle, sin cuota gratis | VM A1 de 4 OCPU y 24 GB (USD 55.48) y mapas MapTiler Flex (USD 30) | USD 85.48 |
| Piloto en DigitalOcean | Droplet de 4 vCPU y 8 GB (USD 48) y mapas MapTiler Flex (USD 30) | USD 78.00 |
| Piloto mínimo en DigitalOcean | Droplet de 2 vCPU y 4 GB (USD 24) y mapas MapTiler Flex (USD 30) | USD 54.00 |

Un piloto real también debería tener servidor y base separados de otros proyectos, y respaldos automáticos.

### Costos que dependen del uso

| Concepto | Precio | Ejemplo |
| --- | --- | --- |
| SMS a Ecuador con Twilio | USD 0.339 por segmento, más posibles cargos del operador | 1000 SMS: USD 339 |
| MapTiler Flex | Incluye 500 000 solicitudes. Extra: USD 0.15 por cada 1000 | 100 000 extra: USD 15 |
| Enlace satelital | Sin precio confirmado | Requiere cotización |

El precio por SMS de Twilio es alto para alertas masivas. Conviene cotizar con un proveedor local.

### Pagos de publicación

| Concepto | Precio |
| --- | --- |
| Google Play | USD 25, una sola vez |
| Apple Developer | USD 99 al año. Entidades públicas, educativas o sin fines de lucro elegibles pueden pedir exención |

## Fuentes

- [Oracle: recursos Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [InfoQ: cambio de límites de Oracle](https://infoq.com/news/2026/07/oracle-cloud-free-tier-limits/)
- [Oracle: precio de OCPU A1](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/?partNumber=B93297&currencyCode=USD)
- [Oracle: precio de memoria A1](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/?partNumber=B93298&currencyCode=USD)
- [Cloudflare Pages: límites](https://developers.cloudflare.com/pages/platform/limits/)
- [Firebase: precios](https://firebase.google.com/pricing)
- [Gmail: límites de envío](https://support.google.com/mail/answer/22839?hl=en)
- [MapTiler: precios](https://www.maptiler.com/cloud/pricing/)
- [DigitalOcean: Droplets](https://www.digitalocean.com/pricing/droplets)
- [Twilio: SMS a Ecuador](https://www.twilio.com/en-us/sms/pricing/ec)
- [Google Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en)
- [Apple Developer Program](https://developer.apple.com/programs/enroll/)
