import '../../../../core/enums/app_enums.dart';

/// Entidad de sesión de usuario en el dominio.
class UsuarioSesion {
  const UsuarioSesion({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.expiraEn,
    this.proveedor = 'correo',
  });

  final String id;
  final String nombre;
  final String correo;
  final RolUsuario rol;

  /// Expiración del JWT (claim `exp`), en UTC.
  final DateTime expiraEn;

  /// `correo` o `google`.
  final String proveedor;

  bool get expirada => DateTime.now().toUtc().isAfter(expiraEn);
}

/// Error de autenticación con mensaje listo para mostrar al usuario.
/// Los mensajes son genéricos: nunca revelan si un correo existe.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Contrato de autenticación y gestión de sesión segura.
/// El token JWT nunca se guarda en Hive; vive en `flutter_secure_storage`.
abstract interface class AuthRepository {
  /// Restaura la sesión guardada si el token sigue vigente.
  Future<UsuarioSesion?> obtenerSesionActual();

  Future<String?> obtenerTokenSeguro();

  Future<UsuarioSesion> iniciarSesion({
    required String correo,
    required String password,
  });

  /// `POST /auth/registro`. Siempre crea rol `ciudadano`: el rol no se envía desde la app.
  Future<UsuarioSesion> registrar({
    required String nombre,
    required String correo,
    required String password,
  });

  /// Google (OAuth 2.0 + PKCE). La app obtiene un `id_token` y el servidor lo verifica
  /// en `POST /auth/google` antes de emitir su propio JWT.
  Future<UsuarioSesion> iniciarSesionConGoogle();

  Future<void> cerrarSesion();
}
