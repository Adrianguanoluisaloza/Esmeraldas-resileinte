/// Validaciones de formularios de autenticación. El servidor repite las mismas reglas.
class Validadores {
  const Validadores._();

  static final RegExp _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? nombre(String? v) {
    final String t = (v ?? '').trim();
    if (t.length < 3) return 'Ingresa tu nombre completo';
    if (t.length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  static String? correo(String? v) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa tu correo';
    if (!_correo.hasMatch(t) || t.length > 120) return 'Correo no válido';
    return null;
  }

  static String? passwordLogin(String? v) =>
      (v ?? '').isEmpty ? 'Ingresa tu contraseña' : null;

  /// Contraseña fuerte: 10+ caracteres, mayúscula, minúscula, número y símbolo.
  static String? passwordNueva(String? v) {
    final String p = v ?? '';
    if (p.length < 10) return 'Mínimo 10 caracteres';
    if (!RegExp('[A-Z]').hasMatch(p)) return 'Incluye una mayúscula';
    if (!RegExp('[a-z]').hasMatch(p)) return 'Incluye una minúscula';
    if (!RegExp(r'\d').hasMatch(p)) return 'Incluye un número';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) return 'Incluye un símbolo';
    return null;
  }

  /// Fuerza de 0 a 4 para la barra visual del registro.
  static int fuerza(String p) {
    int f = 0;
    if (p.length >= 10) f++;
    if (RegExp('[A-Z]').hasMatch(p) && RegExp('[a-z]').hasMatch(p)) f++;
    if (RegExp(r'\d').hasMatch(p)) f++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) f++;
    return f;
  }
}
