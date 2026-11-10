import type { App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { ROLES, type Rol } from "../../dominio/catalogos.js";
import type { ServicioTokens, Usuario } from "../../dominio/puertos.js";

/**
 * Verifica tokens de Firebase (Google Sign-In u otros proveedores de Firebase Auth).
 * Solo verifica — no emite: los tokens los emite Firebase en el cliente.
 * El backend sigue emitiendo su propio JWT para las llamadas REST posteriores al login.
 */
export class TokensFirebase implements ServicioTokens {
  constructor(private readonly app: App) {}

  /** Firebase no emite tokens propios; el JWT propio ya fue emitido por TokensJwt. */
  emitir(_usuario: Usuario): Promise<string> {
    throw new Error("TokensFirebase no emite tokens; usa TokensJwt para eso.");
  }

  async verificar(token: string): Promise<(Pick<Usuario, "id" | "rol" | "nombre"> & { correo?: string }) | null> {
    try {
      // Sin comprobar revocación: eso exige credenciales de administrador que el servidor no tiene.
      // La firma, el proyecto y la expiración se validan igual con las claves públicas de Google.
      const decoded = await getAuth(this.app).verifyIdToken(token);
      // El rol viene en un custom claim que el backend puede haber seteado,
      // o cae a "ciudadano" por defecto para usuarios nuevos de Firebase.
      const rol: Rol = ROLES.includes(decoded["rol"] as Rol) ? (decoded["rol"] as Rol) : "ciudadano";
      return {
        id: decoded.uid,
        rol,
        nombre: decoded.name ?? decoded.email ?? decoded.uid,
        // Solo un correo verificado puede enlazarse con una cuenta existente.
        ...(decoded.email && decoded.email_verified ? { correo: decoded.email } : {}),
      };
    } catch {
      return null;
    }
  }
}
