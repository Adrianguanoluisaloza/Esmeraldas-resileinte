import 'package:flutter/material.dart';

import '../enums/app_enums.dart';

/// Tema visual de Esmeraldas Resiliente alineado con `docs/DISENO.md` y `TAREAS_MOVIL_FRANCO.md` (M4).
class AppTheme {
  AppTheme._();

  // Paleta oficial (`docs/DISENO.md`)
  static const Color colorPrimario = Color(0xFF0B6E4F);
  static const Color colorSemaforoVerde = Color(0xFF2E7D32);
  static const Color colorSemaforoAmbar = Color(0xFFEF6C00);
  static const Color colorSemaforoRojo = Color(0xFFC62828);
  static const Color colorEmergencia = Color(0xFFC62828);

  // Origen del dato (M4)
  static const Color colorOrigenSimulado = Color(0xFF5B4BC4);
  static const Color colorOrigenOficial = Color(0xFF1F4FB8);

  // Superficie y texto (`docs/DISENO.md`)
  static const Color colorFondo = Color(0xFFF5F7F5);
  static const Color colorSuperficie = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDCE3DE);
  static const Color colorCampo = Color(0xFFEEF2EF);
  static const Color colorTexto = Color(0xFF13201A);
  static const Color colorTextoSecundario = Color(0xFF36463E);
  static const Color colorTextoApagado = Color(0xFF5F6F67);

  static Color colorGravedad(GravedadIncidente g) => switch (g) {
    GravedadIncidente.baja => const Color(0xFF546E7A),
    GravedadIncidente.media => const Color(0xFFB26A00),
    GravedadIncidente.alta => const Color(0xFFEF6C00),
    GravedadIncidente.critica => const Color(0xFFC62828),
  };

  static (Color fondo, Color texto) colorEstado(EstadoReporte e) => switch (e) {
    EstadoReporte.pendiente => (
      const Color(0xFFFDECEA),
      const Color(0xFFC62828),
    ),
    EstadoReporte.enProceso => (
      const Color(0xFFFFF3E0),
      const Color(0xFFEF6C00),
    ),
    EstadoReporte.atendido => (
      const Color(0xFFE8F5E9),
      const Color(0xFF2E7D32),
    ),
    EstadoReporte.descartado => (
      const Color(0xFFECEFF1),
      const Color(0xFF546E7A),
    ),
  };

  static Color colorCupo(double ratio) => ratio < 0.7
      ? colorSemaforoVerde
      : ratio < 0.9
      ? colorSemaforoAmbar
      : colorSemaforoRojo;

  /// Etiqueta accesible para el semáforo de cupo (M5: nunca solo color).
  static String etiquetaCupo(double ratio) => ratio < 0.7
      ? 'Con cupo'
      : ratio < 1.0
      ? 'Casi sin cupo'
      : 'Lleno';

  static Color colorRol(RolUsuario r) => switch (r) {
    RolUsuario.ciudadano => colorPrimario,
    RolUsuario.operador911 => colorSemaforoAmbar,
    RolUsuario.bomberos => colorSemaforoRojo,
    RolUsuario.policia => colorOrigenOficial,
    RolUsuario.admin => colorOrigenOficial,
  };

  static String etiquetaRol(RolUsuario r) => switch (r) {
    RolUsuario.ciudadano => 'Ciudadano',
    RolUsuario.operador911 => 'ECU 911',
    RolUsuario.bomberos => 'Bomberos',
    RolUsuario.policia => 'Policía',
    RolUsuario.admin => 'Admin',
  };

  static ThemeData get lightTheme {
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: colorPrimario,
      primary: colorPrimario,
      error: colorSemaforoRojo,
      surface: colorSuperficie,
      brightness: Brightness.light,
    );
    final OutlineInputBorder bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: colorBorde),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: colorFondo,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorSuperficie,
        foregroundColor: colorTexto,
        titleTextStyle: TextStyle(
          color: colorTexto,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorSuperficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: colorBorde),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorCampo,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: colorPrimario, width: 1.5),
        ),
        errorBorder: bordeCampo.copyWith(
          borderSide: const BorderSide(color: colorSemaforoRojo),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: colorBorde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorSuperficie,
        indicatorColor: colorPrimario.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Insignia para diferenciar Dato simulado y Alerta oficial.
class InsigniaOrigenDato extends StatelessWidget {
  const InsigniaOrigenDato({
    super.key,
    required this.esOficial,
    this.etiquetaPersonalizada,
  });

  final bool esOficial;
  final String? etiquetaPersonalizada;

  @override
  Widget build(BuildContext context) {
    final Color color = esOficial
        ? AppTheme.colorOrigenOficial
        : AppTheme.colorOrigenSimulado;
    final String texto =
        etiquetaPersonalizada ??
        (esOficial ? 'Alerta oficial' : 'Dato simulado');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            esOficial ? Icons.verified_outlined : Icons.science_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
