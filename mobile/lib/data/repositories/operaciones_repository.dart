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
        id: 'a4000000-0000-4000-8000-000000000001',
        usuarioId: 'u-coe-1',
        tipo: TipoIncidente.inundacion,
        gravedad: GravedadIncidente.critica,
        estado: EstadoReporte.pendiente,
        sector: 'Isla Piedad',
        punto: const LatLng(0.9765, -79.6582),
        descripcion: 'Evento 1. Acumulación de agua en calles y viviendas de barrios ribereños.',
        personas: 35,
        ninos: 12,
        mayores: 5,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.rescate,
          NecesidadFamiliar.agua,
        ],
        iaExplicacion: 'Detección de cota de agua superior a 1 metro en zona baja.',
        iaConfianza: 'alta',
      ),
      ReporteOperacion(
        id: 'a4000000-0000-4000-8000-000000000002',
        usuarioId: 'u-coe-2',
        tipo: TipoIncidente.inundacion,
        gravedad: GravedadIncidente.critica,
        estado: EstadoReporte.pendiente,
        sector: 'Ribera del río Teaone (Tabiazo)',
        punto: const LatLng(0.9120, -79.6320),
        descripcion: 'Evento 2. Desbordamiento del río en comunidad rural con señal limitada.',
        personas: 60,
        ninos: 20,
        mayores: 9,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.rescate,
          NecesidadFamiliar.alimentos,
          NecesidadFamiliar.agua,
        ],
        iaExplicacion: 'Crecida de caudal reportada por nodo rural.',
        iaConfianza: 'alta',
      ),
      ReporteOperacion(
        id: 'a4000000-0000-4000-8000-000000000003',
        usuarioId: 'u-coe-3',
        tipo: TipoIncidente.viaBloqueada,
        gravedad: GravedadIncidente.alta,
        estado: EstadoReporte.enProceso,
        sector: 'Acceso Puente Tachina',
        punto: const LatLng(0.9824, -79.6385),
        descripcion: 'Evento 3. Deslizamiento interrumpe la vía. Se requiere ruta alterna.',
        verificado: true,
      )..historial.add('Pendiente → En proceso · operador@demo.esmeraldas-resiliente.ec · Maquinaria despachada'),
      ReporteOperacion(
        id: 'a4000000-0000-4000-8000-000000000004',
        usuarioId: 'u-coe-4',
        tipo: TipoIncidente.personasAtrapadas,
        gravedad: GravedadIncidente.critica,
        estado: EstadoReporte.pendiente,
        sector: 'Barrio 20 de Noviembre',
        punto: const LatLng(0.9548, -79.6695),
        descripcion: 'Evento 4. Familias atrapadas en planta alta, piden evacuación.',
        personas: 14,
        ninos: 6,
        mayores: 3,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.rescate,
          NecesidadFamiliar.medicinas,
        ],
        iaExplicacion: 'Personas sobre planta alta aisladas por agua.',
        iaConfianza: 'alta',
      ),
      ReporteOperacion(
        id: 'a4000000-0000-4000-8000-000000000005',
        usuarioId: 'u-coe-5',
        tipo: TipoIncidente.otro,
        gravedad: GravedadIncidente.alta,
        estado: EstadoReporte.enProceso,
        sector: 'Barrio 20 de Noviembre',
        punto: const LatLng(0.9515, -79.6732),
        descripcion: 'Evento 5. Albergue temporal UTLVTE cerca del límite de capacidad.',
        personas: 112,
        ninos: 40,
        mayores: 15,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.alimentos,
          NecesidadFamiliar.agua,
        ],
        verificado: true,
      ),
      ReporteOperacion(
        id: 'a4000000-0000-4000-8000-000000000006',
        usuarioId: 'u-coe-6',
        tipo: TipoIncidente.otro,
        gravedad: GravedadIncidente.alta,
        estado: EstadoReporte.pendiente,
        sector: 'El Arenal',
        punto: const LatLng(0.9700, -79.6490),
        descripcion: 'Evento 6. Solicitud urgente de agua potable, alimentos y medicamentos.',
        personas: 22,
        ninos: 8,
        mayores: 4,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.agua,
          NecesidadFamiliar.alimentos,
          NecesidadFamiliar.medicinas,
        ],
      ),
      ReporteOperacion(
        id: 'b5000000-1111-4000-8000-000000000099',
        usuarioId: 'u-ciu-1',
        tipo: TipoIncidente.inundacion,
        gravedad: GravedadIncidente.alta,
        estado: EstadoReporte.pendiente,
        sector: 'El Arenal',
        punto: const LatLng(0.9682, -79.6517),
        descripcion: 'Reporte sincronizado en vivo desde dispositivo móvil.',
        personas: 4,
        ninos: 1,
        mayores: 1,
        necesidades: <NecesidadFamiliar>[
          NecesidadFamiliar.agua,
          NecesidadFamiliar.alimentos,
        ],
      ),
    ]);
    puntos.addAll(const <PuntoServicioModel>[
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000001',
        nombre: 'Albergue temporal UTLVTE',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9515,
        longitud: -79.6732,
        telefono: 'Campus universitario',
        capacidad: 120,
        ocupacion: 112,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000002',
        nombre: 'Coliseo Nubia Villacís',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9635,
        longitud: -79.6542,
        telefono: 'Centro de la ciudad',
        capacidad: 200,
        ocupacion: 70,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000003',
        nombre: 'Unidad educativa Las Palmas',
        tipo: TipoPuntoServicio.albergue,
        latitud: 0.9880,
        longitud: -79.6470,
        telefono: 'Las Palmas',
        capacidad: 90,
        ocupacion: 20,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000004',
        nombre: 'Hospital Delfina Torres de Concha',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9428,
        longitud: -79.6812,
        telefono: 'Sector San Rafael',
        capacidad: 150,
        ocupacion: 138,
      ),
      PuntoServicioModel(
        id: 'a3000000-0000-4000-8000-000000000005',
        nombre: 'Centro de salud Las Palmas',
        tipo: TipoPuntoServicio.centroSalud,
        latitud: 0.9902,
        longitud: -79.6455,
        telefono: 'Las Palmas',
        capacidad: 40,
        ocupacion: 22,
      ),
    ]);
    alertas.add(
      AlertaSector(
        sector: 'Ribera del río Teaone (Tabiazo)',
        nivel: GravedadIncidente.critica,
        mensaje: 'Simulacro: crecida del río. Dirigirse a zonas altas y seguir indicaciones de las autoridades.',
        creadaPor: 'operador@demo.esmeraldas-resiliente.ec',
        oficial: true,
        hora: DateTime.now(),
      ),
    );
    usuarios.addAll(<UsuarioGestion>[
      UsuarioGestion(
        id: 'usr-911-01',
        nombre: 'Operador COE demo',
        correo: 'operador@demo.esmeraldas-resiliente.ec',
        rol: RolUsuario.operador911,
      ),
      UsuarioGestion(
        id: 'usr-adm-01',
        nombre: 'Administrador demo',
        correo: 'admin@demo.esmeraldas-resiliente.ec',
        rol: RolUsuario.admin,
      ),
      UsuarioGestion(
        id: 'usr-ciu-01',
        nombre: 'Ciudadano demo',
        correo: 'ciudadano@demo.esmeraldas-resiliente.ec',
        rol: RolUsuario.ciudadano,
      ),
    ]);
  }
}
