import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';

/// Pantalla de inicio de sesión ciudadano / operador.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
  });

  final AuthRepository authRepository;
  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _correoController = TextEditingController(
    text: 'ciudadano@esmeraldas.gob.ec',
  );
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() => _cargando = true);
    try {
      await widget.authRepository.iniciarSesion(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onLoginSuccess();
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso — Esmeraldas Resiliente')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Tus reportes en cola offline se conservan aunque tu sesión expire.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _cargando ? null : _iniciarSesion,
              icon: const Icon(Icons.login),
              label: Text(_cargando ? 'Ingresando...' : 'Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
