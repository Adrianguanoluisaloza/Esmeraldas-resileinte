import { GRAVEDADES, TIPOS_INCIDENTE, type Gravedad, type TipoIncidente } from "../../dominio/catalogos.js";
import { ErrorDominio } from "../../dominio/errores.js";
import type { ClasificadorIa, EntradaClasificacion, ResultadoClasificacion } from "../../dominio/puertos.js";

/**
 * Prompt base de ejemplo para clasificación de reportes.
 * En producción se sustituye por las instrucciones completas configuradas en el servidor.
 */
const INSTRUCCION = `Asistente de apoyo para clasificar reportes de emergencia.
Devuelve únicamente un JSON válido con:
- tipo_sugerido: uno de ${TIPOS_INCIDENTE.join(", ")}.
- gravedad_sugerida: una de ${GRAVEDADES.join(", ")}.
- explicacion: breve resumen técnico en español (máximo 3 frases).
- confianza: número entre 0 y 1.
Es apoyo no vinculante: la decisión final corresponde al operador.`;

const ESQUEMA_RESPUESTA = {
  type: "OBJECT",
  properties: {
    tipo_sugerido: { type: "STRING", enum: [...TIPOS_INCIDENTE] },
    gravedad_sugerida: { type: "STRING", enum: [...GRAVEDADES] },
    explicacion: { type: "STRING" },
    confianza: { type: "NUMBER" },
  },
  required: ["tipo_sugerido", "gravedad_sugerida", "explicacion", "confianza"],
};

type Fetch = typeof fetch;

/**
 * Llama a Gemini en Vertex AI (endpoint global) con clave de API. Razonamiento en nivel bajo
 * ("low") para responder rápido y barato. La clave vive solo en el .env del servidor.
 */
export class ClasificadorGemini implements ClasificadorIa {
  constructor(
    private readonly claveApi: string,
    private readonly modelo: string,
    private readonly hacerFetch: Fetch = fetch,
    private readonly tiempoMaximoMs = 25_000,
  ) {}

  async clasificar(e: EntradaClasificacion): Promise<ResultadoClasificacion> {
    const texto = [
      `Tipo reportado: ${e.tipo}. Gravedad reportada: ${e.gravedad}.`,
      `Sector: ${e.sector ?? "desconocido"}.`,
      `Personas afectadas: ${e.personas_afectadas} (niños ${e.ninos}, adultos mayores ${e.adultos_mayores}).`,
      `Necesidades: ${e.necesidades.length ? e.necesidades.join(", ") : "ninguna"}.`,
      `Descripción del ciudadano: """${e.descripcion.slice(0, 1000)}"""`,
      e.foto ? "Se adjunta la foto del lugar." : "El reporte no tiene foto.",
    ].join("\n");

    const partes: unknown[] = [{ text: texto }];
    if (e.foto) partes.push({ inlineData: { mimeType: e.foto.tipo, data: Buffer.from(e.foto.bytes).toString("base64") } });

    const url = `https://aiplatform.googleapis.com/v1/publishers/google/models/${encodeURIComponent(this.modelo)}:generateContent`;
    let res: Response;
    try {
      res = await this.hacerFetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": this.claveApi },
        signal: AbortSignal.timeout(this.tiempoMaximoMs),
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: INSTRUCCION }] },
          contents: [{ role: "user", parts: partes }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: ESQUEMA_RESPUESTA,
            temperature: 0.2,
            maxOutputTokens: 600,
            thinkingConfig: { thinkingLevel: "LOW" },
          },
        }),
      });
    } catch {
      throw new ErrorDominio("NO_DISPONIBLE", "El servicio de IA no respondió a tiempo");
    }
    if (!res.ok) {
      console.error(JSON.stringify({ nivel: "error", origen: "ia", estado: res.status }));
      throw new ErrorDominio("NO_DISPONIBLE", "El servicio de IA no está disponible");
    }
    const cuerpo = (await res.json()) as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
    const salida = cuerpo.candidates?.[0]?.content?.parts?.map((p) => p.text ?? "").join("") ?? "";
    return validar(salida);
  }
}

/** No se confía en el modelo: se validan los valores y se recorta el texto. */
export function validar(salida: string): ResultadoClasificacion {
  let datos: Record<string, unknown>;
  try {
    datos = JSON.parse(salida) as Record<string, unknown>;
  } catch {
    throw new ErrorDominio("NO_DISPONIBLE", "La IA devolvió una respuesta no válida");
  }
  const tipo = datos.tipo_sugerido as TipoIncidente;
  const gravedad = datos.gravedad_sugerida as Gravedad;
  const confianza = Number(datos.confianza);
  if (!TIPOS_INCIDENTE.includes(tipo) || !GRAVEDADES.includes(gravedad) || typeof datos.explicacion !== "string" || !Number.isFinite(confianza)) {
    throw new ErrorDominio("NO_DISPONIBLE", "La IA devolvió una respuesta no válida");
  }
  return {
    tipo_sugerido: tipo,
    gravedad_sugerida: gravedad,
    explicacion: datos.explicacion.trim().slice(0, 600),
    confianza: Math.round(Math.min(1, Math.max(0, confianza)) * 100) / 100,
  };
}
