# Reglas del proyecto

## Objetivo

Construir una plataforma escalable con una aplicación móvil en Flutter y una página web en Astro con componentes React. La solución debe priorizar mantenibilidad, accesibilidad, rendimiento, seguridad y una experiencia consistente entre web y móvil.

## Stack aprobado

- **Aplicación móvil:** Flutter y Dart.
- **Arquitectura móvil:** Clean Architecture, separación por funcionalidades y principios SOLID.
- **Mapa:** OpenStreetMap mediante una biblioteca Flutter compatible. Debe respetarse la atribución requerida por OpenStreetMap y por cada proveedor de teselas.
- **Página web:** Astro.
- **Componentes interactivos:** React dentro de Astro, únicamente donde aporten estado o interacción real.
- **Infraestructura web:** Cloudflare Pages para el despliegue web; Cloudflare Workers solo para lógica de servidor o integraciones que lo necesiten.
- **Distribución de la aplicación:** automatizar builds firmadas para Android e iOS mediante CI/CD y publicar en Google Play y App Store Connect según los entornos configurados.

## Estructura esperada

Cuando se incorporen fuentes al repositorio, mantener una separación similar a esta:

```text
apps/
  mobile/                 # Proyecto Flutter
  web/                    # Proyecto Astro
packages/
  design-system/          # Tokens y componentes compartidos cuando sea viable
  contracts/              # Contratos, modelos serializables y esquemas compartidos
infra/                    # Configuración de Cloudflare y CI/CD
docs/
  adr/                    # Decisiones arquitectónicas
bitacora.md
CHANGELOG.md
AGENTS.md
```

La estructura puede evolucionar, pero cada módulo debe tener una responsabilidad clara y dependencias dirigidas hacia adentro, nunca hacia detalles de infraestructura.

## Clean Architecture

Organizar la aplicación Flutter en capas:

```text
feature/
  presentation/           # Widgets, páginas, estado y navegación
  domain/                 # Entidades, casos de uso y contratos de repositorio
  data/                   # DTOs, fuentes remotas/locales y adaptadores
core/
  error/
  network/
  location/
  routing/
  theme/
```

Reglas de dependencia:

1. `presentation` depende de `domain`, nunca de implementaciones concretas de `data`.
2. `domain` no importa Flutter, HTTP, bases de datos ni SDKs externos.
3. `data` implementa los contratos definidos en `domain`.
4. La composición de dependencias se realiza en un punto de entrada, no dentro de las entidades o casos de uso.
5. Cada funcionalidad debe poder probarse sin red, mapas ni servicios reales.

## SOLID y escalabilidad

- **Responsabilidad única:** una clase, widget o función debe tener un motivo principal para cambiar.
- **Abierto/cerrado:** extender mediante interfaces, estrategias y composición antes que modificar código estable.
- **Sustitución de Liskov:** las implementaciones deben respetar completamente los contratos.
- **Segregación de interfaces:** contratos pequeños y orientados a casos de uso.
- **Inversión de dependencias:** el dominio define interfaces; infraestructura las implementa.

Evitar singletons globales, lógica de negocio en widgets, repositorios que mezclen UI con persistencia, y utilidades genéricas sin dueño claro.

## Mapas y OpenStreetMap

- Mostrar atribución visible y legible de OpenStreetMap y del proveedor de teselas.
- No asumir que los servidores públicos de teselas son una API ilimitada: respetar políticas de uso, caché y límites.
- Encapsular mapas, geocodificación, permisos y ubicación detrás de interfaces del dominio.
- Gestionar estados de permiso denegado, ubicación no disponible, error de red y mapa sin datos.
- No registrar coordenadas sensibles en logs de producción.
- Verificar licencias de datos, teselas, iconos y cualquier proveedor de geocodificación antes de publicar.

## Astro, React y Cloudflare

- Preferir HTML generado por Astro y cargar React solo como isla interactiva cuando sea necesario.
- Mantener componentes React pequeños, accesibles y agnósticos de infraestructura.
- No duplicar en React una página que Astro puede renderizar estáticamente.
- Validar SEO, navegación por teclado, estados de carga y diseño responsive.
- Mantener secretos fuera del cliente y fuera del repositorio.
- Configurar variables por entorno para desarrollo, staging y producción.
- Usar Cloudflare Pages para la entrega de la web y documentar cualquier Worker, binding o regla de caché.
- Las funciones en el borde deben ser stateless cuando sea posible y tener límites, timeouts y manejo explícito de errores.

## Calidad y pruebas

Antes de integrar cambios:

- Flutter: `dart format`, `flutter analyze` y pruebas unitarias/widget relevantes.
- Web: formateo, lint, typecheck y build de Astro.
- Probar primero casos de uso y adaptadores; después la integración visual.
- Añadir pruebas para errores, estados vacíos, permisos y pérdida de conectividad.
- No aceptar warnings nuevos sin documentar la razón.

## Git y cambios

- Ramas y commits pequeños, descriptivos y enfocados.
- No mezclar refactors amplios con cambios funcionales.
- Actualizar `bitacora.md` con avances, decisiones y bloqueos relevantes.
- Actualizar `CHANGELOG.md` cuando un cambio sea visible para usuarios o afecte contratos.
- No incluir secretos, tokens, certificados ni archivos de firma en Git.
- Revisar licencias y atribuciones antes de incorporar dependencias o recursos.

## Definición de terminado

Un cambio está terminado cuando:

1. El comportamiento está implementado en la capa correcta.
2. Tiene pruebas proporcionales al riesgo.
3. Pasa análisis, formato y build del módulo afectado.
4. Maneja estados de error y accesibilidad relevantes.
5. Documenta decisiones, configuración o migraciones necesarias.
6. No rompe los contratos públicos ni los entornos existentes.
