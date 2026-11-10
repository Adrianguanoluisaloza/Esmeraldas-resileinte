import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/analisis.dart';
import '../../domain/repositories/analisis_repository.dart';

/// Panel "Análisis" del COE: indicadores, prioridad por sector, inventario y entregas.
/// Equivale a `/panel/estadisticas` y `/panel/asistencia` de la web.
class AnalisisPage extends StatefulWidget {
  const AnalisisPage({
    super.key,
    required this.repositorio,
    required this.tieneConexion,
  });

  final AnalisisRepository? repositorio;
  final bool tieneConexion;

  @override
  State<AnalisisPage> createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  bool _cargando = false;
  String? _error;
  ResumenCoe? _resumen;
  List<SectorPrioridad> _sectores = const <SectorPrioridad>[];
  List<NecesidadPendiente> _pendientes = const <NecesidadPendiente>[];
  List<ItemInventario> _inventario = const <ItemInventario>[];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant AnalisisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.tieneConexion && widget.tieneConexion) _cargar();
  }

  Future<void> _cargar() async {
    final AnalisisRepository? repo = widget.repositorio;
    if (repo == null) {
      setState(() => _error = 'El panel de análisis no está configurado.');
      return;
    }
    if (!widget.tieneConexion) {
      setState(
        () => _error = 'Sin conexión. Los indicadores se calculan en el servidor; vuelve a conectarte.',
      );
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final List<Object> r = await Future.wait<Object>(<Future<Object>>[
        repo.resumen(),
        repo.prioridadSectores(),
        repo.necesidadesPendientes(),
        repo.inventario(),
      ]);
      if (!mounted) return;
      setState(() {
        _resumen = r[0] as ResumenCoe;
        _sectores = r[1] as List<SectorPrioridad>;
        _pendientes = r[2] as List<NecesidadPendiente>;
        _inventario = r[3] as List<ItemInventario>;
      });
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los indicadores.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrarEntrega(NecesidadPendiente p) async {
    final AnalisisRepository? repo = widget.repositorio;
    if (repo == null) return;
    final (int, String)? datos = await showDialog<(int, String)>(
      context: context,
      builder: (BuildContext context) => _DialogoEntrega(pendiente: p),
    );
    if (datos == null || !mounted) return;
    try {
      await repo.registrarEntrega(
        reporteId: p.reporteId,
        necesidad: p.necesidad,
        cantidad: datos.$1,
        nota: datos.$2,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entrega registrada: ${datos.$1} de ${p.necesidad.etiqueta.toLowerCase()}.',
          ),
        ),
      );
      await _cargar();
    } on Failure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const Material(
            color: AppTheme.colorSuperficie,
            child: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.insights_outlined), text: 'Indicadores'),
                Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Asistencia'),
              ],
            ),
          ),
          if (_cargando) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              children: <Widget>[_vistaIndicadores(), _vistaAsistencia()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _envolver(List<Widget> hijos) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: <Widget>[
          if (_error != null)
            _AvisoError(mensaje: _error!, onReintentar: _cargar),
          ...hijos,
        ],
      ),
    );
  }

  Widget _vistaIndicadores() {
    final ResumenCoe? r = _resumen;
    if (r == null) {
      return _envolver(<Widget>[
        if (_error == null && !_cargando)
          const _Vacio(
            texto: 'Desliza hacia abajo para cargar los indicadores.',
          ),
      ]);
    }
    final List<(String, String)> kpis = <(String, String)>[
      ('${r.totalReportes}', 'Reportes'),
      ('${r.pendientes}', 'Pendientes'),
      ('${r.enProceso}', 'En proceso'),
      ('${r.atendidos}', 'Atendidos'),
      ('${r.criticos}', 'Críticos'),
      ('${r.viasBloqueadas}', 'Vías bloq.'),
      ('${r.personasAfectadas}', 'Personas'),
      ('${r.ninos}', 'Niños'),
      ('${r.adultosMayores}', 'Adultos may.'),
    ];
    return _envolver(<Widget>[
      _Tarjeta(
        titulo: 'Situación general',
        icono: Icons.analytics_outlined,
        insignia: true,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: kpis
              .map(((String, String) k) => _Kpi(valor: k.$1, etiqueta: k.$2))
              .toList(),
        ),
      ),
      const SizedBox(height: 10),
      _Tarjeta(
        titulo: 'Sectores que requieren atención prioritaria',
        icono: Icons.leaderboard_outlined,
        child: _sectores.isEmpty
            ? const _Vacio(texto: 'Sin incidentes agrupados por sector.')
            : Column(
                children: _sectores.take(8).toList().asMap().entries.map((
                  MapEntry<int, SectorPrioridad> e,
                ) {
                  final SectorPrioridad s = e.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.colorGravedad(
                        s.gravedadPromedio,
                      ).withValues(alpha: 0.15),
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colorGravedad(s.gravedadPromedio),
                        ),
                      ),
                    ),
                    title: Text(
                      s.sector,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${s.cantidad} eventos · ${s.abiertos} abiertos · '
                      '${s.personasAfectadas} personas · gravedad ${s.gravedadPromedio.etiqueta.toLowerCase()}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 8),
      const Text(
        'La prioridad se calcula con reglas a la vista: cantidad de eventos, casos abiertos, '
        'personas afectadas y gravedad. Es apoyo a la decisión del operador, no un pronóstico oficial.',
        style: TextStyle(fontSize: 11, color: AppTheme.colorTextoApagado),
      ),
    ]);
  }

  Widget _vistaAsistencia() {
    return _envolver(<Widget>[
      _Tarjeta(
        titulo: 'Inventario disponible',
        icono: Icons.warehouse_outlined,
        insignia: true,
        child: _inventario.isEmpty
            ? const _Vacio(texto: 'Sin datos de inventario.')
            : Row(
                children: _inventario
                    .map(
                      (ItemInventario i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _Kpi(
                            valor: '${i.cantidad}',
                            etiqueta: '${i.necesidad.etiqueta}\n${i.unidad}',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      const SizedBox(height: 10),
      _Tarjeta(
        titulo: 'Necesidades pendientes (${_pendientes.length})',
        icono: Icons.volunteer_activism_outlined,
        child: _pendientes.isEmpty
            ? const _Vacio(texto: 'No hay necesidades pendientes de entrega.')
            : Column(
                children: _pendientes.map((NecesidadPendiente p) {
                  final bool esRescate =
                      p.necesidad == NecesidadFamiliar.rescate;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _iconoNecesidad(p.necesidad),
                      color: AppTheme.colorGravedad(p.gravedad),
                    ),
                    title: Text(
                      '${p.necesidad.etiqueta} · ${p.sector ?? 'Sin sector'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${p.personas} personas · gravedad ${p.gravedad.etiqueta.toLowerCase()}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: esRescate
                        ? const Text(
                            'Despacho',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.colorTextoApagado,
                            ),
                          )
                        : TextButton(
                            onPressed: widget.tieneConexion
                                ? () => _registrarEntrega(p)
                                : null,
                            child: const Text('Entregar'),
                          ),
                  );
                }).toList(),
              ),
      ),
    ]);
  }

  static IconData _iconoNecesidad(NecesidadFamiliar n) => switch (n) {
    NecesidadFamiliar.agua => Icons.water_drop_outlined,
    NecesidadFamiliar.alimentos => Icons.restaurant_outlined,
    NecesidadFamiliar.medicinas => Icons.medical_services_outlined,
    NecesidadFamiliar.rescate => Icons.support_outlined,
  };
}

class _DialogoEntrega extends StatefulWidget {
  const _DialogoEntrega({required this.pendiente});

  final NecesidadPendiente pendiente;

  @override
  State<_DialogoEntrega> createState() => _DialogoEntregaState();
}

class _DialogoEntregaState extends State<_DialogoEntrega> {
  final TextEditingController _cantidad = TextEditingController(text: '1');
  final TextEditingController _nota = TextEditingController();
  String? _errorCantidad;

  @override
  void dispose() {
    _cantidad.dispose();
    _nota.dispose();
    super.dispose();
  }

  void _confirmar() {
    final int? n = int.tryParse(_cantidad.text.trim());
    if (n == null || n < 1 || n > 100000) {
      setState(() => _errorCantidad = 'Ingresa un número entre 1 y 100000');
      return;
    }
    Navigator.of(context).pop((n, _nota.text));
  }

  @override
  Widget build(BuildContext context) {
    final NecesidadPendiente p = widget.pendiente;
    return AlertDialog(
      title: Text('Entregar ${p.necesidad.etiqueta.toLowerCase()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${p.sector ?? 'Sin sector'} · ${p.personas} personas. '
            'Se descuenta del inventario.',
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cantidad,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              errorText: _errorCantidad,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nota,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Registrar')),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.icono,
    required this.child,
    this.insignia = false,
  });

  final String titulo;
  final IconData icono;
  final Widget child;
  final bool insignia;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icono, size: 16, color: AppTheme.colorPrimario),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (insignia) const InsigniaOrigenDato(esOficial: false),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.colorFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.colorBorde),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            valor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.colorTextoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, color: AppTheme.colorTextoApagado),
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.colorSemaforoAmbar.withValues(alpha: 0.08),
      child: ListTile(
        leading: const Icon(
          Icons.cloud_off_outlined,
          color: AppTheme.colorSemaforoAmbar,
        ),
        title: Text(mensaje, style: const TextStyle(fontSize: 12.5)),
        trailing: TextButton(
          onPressed: onReintentar,
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
