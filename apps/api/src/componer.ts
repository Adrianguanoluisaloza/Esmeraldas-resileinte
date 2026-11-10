import { initializeApp, cert, getApps } from "firebase-admin/app";
import { CasosAuth } from "./aplicacion/auth.js";
import { CasosOperacion } from "./aplicacion/operacion.js";
import { CasosReportes } from "./aplicacion/reportes.js";
import { CasosTerritorio } from "./aplicacion/territorio.js";
import type { Config } from "./config.js";
import type { RepositorioAlertas, RepositorioAsistencia, RepositorioReportes, RepositorioRestablecimientos, RepositorioTerritorio, RepositorioUsuarios, ServicioCorreo } from "./dominio/puertos.js";
import type { Dependencias } from "./http/contexto.js";
import { CorreoSinConfigurar, CorreoSmtp } from "./infraestructura/correo.js";
import { FotosEnDisco } from "./infraestructura/fotosDisco.js";
import { AlertasEnMemoria, AsistenciaEnMemoria, ReportesEnMemoria, RestablecimientosEnMemoria, TerritorioEnMemoria, UsuariosEnMemoria } from "./infraestructura/memoria/repositorios.js";
import { AlertasPg, AsistenciaPg, ReportesPg, RestablecimientosPg, TerritorioPg, UsuariosPg, crearPool } from "./infraestructura/postgres/repositorios.js";
import { ClavesScrypt } from "./infraestructura/seguridad/claves.js";
import { TokensDual } from "./infraestructura/seguridad/tokensDual.js";
import { TokensFirebase } from "./infraestructura/seguridad/tokensFirebase.js";
import { TokensJwt } from "./infraestructura/seguridad/tokens.js";
import { BusEventos, relojSistema } from "./infraestructura/sistema.js";

export const CARPETA_FOTOS = process.env.CARPETA_FOTOS ?? "almacen/fotos";

/**
 * Raíz de composición: el ÚNICO lugar que sabe qué implementación concreta se usa.
 * Cambiar de PostgreSQL a otra cosa, o de JWT propio a Keycloak, se hace aquí y en ningún otro archivo.
 */
export function componer(config: Config) {
  const bus = new BusEventos();
  const claves = new ClavesScrypt();
  const tokensJwt = new TokensJwt(config.JWT_SECRET, config.JWT_MINUTOS);

  // Firebase Admin: solo si se configura FIREBASE_PROJECT_ID (opcional en desarrollo sin base)
  let tokens: TokensJwt | TokensDual = tokensJwt;
  if (config.FIREBASE_PROJECT_ID) {
    const firebaseApp = getApps().length === 0
      ? initializeApp({ projectId: config.FIREBASE_PROJECT_ID }, "esmeraldas")
      : getApps()[0]!;
    tokens = new TokensDual(tokensJwt, new TokensFirebase(firebaseApp));
  }

  const correo: ServicioCorreo = config.SMTP_HOST && config.SMTP_USUARIO && config.SMTP_CLAVE && config.CORREO_REMITENTE
    ? new CorreoSmtp(config.SMTP_HOST, config.SMTP_PUERTO, config.SMTP_USUARIO, config.SMTP_CLAVE, config.CORREO_REMITENTE)
    : new CorreoSinConfigurar(config.APP_ENV !== "production");

  let usuarios: RepositorioUsuarios;
  let restablecimientos: RepositorioRestablecimientos;
  let reportes: RepositorioReportes;
  let territorio: RepositorioTerritorio;
  let alertas: RepositorioAlertas;
  let asistencia: RepositorioAsistencia;
  let comprobarAlmacen: () => Promise<boolean>;
  let cerrar: () => Promise<void>;

  if (config.ALMACEN === "postgres") {
    const pool = crearPool(config.DATABASE_URL!);
    usuarios = new UsuariosPg(pool);
    restablecimientos = new RestablecimientosPg(pool);
    reportes = new ReportesPg(pool);
    territorio = new TerritorioPg(pool);
    alertas = new AlertasPg(pool);
    asistencia = new AsistenciaPg(pool);
    comprobarAlmacen = async () => (await pool.query("SELECT 1 AS ok")).rows[0]?.ok === 1;
    cerrar = () => pool.end();
  } else {
    const usuariosRam = new UsuariosEnMemoria();
    usuarios = usuariosRam;
    restablecimientos = new RestablecimientosEnMemoria(usuariosRam);
    reportes = new ReportesEnMemoria();
    territorio = new TerritorioEnMemoria();
    alertas = new AlertasEnMemoria();
    asistencia = new AsistenciaEnMemoria();
    comprobarAlmacen = async () => true;
    cerrar = async () => {};
  }

  const deps: Dependencias = {
    auth: new CasosAuth(usuarios, claves, tokens, relojSistema, restablecimientos, correo, config.URL_WEB),
    reportes: new CasosReportes(reportes, territorio, bus, relojSistema),
    territorio: new CasosTerritorio(territorio, bus),
    operacion: new CasosOperacion(reportes, territorio, alertas, asistencia, bus, relojSistema),
    repoReportes: reportes,
    fotos: new FotosEnDisco(CARPETA_FOTOS, "/fotos"),
    tokens,
    corsOrigenes: config.corsOrigenes,
    confiarEnProxy: config.CONFIAR_EN_PROXY,
    permitirLocalhost: config.APP_ENV !== "production",
    limiteEscriturasMinuto: config.LIMITE_ESCRITURAS_MINUTO,
    comprobarAlmacen,
  };

  return { deps, bus, usuarios, claves, cerrar };
}
