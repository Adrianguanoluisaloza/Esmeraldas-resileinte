import 'package:flutter/material.dart';

import '../../../../core/security/validadores.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mapa_fondo_esmeraldas.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';
import 'registro_page.dart';

/// Pantalla de inicio de sesión único sobre el mapa de Esmeraldas (`FlutterMap`).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
    this.onContinuarSinCuenta,
  });

  final AuthRepository authRepository;
  final ValueChanged<UsuarioSesion> onLoginSuccess;
  final VoidCallback? onContinuarSinCuenta;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final UsuarioSesion s = await widget.authRepository.iniciarSesion(
        correo: _correoCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) widget.onLoginSuccess(s);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _conGoogle() async {
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final UsuarioSesion? s = await widget.authRepository
          .iniciarSesionConGoogle();
      if (s != null && mounted) widget.onLoginSuccess(s);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar sesión con Google.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoRecuperarPassword() async {
    final bool? enviado = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => _RecuperarPasswordDialog(
        correoInicial: _correoCtrl.text.trim(),
        onEnviar: (String c) =>
            widget.authRepository.recuperarPassword(correo: c),
      ),
    );

    if (enviado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si ese correo tiene una cuenta, enviamos un enlace para crear una contraseña nueva.',
          ),
          backgroundColor: AppTheme.colorPrimario,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Fondo vectorial: no descarga teselas detrás de la tarjeta, donde la atribución quedaría tapada.
          const Positioned.fill(
            child: MapaFondoEsmeraldas(tieneConexion: false),
          ),
          // Tarjeta centrada en cualquier pantalla; si no cabe (teclado abierto), se desplaza.
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.colorBorde),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              'assets/logo.png',
                              width: 20,
                              height: 23,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ESMERALDAS ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'RESILIENTE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 14,
                                color: AppTheme.colorPrimario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Reporta y gestiona emergencias por El Niño en Esmeraldas. Tus reportes en la cola offline nunca se pierden.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.colorTextoSecundario,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _correoCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const <String>[
                                    AutofillHints.email,
                                  ],
                                  validator: Validadores.correo,
                                  decoration: const InputDecoration(
                                    hintText: 'Correo electrónico',
                                    prefixIcon: Icon(Icons.alternate_email),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _ocultarPass,
                                  autofillHints: const <String>[
                                    AutofillHints.password,
                                  ],
                                  validator: Validadores.passwordLogin,
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _ocultarPass = !_ocultarPass,
                                      ),
                                      icon: Icon(
                                        _ocultarPass
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _cargando
                                        ? null
                                        : _mostrarDialogoRecuperarPassword,
                                    child: const Text(
                                      'Olvidé mi contraseña',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.colorPrimario,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...<Widget>[
                                  const SizedBox(height: 10),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppTheme.colorSemaforoRojo,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.colorSemaforoRojo,
                                  ),
                                  onPressed: _cargando ? null : _iniciarSesion,
                                  icon: const Icon(Icons.login),
                                  label: Text(
                                    _cargando ? 'Entrando...' : 'Entrar',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GoogleSignInButton(
                                  cargando: _cargando,
                                  onPressed: _conGoogle,
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _cargando
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => RegistroPage(
                                                authRepository:
                                                    widget.authRepository,
                                                onRegistroExitoso:
                                                    (UsuarioSesion s) {
                                                      Navigator.of(context)
                                                          .pop();
                                                      widget.onLoginSuccess(s);
                                                    },
                                              ),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    '¿No tienes cuenta? Crear cuenta ciudadana',
                                  ),
                                ),
                                if (widget.onContinuarSinCuenta != null)
                                  TextButton.icon(
                                    onPressed: widget.onContinuarSinCuenta,
                                    icon: const Icon(
                                      Icons.airplanemode_active,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Emergencia sin internet: reportar ahora',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecuperarPasswordDialog extends StatefulWidget {
  const _RecuperarPasswordDialog({
    required this.correoInicial,
    required this.onEnviar,
  });

  final String correoInicial;
  final Future<void> Function(String correo) onEnviar;

  @override
  State<_RecuperarPasswordDialog> createState() =>
      _RecuperarPasswordDialogState();
}

class _RecuperarPasswordDialogState extends State<_RecuperarPasswordDialog> {
  late final TextEditingController _ctrl;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.correoInicial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.onEnviar(_ctrl.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = e.mensaje;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = 'Error de red al solicitar recuperación.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.lock_reset,
        color: AppTheme.colorPrimario,
        size: 28,
      ),
      title: const Text(
        'Recuperar contraseña',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Ingresa tu correo para recibir un enlace de recuperación. La contraseña nueva se crea en la web.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.colorTextoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.emailAddress,
              validator: Validadores.correo,
              decoration: const InputDecoration(
                hintText: 'Correo electrónico',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.colorSemaforoRojo,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: Text(_enviando ? 'Enviando...' : 'Enviar enlace'),
        ),
      ],
    );
  }
}
