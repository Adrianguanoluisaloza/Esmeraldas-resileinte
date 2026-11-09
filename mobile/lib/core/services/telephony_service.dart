import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../enums/app_enums.dart';

/// Servicio de telefonía y SMS de emergencia para envío de coordenadas GPS
/// cuando no existe cobertura de datos móviles en la provincia de Esmeraldas.
class TelephonyService {
  const TelephonyService();

  /// Construye el mensaje compacto con el punto GPS georreferenciado para SMS de emergencia.
  String construirMensajePuntoGps({
    required double latitud,
    required double longitud,
    required TipoIncidente tipo,
    required GravedadIncidente gravedad,
    double precisionMetros = 12,
    int personasAfectadas = 1,
    String descripcion = '',
  }) {
    final String lat = latitud.toStringAsFixed(5);
    final String lon = longitud.toStringAsFixed(5);
    final String descLimpia = descripcion.trim();
    final String nota = descLimpia.isEmpty
        ? ''
        : ' | Ref: ${descLimpia.length > 48 ? '${descLimpia.substring(0, 48)}...' : descLimpia}';
    return 'SOS ESMERALDAS | ${tipo.etiqueta.toUpperCase()} (${gravedad.etiqueta.toUpperCase()}) '
        '| GPS: $lat,$lon (±${precisionMetros.toStringAsFixed(0)}m) '
        '| Afectados: $personasAfectadas$nota '
        '| Mapa: https://maps.google.com/?q=$lat,$lon';
  }

  /// Envía el punto GPS de emergencia por SMS usando `another_telephony`.
  /// Primero solicita permisos `SEND_SMS` y envía directo por radio celular;
  /// si el usuario prefiere o el permiso directo es rechazado, abre la app SMS con el punto precargado.
  Future<bool> enviarPuntoEmergenciaPorSms({
    required double latitud,
    required double longitud,
    required TipoIncidente tipo,
    required GravedadIncidente gravedad,
    double precisionMetros = 12,
    int personasAfectadas = 1,
    String descripcion = '',
    String? numeroDestino,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;

    final String destino =
        (numeroDestino != null && numeroDestino.trim().isNotEmpty)
        ? numeroDestino.trim()
        : AppConfig.smsEmergenciaNumero;

    final String mensaje = construirMensajePuntoGps(
      latitud: latitud,
      longitud: longitud,
      tipo: tipo,
      gravedad: gravedad,
      precisionMetros: precisionMetros,
      personasAfectadas: personasAfectadas,
      descripcion: descripcion,
    );

    final Telephony telephony = Telephony.instance;
    try {
      final bool? concedido = await telephony.requestPhoneAndSmsPermissions;
      if (concedido == true) {
        await telephony.sendSms(
          to: destino,
          message: mensaje,
          isMultipart: mensaje.length > 155,
        );
        return true;
      }
    } catch (_) {
      // Si el operador restringe el envío silencioso a números cortos, abrimos la app SMS con los datos listos
    }

    try {
      await telephony.sendSmsByDefaultApp(to: destino, message: mensaje);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Abre el marcador telefónico con el número de emergencia (911 por defecto).
  Future<bool> abrirMarcadorEmergencia({String numero = '911'}) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      await Telephony.instance.openDialer(numero);
      return true;
    } catch (_) {
      return false;
    }
  }
}

