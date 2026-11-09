import '../enums/app_enums.dart';

/// Permisos de la app (sección 7 de `estructura-esmeraldas-resiliente.md`).
/// La UI los usa para ocultar o bloquear acciones; el backend SIEMPRE valida de nuevo.
enum Permiso {
  reporteCrear,
  reporteVerPropios,
  reporteVerTodos,
  reporteCambiarEstado,
  puntosVer,
  puntosEditar,
  puntosTodo,
  alertasVer,
  alertasCrear,
  estadisticasVer,
  usuariosGestionar,
  auditoriaVer,
}

const Map<RolUsuario, Set<Permiso>> _permisosPorRol =
    <RolUsuario, Set<Permiso>>{
      RolUsuario.ciudadano: <Permiso>{
        Permiso.reporteCrear,
        Permiso.reporteVerPropios,
        Permiso.puntosVer,
        Permiso.alertasVer,
      },
      RolUsuario.operador911: <Permiso>{
        Permiso.reporteCrear,
        Permiso.reporteVerTodos,
        Permiso.reporteCambiarEstado,
        Permiso.puntosVer,
        Permiso.puntosEditar,
        Permiso.alertasVer,
        Permiso.alertasCrear,
        Permiso.estadisticasVer,
      },
      RolUsuario.admin: <Permiso>{...Permiso.values},
    };

extension PermisosRol on RolUsuario {
  bool puede(Permiso p) => _permisosPorRol[this]!.contains(p);
}

/// Error lanzado cuando un rol intenta una acción sin permiso (equivale a HTTP 403).
class PermisoDenegado implements Exception {
  const PermisoDenegado(this.permiso);
  final Permiso permiso;
  @override
  String toString() => '403 · Tu rol no tiene permiso: ${permiso.name}';
}
