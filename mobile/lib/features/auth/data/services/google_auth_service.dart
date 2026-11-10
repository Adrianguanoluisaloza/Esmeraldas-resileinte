import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/repositories/auth_repository.dart';

/// Servicio de autenticación con Google mediante Firebase Auth.
/// Flujo:
/// 1. google_sign_in con serverClientId = AppConfig.googleClientId
/// 2. GoogleAuthProvider.credential con idToken y accessToken de Google
/// 3. FirebaseAuth.signInWithCredential
/// 4. user.getIdToken() -> token de Firebase para enviar a POST /auth/firebase
class GoogleAuthService {
  GoogleAuthService({this.googleSignIn, this.firebaseAuth});

  final GoogleSignIn? googleSignIn;
  final FirebaseAuth? firebaseAuth;

  GoogleSignIn get _resolvedGoogleSignIn =>
      googleSignIn ??
      GoogleSignIn(
        serverClientId: AppConfig.googleClientId,
        scopes: const <String>['email', 'profile'],
      );

  FirebaseAuth get _resolvedFirebaseAuth =>
      firebaseAuth ?? FirebaseAuth.instance;

  bool get configurado => AppConfig.googleClientId.isNotEmpty;

  /// Obtiene el idToken de Firebase tras autenticar con Google.
  /// Si el usuario cancela la selección de cuenta, retorna `null`.
  Future<String?> obtenerFirebaseIdToken() async {
    if (!configurado) {
      throw const AuthException(
        'Google no está configurado. Usa --dart-define=GOOGLE_CLIENT_ID=...',
      );
    }

    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _resolvedGoogleSignIn.signIn();
    } catch (e) {
      throw AuthException('No se pudo iniciar el selector de Google: $e');
    }

    if (googleUser == null) {
      // El usuario canceló la selección de cuenta
      return null;
    }

    final GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      throw AuthException('Error al obtener credenciales de Google: $e');
    }

    final String? googleIdToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    if (googleIdToken == null && accessToken == null) {
      throw const AuthException('Google no devolvió credenciales válidas.');
    }

    try {
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await _resolvedFirebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw const AuthException('No se pudo autenticar en Firebase.');
      }

      final String? firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const AuthException('Firebase no devolvió un token de sesión.');
      }

      return firebaseIdToken;
    } on FirebaseAuthException catch (e) {
      throw AuthException('Error de Firebase: ${e.message ?? e.code}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error al autenticar con Google: $e');
    }
  }

  Future<void> cerrarSesion() async {
    try {
      if (googleSignIn != null) {
        await googleSignIn!.signOut();
      } else {
        await _resolvedGoogleSignIn.signOut();
      }
    } catch (_) {}
    try {
      if (firebaseAuth != null) {
        await firebaseAuth!.signOut();
      } else {
        await _resolvedFirebaseAuth.signOut();
      }
    } catch (_) {}
  }
}
