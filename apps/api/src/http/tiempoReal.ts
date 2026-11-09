import type { Hono } from "hono";
import type { UpgradeWebSocket, WSContext } from "hono/ws";
import { esPersonalCoe } from "../dominio/catalogos.js";
import type { EventoTiempoReal, ServicioTokens } from "../dominio/puertos.js";
import type { BusEventos } from "../infraestructura/sistema.js";
import type { Entorno, Sesion } from "./contexto.js";

/**
 * GET /ws?token=JWT  (el navegador no puede mandar cabeceras en un WebSocket).
 * El COE recibe todo; un ciudadano solo recibe alertas, cupos y los cambios de SUS reportes.
 * Mensajes: {"tipo": "reporte.creado" | "reporte.estado" | "punto.ocupacion" | "alerta.emitida" | "via.estado" | "asistencia.entrega", "datos": {...}}
 */
export function montarTiempoReal(app: Hono<Entorno>, upgradeWebSocket: UpgradeWebSocket, bus: BusEventos, tokens: ServicioTokens) {
  app.get(
    "/ws",
    upgradeWebSocket(async (c) => {
      const token = c.req.query("token") ?? "";
      const sesion = token ? await tokens.verificar(token) : null;
      let desuscribir: (() => void) | null = null;

      return {
        onOpen(_evento, ws: WSContext) {
          if (!sesion) {
            ws.close(4401, "Sesión requerida");
            return;
          }
          ws.send(JSON.stringify({ tipo: "conectado", datos: { rol: sesion.rol } }));
          desuscribir = bus.suscribir((e) => {
            if (puedeVer(sesion, e)) ws.send(JSON.stringify(e));
          });
        },
        onClose() {
          desuscribir?.();
        },
      };
    }),
  );
}

export function puedeVer(sesion: Sesion, e: EventoTiempoReal): boolean {
  if (esPersonalCoe(sesion.rol)) return true;
  // Información pública para la ciudadanía: alertas, cupos y estado de vías.
  if (e.tipo === "alerta.emitida" || e.tipo === "punto.ocupacion" || e.tipo === "via.estado") return true;
  // De los reportes, solo los propios. Las entregas (datos de familias) son solo para el COE.
  if (e.tipo === "reporte.creado" || e.tipo === "reporte.estado") return e.datos.usuario_id === sesion.id;
  return false;
}
