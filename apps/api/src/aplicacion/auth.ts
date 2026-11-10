import { createHash, randomBytes, randomUUID } from "node:crypto";
import { ErrorDominio } from "../dominio/errores.js";
import type { Rol } from "../dominio/catalogos.js";
import type { Reloj, RepositorioRestablecimientos, RepositorioUsuarios, ServicioClaves, ServicioCorreo, ServicioTokens, Usuario } from "../dominio/puertos.js";

const MINUTOS_ENLACE = 30;
/** Cuentas sin buzón real: no se les envía correo. */
const SIN_BUZON = ["@demo.esmeraldas-resiliente.ec", "@firebase.local"];

const hashToken = (token: string) => createHash("sha256").update(token).digest("hex");

export class CasosAuth {
  constructor(
    private readonly usuarios: RepositorioUsuarios,
    private readonly claves: ServicioClaves,
    private readonly tokens: ServicioTokens,
    private readonly reloj: Reloj,
    private readonly restablecimientos: RepositorioRestablecimientos,
    private readonly correo: ServicioCorreo,
    private readonly urlWeb: string,
  ) {}

  /** Si el correo no existe no hace nada: quien pregunta no puede saber qué correos están registrados. */
  async solicitarRestablecimiento(correo: string) {
    const normalizado = correo.trim().toLowerCase();
    if (SIN_BUZON.some((d) => normalizado.endsWith(d))) return;
    const usuario = await this.usuarios.buscarPorCorreo(normalizado);
    if (!usuario) return;
    const ahora = this.reloj.ahora();
    const token = randomBytes(32).toString("base64url");
    await this.restablecimientos.crear({
      usuario_id: usuario.id,
      // Solo se guarda el hash: quien lea la base no puede usar el enlace.
      token_hash: hashToken(token),
      expira_en: new Date(ahora.getTime() + MINUTOS_ENLACE * 60_000).toISOString(),
      creado_en: ahora.toISOString(),
    });
    // El token va en el fragmento (#): no llega a registros de servidores ni a cabeceras Referer.
    await this.correo.enviarRestablecimiento(usuario.correo, usuario.nombre, `${this.urlWeb}/restablecer/#token=${token}`);
  }

  async restablecerClave(token: string, clave: string) {
    const ok = await this.restablecimientos.consumir(hashToken(token), this.reloj.ahora().toISOString(), await this.claves.cifrar(clave));
    if (!ok) throw new ErrorDominio("VALIDACION", "Enlace inválido o vencido");
  }

  /** El registro público siempre crea ciudadanos. Operadores y admin se crean por script. */
  async registrar(nombre: string, correo: string, clave: string) {
    const normalizado = correo.trim().toLowerCase();
    if (await this.usuarios.buscarPorCorreo(normalizado)) throw new ErrorDominio("CONFLICTO", "Correo ya registrado");
    const usuario: Usuario = { id: randomUUID(), nombre: nombre.trim(), correo: normalizado, rol: "ciudadano", creado_en: this.reloj.ahora().toISOString() };
    await this.usuarios.crear({ ...usuario, clave_hash: await this.claves.cifrar(clave) });
    return { token: await this.tokens.emitir(usuario), usuario };
  }

  listarUsuarios() {
    return this.usuarios.listar();
  }

  /** Solo el administrador llega aquí (lo exige la ruta). No puede cambiarse a sí mismo: evita quedarse sin administradores. */
  async cambiarRol(actorId: string, id: string, rol: Rol) {
    if (actorId === id) throw new ErrorDominio("CONFLICTO", "No puedes cambiar tu propio rol");
    const usuario = await this.usuarios.cambiarRol(id, rol);
    if (!usuario) throw new ErrorDominio("NO_ENCONTRADO", "Usuario no encontrado");
    return usuario;
  }

  async iniciarSesion(correo: string, clave: string) {
    const encontrado = await this.usuarios.buscarPorCorreo(correo.trim().toLowerCase());
    // Mismo mensaje si no existe o si la clave falla: no se revela qué correos están registrados.
    if (!encontrado || !(await this.claves.verificar(clave, encontrado.clave_hash))) {
      throw new ErrorDominio("NO_AUTENTICADO", "Credenciales inválidas");
    }
    const { clave_hash: _omitir, ...usuario } = encontrado;
    return { token: await this.tokens.emitir(usuario), usuario };
  }

  /**
   * Login via Firebase: el token ya fue verificado por TokensFirebase/TokensDual.
   * Si el usuario no existe en la base local lo crea como ciudadano (sin clave, usa Firebase como proveedor).
   */
  async iniciarSesionFirebase(sesion: Pick<Usuario, "id" | "nombre" | "rol"> & { correo?: string }) {
    const correo = (sesion.correo ?? `${sesion.id}@firebase.local`).toLowerCase();
    let encontrado = await this.usuarios.buscarPorCorreo(correo);
    if (!encontrado) {
      const nuevoUsuario: Usuario = {
        // El uid de Firebase no es un UUID: la base usa su propio identificador.
        id: randomUUID(),
        nombre: sesion.nombre.slice(0, 120),
        correo,
        rol: "ciudadano",
        creado_en: this.reloj.ahora().toISOString(),
      };
      // clave_hash vacío: este usuario no puede iniciar sesión con correo+clave
      await this.usuarios.crear({ ...nuevoUsuario, clave_hash: "" });
      return { token: await this.tokens.emitir(nuevoUsuario), usuario: nuevoUsuario };
    }
    const { clave_hash: _omitir, ...usuario } = encontrado;
    return { token: await this.tokens.emitir(usuario), usuario };
  }
}
