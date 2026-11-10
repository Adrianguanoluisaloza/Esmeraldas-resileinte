import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/data/services/google_auth_service.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value != null) _data[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async => _data.remove(key);
}

class FakeGoogleAuthService extends GoogleAuthService {
  FakeGoogleAuthService({
    this.tokenSimulado = 'fake-firebase-token-xyz',
    this.cancelar = false,
    this.errorSimulado,
  });

  final String? tokenSimulado;
  final bool cancelar;
  final Exception? errorSimulado;

  @override
  Future<String?> obtenerFirebaseIdToken() async {
    if (errorSimulado != null) throw errorSimulado!;
    if (cancelar) return null;
    return tokenSimulado;
  }
}

class TestHttpAdapter implements HttpClientAdapter {
  TestHttpAdapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions options) responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => responder(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group(
    'SecureStorageAuthRepository con dobles (sin red ni Firebase real)',
    () {
      late FakeSecureStorage storage;
      late Dio dio;

      setUp(() {
        storage = FakeSecureStorage();
        dio = Dio(BaseOptions(baseUrl: 'https://api.test.ec'));
      });

      test('1. Google correcto: intercambia idToken en /auth/firebase y guarda sesión', () async {
        String? endpointLlamado;
        Map<String, dynamic>? cuerpoEnviado;

        dio.httpClientAdapter = TestHttpAdapter((RequestOptions o) async {
          endpointLlamado = o.path;
          cuerpoEnviado = o.data is Map
              ? Map<String, dynamic>.from(o.data as Map)
              : null;

          final Map<String, dynamic> respuesta = <String, dynamic>{
            'token': 'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6InVzci0xMjMiLCJyb2wiOiJjaXVkYWRhbm8iLCJleHAiOjE5OTk5OTk5OTl9.signature',
            'usuario': <String, dynamic>{
              'id': 'usr-123',
              'nombre': 'Adrian Lozada',
              'correo': 'adrian@esmeraldas.ec',
              'rol': 'ciudadano',
            },
          };

          return ResponseBody.fromString(
            jsonEncode(respuesta),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });

        final FakeGoogleAuthService googleService = FakeGoogleAuthService(
          tokenSimulado: 'firebase-token-777',
        );
        final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
          secureStorage: storage,
          dio: dio,
          googleAuthService: googleService,
        );

        final UsuarioSesion? sesion = await repo.iniciarSesionConGoogle();

        expect(sesion, isNotNull);
        expect(sesion!.id, 'usr-123');
        expect(sesion.correo, 'adrian@esmeraldas.ec');
        expect(sesion.proveedor, 'google');
        expect(endpointLlamado, '/auth/firebase');
        expect(cuerpoEnviado?['idToken'], 'firebase-token-777');

        final String? tokenGuardado = await repo.obtenerTokenSeguro();
        expect(tokenGuardado, isNotNull);
      });

      test('2. Google cancelado: devuelve null sin llamar al servidor ni guardar token', () async {
        bool llamado = false;
        dio.httpClientAdapter = TestHttpAdapter((_) async {
          llamado = true;
          return ResponseBody.fromString('{}', 200);
        });

        final FakeGoogleAuthService googleService = FakeGoogleAuthService(
          cancelar: true,
        );
        final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
          secureStorage: storage,
          dio: dio,
          googleAuthService: googleService,
        );

        final UsuarioSesion? sesion = await repo.iniciarSesionConGoogle();

        expect(sesion, isNull);
        expect(llamado, isFalse);
        expect(await repo.obtenerTokenSeguro(), isNull);
      });

      test(
        '3. Error de red al contactar al servidor: lanza AuthException clara',
        () async {
          dio.httpClientAdapter = TestHttpAdapter((RequestOptions o) async {
            throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
              error: 'Connection refused',
            );
          });

          final FakeGoogleAuthService googleService = FakeGoogleAuthService();
          final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
            secureStorage: storage,
            dio: dio,
            googleAuthService: googleService,
          );

          expect(
            () => repo.iniciarSesionConGoogle(),
            throwsA(
              isA<AuthException>().having(
                (e) => e.mensaje,
                'mensaje',
                contains('Sin conexión con el servidor'),
              ),
            ),
          );
        },
      );

      test('4. Error 401 del servidor: token inválido o vencido', () async {
        dio.httpClientAdapter = TestHttpAdapter((RequestOptions o) async {
          return ResponseBody.fromString(
            jsonEncode(<String, dynamic>{
              'codigo': 'NO_AUTENTICADO',
              'mensaje': 'Token de Firebase inválido o vencido',
            }),
            401,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });

        final FakeGoogleAuthService googleService = FakeGoogleAuthService();
        final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
          secureStorage: storage,
          dio: dio,
          googleAuthService: googleService,
        );

        expect(
          () => repo.iniciarSesionConGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('inválido o expirado'),
            ),
          ),
        );
      });

      test(
        '5. Recuperar contraseña: llama a POST /auth/recuperar con 202',
        () async {
          String? path;
          Map<String, dynamic>? data;

          dio.httpClientAdapter = TestHttpAdapter((RequestOptions o) async {
            path = o.path;
            data = o.data is Map
                ? Map<String, dynamic>.from(o.data as Map)
                : null;
            return ResponseBody.fromString('{}', 202);
          });

          final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
            secureStorage: storage,
            dio: dio,
          );

          await repo.recuperarPassword(correo: 'usuario@esmeraldas.ec');

          expect(path, '/auth/recuperar');
          expect(data?['correo'], 'usuario@esmeraldas.ec');
        },
      );
    },
  );

  group('LoginPage UI: Interacción con dobles', () {
    testWidgets(
      'Cancelación de Google vuelve al login sin mostrar error en pantalla',
      (WidgetTester tester) async {
        final FakeGoogleAuthService googleService = FakeGoogleAuthService(
          cancelar: true,
        );
        final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
          secureStorage: FakeSecureStorage(),
          googleAuthService: googleService,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: LoginPage(authRepository: repo, onLoginSuccess: (_) {}),
          ),
        );

        // Buscar botón Google
        final Finder botonGoogle = find.text('Continuar con Google');
        expect(botonGoogle, findsOneWidget);

        await tester.tap(botonGoogle);
        await tester.pumpAndSettle();

        // No debe mostrar ningún mensaje de error
        expect(find.byType(SnackBar), findsNothing);
        expect(find.textContaining('cancelado'), findsNothing);
        expect(find.textContaining('Error'), findsNothing);
        // El formulario sigue visible
        expect(find.text('Iniciar sesión'), findsOneWidget);
      },
    );

    testWidgets('Error en Google muestra mensaje claro en pantalla', (
      WidgetTester tester,
    ) async {
      final FakeGoogleAuthService googleService = FakeGoogleAuthService(
        errorSimulado: const AuthException(
          'No se pudo validar tu cuenta en el servidor.',
        ),
      );
      final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
        secureStorage: FakeSecureStorage(),
        googleAuthService: googleService,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LoginPage(authRepository: repo, onLoginSuccess: (_) {}),
        ),
      );

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo validar tu cuenta en el servidor.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Flujo "Olvidé mi contraseña" abre diálogo y muestra mensaje exacto',
      (WidgetTester tester) async {
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test.ec'));
        dio.httpClientAdapter = TestHttpAdapter((RequestOptions o) async {
          return ResponseBody.fromString('{}', 202);
        });

        final SecureStorageAuthRepository repo = SecureStorageAuthRepository(
          secureStorage: FakeSecureStorage(),
          dio: dio,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: LoginPage(authRepository: repo, onLoginSuccess: (_) {}),
          ),
        );

        // Presionar "Olvidé mi contraseña"
        final Finder botonOlvide = find.text('Olvidé mi contraseña');
        expect(botonOlvide, findsOneWidget);
        await tester.tap(botonOlvide);
        await tester.pumpAndSettle();

        // Diálogo abierto
        expect(find.text('Recuperar contraseña'), findsOneWidget);
        expect(
          find.text(
            'Ingresa tu correo para recibir un enlace de recuperación. La contraseña nueva se crea en la web.',
          ),
          findsOneWidget,
        );

        // Ingresar correo dentro del diálogo
        final Finder campoCorreo = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(campoCorreo, 'ciudadano@esmeraldas.ec');
        await tester.pumpAndSettle();

        // Presionar "Enviar enlace"
        await tester.tap(find.text('Enviar enlace'));
        await tester.pumpAndSettle();

        // Diálogo cerrado y mensaje exacto mostrado en SnackBar
        expect(find.text('Recuperar contraseña'), findsNothing);
        expect(
          find.text(
            'Si ese correo tiene una cuenta, enviamos un enlace para crear una contraseña nueva.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
