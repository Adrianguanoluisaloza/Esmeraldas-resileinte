import { randomUUID } from "node:crypto";
import { esPersonalCoe, type Necesidad } from "../dominio/catalogos.js";
import { ErrorDominio } from "../dominio/errores.js";
import {
  estadisticas,
  necesidadesPendientes,
  prioridadSectores,
  type Alerta,
  type EstadoVia,
  type NivelAlerta,
  type OrigenAlerta,
} from "../dominio/operacion.js";
import type {
  PublicadorEventos,
  Reloj,
  RepositorioAlertas,
  RepositorioAsistencia,
  RepositorioReportes,
  RepositorioTerritorio,
  Usuario,
} from "../dominio/puertos.js";

type Actor = Pick<Usuario, "id" | "rol">;

/** Tope de reportes que entran al análisis en memoria. Suficiente para el escenario y una emergencia cantonal. */
const MAX_ANALISIS = 20_000;

/** Módulos 3, 4 y 5: alertas por sector, estado de vías, indicadores del COE y asistencia humanitaria. */
export class CasosOperacion {
  constructor(
    private readonly reportes: RepositorioReportes,
    private readonly territorio: RepositorioTerritorio,
    private readonly alertas: RepositorioAlertas,
    private readonly asistencia: RepositorioAsistencia,
    private readonly eventos: PublicadorEventos,
    private readonly reloj: Reloj,
  ) {}

  private exigirCoe(actor: Actor) {
    if (!esPersonalCoe(actor.rol)) throw new ErrorDominio("SIN_PERMISO", "Requiere rol operador_911 o admin");
  }

  private async todos() {
    return (await this.reportes.listar({ limite: MAX_ANALISIS, pagina: 1 })).items;
  }

  // Alertas -------------------------------------------------------------------------------------------
  listarAlertas(soloVigentes = true) {
    return this.alertas.listar(soloVigentes);
  }

  async emitirAlerta(actor: Actor, datos: { sector: string; mensaje: string; nivel: NivelAlerta; origen: OrigenAlerta }) {
    this.exigirCoe(actor);
    const alerta: Alerta = { id: randomUUID(), ...datos, creado_por: actor.id, creado_en: this.reloj.ahora().toISOString(), vigente: true };
    await this.alertas.crear(alerta);
    this.eventos.publicar({ tipo: "alerta.emitida", datos: alerta });
    return alerta;
  }

  async cerrarAlerta(actor: Actor, id: string) {
    this.exigirCoe(actor);
    const a = await this.alertas.cerrar(id);
    if (!a) throw new ErrorDominio("NO_ENCONTRADO", "Alerta no encontrada");
    this.eventos.publicar({ tipo: "alerta.emitida", datos: a });
    return a;
  }

  // Vías ------------------------------------------------------------------------------------------------
  async cambiarVia(actor: Actor, id: string, estado: EstadoVia) {
    this.exigirCoe(actor);
    const via = await this.territorio.actualizarVia(id, estado);
    if (!via) throw new ErrorDominio("NO_ENCONTRADO", "Vía no encontrada");
    this.eventos.publicar({ tipo: "via.estado", datos: via });
    return via;
  }

  // Indicadores -------------------------------------------------------------------------------------
  async estadisticas(actor: Actor) {
    this.exigirCoe(actor);
    const [reportes, puntos, vias] = await Promise.all([this.todos(), this.territorio.listarPuntos(undefined, true), this.territorio.viasGeoJson()]);
    const bloqueadas = vias.features.filter((f) => f.properties.estado === "bloqueada").length;
    return estadisticas(reportes, puntos, bloqueadas);
  }

  async prioridadSectores(actor: Actor) {
    this.exigirCoe(actor);
    return prioridadSectores(await this.todos());
  }

  // Asistencia humanitaria (módulo 5) ---------------------------------------------------------------
  async necesidadesPendientes(actor: Actor) {
    this.exigirCoe(actor);
    const [reportes, entregas] = await Promise.all([this.todos(), this.asistencia.listar()]);
    return necesidadesPendientes(reportes, entregas);
  }

  async listarEntregas(actor: Actor) {
    this.exigirCoe(actor);
    return this.asistencia.listar();
  }

  async registrarEntrega(actor: Actor, datos: { reporte_id: string; necesidad: Necesidad; cantidad: number; nota: string | null }) {
    this.exigirCoe(actor);
    const reporte = await this.reportes.buscar(datos.reporte_id);
    if (!reporte) throw new ErrorDominio("NO_ENCONTRADO", "Reporte no encontrado");
    if (!reporte.necesidades.includes(datos.necesidad)) {
      throw new ErrorDominio("VALIDACION", "Ese reporte no pidió esa necesidad");
    }
    const entrega = { id: randomUUID(), ...datos, entregado_por: actor.id, entregado_en: this.reloj.ahora().toISOString() };
    await this.asistencia.registrar(entrega);
    this.eventos.publicar({ tipo: "asistencia.entrega", datos: entrega });
    return entrega;
  }
}
