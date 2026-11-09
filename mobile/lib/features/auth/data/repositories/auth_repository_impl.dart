import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/google_auth_service.dart';

/// Implementación del repositorio de autenticación (M2 de `TAREAS_MOVIL_FRANCO.md`).
/// - Llama a `POST /auth/login`, `POST /auth/registro` y `POST /auth/google` en el backend real.
/// - Guarda `token` y `usuario` en `flutter_secure_storage` (nunca en Hive).
class SecureStorageAuthRepository implements AuthRepository {
  SecureStorageAuthRepository({
    FlutterSecureStorage? secureStorage,
    Dio? dio,
    GoogleAuthService? googleAuthService,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiBaseUrl,
               connectTimeout: const Duration(seconds: 6),
               receiveTimeout: const Duration(seconds: 8),
             ),
           ),
       _google = googleAuthService ?? GoogleAuthService();

  static const String _keyJwtToken = 'auth_jwt_token';
  static const String _keySesion = 'auth_sesion';

  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  final GoogleAuthService _google;
  UsuarioSesion? _sesionCache;

  int _intentosFallidos = 0;
  DateTime? _bloqueadoHasta;

  @override
  Future<UsuarioSesion?> obtenerSesionActual() async {
    if (_sesionCache != null && !_sesionCache!.expirada) return _sesionCache;
    final String? raw = await _secureStorage.read(key: _keySesion);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final UsuarioSesion s = UsuarioSesion(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        correo: m['correo'] as String,
        rol: RolUsuario.fromValor(m['rol'] as String),
        expiraEn: DateTime.parse(m['exp'] as String).toUtc(),
        proveedor: m['proveedor'] as String? ?? 'correo',
      );
      if (s.expirada) {
        await cerrarSesion();
        return null;
      }
      return _sesionCache = s;
    } catch (_) {
      await cerrarSesion();
      return null;
    }
  }

  @override
  Future<String?> obtenerTokenSeguro() =>
      _secureStorage.read(key: _keyJwtToken);

  @override
  Future<UsuarioSesion> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    _verificarBloqueo();
    final String c = correo.trim().toLowerCase();
    try {
      final Response<dynamic> r = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, String>{'correo': c, 'password': password},
      );
      return await _desdeRespuesta(r.data as Map<String, dynamic>, 'correo');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        _registrarFallo();
        throw _mensajeFallo();
      }
      if (e.response?.statusCode == 429) {
        throw const AuthException('Demasiados intentos. Intenta más tarde.');
      }
      throw const AuthException(
        'Sin conexión con el servidor. Usa "Emergencia sin internet" si necesitas reportar ahora.',
      );
    }
  }

  @override
  Future<UsuarioSesion> registrar({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final String c = correo.trim().toLowerCase();
    try {
      final Response<dynamic> r = await _dio.post<dynamic>(
        '/auth/registro',
        data: <String, String>{
          'nombre': nombre.trim(),
          'correo': c,
          'password': password,
        },
      );
      return await _desdeRespuesta(r.data as Map<String, dynamic>, 'correo');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
        final dynamic data = e.response?.data;
        final String msg = data is Map && data['mensaje'] != null
            ? '${data['mensaje']}'
            : 'No se pudo completar el registro con esos datos.';
        throw AuthException(msg);
      }
      throw const AuthException(
        'Sin conexión con el servidor. Intenta de nuevo cuando tengas señal.',
      );
    }
  }

  @override
  Future<UsuarioSesion> iniciarSesionConGoogle() async {
    final String idToken = await _google.obtenerIdToken();
    if (idToken.isEmpty) {
      throw const AuthException(
        'No se recibió el token de autenticación de Google.',
      );
    }
    try {
      final Response<dynamic> r = await _dio.post<dynamic>(
        '/auth/google',
        data: <String, String>{'id_token': idToken},
      );
      return await _desdeRespuesta(r.data as Map<String, dynamic>, 'google');
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      final String msg = data is Map && data['mensaje'] != null
          ? '${data['mensaje']}'
          : 'No se pudo validar tu cuenta de Google en el servidor.';
      throw AuthException(msg);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    _sesionCache = null;
    await _secureStorage.delete(key: _keyJwtToken);
    await _secureStorage.delete(key: _keySesion);
  }

  void _verificarBloqueo() {
    final DateTime? hasta = _bloqueadoHasta;
    if (hasta != null && DateTime.now().isBefore(hasta)) {
      final int s = hasta.difference(DateTime.now()).inSeconds + 1;
      throw AuthException('Demasiados intentos. Espera $s s.');
    }
  }

  void _registrarFallo() {
    _intentosFallidos++;
    if (_intentosFallidos >= AppConfig.maxIntentosLogin) {
      _bloqueadoHasta = DateTime.now().add(AppConfig.bloqueoLogin);
      _intentosFallidos = 0;
    }
  }

  AuthException _mensajeFallo() {
    if (_bloqueadoHasta != null && DateTime.now().isBefore(_bloqueadoHasta!)) {
      return AuthException(
        'Demasiados intentos. Espera ${AppConfig.bloqueoLogin.inSeconds} s.',
      );
    }
    final int restantes = AppConfig.maxIntentosLogin - _intentosFallidos;
    return AuthException(
      'Correo o contraseña incorrectos. Intentos restantes: $restantes',
    );
  }

  DateTime _expDeToken(String token) {
    try {
      final String p = base64Url.normalize(token.split('.')[1]);
      final Map<String, dynamic> claims =
          jsonDecode(utf8.decode(base64Url.decode(p))) as Map<String, dynamic>;
      return DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as int) * 1000,
        isUtc: true,
      );
    } catch (_) {
      return DateTime.now().toUtc().add(AppConfig.duracionSesion);
    }
  }

  Future<UsuarioSesion> _desdeRespuesta(Map<String, dynamic> d, String prov) {
    final Map<String, dynamic> u = d['usuario'] as Map<String, dynamic>;
    return _guardar(d['token'] as String, <String, String>{
      'id': '${u['id']}',
      'nombre': '${u['nombre']}',
      'correo': '${u['correo']}',
      'rol': '${u['rol']}',
    }, prov);
  }

  Future<UsuarioSesion> _guardar(
    String token,
    Map<String, String> u,
    String proveedor,
  ) async {
    _intentosFallidos = 0;
    _bloqueadoHasta = null;
    final UsuarioSesion s = UsuarioSesion(
      id: u['id']!,
      nombre: u['nombre']!,
      correo: u['correo']!,
      rol: RolUsuario.fromValor(u['rol']!),
      expiraEn: _expDeToken(token),
      proveedor: proveedor,
    );
    await _secureStorage.write(key: _keyJwtToken, value: token);
    await _secureStorage.write(
      key: _keySesion,
      value: jsonEncode(<String, String>{
        'id': s.id,
        'nombre': s.nombre,
        'correo': s.correo,
        'rol': s.rol.valor,
        'exp': s.expiraEn.toIso8601String(),
        'proveedor': proveedor,
      }),
    );
    return _sesionCache = s;
  }
}
