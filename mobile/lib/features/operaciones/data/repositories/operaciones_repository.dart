import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/permisos.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../albergues/data/models/punto_servicio_model.dart';
import '../../../reporte/data/models/reporte_cola_model.dart';

/// Reporte tal como lo ve el centro de operaciones (`GET /reportes`).
class ReporteOperacion {
  ReporteOperacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.gravedad,
    required this.estado,
    required this.sector,
    required this.punto,
    required this.descripcion,
    this.personas = 0,
    this.ninos = 0,
    this.mayores = 0,
    this.necesidades = const <NecesidadFamiliar>[],
    this.verificado = false,
    this.tieneFoto = true,
    this.iaExplicacion,
    this.iaConfianza,
  });

  final String id;
  final String usuarioId;
  final TipoIncidente tipo;
  GravedadIncidente gravedad;
  EstadoReporte estado;
  final String sector;
  final LatLng punto;
  final String descripcion;
  final int personas, ninos, mayores;
  final List<NecesidadFamiliar> necesidades;
  bool verificado;
  final bool tieneFoto;
  final String? iaExplicacion;
  final String? iaConfianza;
  final List<String> historial = <String>[];
}

class AlertaSector {
  const AlertaSector({
    required this.sector,
    required this.nivel,
    required this.mensaje,
    required this.creadaPor,
    required this.oficial,
    required this.hora,
  });
  final String sector;
  final GravedadIncidente nivel;
  final String mensaje;
  final String creadaPor;
  final bool oficial;
  final DateTime hora;
}

class UsuarioGestion {
  UsuarioGestion({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.activo = true,
  });
  final String id;
  final String nombre;
  final String correo;
  final RolUsuario rol;
  bool activo;
}

class EventoAuditoria {
  EventoAuditoria(
    this.usuario,
    this.evento,
    this.detalle, {
    this.critico = false,
  }) : hora = DateTime.now().toUtc();
  final String usuario, evento, detalle;
  final bool critico;
  final DateTime hora;
}

/// Repositorio del centro de operaciones (operador 911 y admin) conectado al backend real.
/// Cada método verifica el permiso del rol antes de actuar (el backend repite la validación).
class OperacionesRepository extends ChangeNotifier {
  OperacionesRepository({this.apiClient});

  ApiClient? apiClient;
  final List<ReporteOperacion> reportes = <ReporteOperacion>[];
  final List<PuntoServicioModel> puntos = <PuntoServicioModel>[];
  final List<AlertaSector> alertas = <AlertaSector>[];
  final List<UsuarioGestion> usuarios = <UsuarioGestion>[];
  final List<EventoAuditoria> auditoria = <EventoAuditoria>[];

  /// Descarga incidentes georreferenciados (`GET /reportes`), albergues (`GET /puntos-servicio`)
  /// y alertas (`GET /alertas`) desde el backend real y los fusiona con el estado local.
  Future<void> sincronizarDesdeBackend([ApiClient? clienteOverride]) async {
    final ApiClient? cliente = clienteOverride ?? apiClient;
    if (cliente == null) return;
    bool huboCambios = false;

    try {
      final List<PuntoServicioModel> puntosRemotos = await cliente
          .obtenerPuntosServicio();
      if (puntosRemotos.isNotEmpty) {
        puntos
          ..clear()
          ..addAll(puntosRemotos);
        huboCambios = true;
      }
    } catch (_) {
      // Mantiene los puntos sembrados localmente si no hay red
    }

    try {
      final List<Map<String, dynamic>> alertasRemotas = await cliente
          .obtenerAlertasActivas();
      if (alertasRemotas.isNotEmpty) {
        alertas
          ..clear()
          ..addAll(
            alertasRemotas.map((Map<String, dynamic> a) {
              final bool esOficial =
                  a['origen'] == 'oficial' && a['es_simulacro'] != true;
              return AlertaSector(
                sector: '${a['sector'] ?? a['titulo'] ?? 'Esmeraldas'}',
                nivel: GravedadIncidente.fromValor('${a['nivel'] ?? 'alta'}'),
                mensaje: '${a['mensaje'] ?? ''}',
                creadaPor: '${a['creado_por'] ?? 'COE Provincial'}',
                oficial: esOficial,
                hora:
                    DateTime.tryParse('${a['creado_en'] ?? ''}')?.toLocal() ??
                    DateTime.now(),
              );
            }),
          );
        huboCambios = true;
      }
    } catch (_) {
      // Mantiene las alertas locales si falla la consulta
    }

    try {
      final List<Map<String, dynamic>> remotos = await cliente
          .obtenerReportesRemotos();
      for (final Map<String, dynamic> m in remotos) {
        final String id = '${m['id'] ?? ''}';
        if (id.isEmpty) continue;
        final double lat = ((m['latitud'] ?? m['lat'] ?? 0.9592) as num)
            .toDouble();
        final double lng = ((m['longitud'] ?? m['lng'] ?? -79.6539) as num)
            .toDouble();
        final List<dynamic> necRaw = m['necesidades'] is List
            ? m['necesidades'] as List<dynamic>
            : const <dynamic>[];
        final ReporteOperacion mapeado = ReporteOperacion(
          id: id,
          usuarioId: '${m['usuario_id'] ?? 'u1'}',
          tipo: TipoIncidente.fromValor('${m['tipo'] ?? 'otro'}'),
          gravedad: GravedadIncidente.fromValor('${m['gravedad'] ?? 'media'}'),
          estado: EstadoReporte.fromValor('${m['estado'] ?? 'pendiente'}'),
          sector:
              '${m['sector'] ?? 'Esmeraldas (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})'}',
          punto: LatLng(lat, lng),
          descripcion: '${m['descripcion'] ?? ''}',
          personas: ((m['personas_afectadas'] ?? 0) as num).toInt(),
          ninos: ((m['ninos'] ?? 0) as num).toInt(),
          mayores: ((m['adultos_mayores'] ?? 0) as num).toInt(),
          necesidades: necRaw
              .map((dynamic item) => NecesidadFamiliar.fromValor('$item'))
              .toList(),
          verificado: m['verificado'] == true,
          tieneFoto: m['foto_url'] != null || m['foto_ruta'] != null,
          iaExplicacion: m['ia_explicacion'] as String?,
          iaConfianza: m['ia_confianza']?.toString(),
        );
        final int idx = reportes.indexWhere(
          (ReporteOperacion op) => op.id == id,
        );
        if (idx == -1) {
          reportes.insert(0, mapeado);
        } else {
          reportes[idx] = mapeado;
        }
        huboCambios = true;
      }
    } catch (_) {
      // Mantiene los reportes locales/escenario si no hay token de operador o sin red
    }

    if (huboCambios) {
      notifyListeners();
    }
  }

  void auditar(
    UsuarioSesion? s,
    String evento,
    String detalle, {
    bool critico = false,
  }) {
    auditoria.insert(
      0,
      EventoAuditoria(
        s?.correo ?? 'anónimo',
        evento,
        detalle,
        critico: critico,
      ),
    );
    notifyListeners();
  }

  /// Lanza [PermisoDenegado] y deja registro si el rol no tiene el permiso.
  void exigir(UsuarioSesion s, Permiso p) {
    if (s.expirada) throw const AuthException('Sesión expirada');
    if (!s.rol.puede(p)) {
      auditar(s, '403 PROHIBIDO', p.name, critico: true);
      throw PermisoDenegado(p);
    }
  }

  List<ReporteOperacion> reportesVisibles(UsuarioSesion s) {
    if (s.rol.puede(Permiso.reporteVerTodos)) return reportes;
    final Set<TipoIncidente>? competencia = competenciaInstitucion[s.rol];
    if (competencia != null) {
      return reportes.where((r) => competencia.contains(r.tipo)).toList();
    }
    return reportes.where((r) => r.usuarioId == s.id).toList();
  }

  /// Une los reportes creados por el ciudadano en la cola local de Hive (`cola_reportes_box`)
  /// con el repositorio de operaciones para que aparezcan en los mapas de Ciudadano, Operador 911 y Admin.
  void sincronizarDesdeColaLocal(
    List<ReporteColaModel> cola, {
    String usuarioIdActual = 'u1',
  }) {
    bool huboCambios = false;
    for (final ReporteColaModel r in cola) {
      final int idx = reportes.indexWhere((op) => op.id == r.id);
      if (idx == -1) {
        reportes.insert(
          0,
          ReporteOperacion(
            id: r.id,
            usuarioId: usuarioIdActual,
            tipo: r.tipo,
            gravedad: r.gravedad,
            estado: EstadoReporte.pendiente,
            sector: r.descripcion.trim().isNotEmpty
                ? r.descripcion.trim()
                : 'Esmeraldas (${r.latitud.toStringAsFixed(4)}, ${r.longitud.toStringAsFixed(4)})',
            punto: LatLng(r.latitud, r.longitud),
            descripcion: r.descripcion.trim().isNotEmpty
                ? r.descripcion.trim()
                : '${r.tipo.etiqueta} reportada desde la app móvil',
            personas: r.personasAfectadas,
            ninos: r.ninos,
            mayores: r.adultosMayores,
            necesidades: r.necesidades,
            tieneFoto:
                r.rutaFotoLocal.isNotEmpty || r.estadoCola.estaSincronizado,
          ),
        );
        huboCambios = true;
      }
    }
    if (huboCambios) {
      notifyListeners();
    }
  }

  void cambiarEstado(
    UsuarioSesion s,
    ReporteOperacion r, {
    required EstadoReporte estado,
    required GravedadIncidente gravedad,
    required String nota,
  }) {
    exigir(s, Permiso.reporteCambiarEstado);
    final String n = nota.trim();
    if (n.isEmpty) throw const AuthException('La nota es obligatoria');
    r.historial.add(
      '${r.estado.etiqueta} → ${estado.etiqueta} · ${s.correo} · $n',
    );
    auditar(
      s,
      'PATCH /reportes/:id/estado',
      '${r.estado.valor}→${estado.valor}',
    );
    r
      ..estado = estado
      ..gravedad = gravedad;
    if (apiClient != null) {
      unawaited(
        apiClient!
            .actualizarEstadoReporteRemoto(
              id: r.id,
              estado: estado.valor,
              verificado: r.verificado,
              nota: n,
            )
            .catchError((_) {}),
      );
    }
    notifyListeners();
  }

  void verificar(UsuarioSesion s, ReporteOperacion r) {
    exigir(s, Permiso.reporteCambiarEstado);
    r.verificado = true;
    if (apiClient != null) {
      unawaited(
        apiClient!
            .actualizarEstadoReporteRemoto(
              id: r.id,
              estado: r.estado.valor,
              verificado: true,
              nota: 'Reporte verificado en campo por ${s.correo}',
            )
            .catchError((_) {}),
      );
    }
    auditar(s, 'VERIFICAR', r.id.substring(0, 8));
  }

  void ajustarOcupacion(UsuarioSesion s, PuntoServicioModel p, int delta) {
    exigir(s, Permiso.puntosEditar);
    final int i = puntos.indexOf(p);
    final int nuevaOcupacion = (p.ocupacion + delta).clamp(0, p.capacidad);
    final PuntoServicioModel n = PuntoServicioModel(
      id: p.id,
      nombre: p.nombre,
      tipo: p.tipo,
      latitud: p.latitud,
      longitud: p.longitud,
      telefono: p.telefono,
      capacidad: p.capacidad,
      ocupacion: nuevaOcupacion,
      activo: p.activo,
    );
    puntos[i] = n;
    if (apiClient != null) {
      unawaited(
        apiClient!
            .actualizarOcupacionAlbergueRemoto(
              id: p.id,
              ocupacion: nuevaOcupacion,
            )
            .catchError((_) {}),
      );
    }
    auditar(s, 'PATCH /albergues/:id/ocupacion', '${p.nombre}: ${n.ocupacion}');
  }

  void crearPunto(
    UsuarioSesion s,
    String nombre,
    TipoPuntoServicio tipo,
    int capacidad,
  ) {
    exigir(s, Permiso.puntosTodo);
    if (nombre.trim().isEmpty || capacidad <= 0) {
      throw const AuthException('Datos inválidos');
    }
    puntos.add(
      PuntoServicioModel(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        nombre: '${nombre.trim()} (sim.)',
        tipo: tipo,
        latitud: 0.955,
        longitud: -79.655,
        telefono: '—',
        capacidad: capacidad,
        ocupacion: 0,
      ),
    );
    auditar(s, 'CREAR PUNTO', nombre);
  }

  void emitirAlerta(
    UsuarioSesion s, {
    required String sector,
    required GravedadIncidente nivel,
    required String mensaje,
    required bool oficial,
  }) {
    exigir(s, Permiso.alertasCrear);
    if (sector.trim().isEmpty || mensaje.trim().isEmpty) {
      throw const AuthException('Sector y mensaje son obligatorios');
    }
    alertas.insert(
      0,
      AlertaSector(
        sector: sector.trim(),
        nivel: nivel,
        mensaje: mensaje.trim(),
        creadaPor: s.correo,
        oficial: oficial,
        hora: DateTime.now(),
      ),
    );
    if (apiClient != null) {
      unawaited(
        apiClient!
            .crearAlertaRemota(
              sector: sector.trim(),
              nivel: nivel.valor,
              mensaje: mensaje.trim(),
              origen: oficial ? 'oficial' : 'simulada',
            )
            .catchError((_) {}),
      );
    }
    auditar(s, 'POST /alertas', sector);
  }

  void crearUsuario(
    UsuarioSesion s,
    String nombre,
    String correo,
    RolUsuario rol,
  ) {
    exigir(s, Permiso.usuariosGestionar);
    final String c = correo.trim().toLowerCase();
    if (usuarios.any((u) => u.correo == c)) {
      throw const AuthException('El correo ya existe');
    }
    usuarios.add(
      UsuarioGestion(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre.trim(),
        correo: c,
        rol: rol,
      ),
    );
    auditar(s, 'POST /usuarios', '$c (${rol.valor})');
  }

  void alternarUsuario(UsuarioSesion s, UsuarioGestion u) {
    exigir(s, Permiso.usuariosGestionar);
    if (u.id == s.id) {
      throw const AuthException('No puedes desactivarte a ti mismo');
    }
    u.activo = !u.activo;
    auditar(s, u.activo ? 'ACTIVAR USUARIO' : 'DESACTIVAR USUARIO', u.correo);
  }
}
