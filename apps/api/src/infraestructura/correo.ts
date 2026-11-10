import nodemailer, { type Transporter } from "nodemailer";
import type { ServicioCorreo } from "../dominio/puertos.js";

const texto = (nombre: string, enlace: string) => `Hola ${nombre}:

Recibimos una solicitud para restablecer tu contraseña de Esmeraldas Resiliente.
Abre este enlace para crear una nueva. Vence en 30 minutos y solo funciona una vez:

${enlace}

Si no la pediste, ignora este correo. Tu contraseña no cambia.
`;

export class CorreoSmtp implements ServicioCorreo {
  private readonly transporte: Transporter;

  constructor(host: string, puerto: number, usuario: string, clave: string, private readonly remitente: string) {
    this.transporte = nodemailer.createTransport({ host, port: puerto, secure: puerto === 465, requireTLS: puerto !== 465, auth: { user: usuario, pass: clave } });
  }

  async enviarRestablecimiento(destino: string, nombre: string, enlace: string) {
    await this.transporte.sendMail({
      from: `"Esmeraldas Resiliente" <${this.remitente}>`,
      to: destino,
      subject: "Restablecer tu contraseña",
      text: texto(nombre, enlace),
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
