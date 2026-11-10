# Modelo de datos

PostgreSQL 16 + PostGIS. Todas las geometrías usan SRID 4326 (WGS84) y tienen índice GIST.
Fuente exacta: `database/01_schema_postgis.sql`.

```mermaid
erDiagram
    usuarios ||--o{ reportes : "crea (opcional)"
    usuarios ||--o{ restablecimientos : "solicita"
    usuarios ||--o{ reportes_historial : "opera"
    usuarios ||--o{ alertas : "emite"
    usuarios ||--o{ entregas : "registra"
    reportes ||--o{ reportes_historial : "tiene"
    reportes ||--o{ entregas : "recibe"
    inventario ||--o{ entregas : "descuenta por necesidad"

    usuarios {
        uuid id PK
        varchar nombre
        varchar correo UK
        varchar rol "ciudadano, operador_911, bomberos, policia, admin"
        text clave_hash
        timestamptz creado_en
    }
    restablecimientos {
        uuid id PK
        uuid usuario_id FK
        char token_hash UK
        timestamptz expira_en
        timestamptz usado_en
    }
    zonas_riesgo {
        uuid id PK
        varchar nombre_sector
        varchar tipo_amenaza
        varchar nivel_riesgo
        varchar origen
        geometry geom "Polygon 4326"
    }
    vias {
        uuid id PK
        varchar nombre
        varchar estado "habilitada, parcial, bloqueada"
        varchar origen
        geometry geom "LineString 4326"
    }
    puntos_servicio {
        uuid id PK
        varchar nombre
        varchar tipo "albergue, centro_salud"
        int capacidad
        int ocupacion
        varchar origen "simulado, coe"
        geometry geom "Point 4326"
    }
    reportes {
        uuid id PK "generado en el celular"
        uuid usuario_id FK "nulo si es sin cuenta"
        varchar origen "ciudadano, simulado, oficial"
        varchar tipo
        varchar gravedad
        varchar estado
        geometry geom "Point 4326"
        boolean ubicacion_aproximada
        int personas_afectadas
        int ninos
        int adultos_mayores
        text_array necesidades
        text foto_ruta
        text foto_miniatura_ruta
    }
    reportes_historial {
        uuid id PK
        uuid reporte_id FK
        varchar estado_anterior
        varchar estado_nuevo
        uuid operador_id FK
        timestamptz fecha
    }
    alertas {
        uuid id PK
        varchar sector
        varchar nivel
        varchar origen "oficial, simulada"
        uuid creado_por FK
        boolean vigente
    }
    entregas {
        uuid id PK
        uuid reporte_id FK
        varchar necesidad
        int cantidad
        uuid entregado_por FK
    }
    inventario {
        varchar necesidad PK
        int cantidad
        varchar unidad
    }
```

## Consultas geográficas

| Uso | Función |
|---|---|
| Sector de un reporte | Punto dentro de `zonas_riesgo` |
| Albergue más cercano con cupo | `ST_Distance` sobre `geography` |
| Paso bloqueado hacia un albergue | `ST_Intersects` con `vias` bloqueadas |
| Capas del mapa | GeoJSON generado desde PostGIS |

## Integridad y protección de datos

- La entrega y el descuento de inventario ocurren en la misma transacción.
- `reportes_historial` y `entregas` son de solo inserción: un trigger bloquea cambios y borrados.
- La API entra con `resiliente_app`, sin permiso de borrar ni de cambiar el esquema.
- Las coordenadas fuera de la provincia se rechazan en la base y en la API.
- Las contraseñas y los enlaces de restablecimiento se guardan solo como hash.
