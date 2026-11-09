import 'package:flutter/material.dart';

import '../../../../core/security/validadores.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';

/// Pantalla de registro ciudadano (`POST /auth/registro`).
/// El rol siempre es `ciudadano` y lo asigna el servidor, nunca el cliente.
class RegistroPage extends StatefulWidget {
  const RegistroPage({
    super.key,
    required this.authRepository,
    required this.onRegistroExitoso,
  });

  final AuthRepository authRepository;
  final ValueChanged<UsuarioSesion> onRegistroExitoso;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _ocultarPass = true;
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _errorServidor;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _errorServidor = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      setState(() => _errorServidor = 'Acepta el uso de datos de emergencia.');
      return;
    }
    setState(() => _cargando = true);
    try {
      final UsuarioSesion s = await widget.authRepository.registrar(
        nombre: _nombreCtrl.text,
        correo: _correoCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) widget.onRegistroExitoso(s);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorServidor = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _conGoogle() async {
    setState(() {
      _errorServidor = null;
      _cargando = true;
    });
    try {
      final UsuarioSesion s = await widget.authRepository
          .iniciarSesionConGoogle();
      if (mounted) widget.onRegistroExitoso(s);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorServidor = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int fuerza = Validadores.fuerza(_passCtrl.text);
    final List<Color> coloresFuerza = <Color>[
      Colors.grey,
      AppTheme.colorSemaforoRojo,
      AppTheme.colorSemaforoAmbar,
      Colors.lightGreen,
      AppTheme.colorSemaforoVerde,
    ];
    final List<String> textosFuerza = <String>[
      'Mín. 10 caracteres, mayúscula, minúscula, número y símbolo',
      'Contraseña muy débil',
      'Contraseña regular',
      'Contraseña buena',
      'Contraseña fuerte',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('CREAR CUENTA CIUDADANA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Registro ciudadano',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tu cuenta se crea con rol ciudadano. Las cuentas de 911 y administración solo las asigna un administrador.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const <String>[AutofillHints.name],
                        validator: Validadores.nombre,
                        decoration: const InputDecoration(
                          hintText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          AutofillHints.newPassword,
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: Validadores.passwordNueva,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _ocultarPass = !_ocultarPass),
                            icon: Icon(
                              _ocultarPass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fuerza / 4,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: coloresFuerza[fuerza],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textosFuerza[fuerza],
                        style: TextStyle(
                          fontSize: 11,
                          color: coloresFuerza[fuerza],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _ocultarPass,
                        validator: (String? v) => v == _passCtrl.text
                            ? null
                            : 'Las contraseñas no coinciden',
                        decoration: const InputDecoration(
                          hintText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _aceptaTerminos,
                        onChanged: (bool? v) =>
                            setState(() => _aceptaTerminos = v ?? false),
                        title: const Text(
                          'Autorizo el uso de ubicación y fotos únicamente para la atención de emergencias.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      if (_errorServidor != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          _errorServidor!,
                          style: const TextStyle(
                            color: AppTheme.colorSemaforoRojo,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.colorSemaforoRojo,
                        ),
                        onPressed: _cargando ? null : _registrar,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(
                          _cargando ? 'Creando cuenta...' : 'Crear cuenta',
                        ),
                      ),
                      const SizedBox(height: 12),
                      GoogleSignInButton(
                        cargando: _cargando,
                        texto: 'Registrarse con Google',
                        onPressed: _conGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
