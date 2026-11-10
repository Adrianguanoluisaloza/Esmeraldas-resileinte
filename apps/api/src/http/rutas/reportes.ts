import { Hono } from "hono";
import { ErrorDominio } from "../../dominio/errores.js";
import { detectarImagen } from "../../infraestructura/fotosDisco.js";
import { leerJson, requiereSesion, sesionDe, sesionOpcional, validar, type Dependencias, type Entorno } from "../contexto.js";
import { CambioEstadoEntrada, EdicionReporteEntrada, FiltroReportesEntrada, IdRuta, ReporteEntrada } from "../esquemas.js";

const FOTO_MAX_BYTES = 2 * 1024 * 1024;

export function rutasReportes(deps: Dependencias) {
  const r = new Hono<Entorno>();
  const conSesion = requiereSesion(deps.tokens);
  const sesionSiHay = sesionOpcional(deps.tokens);

  // Paso 1 de la cola offline: datos livianos. Con o sin cuenta (emergencia sin cuenta queda anónima).
  // 201 si es nuevo, 200 si ya se había recibido.
  r.post("/", sesionSiHay, async (c) => {
    const e = await leerJson(c, ReporteEntrada);
    const { reporte, nuevo } = await deps.reportes.crear(sesionDe(c), {
      ...e,
      precision_m: e.precision_m ?? null,
      ubicacion_aproximada: e.ubicacion_aproximada ?? false,
      capturado_en: new Date(e.capturado_en).toISOString(),
      personas_afectadas: e.personas_afectadas ?? 0,
      ninos: e.ninos ?? 0,
      adultos_mayores: e.adultos_mayores ?? 0,
      necesidades: [...new Set(e.necesidades ?? [])],
    });
    return c.json(reporte, nuevo ? 201 : 200);
  });

  r.get("/", conSesion, async (c) => {
    const f = validar(FiltroReportesEntrada, c.req.query());
    const { total, items } = await deps.reportes.listar(c.get("sesion"), f);
    return c.json({ total, pagina: f.pagina, items });
  });

  r.get("/:id", conSesion, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    return c.json(await deps.reportes.detalleConHistorial(c.get("sesion"), id));
  });

  r.patch("/:id", conSesion, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    const e = await leerJson(c, EdicionReporteEntrada);
    return c.json(await deps.reportes.editar(c.get("sesion"), id, e));
  });

  r.patch("/:id/estado", conSesion, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    const e = await leerJson(c, CambioEstadoEntrada);
    return c.json(await deps.reportes.cambiarEstado(c.get("sesion"), id, e.estado, e.nota ?? null, e.verificado));
  });

  // Paso 2 de la cola offline: foto comprimida (multipart, campo "foto").
  r.post("/:id/foto", sesionSiHay, async (c) => {
    const { id } = validar(IdRuta, c.req.param());
    await deps.reportes.validarSubidaFoto(sesionDe(c), id);
    const cuerpo = await c.req.parseBody();
    const archivo = cuerpo.foto;
    if (!(archivo instanceof File)) throw new ErrorDominio("VALIDACION", "Falta el archivo en el campo foto");
    if (archivo.size > FOTO_MAX_BYTES) throw new ErrorDominio("VALIDACION", "La foto supera 2 MB");
    const bytes = new Uint8Array(await archivo.arrayBuffer());
    const extension = detectarImagen(bytes);
    if (!extension) throw new ErrorDominio("VALIDACION", "Solo se aceptan JPEG o PNG");
    const guardada = await deps.fotos.guardar(id, bytes, extension);
    await deps.repoReportes.guardarFoto(id, guardada.url, guardada.miniaturaUrl);
    return c.json({
      reporte_id: id,
      ruta: guardada.url,
      ruta_miniatura: guardada.miniaturaUrl,
      tamano_bytes: guardada.tamano,
      subida_en: new Date().toISOString(),
    }, 201);
  });

  return r;
}
