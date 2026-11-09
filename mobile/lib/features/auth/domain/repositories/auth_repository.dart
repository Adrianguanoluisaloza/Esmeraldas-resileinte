import '../../../../core/enums/app_enums.dart';

/// Entidad de sesión de usuario en el dominio.
class UsuarioSesion {
  const UsuarioSesion({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  final String id;
  final String nombre;
  final String correo;
  final RolUsuario rol;
}

/// Contrato de autenticación y gestión de sesión segura.
/// El token JWT nunca se guarda en Hive; vive en `flutter_secure_storage`.
abstract interface class AuthRepository {
  Future<UsuarioSesion?> obtenerSesionActual();

  Future<String?> obtenerTokenSeguro();

  Future<UsuarioSesion> iniciarSesion({
    required String correo,
    required String password,
  });

  Future<void> cerrarSesion();
}
