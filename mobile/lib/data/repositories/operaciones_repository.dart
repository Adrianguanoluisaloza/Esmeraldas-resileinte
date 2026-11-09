import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../core/enums/app_enums.dart';
import '../../core/security/permisos.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../models/punto_servicio_model.dart';

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

/// Repositorio del centro de operaciones (operador 911 y admin).
/// En modo demo trabaja en memoria con datos SIMULADOS del escenario "jueves 06:00".
/// Cada método verifica el permiso del rol antes de actuar (el backend repite la validación).
class OperacionesRepository extends ChangeNotifier {
  OperacionesRepository() {
    _sembrar();
  }

  final List<ReporteOperacion> reportes = <ReporteOperacion>[];
  final List<PuntoServicioModel> puntos = <PuntoServicioModel>[];
  final List<AlertaSector> alertas = <AlertaSector>[];
  final List<UsuarioGestion> usuarios = <UsuarioGestion>[];
  final List<EventoAuditoria> auditoria = <EventoAuditoria>[];

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
    return reportes.where((r) => r.usuarioId == s.id).toList();
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
    notifyListeners();
  }

  void verificar(UsuarioSesion s, ReporteOperacion r) {
    exigir(s, Permiso.reporteCambiarEstado);
    r.verificado = true;
    auditar(s, 'VERIFICAR', r.id.substring(0, 8));
  }

  void ajustarOcupacion(UsuarioSesion s, PuntoServicioModel p, int delta) {
    exigir(s, Permiso.puntosEditar);
    final int i = puntos.indexOf(p);
    final PuntoServicioModel n = PuntoServicioModel(
      id: p.id,
      nombre: p.nombre,
      tipo: p.tipo,
      latitud: p.latitud,
      longitud: p.longitud,
      telefono: p.telefono,
      capacidad: p.capacidad,
      ocupacion: (p.ocupacion + delta).clamp(0, p.capacidad),
      activo: p.activo,
    );
    puntos[i] = n;
    auditar(
      s,
      'PATCH /puntos-servicio/:id/ocupacion',
      '${p.nombre}: ${n.ocupacion}',
    );
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

  void _sembrar() {
    reportes.addAll(<ReporteOperacion>[
      ReporteOperacion(
        id: 'a1f3c2d4-0001',
        usuarioId: 'u1',
        tipo: TipoIncidente.inundacion,
        gravedad: GravedadIncidente.critica,
        estado: EstadoReporte.pendiente,
        sector: 'Las Palmas',
        punto: const LatLng(0.9790, -79.6580),
        descripcion: 'Agua sobre 1 m en calles',
        personas: 12,
        ninos: 4,
        mayores: 2,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.rescate,
          NecesidadFamiliar.agua,
        ],
        iaExplicacion:
            'Se observa agua cubriendo la vía y la mitad de las puertas.',
        iaConfianza: 'alta',
      ),
      ReporteOperacion(
          id: 'b2e4d5f6-0002',
          usuarioId: 'u9',
          tipo: TipoIncidente.deslizamiento,
          gravedad: GravedadIncidente.alta,
          estado: EstadoReporte.enProceso,
          sector: 'Barrio 50 Casas',
          punto: const LatLng(0.9480, -79.6700),
          descripcion: 'Tierra cayó sobre 2 casas',
          personas: 7,
          ninos: 2,
          mayores: 1,
          necesidades: <NecesidadFamiliar>[NecesidadFamiliar.alimentos],
          verificado: true,
          iaExplicacion:
              'Masa de tierra visible contra la pared de una vivienda.',
          iaConfianza: 'media',
        )
        ..historial.add(
          'Pendiente → En proceso · operador@911.ec · Bomberos en camino',
        ),
      ReporteOperacion(
        id: 'c3f5e6a7-0003',
        usuarioId: 'u9',
        tipo: TipoIncidente.viaBloqueada,
        gravedad: GravedadIncidente.media,
        estado: EstadoReporte.pendiente,
        sector: 'Vía Esmeraldas–Atacames',
        punto: const LatLng(0.9600, -79.6900),
        descripcion: 'Árbol caído bloquea ambos carriles',
        tieneFoto: false,
      ),
      ReporteOperacion(
        id: 'd4a6f7b8-0004',
        usuarioId: 'u8',
        tipo: TipoIncidente.personasAtrapadas,
        gravedad: GravedadIncidente.critica,
        estado: EstadoReporte.pendiente,
        sector: 'Isla Piedad',
        punto: const LatLng(0.9700, -79.6450),
        descripcion: 'Familia en el techo',
        personas: 5,
        ninos: 3,
        mayores: 1,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.rescate,
          NecesidadFamiliar.medicinas,
        ],
        iaExplicacion: 'Personas sobre un techo rodeadas de agua.',
        iaConfianza: 'media',
      ),
      ReporteOperacion(
        id: 'e5b7a8c9-0005',
        usuarioId: 'u8',
        tipo: TipoIncidente.danoVivienda,
        gravedad: GravedadIncidente.baja,
        estado: EstadoReporte.atendido,
        sector: 'Centro',
        punto: const LatLng(0.9560, -79.6530),
        descripcion: 'Techo con filtraciones',
        personas: 3,
        ninos: 1,
        verificado: true,
      ),
    ]);
    puntos.addAll(const <PuntoServicioModel>[
      PuntoServicioModel(
        id: 'p1',
        nombre: 'Albergue Unidad Educativa (sim.)',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9620,
        longitud: -79.6600,
        telefono: '06-000-0001',
        capacidad: 150,
        ocupacion: 60,
      ),
      PuntoServicioModel(
        id: 'p2',
        nombre: 'Albergue Coliseo (sim.)',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9450,
        longitud: -79.6480,
        telefono: '06-000-0002',
        capacidad: 300,
        ocupacion: 240,
      ),
      PuntoServicioModel(
        id: 'p3',
        nombre: 'Centro de Salud Norte (sim.)',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9820,
        longitud: -79.6520,
        telefono: '06-000-0003',
        capacidad: 40,
        ocupacion: 39,
      ),
    ]);
    alertas.add(
      AlertaSector(
        sector: 'Las Palmas',
        nivel: GravedadIncidente.alta,
        mensaje: 'Crecida del río. Evacuar hacia zonas altas.',
        creadaPor: 'operador@911.ec',
        oficial: false,
        hora: DateTime.now(),
      ),
    );
    usuarios.addAll(<UsuarioGestion>[
      UsuarioGestion(
        id: 'u1',
        nombre: 'María Quiñónez',
        correo: 'ciudadano@demo.ec',
        rol: RolUsuario.ciudadano,
      ),
      UsuarioGestion(
        id: 'u2',
        nombre: 'Operador Turno A',
        correo: 'operador@911.ec',
        rol: RolUsuario.operador911,
      ),
      UsuarioGestion(
        id: 'u3',
        nombre: 'Administrador',
        correo: 'admin@resiliente.ec',
        rol: RolUsuario.admin,
      ),
    ]);
  }
}
