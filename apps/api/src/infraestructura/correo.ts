import nodemailer, { type Transporter } from "nodemailer";
import type { ServicioCorreo } from "../dominio/puertos.js";

const texto = (nombre: string, enlace: string) => `Hola ${nombre}:

Recibimos una solicitud para restablecer tu contraseña de Esmeraldas Resiliente.
Abre este enlace para crear una nueva. Vence en 30 minutos y solo funciona una vez:

${enlace}

Si no la pediste, ignora este correo. Tu contraseña no cambia.
`;

const escapar = (t: string) => t.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

/** Los clientes de correo no leen hojas de estilo ni variables: tabla y estilos en línea. */
const html = (nombre: string, enlace: string) => `<!doctype html>
<html lang="es"><body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,Helvetica,sans-serif;color:#171717">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:32px 16px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border:1px solid #e4e4e7;border-radius:8px">
<tr><td style="padding:20px 28px;border-bottom:1px solid #e4e4e7;font-size:15px;font-weight:700;color:#0b6e4f">Esmeraldas Resiliente</td></tr>
<tr><td style="padding:28px">
<h1 style="margin:0 0 12px;font-size:20px;line-height:1.3;color:#171717">Restablece tu contraseña</h1>
<p style="margin:0 0 24px;font-size:15px;line-height:1.55;color:#3f3f46">Hola ${escapar(nombre)}, recibimos una solicitud para crear una contraseña nueva en tu cuenta.</p>
<table role="presentation" cellpadding="0" cellspacing="0"><tr><td style="background:#0b6e4f;border-radius:6px"><a href="${escapar(enlace)}" style="display:inline-block;padding:12px 22px;font-size:15px;font-weight:700;color:#ffffff;text-decoration:none">Crear contraseña nueva</a></td></tr></table>
<p style="margin:24px 0 0;font-size:13px;line-height:1.55;color:#71717a">El enlace vence en 30 minutos y solo funciona una vez. Si no la pediste, ignora este correo: tu contraseña no cambia.</p>
</td></tr>
<tr><td style="padding:16px 28px;border-top:1px solid #e4e4e7;font-size:12px;line-height:1.5;color:#71717a">Esmeraldas Resiliente no reemplaza al ECU 911. En una emergencia llama al 911.</td></tr>
</table>
</td></tr></table>
</body></html>`;

export class CorreoSmtp implements ServicioCorreo {
  private readonly transporte: Transporter;

  constructor(host: string, puerto: number, usuario: string, clave: string, private readonly remitente: string) {
    this.transporte = nodemailer.createTransport({ host, port: puerto, secure: puerto === 465, requireTLS: puerto !== 465, auth: { user: usuario, pass: clave } });
  }

  async enviarRestablecimiento(destino: string, nombre: string, enlace: string) {
    await this.transporte.sendMail({
      from: `"Esmeraldas Resiliente" <${this.remitente}>`,
      to: destino,
      subject: "Restablece tu contraseña",
      text: texto(nombre, enlace),
      html: html(nombre, enlace),
    });
  }
}

/** Sin SMTP configurado. Fuera de producción muestra el enlace en consola para poder probar. */
export class CorreoSinConfigurar implements ServicioCorreo {
  constructor(private readonly mostrarEnlace: boolean) {}

  async enviarRestablecimiento(_destino: string, _nombre: string, enlace: string) {
    console.warn(JSON.stringify({ evento: "correo_sin_configurar", ...(this.mostrarEnlace ? { enlace } : {}) }));
  }
}
