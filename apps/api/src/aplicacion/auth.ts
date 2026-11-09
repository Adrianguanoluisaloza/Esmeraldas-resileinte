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
}
