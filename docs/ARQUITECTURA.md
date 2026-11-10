# Arquitectura

```mermaid
flowchart LR
    subgraph Clientes
        M["App Flutter<br/>cola sin conexión en Hive"]
        W["Web Astro + React<br/>Cloudflare Pages"]
    end
    subgraph Cloudflare
        T["Túnel HTTPS"]
    end
    subgraph VM["VM Oracle Cloud · Docker aislado"]
        A["API Hono + TypeScript<br/>REST, GeoJSON, WebSocket"]
        D[("PostgreSQL 16<br/>PostGIS")]
        F[("Volumen de fotos")]
    end
    G["Firebase<br/>solo ingreso con Google"]
    C["SMTP<br/>restablecer contraseña"]
    O["OpenStreetMap<br/>teselas"]

    M -->|HTTPS| T
    W -->|"HTTPS y WebSocket"| T
    T --> A
    A --> D
    A --> F
    A --> C
    M -.->|token de Google| G
    W -.->|token de Google| G
    A -.->|verifica la firma| G
    M --> O
    W --> O
```

## Flujo de un reporte

```mermaid
sequenceDiagram
    actor C as Ciudadano
    participant M as App
    participant A as API
    participant D as PostGIS
    actor I as Institución
    C->>M: Reporta con GPS, foto y familia
    M->>M: Guarda en la cola local
    Note over M: Sin señal, espera aquí
    M->>A: POST /reportes con UUID
    A->>D: Guarda sin duplicar
    A-->>I: WebSocket según competencia
    M->>A: POST /reportes/{id}/foto
    I->>A: Cambia el estado
    A->>D: Guarda estado e historial
    A-->>M: Actualización al ciudadano
```

## Capas

| Componente | Capas | Regla |
|---|---|---|
| API (`apps/api`) | `dominio`, `aplicacion`, `infraestructura`, `http` | El dominio no conoce HTTP ni la base. |
| App (`mobile`) | `presentation`, `domain`, `data` | La presentación depende del dominio. |
| Web (`apps/web`) | Páginas Astro con islas React | Un cliente único habla con la API. |

## Por qué estas tecnologías

| Elección | Motivo |
|---|---|
| PostGIS | Distancias reales, polígonos e intersecciones en la base. |
| Flutter con Hive | Una sola app con almacenamiento local para operar sin señal. |
| Hono en Node 22 | API liviana con WebSocket y validación con zod. |
| Astro con islas React | Páginas rápidas y JavaScript solo donde hay interacción. |
| OpenStreetMap con Leaflet | Datos abiertos y sin costo de licencia. |
| Docker Compose | El mismo entorno en local y en la VM, aislado de otros servicios. |

Los permisos están en `docs/ROLES.md` y el despliegue en `docs/DESPLIEGUE.md`.
