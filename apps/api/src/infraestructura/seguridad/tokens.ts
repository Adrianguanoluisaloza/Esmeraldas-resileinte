import { sign, verify } from "hono/jwt";
import { ROLES, type Rol } from "../../dominio/catalogos.js";
import type { ServicioTokens, Usuario } from "../../dominio/puertos.js";

/** JWT HS256 firmado con JWT_SECRET. Para Keycloak bastaría otra implementación de este puerto. */
export class TokensJwt implements ServicioTokens {
  constructor(
    private readonly secreto: string,
    private readonly minutos: number,
  ) {}

  emitir(u: Usuario): Promise<string> {
    const ahora = Math.floor(Date.now() / 1000);
    return sign({ sub: u.id, rol: u.rol, nombre: u.nombre, iat: ahora, exp: ahora + this.minutos * 60 }, this.secreto, "HS256");
  }

  async verificar(token: string) {
    try {
      const p = await verify(token, this.secreto, "HS256");
      if (typeof p.sub !== "string" || !ROLES.includes(p.rol as Rol)) return null;
      return { id: p.sub, rol: p.rol as Rol, nombre: String(p.nombre ?? "") };
    } catch {
      return null;
    }
  }
}
