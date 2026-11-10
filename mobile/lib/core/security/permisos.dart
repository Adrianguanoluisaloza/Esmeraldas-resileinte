import '../enums/app_enums.dart';

/// Permisos de la app (sección 7 de `estructura-esmeraldas-resiliente.md`).
/// La UI los usa para ocultar o bloquear acciones; el backend SIEMPRE valida de nuevo.
enum Permiso {
  reporteCrear,
  reporteVerPropios,
  reporteVerTodos,
  reporteVerCompetencia,
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
      RolUsuario.bomberos: _permisosInstitucion,
      RolUsuario.policia: _permisosInstitucion,
      RolUsuario.admin: <Permiso>{...Permiso.values},
    };

const Set<Permiso> _permisosInstitucion = <Permiso>{
  Permiso.reporteCrear,
  Permiso.reporteVerCompetencia,
  Permiso.reporteCambiarEstado,
  Permiso.puntosVer,
  Permiso.alertasVer,
};

/// Reportes que atiende cada institución. Igual que `COMPETENCIA_INSTITUCION` en la API.
const Map<RolUsuario, Set<TipoIncidente>> competenciaInstitucion =
    <RolUsuario, Set<TipoIncidente>>{
      RolUsuario.bomberos: <TipoIncidente>{
        TipoIncidente.inundacion,
        TipoIncidente.deslizamiento,
        TipoIncidente.personasAtrapadas,
        TipoIncidente.danoVivienda,
      },
      RolUsuario.policia: <TipoIncidente>{
        TipoIncidente.viaBloqueada,
        TipoIncidente.personasAtrapadas,
      },
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
