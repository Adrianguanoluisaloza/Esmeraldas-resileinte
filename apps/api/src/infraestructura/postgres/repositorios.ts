import pg from "pg";
import type { Rol, TipoPuntoServicio } from "../../dominio/catalogos.js";
import { esSuministro, type Alerta, type Entrega, type EstadoVia, type HistorialEstado, type ItemInventario, type Suministro } from "../../dominio/operacion.js";
import type {
  Cercania,
  RepositorioAlertas,
  RepositorioAsistencia,
  FiltroReportes,
  GeoJsonColeccion,
  RepositorioReportes,
  RepositorioRestablecimientos,
  RepositorioTerritorio,
  RepositorioUsuarios,
  SolicitudRestablecimiento,
  Usuario,
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

  async listar() {
    const r = await this.db.query("SELECT id, nombre, correo, rol, creado_en FROM usuarios ORDER BY creado_en DESC LIMIT 200");
    return r.rows.map((f) => ({ ...f, creado_en: iso(f.creado_en) }) as Usuario);
  }

  async cambiarRol(id: string, rol: Rol) {
    const r = await this.db.query("UPDATE usuarios SET rol = $2 WHERE id = $1 RETURNING id, nombre, correo, rol, creado_en", [id, rol]);
    const f = r.rows[0];
    return f ? ({ ...f, creado_en: iso(f.creado_en) } as Usuario) : null;
  }
}

export class RestablecimientosPg implements RepositorioRestablecimientos {
  constructor(private readonly db: pg.Pool) {}

  async crear(s: SolicitudRestablecimiento) {
    await this.db.query(
      `WITH previas AS (UPDATE restablecimientos SET usado_en = $4 WHERE usuario_id = $1 AND usado_en IS NULL)
       INSERT INTO restablecimientos (usuario_id, token_hash, expira_en, creado_en) VALUES ($1, $2, $3, $4)`,
      [s.usuario_id, s.token_hash, s.expira_en, s.creado_en],
    );
  }

  async consumir(token_hash: string, ahora: string, clave_hash: string) {
    // Una sola sentencia: dos peticiones simultáneas con el mismo token no pueden usarlo las dos.
    const r = await this.db.query(
      `WITH token AS (
         UPDATE restablecimientos SET usado_en = $2
         WHERE token_hash = $1 AND usado_en IS NULL AND expira_en > $2
         RETURNING usuario_id
       )
       UPDATE usuarios u SET clave_hash = $3 FROM token WHERE u.id = token.usuario_id`,
      [token_hash, ahora, clave_hash],
    );
    return r.rowCount === 1;
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
    if (f.tipos) {
      valores.push([...f.tipos]);
      condiciones.push(`tipo = ANY($${valores.length}::text[])`);
    }
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
  async actualizarEstado(id: string, c: Pick<Reporte, "estado" | "verificado">, nota: string | null, operador: { id: string; nombre: string }) {
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
        [id, previo.rows[0].estado, c.estado, operador.id, nota],
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

  async historial(id: string): Promise<HistorialEstado[]> {
    const r = await this.db.query(
      `SELECT h.id, h.estado_anterior, h.estado_nuevo, u.nombre AS operador_nombre, h.nota, h.fecha
       FROM reportes_historial h LEFT JOIN usuarios u ON u.id = h.operador_id
       WHERE h.reporte_id = $1 ORDER BY h.fecha`,
      [id],
    );
    return r.rows.map((f) => ({ ...f, fecha: iso(f.fecha) }) as HistorialEstado);
  }

  async guardarFoto(id: string, url: string, miniaturaUrl: string) {
    const r = await this.db.query(
      `UPDATE reportes SET foto_ruta = $2, foto_miniatura_ruta = $3 WHERE id = $1 RETURNING ${COLUMNAS_REPORTE}`,
      [id, url, miniaturaUrl],
    );
    return r.rows[0] ? filaReporte(r.rows[0]) : null;
  }
}

const COLUMNAS_PUNTO = `id, nombre, tipo, telefono, direccion, capacidad, ocupacion, activo, origen,
  ST_Y(geom) AS latitud, ST_X(geom) AS longitud`;
/** Mismas columnas con alias "p." para consultas con varias tablas. */
const COLUMNAS_PUNTO_P = `p.id, p.nombre, p.tipo, p.telefono, p.direccion, p.capacidad, p.ocupacion, p.activo, p.origen,
  ST_Y(p.geom) AS latitud, ST_X(p.geom) AS longitud`;

const filaPunto = (f: Record<string, unknown>) =>
  ({ ...(f as unknown as PuntoServicio), latitud: Number(f.latitud), longitud: Number(f.longitud) });

export class TerritorioPg implements RepositorioTerritorio {
  constructor(private readonly db: pg.Pool) {}

  async crearPunto(p: PuntoServicio) {
    const r = await this.db.query(
      `INSERT INTO puntos_servicio (id, nombre, tipo, telefono, direccion, capacidad, ocupacion, activo, origen, geom)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, ST_SetSRID(ST_MakePoint($10, $11), 4326))
       RETURNING ${COLUMNAS_PUNTO}`,
      [p.id, p.nombre, p.tipo, p.telefono, p.direccion, p.capacidad, p.ocupacion, p.activo, p.origen, p.longitud, p.latitud],
    );
    return filaPunto(r.rows[0]);
  }

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
      `WITH origen AS (SELECT ST_SetSRID(ST_MakePoint($1, $2), 4326) AS g),
            bloqueadas AS (SELECT geom FROM vias WHERE estado = 'bloqueada')
       SELECT ${COLUMNAS_PUNTO_P},
         ST_Distance(p.geom::geography, o.g::geography) AS distancia_m,
         EXISTS (SELECT 1 FROM bloqueadas b WHERE ST_Intersects(ST_MakeLine(o.g, p.geom), b.geom)) AS paso_bloqueado
       FROM puntos_servicio p, origen o
       WHERE p.activo AND p.capacidad - p.ocupacion >= $5 AND ($3::text IS NULL OR p.tipo = $3)
       ORDER BY paso_bloqueado, distancia_m LIMIT $4`,
      [c.longitud, c.latitud, c.tipo ?? null, c.limite, c.personas],
    );
    return r.rows.map((f) => ({ ...filaPunto(f), distancia_m: Number(f.distancia_m), paso_bloqueado: Boolean(f.paso_bloqueado) }));
  }

  async actualizarVia(id: string, estado: EstadoVia) {
    const r = await this.db.query(
      `UPDATE vias SET estado = $2, actualizado_en = now() WHERE id = $1
       RETURNING id, nombre, estado, origen, actualizado_en`,
      [id, estado],
    );
    return r.rows[0] ? { ...r.rows[0], actualizado_en: iso(r.rows[0].actualizado_en) } : null;
  }

  async actualizarOcupacion(id: string, ocupacion: number) {
    const r = await this.db.query(
      `UPDATE puntos_servicio SET ocupacion = $2, actualizado_en = now() WHERE id = $1 RETURNING ${COLUMNAS_PUNTO}`,
      [id, ocupacion],
    );
    return r.rows[0] ? filaPunto(r.rows[0]) : null;
  }
}

const filaAlerta = (f: Record<string, unknown>) => ({ ...(f as unknown as Alerta), creado_en: iso(f.creado_en) });

export class AlertasPg implements RepositorioAlertas {
  constructor(private readonly db: pg.Pool) {}

  async listar(soloVigentes: boolean) {
    const r = await this.db.query(
      `SELECT id, sector, mensaje, nivel, origen, creado_por, creado_en, vigente FROM alertas
       WHERE (NOT $1 OR vigente) ORDER BY creado_en DESC LIMIT 200`,
      [soloVigentes],
    );
    return r.rows.map(filaAlerta);
  }

  async crear(a: Alerta) {
    await this.db.query(
      `INSERT INTO alertas (id, sector, mensaje, nivel, origen, creado_por, creado_en, vigente)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [a.id, a.sector, a.mensaje, a.nivel, a.origen, a.creado_por, a.creado_en, a.vigente],
    );
  }

  async cerrar(id: string) {
    const r = await this.db.query(
      `UPDATE alertas SET vigente = false WHERE id = $1
       RETURNING id, sector, mensaje, nivel, origen, creado_por, creado_en, vigente`,
      [id],
    );
    return r.rows[0] ? filaAlerta(r.rows[0]) : null;
  }
}

export class AsistenciaPg implements RepositorioAsistencia {
  constructor(private readonly db: pg.Pool) {}

  /** Descuento de stock e inserción en una sola transacción: o pasan las dos, o ninguna. */
  async registrar(e: Entrega) {
    const cliente = await this.db.connect();
    try {
      await cliente.query("BEGIN");
      if (esSuministro(e.necesidad)) {
        const r = await cliente.query(
          "UPDATE inventario SET cantidad = cantidad - $2, actualizado_en = now() WHERE necesidad = $1 AND cantidad >= $2",
          [e.necesidad, e.cantidad],
        );
        if (r.rowCount !== 1) {
          await cliente.query("ROLLBACK");
          return "sin_stock" as const;
        }
      }
      await cliente.query(
        `INSERT INTO entregas (id, reporte_id, necesidad, cantidad, nota, entregado_por, entregado_en)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [e.id, e.reporte_id, e.necesidad, e.cantidad, e.nota, e.entregado_por, e.entregado_en],
      );
      await cliente.query("COMMIT");
      return "ok" as const;
    } catch (err) {
      await cliente.query("ROLLBACK");
      throw err;
    } finally {
      cliente.release();
    }
  }

  async inventario() {
    const r = await this.db.query("SELECT necesidad, cantidad, unidad, actualizado_en FROM inventario ORDER BY necesidad");
    return r.rows.map((f) => ({ ...f, actualizado_en: iso(f.actualizado_en) }) as ItemInventario);
  }

  async ajustarInventario(necesidad: Suministro, delta: number) {
    const r = await this.db.query(
      `UPDATE inventario SET cantidad = GREATEST(0, cantidad + $2), actualizado_en = now() WHERE necesidad = $1
       RETURNING necesidad, cantidad, unidad, actualizado_en`,
      [necesidad, delta],
    );
    return r.rows[0] ? ({ ...r.rows[0], actualizado_en: iso(r.rows[0].actualizado_en) } as ItemInventario) : null;
  }

  async listar() {
    const r = await this.db.query(
      "SELECT id, reporte_id, necesidad, cantidad, nota, entregado_por, entregado_en FROM entregas ORDER BY entregado_en DESC LIMIT 5000",
    );
    return r.rows.map((f) => ({ ...f, entregado_en: iso(f.entregado_en) }) as Entrega);
  }
}
