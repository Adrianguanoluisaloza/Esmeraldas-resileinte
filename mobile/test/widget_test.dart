import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/data/models/punto_servicio_model.dart';
import 'package:mobile/data/models/reporte_cola_model.dart';
import 'package:mobile/data/repositories/cola_reportes_repository.dart';
import 'package:mobile/main.dart';

/// Repositorio en memoria para probar las pantallas sin depender de disco ni red.
class InMemoryColaReportesRepository implements ColaReportesRepository {
  final List<ReporteColaModel> _cola = <ReporteColaModel>[];
  List<PuntoServicioModel> _directorio = <PuntoServicioModel>[
    const PuntoServicioModel(
      id: 'alb-01',
      nombre: 'Coliseo Nubia Villacís (Albergue Temporal)',
      tipo: TipoPuntoServicio.albergue,
      latitud: 0.9615,
      longitud: -79.6522,
      telefono: '911',
      capacidad: 250,
      ocupacion: 110,
    ),
  ];

  @override
  Future<void> inicializar() async {}

  @override
  Future<void> encolarReporte(ReporteColaModel reporte) async {
    _cola.add(reporte);
  }

  @override
  Future<List<ReporteColaModel>> obtenerTodosLosReportes() async =>
      List<ReporteColaModel>.from(_cola);

  @override
  Future<List<ReporteColaModel>> obtenerReportesPendientesDeEnvio() async =>
      _cola.where((r) => !r.estadoCola.estaSincronizado).toList();

  @override
  Future<void> actualizarEstadoReporte({
    required String id,
    required EstadoColaReporte nuevoEstado,
    int? intentos,
    DateTime? proximoIntentoUtc,
    String? mensajeError,
    String? rutaFotoLocal,
  }) async {
    final int idx = _cola.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _cola[idx] = _cola[idx].copyWith(
      estadoCola: nuevoEstado,
      intentos: intentos,
      proximoIntentoUtc: proximoIntentoUtc,
      mensajeError: mensajeError,
      rutaFotoLocal: rutaFotoLocal,
    );
  }

  @override
  Future<List<PuntoServicioModel>> obtenerDirectorioPuntosServicio() async =>
      _directorio;

  @override
  Future<void> guardarDirectorioPuntosServicio(
    List<PuntoServicioModel> puntos,
  ) async {
    _directorio = List<PuntoServicioModel>.from(puntos);
  }
}

void main() {
  testWidgets(
    'EsmeraldasResilienteApp renderiza la pantalla de reporte y permite encolar offline',
    (WidgetTester tester) async {
      final InMemoryColaReportesRepository repo =
          InMemoryColaReportesRepository();

      await tester.pumpWidget(EsmeraldasResilienteApp(colaRepository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Esmeraldas Resiliente'), findsOneWidget);
      expect(find.text('2. Tipo de incidente'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        find.text('Guardar reporte (Funciona sin internet)'),
        findsOneWidget,
      );
    },
  );
}
