import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/enums/app_enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/google_auth_service.dart';

/// Implementación del repositorio de autenticación (M2 de `TAREAS_MOVIL_FRANCO.md`).
/// - Llama a `POST /auth/login` y `POST /auth/registro` en el backend real.
/// - Guarda `token` y `usuario` en `flutter_secure_storage` (nunca en Hive).
/// - Si el backend local aún no está levantado y [AppConfig.modoDemo] es true,
///   permite autenticar con las cuentas demo del hackathon guardadas como hash.
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
               connectTimeout: const Duration(seconds: 5),
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

  static String _hash(String p) {
    final List<int> bytes = utf8.encode('sal-demo-2026:$p');
    int h1 = 0x811c9dc5, h2 = 0xcbf29ce4;
    for (final int b in bytes) {
      h1 = ((h1 ^ b) * 0x01000193) & 0xffffffff;
      h2 = ((h2 + b) * 0x85ebca6b) & 0xffffffff;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }

  final List<Map<String, String>> _cuentasDemo = <Map<String, String>>[
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000001',
      'nombre': 'María Quiñónez',
      'correo': 'ciudadano@demo.esmeraldas-resiliente.ec',
      'rol': 'ciudadano',
      'hash': _hash('demo-resiliente-2026'),
    },
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000002',
      'nombre': 'Operador Turno A',
      'correo': 'operador@demo.esmeraldas-resiliente.ec',
      'rol': 'operador_911',
      'hash': _hash('demo-resiliente-2026'),
    },
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000003',
      'nombre': 'Administrador COE',
      'correo': 'admin@demo.esmeraldas-resiliente.ec',
      'rol': 'admin',
      'hash': _hash('demo-resiliente-2026'),
    },
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000004',
      'nombre': 'María Quiñónez',
      'correo': 'ciudadano@demo.ec',
      'rol': 'ciudadano',
      'hash': _hash('Ciudadano#2026'),
    },
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000005',
      'nombre': 'Operador Turno A',
      'correo': 'operador@911.ec',
      'rol': 'operador_911',
      'hash': _hash('Operador#2026'),
    },
    <String, String>{
      'id': 'b0000000-0000-4000-8000-000000000006',
      'nombre': 'Administrador COE',
      'correo': 'admin@resiliente.ec',
      'rol': 'admin',
      'hash': _hash('Admin#2026x'),
    },
  ];

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
      if (AppConfig.modoDemo) {
        final Map<String, String>? u = _cuentasDemo
            .where((m) => m['correo'] == c && m['hash'] == _hash(password))
            .firstOrNull;
        if (u == null) {
          _registrarFallo();
          throw _mensajeFallo();
        }
        return _guardar(_tokenDemo(u['id']!, u['rol']!), u, 'correo');
      }
      throw const AuthException(
        'Sin conexión con el servidor. Intenta de nuevo.',
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
        throw const AuthException(
          'No se pudo completar el registro con esos datos.',
        );
      }
      if (AppConfig.modoDemo) {
        if (_cuentasDemo.any((m) => m['correo'] == c)) {
          throw const AuthException(
            'No se pudo completar el registro con esos datos.',
          );
        }
        final Map<String, String> u = <String, String>{
          'id': 'u${DateTime.now().millisecondsSinceEpoch}',
          'nombre': nombre.trim(),
          'correo': c,
          'rol': 'ciudadano',
          'hash': _hash(password),
        };
        _cuentasDemo.add(u);
        return _guardar(_tokenDemo(u['id']!, 'ciudadano'), u, 'correo');
      }
      throw const AuthException(
        'Sin conexión con el servidor. Intenta de nuevo.',
      );
    }
  }

  @override
  Future<UsuarioSesion> iniciarSesionConGoogle() async {
    String? idToken;
    try {
      idToken = await _google.obtenerIdToken();
    } on AuthException catch (e) {
      if (e.mensaje.contains('cancelado')) rethrow;
      if (!AppConfig.modoDemo) rethrow;
    }

    if (idToken != null) {
      try {
        final Response<dynamic> r = await _dio.post<dynamic>(
          '/auth/google',
          data: <String, String>{'id_token': idToken},
        );
        return await _desdeRespuesta(r.data as Map<String, dynamic>, 'google');
      } on DioException {
        if (!AppConfig.modoDemo) {
          throw const AuthException('No se pudo validar tu cuenta de Google.');
        }
        final Map<String, String> u = _extraerUsuarioDeIdToken(idToken);
        return _guardar(_tokenDemo(u['id']!, 'ciudadano'), u, 'google');
      }
    }

    // Respaldo en modo demo (ej. Chrome o sin SHA-1 registrado aún en Firebase)
    final Map<String, String> u = <String, String>{
      'id': 'g-644267053650',
      'nombre': 'Cuenta Google (esmeralsrelesiente)',
      'correo': 'ciudadano.google@esmeraldas-resiliente.ec',
      'rol': 'ciudadano',
    };
    return _guardar(_tokenDemo(u['id']!, 'ciudadano'), u, 'google');
  }

  Map<String, String> _extraerUsuarioDeIdToken(String idToken) {
    try {
      final String payload = base64Url.normalize(idToken.split('.')[1]);
      final Map<String, dynamic> claims = jsonDecode(
        utf8.decode(base64Url.decode(payload)),
      ) as Map<String, dynamic>;
      return <String, String>{
        'id': 'g-${claims['sub'] ?? 'google'}',
        'nombre': '${claims['name'] ?? claims['email'] ?? 'Usuario Google'}',
        'correo': '${claims['email'] ?? 'usuario@gmail.com'}',
        'rol': 'ciudadano',
      };
    } catch (_) {
      return <String, String>{
        'id': 'g-google',
        'nombre': 'Usuario Google',
        'correo': 'usuario@gmail.com',
        'rol': 'ciudadano',
      };
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

  String _tokenDemo(String sub, String rol) {
    String b64(Map<String, dynamic> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final int exp =
        DateTime.now().add(AppConfig.duracionSesion).millisecondsSinceEpoch ~/
        1000;
    return '${b64(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'})}.'
        '${b64(<String, dynamic>{'sub': sub, 'rol': rol, 'exp': exp})}.firma-demo';
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
