import { CasosAuth } from "./aplicacion/auth.js";
import { CasosOperacion } from "./aplicacion/operacion.js";
import { CasosReportes } from "./aplicacion/reportes.js";
import { CasosTerritorio } from "./aplicacion/territorio.js";
import type { Config } from "./config.js";
import type { RepositorioAlertas, RepositorioAsistencia, RepositorioReportes, RepositorioTerritorio, RepositorioUsuarios } from "./dominio/puertos.js";
import type { Dependencias } from "./http/contexto.js";
import { FotosEnDisco } from "./infraestructura/fotosDisco.js";
import { AlertasEnMemoria, AsistenciaEnMemoria, ReportesEnMemoria, TerritorioEnMemoria, UsuariosEnMemoria } from "./infraestructura/memoria/repositorios.js";
import { AlertasPg, AsistenciaPg, ReportesPg, TerritorioPg, UsuariosPg, crearPool } from "./infraestructura/postgres/repositorios.js";
import { ClavesScrypt } from "./infraestructura/seguridad/claves.js";
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
  const tokens = new TokensJwt(config.JWT_SECRET, config.JWT_MINUTOS);

  let usuarios: RepositorioUsuarios;
  let reportes: RepositorioReportes;
  let territorio: RepositorioTerritorio;
  let alertas: RepositorioAlertas;
  let asistencia: RepositorioAsistencia;
  let comprobarAlmacen: () => Promise<boolean>;
  let cerrar: () => Promise<void>;

  if (config.ALMACEN === "postgres") {
    const pool = crearPool(config.DATABASE_URL!);
    usuarios = new UsuariosPg(pool);
    reportes = new ReportesPg(pool);
    territorio = new TerritorioPg(pool);
    alertas = new AlertasPg(pool);
    asistencia = new AsistenciaPg(pool);
    comprobarAlmacen = async () => (await pool.query("SELECT 1 AS ok")).rows[0]?.ok === 1;
    cerrar = () => pool.end();
  } else {
    usuarios = new UsuariosEnMemoria();
    reportes = new ReportesEnMemoria();
    territorio = new TerritorioEnMemoria();
    alertas = new AlertasEnMemoria();
    asistencia = new AsistenciaEnMemoria();
    comprobarAlmacen = async () => true;
    cerrar = async () => {};
  }

  const deps: Dependencias = {
    auth: new CasosAuth(usuarios, claves, tokens, relojSistema),
    reportes: new CasosReportes(reportes, territorio, bus, relojSistema),
    territorio: new CasosTerritorio(territorio, bus),
    operacion: new CasosOperacion(reportes, territorio, alertas, asistencia, bus, relojSistema),
    repoReportes: reportes,
    fotos: new FotosEnDisco(CARPETA_FOTOS, "/fotos"),
    tokens,
    corsOrigenes: config.corsOrigenes,
    confiarEnProxy: config.CONFIAR_EN_PROXY,
    limiteEscriturasMinuto: config.LIMITE_ESCRITURAS_MINUTO,
    comprobarAlmacen,
  };

  return { deps, bus, usuarios, claves, cerrar };
}
