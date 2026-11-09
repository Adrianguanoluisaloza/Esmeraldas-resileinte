import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/reporte_cola_model.dart';
import '../../../../data/repositories/cola_reportes_repository.dart';

/// Servicio de sincronización en dos pasos con espera creciente (backoff) y control de concurrencia por UUID.
class SyncWorkerService {
  SyncWorkerService({required this.colaRepository, required this.apiClient});

  final ColaReportesRepository colaRepository;
  final ApiClient apiClient;

  /// Conjunto de UUIDs actualmente en proceso para evitar envíos duplicados en paralelo.
  final Set<String> _uuidsEnVuelo = <String>{};
  bool _sincronizando = false;

  bool get estaSincronizando => _sincronizando;

  /// Ejecuta un ciclo de sincronización de los reportes pendientes en la cola.
  /// Antes de enviar, comprueba que exista salida real al servidor (`GET /salud`).
  Future<int> sincronizarPendientes() async {
    if (_sincronizando) return 0;
    _sincronizando = true;
    int sincronizadosExitosos = 0;

    try {
      final List<ReporteColaModel> pendientes = await colaRepository
          .obtenerReportesPendientesDeEnvio();
      if (pendientes.isEmpty) return 0;

      final bool servidorDisponible = await apiClient.verificarSaludServidor();
      if (!servidorDisponible) {
        return 0;
      }

      for (final ReporteColaModel reporte in pendientes) {
        if (_uuidsEnVuelo.contains(reporte.id)) continue;
        _uuidsEnVuelo.add(reporte.id);

        try {
          final bool completado = await _procesarReportePorPasos(reporte);
          if (completado) {
            sincronizadosExitosos++;
          }
        } finally {
          _uuidsEnVuelo.remove(reporte.id);
        }
      }
      return sincronizadosExitosos;
    } finally {
      _sincronizando = false;
    }
  }

  Future<bool> _procesarReportePorPasos(ReporteColaModel reporte) async {
    EstadoColaReporte estadoActual = reporte.estadoCola;

    try {
      // Paso 1: Datos livianos (idempotente por UUID)
      if (estadoActual == EstadoColaReporte.pendiente ||
          estadoActual == EstadoColaReporte.enviandoDatos) {
        await colaRepository.actualizarEstadoReporte(
          id: reporte.id,
          nuevoEstado: EstadoColaReporte.enviandoDatos,
        );

        await apiClient.enviarDatosReporte(reporte.toApiPayload());

        estadoActual = EstadoColaReporte.datosEnviados;
        await colaRepository.actualizarEstadoReporte(
          id: reporte.id,
          nuevoEstado: EstadoColaReporte.datosEnviados,
        );
      }

      // Paso 2: Subida de foto comprimida (si existe archivo local)
      if (estadoActual == EstadoColaReporte.datosEnviados ||
          estadoActual == EstadoColaReporte.enviandoFoto) {
        if (reporte.rutaFotoLocal.isNotEmpty) {
          await colaRepository.actualizarEstadoReporte(
            id: reporte.id,
            nuevoEstado: EstadoColaReporte.enviandoFoto,
          );

          await apiClient.subirFotoReporte(
            reporteId: reporte.id,
            rutaArchivoLocal: reporte.rutaFotoLocal,
          );

          // Al recibir confirmación, borrar foto local para liberar almacenamiento
          final File archivoLocal = File(reporte.rutaFotoLocal);
          if (await archivoLocal.exists()) {
            await archivoLocal.delete();
          }
        }

        await colaRepository.actualizarEstadoReporte(
          id: reporte.id,
          nuevoEstado: EstadoColaReporte.enviado,
          rutaFotoLocal: '',
        );
      }

      return true;
    } catch (error) {
      final int nuevosIntentos = reporte.intentos + 1;
      final Duration espera = _calcularEsperaBackoff(nuevosIntentos);
      final EstadoColaReporte estadoRecuperacion =
          (estadoActual == EstadoColaReporte.datosEnviados ||
              estadoActual == EstadoColaReporte.enviandoFoto)
          ? EstadoColaReporte.datosEnviados
          : EstadoColaReporte.pendiente;

      await colaRepository.actualizarEstadoReporte(
        id: reporte.id,
        nuevoEstado: estadoRecuperacion,
        intentos: nuevosIntentos,
        proximoIntentoUtc: DateTime.now().toUtc().add(espera),
        mensajeError: error.toString(),
      );
      return false;
    }
  }

  Duration _calcularEsperaBackoff(int intento) {
    final List<int> tabla = AppConfig.syncBackoffSeconds;
    final int indice = (intento - 1).clamp(0, tabla.length - 1);
    return Duration(seconds: tabla[indice]);
  }
}
