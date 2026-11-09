-- Esmeraldas Resiliente: esquema PostgreSQL + PostGIS (SRID 4326, WGS84).
-- Se ejecuta solo la primera vez que arranca el contenedor de base (docker-entrypoint-initdb.d).
-- Fuente de verdad de los catálogos: contrato/openapi.yaml. Si cambia un enum, se cambia aquí también.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Usuarios ---------------------------------------------------------------------------------------
CREATE TABLE usuarios (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre       VARCHAR(120) NOT NULL,
  correo       VARCHAR(254) NOT NULL,
  rol          VARCHAR(20)  NOT NULL CHECK (rol IN ('ciudadano', 'operador_911', 'admin')),
  clave_hash   TEXT         NOT NULL,
  creado_en    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX usuarios_correo_unico ON usuarios (lower(correo));

-- Módulo 1: zonas de riesgo (polígonos) ---------------------------------------------------------
CREATE TABLE zonas_riesgo (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre_sector VARCHAR(120) NOT NULL,
  tipo_amenaza  VARCHAR(20)  NOT NULL CHECK (tipo_amenaza IN ('inundacion', 'deslizamiento', 'desbordamiento')),
  nivel_riesgo  VARCHAR(10)  NOT NULL CHECK (nivel_riesgo IN ('bajo', 'medio', 'alto', 'critico')),
  -- Quién respalda el dato: oficial (SNGR, GAD) o simulado para el escenario del hackathon.
  origen        VARCHAR(10)  NOT NULL DEFAULT 'simulado' CHECK (origen IN ('oficial', 'simulado')),
  fuente        TEXT,
  geom          GEOMETRY(Polygon, 4326) NOT NULL
);
CREATE INDEX zonas_riesgo_geom ON zonas_riesgo USING GIST (geom);

-- Módulo 4: red vial con estado -----------------------------------------------------------------
CREATE TABLE vias (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre         VARCHAR(160) NOT NULL,
  estado         VARCHAR(12)  NOT NULL DEFAULT 'habilitada' CHECK (estado IN ('habilitada', 'parcial', 'bloqueada')),
  origen         VARCHAR(10)  NOT NULL DEFAULT 'simulado' CHECK (origen IN ('oficial', 'simulado')),
  actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
  geom           GEOMETRY(LineString, 4326) NOT NULL
);
CREATE INDEX vias_geom ON vias USING GIST (geom);

-- Módulo 4: albergues y centros de salud ----------------------------------------------------------
CREATE TABLE puntos_servicio (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre         VARCHAR(160) NOT NULL,
  tipo           VARCHAR(15)  NOT NULL CHECK (tipo IN ('albergue', 'centro_salud')),
  telefono       VARCHAR(30)  NOT NULL DEFAULT '',
  direccion      VARCHAR(200) NOT NULL DEFAULT '',
  capacidad      INTEGER      NOT NULL CHECK (capacidad > 0),
  ocupacion      INTEGER      NOT NULL DEFAULT 0 CHECK (ocupacion >= 0),
  activo         BOOLEAN      NOT NULL DEFAULT true,
  actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
  geom           GEOMETRY(Point, 4326) NOT NULL
);
CREATE INDEX puntos_servicio_geom ON puntos_servicio USING GIST (geom);

-- Módulo 2 y 3: reportes ciudadanos e incidentes del escenario -----------------------------------
CREATE TABLE reportes (
  id                    UUID PRIMARY KEY,               -- lo genera el celular (UUID v4): idempotencia offline
  usuario_id            UUID REFERENCES usuarios (id) ON DELETE SET NULL,
  origen                VARCHAR(10)  NOT NULL CHECK (origen IN ('ciudadano', 'simulado', 'oficial')),
  tipo                  VARCHAR(20)  NOT NULL CHECK (tipo IN ('inundacion', 'deslizamiento', 'via_bloqueada', 'personas_atrapadas', 'dano_vivienda', 'otro')),
  descripcion           VARCHAR(1000) NOT NULL,
  gravedad              VARCHAR(10)  NOT NULL CHECK (gravedad IN ('baja', 'media', 'alta', 'critica')),
  estado                VARCHAR(12)  NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_proceso', 'atendido', 'descartado')),
  geom                  GEOMETRY(Point, 4326) NOT NULL,
  precision_m           REAL CHECK (precision_m IS NULL OR precision_m >= 0),
  ubicacion_aproximada  BOOLEAN      NOT NULL DEFAULT false,
  sector                VARCHAR(120),
  capturado_en          TIMESTAMPTZ  NOT NULL,
  recibido_en           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  verificado            BOOLEAN      NOT NULL DEFAULT false,
  personas_afectadas    INTEGER      NOT NULL DEFAULT 0 CHECK (personas_afectadas >= 0),
  ninos                 INTEGER      NOT NULL DEFAULT 0 CHECK (ninos >= 0),
  adultos_mayores       INTEGER      NOT NULL DEFAULT 0 CHECK (adultos_mayores >= 0),
  necesidades           TEXT[]       NOT NULL DEFAULT '{}' CHECK (necesidades <@ ARRAY['agua', 'alimentos', 'medicinas', 'rescate']::TEXT[]),
  foto_ruta             TEXT,
  foto_miniatura_ruta   TEXT,
  -- Sugerencia de IA: apoyo no vinculante, siempre requiere confirmación humana.
  ia_tipo_sugerido      VARCHAR(20),
  ia_gravedad_sugerida  VARCHAR(10),
  ia_explicacion        TEXT,
  ia_confianza          REAL CHECK (ia_confianza IS NULL OR ia_confianza BETWEEN 0 AND 1)
);
CREATE INDEX reportes_geom ON reportes USING GIST (geom);
CREATE INDEX reportes_estado_gravedad ON reportes (estado, gravedad);
CREATE INDEX reportes_usuario ON reportes (usuario_id);

CREATE TABLE reportes_historial (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporte_id      UUID NOT NULL REFERENCES reportes (id) ON DELETE CASCADE,
  estado_anterior VARCHAR(12) NOT NULL,
  estado_nuevo    VARCHAR(12) NOT NULL,
  operador_id     UUID REFERENCES usuarios (id) ON DELETE SET NULL,
  nota            VARCHAR(500),
  fecha           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX reportes_historial_reporte ON reportes_historial (reporte_id, fecha);

-- Módulo 3: alertas por sector ---------------------------------------------------------------------
CREATE TABLE alertas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sector      VARCHAR(120) NOT NULL,
  mensaje     VARCHAR(500) NOT NULL,
  nivel       VARCHAR(10)  NOT NULL CHECK (nivel IN ('baja', 'media', 'alta', 'critica')),
  origen      VARCHAR(10)  NOT NULL CHECK (origen IN ('oficial', 'simulada')),
  creado_por  UUID REFERENCES usuarios (id) ON DELETE SET NULL,
  creado_en   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  vigente     BOOLEAN      NOT NULL DEFAULT true
);

CREATE INDEX alertas_vigentes ON alertas (vigente, creado_en DESC);

-- Módulo 5: entregas de asistencia humanitaria ----------------------------------------------------
-- Cada entrega cubre una necesidad de un reporte. Solo el COE la registra; no se edita ni se borra.
CREATE TABLE entregas (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporte_id    UUID NOT NULL REFERENCES reportes (id) ON DELETE RESTRICT,
  necesidad     VARCHAR(10)  NOT NULL CHECK (necesidad IN ('agua', 'alimentos', 'medicinas', 'rescate')),
  cantidad      INTEGER      NOT NULL CHECK (cantidad > 0 AND cantidad <= 100000),
  nota          VARCHAR(500),
  entregado_por UUID REFERENCES usuarios (id) ON DELETE SET NULL,
  entregado_en  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX entregas_reporte ON entregas (reporte_id, necesidad);

-- Integridad extra --------------------------------------------------------------------------------
ALTER TABLE reportes ADD CONSTRAINT reportes_vulnerables_coherentes
  CHECK (ninos + adultos_mayores <= GREATEST(personas_afectadas, ninos + adultos_mayores));
ALTER TABLE reportes ADD CONSTRAINT reportes_coordenadas_esmeraldas
  CHECK (ST_Y(geom) BETWEEN -0.5 AND 1.6 AND ST_X(geom) BETWEEN -80.3 AND -78.4);

-- Auditoría: historial y entregas son de solo inserción. Ni la API puede reescribir el pasado.
CREATE OR REPLACE FUNCTION bloquear_cambios() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'La tabla % es de solo inserción (auditoría)', TG_TABLE_NAME;
END;
$$;
CREATE TRIGGER historial_inmutable BEFORE UPDATE OR DELETE ON reportes_historial
  FOR EACH ROW EXECUTE FUNCTION bloquear_cambios();
CREATE TRIGGER entregas_inmutables BEFORE UPDATE OR DELETE ON entregas
  FOR EACH ROW EXECUTE FUNCTION bloquear_cambios();
