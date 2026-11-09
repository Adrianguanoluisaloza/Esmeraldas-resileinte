import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/validadores.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mapa_fondo_esmeraldas.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';
import 'registro_page.dart';

/// Pantalla de inicio de sesión único sobre el mapa de Esmeraldas (`FlutterMap`).
/// Cero emojis (M4) y soporte para las credenciales demo de `TAREAS_MOVIL_FRANCO.md` (M2).
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
      final UsuarioSesion s = await widget.authRepository
          .iniciarSesionConGoogle();
      if (mounted) widget.onLoginSuccess(s);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _rellenarDemo(String correo, String pass) {
    _correoCtrl.text = correo;
    _passCtrl.text = pass;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MapaFondoEsmeraldas()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.shield,
                        color: AppTheme.colorSemaforoRojo,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ESMERALDAS ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                      Text(
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
                            autofillHints: const <String>[AutofillHints.email],
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
                            label: Text(_cargando ? 'Entrando...' : 'Entrar'),
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
                                          authRepository: widget.authRepository,
                                          onRegistroExitoso: (UsuarioSesion s) {
                                            Navigator.of(context).pop();
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
                if (AppConfig.modoDemo) ...<Widget>[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              InsigniaOrigenDato(esOficial: false),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cuentas de demostración (toca para rellenar):',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _BotonDemo(
                            icono: Icons.person_outline,
                            etiqueta: 'Reporte ciudadano — ciudadano@demo.esmeraldas-resiliente.ec',
                            onTap: () => _rellenarDemo(
                              'ciudadano@demo.esmeraldas-resiliente.ec',
                              'demo-resiliente-2026',
                            ),
                          ),
                          _BotonDemo(
                            icono: Icons.support_agent,
                            etiqueta: 'Operador 911 — operador@demo.esmeraldas-resiliente.ec',
                            onTap: () => _rellenarDemo(
                              'operador@demo.esmeraldas-resiliente.ec',
                              'demo-resiliente-2026',
                            ),
                          ),
                          _BotonDemo(
                            icono: Icons.admin_panel_settings_outlined,
                            etiqueta: 'Administrador — admin@demo.esmeraldas-resiliente.ec',
                            onTap: () => _rellenarDemo(
                              'admin@demo.esmeraldas-resiliente.ec',
                              'demo-resiliente-2026',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonDemo extends StatelessWidget {
  const _BotonDemo({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.colorBorde),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(icono, size: 16, color: AppTheme.colorPrimario),
              const SizedBox(width: 8),
              Expanded(
                child: Text(etiqueta, style: const TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
