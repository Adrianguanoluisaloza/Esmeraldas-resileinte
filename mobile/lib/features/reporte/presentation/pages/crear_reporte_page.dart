import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/usecases/crear_reporte_offline_usecase.dart';
import '../widgets/bloque_familia_widget.dart';

/// Pantalla de creación rápida de reporte ciudadano (sin mapa para no bloquear en modo avión).
class CrearReportePage extends StatefulWidget {
  const CrearReportePage({
    super.key,
    required this.crearReporteUseCase,
    required this.locationService,
    required this.onReporteGuardado,
  });

  final CrearReporteOfflineUseCase crearReporteUseCase;
  final LocationService locationService;
  final VoidCallback onReporteGuardado;

  @override
  State<CrearReportePage> createState() => _CrearReportePageState();
}

class _CrearReportePageState extends State<CrearReportePage> {
  TipoIncidente _tipoSeleccionado = TipoIncidente.inundacion;
  GravedadIncidente _gravedadSeleccionada = GravedadIncidente.alta;
  final TextEditingController _descripcionController = TextEditingController();

  CoordenadaCapturada? _coordenada;
  bool _capturandoGps = false;
  String _rutaFotoSimulada = '';

  int _personasAfectadas = 0;
  int _ninos = 0;
  int _adultosMayores = 0;
  final Set<NecesidadFamiliar> _necesidades = <NecesidadFamiliar>{};

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _capturandoGps = true);
    try {
      final CoordenadaCapturada? coord = await widget.locationService
          .capturarUbicacionConRespaldo();
      if (mounted) {
        setState(() => _coordenada = coord);
      }
    } finally {
      if (mounted) {
        setState(() => _capturandoGps = false);
      }
    }
  }

  Future<void> _guardarReporteEnCola() async {
    final CoordenadaCapturada coordenadaFinal =
        _coordenada ??
        const CoordenadaCapturada(
          latitud: 0.9592,
          longitud: -79.6539,
          precisionMetros: 50.0,
          esAproximada: true,
        );

    await widget.crearReporteUseCase.ejecutar(
      DatosNuevoReporte(
        tipo: _tipoSeleccionado,
        descripcion: _descripcionController.text,
        gravedad: _gravedadSeleccionada,
        coordenada: coordenadaFinal,
        rutaFotoLocal: _rutaFotoSimulada,
        personasAfectadas: _personasAfectadas,
        ninos: _ninos,
        adultosMayores: _adultosMayores,
        necesidades: _necesidades.toList(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reporte guardado en cola local ✓ Se enviará al recuperar señal.',
        ),
      ),
    );
    _descripcionController.clear();
    setState(() {
      _personasAfectadas = 0;
      _ninos = 0;
      _adultosMayores = 0;
      _necesidades.clear();
      _rutaFotoSimulada = '';
    });
    widget.onReporteGuardado();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Tarjeta de estado GPS (nunca muestra un mapa que pueda quedar en blanco sin red)
        Card(
          child: ListTile(
            leading: Icon(
              _coordenada != null ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _coordenada != null
                  ? Colors.green.shade700
                  : Colors.orange,
            ),
            title: Text(
              _capturandoGps
                  ? 'Capturando señal de satélites GPS...'
                  : _coordenada != null
                  ? 'Ubicación capturada ✓ ${_coordenada!.esAproximada ? "(Aproximada)" : ""}'
                  : 'Ubicación pendiente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _coordenada != null
                ? Text(
                    'Lat: ${_coordenada!.latitud.toStringAsFixed(4)}, '
                    'Lng: ${_coordenada!.longitud.toStringAsFixed(4)} '
                    '(±${_coordenada!.precisionMetros.toStringAsFixed(0)} m)',
                  )
                : const Text('El GPS funciona incluso en modo avión.'),
            trailing: IconButton(
              onPressed: _capturandoGps ? null : _obtenerUbicacion,
              icon: const Icon(Icons.my_location),
              tooltip: 'Actualizar GPS',
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Captura de evidencia fotográfica
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _rutaFotoSimulada = 'app_docs/evidencia_comprimida_1280px.jpg';
            });
          },
          icon: Icon(
            _rutaFotoSimulada.isEmpty ? Icons.camera_alt : Icons.check_circle,
          ),
          label: Text(
            _rutaFotoSimulada.isEmpty
                ? '1. Tomar foto de la emergencia (comprimida ≤400 KB)'
                : 'Foto lista y comprimida en almacenamiento local ✓',
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '2. Tipo de incidente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TipoIncidente.values.map((TipoIncidente tipo) {
            return ChoiceChip(
              label: Text(tipo.etiqueta),
              selected: _tipoSeleccionado == tipo,
              onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          '3. Gravedad estimada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<GravedadIncidente>(
          segments: GravedadIncidente.values
              .map(
                (GravedadIncidente g) => ButtonSegment<GravedadIncidente>(
                  value: g,
                  label: Text(g.etiqueta),
                ),
              )
              .toList(),
          selected: <GravedadIncidente>{_gravedadSeleccionada},
          onSelectionChanged: (Set<GravedadIncidente> nueva) {
            setState(() => _gravedadSeleccionada = nueva.first);
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _descripcionController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Descripción breve (sector o referencia)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        BloqueFamiliaWidget(
          personasAfectadas: _personasAfectadas,
          ninos: _ninos,
          adultosMayores: _adultosMayores,
          necesidadesSeleccionadas: _necesidades,
          onPersonasChanged: (int v) => setState(() => _personasAfectadas = v),
          onNinosChanged: (int v) => setState(() => _ninos = v),
          onAdultosMayoresChanged: (int v) =>
              setState(() => _adultosMayores = v),
          onToggleNecesidad: (NecesidadFamiliar nec) {
            setState(() {
              if (_necesidades.contains(nec)) {
                _necesidades.remove(nec);
              } else {
                _necesidades.add(nec);
              }
            });
          },
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _guardarReporteEnCola,
          icon: const Icon(Icons.save_alt),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Guardar reporte (Funciona sin internet)',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
