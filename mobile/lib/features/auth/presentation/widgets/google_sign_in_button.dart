import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Botón oficial de inicio de sesión con Google (OAuth 2.0 + PKCE).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.cargando = false,
    this.texto = 'Continuar con Google',
  });

  final VoidCallback? onPressed;
  final bool cargando;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: cargando ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.colorTexto,
        side: const BorderSide(color: Color(0xFFDADCE0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const _LogoGoogle(),
          const SizedBox(width: 12),
          Text(
            cargando ? 'Conectando con Google...' : texto,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4285F4), width: 2),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
  }
}
