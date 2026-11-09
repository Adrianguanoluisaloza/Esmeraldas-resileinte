import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/repositories/auth_repository.dart';

/// Obtiene un `id_token` de Google usando OAuth 2.0 con PKCE (sin client secret en la app).
/// El `id_token` se envía al backend, que verifica firma, `aud` y `exp` con las claves de Google.
class GoogleAuthService {
  GoogleAuthService({FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  bool get configurado => AppConfig.googleClientId.isNotEmpty;

  Future<String> obtenerIdToken() async {
    if (!configurado) {
      throw const AuthException(
        'Google no está configurado. Usa --dart-define=GOOGLE_CLIENT_ID=...',
      );
    }
    try {
      final AuthorizationTokenResponse
      r = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.googleClientId,
          AppConfig.googleRedirectUri,
          discoveryUrl:
              'https://accounts.google.com/.well-known/openid-configuration',
          scopes: const <String>['openid', 'email', 'profile'],
          promptValues: const <String>['select_account'],
        ),
      );
      final String? idToken = r.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google no devolvió credenciales.');
      }
      return idToken;
    } on AuthException {
      rethrow;
    } on FlutterAppAuthUserCancelledException {
      throw const AuthException('Inicio con Google cancelado.');
    } catch (_) {
      throw const AuthException('No se pudo iniciar sesión con Google.');
    }
  }
}
