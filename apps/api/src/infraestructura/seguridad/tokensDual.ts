import type { ServicioTokens, Usuario } from "../../dominio/puertos.js";

/**
 * Acepta tokens del JWT propio (HS256) Y tokens de Firebase (RS256).
 * Los tokens Firebase empiezan siempre con un payload que tiene "firebase" en los claims;
 * los propios son más cortos y no tienen ese claim. En la práctica se intenta primero el
 * JWT propio y si falla se prueba Firebase.
 *
 * Así la app móvil y la web pueden mandar indistintamente cualquiera de los dos.
 */
export class TokensDual implements ServicioTokens {
  constructor(
    private readonly propio: ServicioTokens,
    private readonly firebase: ServicioTokens,
  ) {}

  emitir(usuario: Usuario): Promise<string> {
    return this.propio.emitir(usuario);
  }

  async verificar(token: string): Promise<Pick<Usuario, "id" | "rol" | "nombre"> | null> {
    // Intento 1: JWT propio (HS256, rápido, sin red)
    const sesionPropia = await this.propio.verificar(token);
    if (sesionPropia) return sesionPropia;

    // Intento 2: token de Firebase (RS256, verifica contra JWKS de Google)
    return this.firebase.verificar(token);
  }
}
