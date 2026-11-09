import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import pg from "pg";
import type { TipoPuntoServicio } from "../../dominio/catalogos.js";
import type {
  Cercania,
  FiltroReportes,
  GeoJsonColeccion,
  RepositorioReportes,
  RepositorioTerritorio,
  RepositorioUsuarios,
  UsuarioConClave,
} from "../../dominio/puertos.js";
import type { PuntoServicio } from "../../dominio/puntoServicio.js";
import type { Reporte } from "../../dominio/reporte.js";

/**
 * Adaptadores PostgreSQL + PostGIS. Todas las consultas van parametrizadas ($1, $2...): nunca se arma SQL
 * concatenando texto que venga del usuario.
 */

export function crearPool(url: string): pg.Pool {
  return new pg.Pool({ connectionString: url, max: 10, idleTimeoutMillis: 30_000, connectionTimeoutMillis: 5_000 });
}

const SHIM_SIN_POSTGIS_SQL = `
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'geometry') THEN
    CREATE DOMAIN geometry AS TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'geography') THEN
    CREATE DOMAIN geography AS TEXT;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION ST_MakePoint(lon double precision, lat double precision)
RETURNS geometry LANGUAGE sql IMMUTABLE AS $f$
  SELECT jsonb_build_object('type', 'Point', 'coordinates', jsonb_build_array(lon, lat))::text::geometry;
$f$;

CREATE OR REPLACE FUNCTION ST_SetSRID(g geometry, srid integer)
RETURNS geometry LANGUAGE sql IMMUTABLE AS $f$
  SELECT g;
$f$;

CREATE OR REPLACE FUNCTION ST_X(g geometry)
RETURNS double precision LANGUAGE sql IMMUTABLE AS $f$
  SELECT ((g::jsonb)->'coordinates'->>0)::double precision;
$f$;

CREATE OR REPLACE FUNCTION ST_Y(g geometry)
RETURNS double precision LANGUAGE sql IMMUTABLE AS $f$
  SELECT ((g::jsonb)->'coordinates'->>1)::double precision;
$f$;

CREATE OR REPLACE FUNCTION ST_AsGeoJSON(g geometry, max_digits integer DEFAULT 6)
RETURNS text LANGUAGE sql IMMUTABLE AS $f$
  SELECT g::text;
$f$;

CREATE OR REPLACE FUNCTION ST_GeomFromText(wkt text, srid integer DEFAULT 4326)
RETURNS geometry LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  limpio text;
  par text;
  partes text[];
  coords jsonb := '[]'::jsonb;
BEGIN
  limpio := btrim(translate(regexp_replace(wkt, '^[A-Za-z]+', ''), '()', ''));
  FOREACH par IN ARRAY string_to_array(limpio, ',') LOOP
    partes := regexp_split_to_array(btrim(par), '[[:space:]]+');
    coords := coords || jsonb_build_array(jsonb_build_array(partes[1]::double precision, partes[2]::double precision));
  END LOOP;
  IF upper(btrim(wkt)) LIKE 'POLYGON%' THEN
    RETURN jsonb_build_object('type', 'Polygon', 'coordinates', jsonb_build_array(coords))::text::geometry;
  ELSIF upper(btrim(wkt)) LIKE 'LINESTRING%' THEN
    RETURN jsonb_build_object('type', 'LineString', 'coordinates', coords)::text::geometry;
  ELSE
    RETURN wkt::geometry;
  END IF;
END;
$f$;

CREATE OR REPLACE FUNCTION ST_Contains(poly geometry, pt geometry)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  anillo jsonb;
  px double precision;
  py double precision;
  min_x double precision := 999999;
  max_x double precision := -999999;
  min_y double precision := 999999;
  max_y double precision := -999999;
  vertice jsonb;
  vx double precision;
  vy double precision;
BEGIN
  anillo := (poly::jsonb)->'coordinates'->0;
  px := ST_X(pt);
  py := ST_Y(pt);
  FOR vertice IN SELECT * FROM jsonb_array_elements(anillo) LOOP
    vx := (vertice->>0)::double precision;
    vy := (vertice->>1)::double precision;
    IF vx < min_x THEN min_x := vx; END IF;
    IF vx > max_x THEN max_x := vx; END IF;
    IF vy < min_y THEN min_y := vy; END IF;
    IF vy > max_y THEN max_y := vy; END IF;
  END LOOP;
  RETURN px >= min_x AND px <= max_x AND py >= min_y AND py <= max_y;
END;
$f$;

CREATE OR REPLACE FUNCTION ST_Distance(g1 geography, g2 geography)
RETURNS double precision LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
  lon1 double precision := radians(((g1::jsonb)->'coordinates'->>0)::double precision);
  lat1 double precision := radians(((g1::jsonb)->'coordinates'->>1)::double precision);
  lon2 double precision := radians(((g2::jsonb)->'coordinates'->>0)::double precision);
  lat2 double precision := radians(((g2::jsonb)->'coordinates'->>1)::double precision);
  dlon double precision := lon2 - lon1;
  dlat double precision := lat2 - lat1;
  a double precision;
BEGIN
  a := pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
  RETURN 6371000.0 * 2.0 * asin(least(1.0, sqrt(a)));
END;
$f$;
`;

function buscarCarpetaDatabase(): string | null {
  for (const ruta of [resolve(process.cwd(), "database"), resolve(process.cwd(), "../../database")]) {
    if (existsSync(resolve(ruta, "01_schema_postgis.sql"))) return ruta;
  }
  return null;
}

/**
 * Inicializa automáticamente las tablas y la semilla en PostgreSQL si la base está vacía.
 * Usa la extensión PostGIS nativa cuando está disponible (Docker / Oracle Cloud) o funciones
 * equivalentes en SQL puro si el PostgreSQL local no tiene el binario de PostGIS instalado.
 */
export async function asegurarEsquemaPostgres(db: pg.Pool): Promise<void> {
  const ext = await db.query("SELECT 1 FROM pg_available_extensions WHERE name = 'postgis'");
  const tienePostgis = (ext.rowCount ?? 0) > 0;
  if (!tienePostgis) {
    await db.query(SHIM_SIN_POSTGIS_SQL);
  }

  const existeTabla = await db.query("SELECT to_regclass('public.reportes') AS reg");
  const dir = buscarCarpetaDatabase();
  if (!existeTabla.rows[0]?.reg && dir) {
    let schemaSql = readFileSync(resolve(dir, "01_schema_postgis.sql"), "utf8");
    if (!tienePostgis) {
      schemaSql = schemaSql
        .replace(/CREATE EXTENSION IF NOT EXISTS postgis;/gi, "-- postgis shim")
        .replace(/GEOMETRY\s*\([^)]+\)/gi, "geometry")
        .replace(/USING GIST\s*\(geom\)/gi, "(geom)");
    }
    await db.query(schemaSql);
  }
  if (dir) {
    const conteoZonas = await db.query("SELECT count(*)::int AS n FROM zonas_riesgo");
    if ((conteoZonas.rows[0]?.n ?? 0) === 0) {
      const seedSql = readFileSync(resolve(dir, "02_seed_escenario_06am.sql"), "utf8");
      await db.query(seedSql);
    }
  }
}

const iso = (v: unknown) => (v instanceof Date ? v.toISOString() : String(v));

const COLUMNAS_REPORTE = `
  id, usuario_id, origen, tipo, descripcion, gravedad, estado,
  ST_Y(geom) AS latitud, ST_X(geom) AS longitud, precision_m, ubicacion_aproximada, sector,
  capturado_en, recibido_en, verificado, personas_afectadas, ninos, adultos_mayores, necesidades,
  foto_ruta AS foto_url, foto_miniatura_ruta AS foto_miniatura_url`;

function filaReporte(f: Record<string, unknown>): Reporte {
  return {
    ...(f as unknown as Reporte),
    latitud: Number(f.latitud),
    longitud: Number(f.longitud),
    precision_m: f.precision_m === null ? null : Number(f.precision_m),
    capturado_en: iso(f.capturado_en),
    recibido_en: iso(f.recibido_en),
  };
}

export class UsuariosPg implements RepositorioUsuarios {
  constructor(private readonly db: pg.Pool) {}

  async buscarPorCorreo(correo: string) {
    const r = await this.db.query(
      "SELECT id, nombre, correo, rol, clave_hash, creado_en FROM usuarios WHERE lower(correo) = lower($1)",
      [correo],
    );
    const f = r.rows[0];
    return f ? ({ ...f, creado_en: iso(f.creado_en) } as UsuarioConClave) : null;
  }

  async crear(u: UsuarioConClave) {
    await this.db.query(
      "INSERT INTO usuarios (id, nombre, correo, rol, clave_hash, creado_en) VALUES ($1, $2, $3, $4, $5, $6)",
      [u.id, u.nombre, u.correo, u.rol, u.clave_hash, u.creado_en],
    );
  }
}

export class ReportesPg implements RepositorioReportes {
  constructor(private readonly db: pg.Pool) {}

  async insertar(r: Reporte) {
    const res = await this.db.query(
      `INSERT INTO reportes (id, usuario_id, origen, tipo, descripcion, gravedad, estado, geom, precision_m,
         ubicacion_aproximada, sector, capturado_en, recibido_en, verificado, personas_afectadas, ninos,
         adultos_mayores, necesidades)
       VALUES ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($8, $9), 4326), $10, $11, $12, $13, $14, $15,
         $16, $17, $18, $19)
       ON CONFLICT (id) DO NOTHING`,
      [r.id, r.usuario_id, r.origen, r.tipo, r.descripcion, r.gravedad, r.estado, r.longitud, r.latitud, r.precision_m,
        r.ubicacion_aproximada, r.sector, r.capturado_en, r.recibido_en, r.verificado, r.personas_afectadas, r.ninos,
        r.adultos_mayores, r.necesidades],
    );
    return res.rowCount === 1;
  }

  async buscar(id: string) {
    const r = await this.db.query(`SELECT ${COLUMNAS_REPORTE} FROM reportes WHERE id = $1`, [id]);
    return r.rows[0] ? filaReporte(r.rows[0]) : null;
  }

  async listar(f: FiltroReportes) {
    const condiciones: string[] = [];
    const valores: unknown[] = [];
    const agregar = (columna: string, valor: unknown) => {
      if (valor === undefined) return;
      valores.push(valor);
      condiciones.push(`${columna} = $${valores.length}`);
    };
    agregar("estado", f.estado);
    agregar("tipo", f.tipo);
    agregar("gravedad", f.gravedad);
    agregar("verificado", f.verificado);
    agregar("usuario_id", f.usuario_id);
    const donde = condiciones.length ? `WHERE ${condiciones.join(" AND ")}` : "";
    const total = await this.db.query(`SELECT count(*)::int AS n FROM reportes ${donde}`, valores);
    const pagina = await this.db.query(
      `SELECT ${COLUMNAS_REPORTE} FROM reportes ${donde} ORDER BY recibido_en DESC
       LIMIT $${valores.length + 1} OFFSET $${valores.length + 2}`,
      [...valores, f.limite, (f.pagina - 1) * f.limite],
    );
    return { total: total.rows[0].n as number, items: pagina.rows.map(filaReporte) };
  }

  /** Cambio de estado + historial en una sola transacción (ACID). */
  async actualizarEstado(id: string, c: Pick<Reporte, "estado" | "verificado">, nota: string | null, operadorId: string) {
    const cliente = await this.db.connect();
    try {
      await cliente.query("BEGIN");
      const previo = await cliente.query("SELECT estado FROM reportes WHERE id = $1 FOR UPDATE", [id]);
      if (!previo.rows[0]) {
        await cliente.query("ROLLBACK");
        return null;
      }
      await cliente.query("UPDATE reportes SET estado = $2, verificado = $3 WHERE id = $1", [id, c.estado, c.verificado]);
      await cliente.query(
        `INSERT INTO reportes_historial (reporte_id, estado_anterior, estado_nuevo, operador_id, nota)
         VALUES ($1, $2, $3, $4, $5)`,
        [id, previo.rows[0].estado, c.estado, operadorId, nota],
      );
      const r = await cliente.query(`SELECT ${COLUMNAS_REPORTE} FROM reportes WHERE id = $1`, [id]);
      await cliente.query("COMMIT");
      return filaReporte(r.rows[0]);
    } catch (e) {
      await cliente.query("ROLLBACK");
      throw e;
    } finally {
      cliente.release();
    }
  }

  async guardarFoto(id: string, url: string, miniaturaUrl: string) {
    const r = await this.db.query(
      `UPDATE reportes SET foto_ruta = $2, foto_miniatura_ruta = $3 WHERE id = $1 RETURNING ${COLUMNAS_REPORTE}`,
      [id, url, miniaturaUrl],
    );
    return r.rows[0] ? filaReporte(r.rows[0]) : null;
  }
}

const COLUMNAS_PUNTO = `id, nombre, tipo, telefono, direccion, capacidad, ocupacion, activo,
  ST_Y(geom) AS latitud, ST_X(geom) AS longitud`;

const filaPunto = (f: Record<string, unknown>) =>
  ({ ...(f as unknown as PuntoServicio), latitud: Number(f.latitud), longitud: Number(f.longitud) });

export class TerritorioPg implements RepositorioTerritorio {
  constructor(private readonly db: pg.Pool) {}

  private async coleccion(sql: string): Promise<GeoJsonColeccion> {
    const r = await this.db.query(sql);
    return { type: "FeatureCollection", features: r.rows.map((f) => f.feature) };
  }

  zonasGeoJson() {
    return this.coleccion(`
      SELECT json_build_object('type', 'Feature', 'id', id, 'geometry', ST_AsGeoJSON(geom, 6)::json,
        'properties', json_build_object('id', id, 'nombre_sector', nombre_sector, 'tipo_amenaza', tipo_amenaza,
          'nivel_riesgo', nivel_riesgo, 'origen', origen, 'fuente', fuente)) AS feature
      FROM zonas_riesgo ORDER BY nombre_sector`);
  }

  viasGeoJson() {
    return this.coleccion(`
      SELECT json_build_object('type', 'Feature', 'id', id, 'geometry', ST_AsGeoJSON(geom, 6)::json,
        'properties', json_build_object('id', id, 'nombre', nombre, 'estado', estado, 'origen', origen,
          'actualizado_en', actualizado_en)) AS feature
      FROM vias ORDER BY nombre`);
  }

  async sectorDe(lat: number, lon: number) {
    const r = await this.db.query(
      `SELECT nombre_sector FROM zonas_riesgo
       WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($1, $2), 4326)) LIMIT 1`,
      [lon, lat],
    );
    return (r.rows[0]?.nombre_sector as string | undefined) ?? null;
  }

  async listarPuntos(tipo?: TipoPuntoServicio, soloActivos = true) {
    const r = await this.db.query(
      `SELECT ${COLUMNAS_PUNTO} FROM puntos_servicio
       WHERE ($1::text IS NULL OR tipo = $1) AND (NOT $2 OR activo) ORDER BY nombre`,
      [tipo ?? null, soloActivos],
    );
    return r.rows.map(filaPunto);
  }

  async puntosCercanos(c: Cercania) {
    const r = await this.db.query(
      `SELECT ${COLUMNAS_PUNTO},
         ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) AS distancia_m
       FROM puntos_servicio
       WHERE activo AND capacidad - ocupacion >= $5 AND ($3::text IS NULL OR tipo = $3)
       ORDER BY distancia_m LIMIT $4`,
      [c.longitud, c.latitud, c.tipo ?? null, c.limite, c.personas],
    );
    return r.rows.map((f) => ({ ...filaPunto(f), distancia_m: Number(f.distancia_m) }));
  }

  async actualizarOcupacion(id: string, ocupacion: number) {
    const r = await this.db.query(
      `UPDATE puntos_servicio SET ocupacion = $2, actualizado_en = now() WHERE id = $1 RETURNING ${COLUMNAS_PUNTO}`,
      [id, ocupacion],
    );
    return r.rows[0] ? filaPunto(r.rows[0]) : null;
  }
}
