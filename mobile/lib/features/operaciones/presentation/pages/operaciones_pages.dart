import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/security/permisos.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mapa_fondo_esmeraldas.dart';
import '../../../../core/widgets/rejilla_adaptable.dart';
import '../../../albergues/data/models/punto_servicio_model.dart';
import '../../../albergues/presentation/widgets/tarjeta_albergue.dart';
import '../../data/repositories/operaciones_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

void _mostrarError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppTheme.colorSemaforoRojo,
      content: Text(e.toString()),
    ),
  );
}

// ============================================================================
// 1. Situación (Mapa de Esmeraldas de fondo + KPIs flotantes + necesidades)
// ============================================================================
class SituacionOperadorPage extends StatelessWidget {
  const SituacionOperadorPage({
    super.key,
    required this.repo,
    required this.sesion,
    required this.tieneConexion,
    required this.onSeleccionarReporte,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;
  final bool tieneConexion;
  final ValueChanged<ReporteOperacion> onSeleccionarReporte;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        final List<ReporteOperacion> R = repo.reportesVisibles(sesion);
        final Map<NecesidadFamiliar, int> nec = <NecesidadFamiliar, int>{};
        for (final ReporteOperacion r in R.where(
          (x) => x.estado != EstadoReporte.atendido,
        )) {
          for (final NecesidadFamiliar n in r.necesidades) {
            nec[n] = (nec[n] ?? 0) + 1;
          }
        }
        final List<(String, String)> kpis = <(String, String)>[
          ('${R.length}', 'Incidentes'),
          (
            '${R.where((r) => r.estado == EstadoReporte.pendiente).length}',
            'Pendientes',
          ),
          (
            '${R.where((r) => r.gravedad == GravedadIncidente.critica).length}',
            'Críticos',
          ),
          ('${R.fold<int>(0, (a, r) => a + r.personas)}', 'Personas'),
          (
            '${R.where((r) => r.tipo == TipoIncidente.viaBloqueada).length}',
            'Vías bloq.',
          ),
          (
            '${repo.puntos.where((p) => p.ratioOcupacion < 1.0).length}',
            'Con cupo',
          ),
        ];

        final Widget mapa = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.colorBorde),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MapaFondoEsmeraldas(
              tieneConexion: tieneConexion,
              ubicacionUsuario: const LatLng(
                AppConfig.esmeraldasCenterLat,
                AppConfig.esmeraldasCenterLng,
              ),
              puntosServicio: repo.puntos,
              incidentes: R
                  .map(
                    (ReporteOperacion r) => PinMapaIncidente(
                      punto: r.punto,
                      gravedad: r.gravedad,
                      etiqueta: r.sector,
                      onTap: () => onSeleccionarReporte(r),
                    ),
                  )
                  .toList(),
            ),
          ),
        );

        // Contadores arriba, mapa grande en el centro y necesidades abajo.
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: <Widget>[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Situación en Esmeraldas',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InsigniaOrigenDato(esOficial: false),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 6,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.95,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: kpis
                            .map(
                              ((String, String) k) => Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.colorFondo,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.colorBorde,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        k.$1,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        k.$2,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: AppTheme.colorTextoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: mapa),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: AppTheme.colorPrimario,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Necesidades pendientes de movilizar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nec.isEmpty
                            ? 'Sin necesidades pendientes'
                            : nec.entries
                                  .map((e) => '${e.key.etiqueta}: ${e.value}')
                                  .join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. Incidentes + hoja de Gestión (estado, gravedad, nota, verificar, IA)
// ============================================================================
class IncidentesOperadorPage extends StatefulWidget {
  const IncidentesOperadorPage({
    super.key,
    required this.repo,
    required this.sesion,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;

  @override
  State<IncidentesOperadorPage> createState() => _IncidentesOperadorPageState();
}

class _IncidentesOperadorPageState extends State<IncidentesOperadorPage> {
  EstadoReporte? _fEstado;
  TipoIncidente? _fTipo;
  GravedadIncidente? _fGrav;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (BuildContext context, _) {
        final List<ReporteOperacion> lista = widget.repo
            .reportesVisibles(widget.sesion)
            .where(
              (r) =>
                  (_fEstado == null || r.estado == _fEstado) &&
                  (_fTipo == null || r.tipo == _fTipo) &&
                  (_fGrav == null || r.gravedad == _fGrav),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<EstadoReporte?>(
                    initialValue: _fEstado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: <DropdownMenuItem<EstadoReporte?>>[
                      const DropdownMenuItem<EstadoReporte?>(
                        value: null,
                        child: Text('Estado', style: TextStyle(fontSize: 12)),
                      ),
                      ...EstadoReporte.values.map(
                        (e) => DropdownMenuItem<EstadoReporte?>(
                          value: e,
                          child: Text(
                            e.etiqueta,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _fEstado = v),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<TipoIncidente?>(
                    initialValue: _fTipo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: <DropdownMenuItem<TipoIncidente?>>[
                      const DropdownMenuItem<TipoIncidente?>(
                        value: null,
                        child: Text('Tipo', style: TextStyle(fontSize: 12)),
                      ),
                      ...TipoIncidente.values.map(
                        (t) => DropdownMenuItem<TipoIncidente?>(
                          value: t,
                          child: Text(
                            t.etiqueta,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _fTipo = v),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<GravedadIncidente?>(
                    initialValue: _fGrav,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: <DropdownMenuItem<GravedadIncidente?>>[
                      const DropdownMenuItem<GravedadIncidente?>(
                        value: null,
                        child: Text('Gravedad', style: TextStyle(fontSize: 12)),
                      ),
                      ...GravedadIncidente.values.map(
                        (g) => DropdownMenuItem<GravedadIncidente?>(
                          value: g,
                          child: Text(
                            g.etiqueta,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _fGrav = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay incidentes con esos filtros.',
                    style: TextStyle(color: AppTheme.colorTextoApagado),
                  ),
                ),
              ),
            RejillaAdaptable(
              children: lista
                  .map(
                    (ReporteOperacion r) => _TarjetaIncidente(
                      reporte: r,
                      onTap: () => mostrarHojaGestionReporte(
                        context,
                        repo: widget.repo,
                        sesion: widget.sesion,
                        reporte: r,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Tarjeta de incidente: el texto nunca queda apretado entre dos insignias.
class _TarjetaIncidente extends StatelessWidget {
  const _TarjetaIncidente({required this.reporte, required this.onTap});

  final ReporteOperacion reporte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReporteOperacion r = reporte;
    final (Color bg, Color fg) = AppTheme.colorEstado(r.estado);
    final Color cGrav = AppTheme.colorGravedad(r.gravedad);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: cGrav, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${r.tipo.etiqueta} · ${r.sector}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorTextoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _Insignia(
                    texto: r.gravedad.etiqueta,
                    fondo: cGrav.withValues(alpha: 0.14),
                    color: cGrav,
                  ),
                  _Insignia(texto: r.estado.etiqueta, fondo: bg, color: fg),
                  Text(
                    '${r.personas} personas · ${r.verificado ? "Verificado por 911" : "Sin verificar"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.colorTextoApagado,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia({
    required this.texto,
    required this.fondo,
    required this.color,
  });

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

void mostrarHojaGestionReporte(
  BuildContext context, {
  required OperacionesRepository repo,
  required UsuarioSesion sesion,
  required ReporteOperacion reporte,
}) {
  EstadoReporte estado = reporte.estado;
  GravedadIncidente gravedad = reporte.gravedad;
  final TextEditingController notaCtrl = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.colorFondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: reporte.tieneFoto
                          ? AppTheme.colorPrimario.withValues(alpha: 0.12)
                          : AppTheme.colorCampo,
                      border: Border.all(color: AppTheme.colorBorde),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          reporte.tieneFoto
                              ? Icons.photo_camera_outlined
                              : Icons.hourglass_top,
                          color: AppTheme.colorTextoSecundario,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reporte.tieneFoto
                              ? 'Evidencia fotográfica (${reporte.tipo.etiqueta})'
                              : 'Foto en camino (fase 2 de sincronización)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${reporte.tipo.etiqueta} — ${reporte.sector}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(reporte.descripcion),
                  const SizedBox(height: 4),
                  Text(
                    'Personas: ${reporte.personas} · Niños: ${reporte.ninos} · '
                    'Adultos mayores: ${reporte.mayores} · '
                    'Necesidades: ${reporte.necesidades.map((n) => n.etiqueta).join(", ")}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.colorTextoSecundario,
                    ),
                  ),
                  if (reporte.iaExplicacion != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.colorOrigenSimulado.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.colorOrigenSimulado),
                      ),
                      child: Text(
                        'Sugerencia IA — no oficial (confianza ${reporte.iaConfianza})\n'
                        '"${reporte.iaExplicacion}"\n'
                        'Apoyo a la decisión del operador.',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<EstadoReporte>(
                          initialValue: estado,
                          items: EstadoReporte.values
                              .map(
                                (e) => DropdownMenuItem<EstadoReporte>(
                                  value: e,
                                  child: Text(e.etiqueta),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setModal(() => estado = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<GravedadIncidente>(
                          initialValue: gravedad,
                          items: GravedadIncidente.values
                              .map(
                                (g) => DropdownMenuItem<GravedadIncidente>(
                                  value: g,
                                  child: Text(g.etiqueta),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setModal(() => gravedad = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nota de despacho (obligatoria)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            try {
                              repo.cambiarEstado(
                                sesion,
                                reporte,
                                estado: estado,
                                gravedad: gravedad,
                                nota: notaCtrl.text,
                              );
                              Navigator.of(ctx).pop();
                            } catch (e) {
                              _mostrarError(context, e);
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            try {
                              repo.verificar(sesion, reporte);
                              setModal(() {});
                            } catch (e) {
                              _mostrarError(context, e);
                            }
                          },
                          icon: Icon(
                            reporte.verificado
                                ? Icons.verified
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            reporte.verificado ? 'Verificado' : 'Verificar',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reporte.historial.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    const Text(
                      'Historial de estados',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    ...reporte.historial.map(
                      (h) => Text(h, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// 3. Albergues y Alertas por sector
// ============================================================================
class PuntosAlertasOperadorPage extends StatefulWidget {
  const PuntosAlertasOperadorPage({
    super.key,
    required this.repo,
    required this.sesion,
    this.seccionVias,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;

  /// Estado de vías (como "Alertas y vías" de la web). Lo arma el router.
  final Widget? seccionVias;

  @override
  State<PuntosAlertasOperadorPage> createState() =>
      _PuntosAlertasOperadorPageState();
}

class _PuntosAlertasOperadorPageState extends State<PuntosAlertasOperadorPage> {
  final TextEditingController _sectorCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  GravedadIncidente _nivel = GravedadIncidente.alta;
  bool _oficial = false;

  final TextEditingController _pNombreCtrl = TextEditingController();
  final TextEditingController _pCapCtrl = TextEditingController(text: '100');
  TipoPuntoServicio _pTipo = TipoPuntoServicio.albergue;

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _msgCtrl.dispose();
    _pNombreCtrl.dispose();
    _pCapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool editaCupo = widget.sesion.rol.puede(Permiso.puntosEditar);
    final bool creaPunto = widget.sesion.rol.puede(Permiso.puntosTodo);
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (BuildContext context, _) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            const Text(
              'Albergues y centros de salud',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RejillaAdaptable(
              children: widget.repo.puntos
                  .map(
                    (PuntoServicioModel p) => TarjetaAlbergue(
                      punto: p,
                      acciones: editaCupo
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                const Text(
                                  'Ocupación',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                IconButton(
                                  tooltip: 'Restar 10',
                                  onPressed: () => widget.repo.ajustarOcupacion(
                                    widget.sesion,
                                    p,
                                    -10,
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Sumar 10',
                                  onPressed: () => widget.repo.ajustarOcupacion(
                                    widget.sesion,
                                    p,
                                    10,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            )
                          : null,
                    ),
                  )
                  .toList(),
            ),
            if (creaPunto) ...<Widget>[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Nuevo punto de servicio (solo admin)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pNombreCtrl,
                        decoration: const InputDecoration(hintText: 'Nombre'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<TipoPuntoServicio>(
                              initialValue: _pTipo,
                              items: TipoPuntoServicio.values
                                  .map(
                                    (t) => DropdownMenuItem<TipoPuntoServicio>(
                                      value: t,
                                      child: Text(t.etiqueta),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _pTipo = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _pCapCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Capacidad',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          try {
                            widget.repo.crearPunto(
                              widget.sesion,
                              _pNombreCtrl.text,
                              _pTipo,
                              int.tryParse(_pCapCtrl.text) ?? 0,
                            );
                            _pNombreCtrl.clear();
                          } catch (e) {
                            _mostrarError(context, e);
                          }
                        },
                        child: const Text('Crear punto'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.seccionVias != null) ...<Widget>[
              const SizedBox(height: 16),
              widget.seccionVias!,
            ],
            const SizedBox(height: 16),
            const Text(
              'Alertas por sector',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (widget.sesion.rol.puede(Permiso.alertasCrear))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextField(
                        controller: _sectorCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Sector (ej. Las Palmas)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<GravedadIncidente>(
                              initialValue: _nivel,
                              items: GravedadIncidente.values
                                  .map(
                                    (g) => DropdownMenuItem<GravedadIncidente>(
                                      value: g,
                                      child: Text(g.etiqueta),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _nivel = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              _oficial ? 'Alerta oficial' : 'Dato simulado',
                            ),
                            selected: _oficial,
                            onSelected: (v) => setState(() => _oficial = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Mensaje para la población',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.colorSemaforoRojo,
                        ),
                        onPressed: () {
                          try {
                            widget.repo.emitirAlerta(
                              widget.sesion,
                              sector: _sectorCtrl.text,
                              nivel: _nivel,
                              mensaje: _msgCtrl.text,
                              oficial: _oficial,
                            );
                            _sectorCtrl.clear();
                            _msgCtrl.clear();
                          } catch (e) {
                            _mostrarError(context, e);
                          }
                        },
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('Emitir alerta'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ...widget.repo.alertas.map((AlertaSector a) {
              final bool esSimulacro = !a.oficial;
              String mensaje = a.mensaje.trim();
              if (esSimulacro &&
                  mensaje.toLowerCase().startsWith('simulacro:')) {
                mensaje = mensaje.substring('simulacro:'.length).trim();
              }
              final Color colorAlerta = esSimulacro
                  ? AppTheme.colorOrigenSimulado
                  : AppTheme.colorSemaforoRojo;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esSimulacro
                        ? const Color(0xFFF7F5FE)
                        : const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: esSimulacro
                          ? const Color(0xFFE9E4F8)
                          : const Color(0xFFF9D5D5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: colorAlerta,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${a.sector} · ${a.nivel.etiqueta}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: colorAlerta,
                              ),
                            ),
                          ),
                          Text(
                            esSimulacro ? 'Simulacro' : 'Alerta oficial',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorAlerta,
                            ),
                          ),
                        ],
                      ),
                      if (mensaje.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          mensaje,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'por ${a.creadaPor}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.colorTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
