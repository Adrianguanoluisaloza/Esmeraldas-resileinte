/**
 * Error de negocio con código estable. La capa HTTP lo traduce a estado y JSON;
 * la web y la app deciden el texto que ve la persona a partir del código.
 */
export type CodigoError =
  | "VALIDACION"
  | "NO_AUTENTICADO"
  | "SIN_PERMISO"
  | "NO_ENCONTRADO"
  | "CONFLICTO"
  | "TRANSICION_INVALIDA"
  | "NO_IMPLEMENTADO"
  | "NO_DISPONIBLE";

export class ErrorDominio extends Error {
  readonly codigo: CodigoError;
  readonly detalles: string[];
  constructor(codigo: CodigoError, mensaje: string, detalles: string[] = []) {
    super(mensaje);
    this.name = "ErrorDominio";
    this.codigo = codigo;
    this.detalles = detalles;
  }
}
