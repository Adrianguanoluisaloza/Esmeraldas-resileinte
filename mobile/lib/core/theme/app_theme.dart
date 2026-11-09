import 'package:flutter/material.dart';

/// Tema visual de Esmeraldas Resiliente con colores semánticos de emergencia y alto contraste.
class AppTheme {
  const AppTheme._();

  static const Color colorPrimario = Color(0xFF0B6E4F);
  static const Color colorSemaforoVerde = Color(0xFF2E7D32);
  static const Color colorSemaforoAmbar = Color(0xFFEF6C00);
  static const Color colorSemaforoRojo = Color(0xFFC62828);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrimario,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
