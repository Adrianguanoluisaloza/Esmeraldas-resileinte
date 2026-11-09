import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { AlmacenFotos } from "../dominio/puertos.js";

/**
 * Guarda la foto en disco (en Docker, un volumen). La miniatura se genera con sharp si está instalado;
 * si no, se usa la misma foto para no bloquear la sincronización del celular.
 * El nombre del archivo es el id del reporte: reenviar la foto la reemplaza (idempotente).
 */
export class FotosEnDisco implements AlmacenFotos {
  constructor(
    private readonly carpeta: string,
    private readonly urlPublica: string,
  ) {}

  async guardar(reporteId: string, bytes: Uint8Array, extension: "jpg" | "png") {
    await mkdir(this.carpeta, { recursive: true });
    const nombre = `${reporteId}.${extension}`;
    await writeFile(join(this.carpeta, nombre), bytes);
    let miniatura = nombre;
    try {
      const { default: sharp } = await import("sharp");
      miniatura = `${reporteId}.min.jpg`;
      await sharp(bytes).rotate().resize({ width: 320, withoutEnlargement: true }).jpeg({ quality: 60 }).toFile(join(this.carpeta, miniatura));
    } catch {
      miniatura = nombre;
    }
    return { url: `${this.urlPublica}/${nombre}`, miniaturaUrl: `${this.urlPublica}/${miniatura}`, tamano: bytes.byteLength };
  }
}

/** Revisa los primeros bytes en vez de confiar en la extensión o el Content-Type que manda el cliente. */
export function detectarImagen(bytes: Uint8Array): "jpg" | "png" | null {
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return "jpg";
  if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47) return "png";
  return null;
}
