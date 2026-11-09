import { randomUUID } from "node:crypto";
import { ErrorDominio } from "../dominio/errores.js";
import type { Reloj, RepositorioUsuarios, ServicioClaves, ServicioTokens, Usuario } from "../dominio/puertos.js";

export class CasosAuth {
  constructor(
    private readonly usuarios: RepositorioUsuarios,
    private readonly claves: ServicioClaves,
    private readonly tokens: ServicioTokens,
    private readonly reloj: Reloj,
  ) {}

  /** El registro público siempre crea ciudadanos. Operadores y admin se crean por script. */
  async registrar(nombre: string, correo: string, clave: string) {
    const normalizado = correo.trim().toLowerCase();
    if (await this.usuarios.buscarPorCorreo(normalizado)) throw new ErrorDominio("CONFLICTO", "Correo ya registrado");
    const usuario: Usuario = { id: randomUUID(), nombre: nombre.trim(), correo: normalizado, rol: "ciudadano", creado_en: this.reloj.ahora().toISOString() };
    await this.usuarios.crear({ ...usuario, clave_hash: await this.claves.cifrar(clave) });
    return { token: await this.tokens.emitir(usuario), usuario };
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
        id: sesion.id,
        nombre: sesion.nombre,
        correo,
        rol: sesion.rol ?? "ciudadano",
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
