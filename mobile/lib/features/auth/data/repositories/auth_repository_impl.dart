import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/enums/app_enums.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación que guarda el token en `flutter_secure_storage`.
class SecureStorageAuthRepository implements AuthRepository {
  SecureStorageAuthRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _keyJwtToken = 'auth_jwt_token';

  final FlutterSecureStorage _secureStorage;
  UsuarioSesion? _sesionCache;

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async {
    return _sesionCache;
  }

  @override
  Future<String?> obtenerTokenSeguro() async {
    return _secureStorage.read(key: _keyJwtToken);
  }

  @override
  Future<UsuarioSesion> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    // Esqueleto: POST /auth/login -> guarda token en FlutterSecureStorage
    await _secureStorage.write(key: _keyJwtToken, value: 'demo-jwt-token');
    final UsuarioSesion sesion = UsuarioSesion(
      id: 'usr-ciudadano-01',
      nombre: 'Ciudadano Esmeraldas',
      correo: correo,
      rol: RolUsuario.ciudadano,
    );
    _sesionCache = sesion;
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    _sesionCache = null;
    await _secureStorage.delete(key: _keyJwtToken);
  }
}
