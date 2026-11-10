import 'package:mobile/features/auth/data/services/google_auth_service.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _UsuarioFalso implements User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'token-firebase';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CredencialFalsa implements UserCredential {
  _CredencialFalsa(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthFalso implements FirebaseAuth {
  _AuthFalso({this.error, this.usuario});

  final FirebaseAuthException? error;
  final User? usuario;
  int ventanasAbiertas = 0;

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    ventanasAbiertas++;
    if (error != null) throw error!;
    return _CredencialFalsa(usuario);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Google en el navegador', () {
    test('devuelve el token de Firebase tras la ventana', () async {
      final _AuthFalso auth = _AuthFalso(usuario: _UsuarioFalso());
      final GoogleAuthService servicio = GoogleAuthService(
        firebaseAuth: auth,
        esWeb: true,
      );

      expect(await servicio.obtenerFirebaseIdToken(), 'token-firebase');
      expect(auth.ventanasAbiertas, 1);
    });

    test('cerrar la ventana cuenta como cancelación', () async {
      final GoogleAuthService servicio = GoogleAuthService(
        firebaseAuth: _AuthFalso(
          error: FirebaseAuthException(code: 'popup-closed-by-user'),
        ),
        esWeb: true,
      );

      expect(await servicio.obtenerFirebaseIdToken(), isNull);
    });

    test('ventana bloqueada da un mensaje claro', () async {
      final GoogleAuthService servicio = GoogleAuthService(
        firebaseAuth: _AuthFalso(
          error: FirebaseAuthException(code: 'popup-blocked'),
        ),
        esWeb: true,
      );

      expect(
        servicio.obtenerFirebaseIdToken(),
        throwsA(
          isA<AuthException>().having(
            (AuthException e) => e.mensaje,
            'mensaje',
            contains('ventanas emergentes'),
          ),
        ),
      );
    });

    test('sin usuario falla con error de autenticación', () async {
      final GoogleAuthService servicio = GoogleAuthService(
        firebaseAuth: _AuthFalso(),
        esWeb: true,
      );

      expect(servicio.obtenerFirebaseIdToken(), throwsA(isA<AuthException>()));
    });
  });
}
