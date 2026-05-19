import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Tema Azul/Blanco
  static const Color primary = Color(0xFF1976D2); // Azul
  static const Color primaryDark = Color(0xFF1565C0); // Azul oscuro
  static const Color secondary = Color(0xFF42A5F5); // Azul claro
  static const Color accent = Color(0xFF0288D1); // Azul acento
  static const Color surface = Color(0xFFFFFFFF); // Blanco
  static const Color background = Color(0xFFF0F4FF); // Azul muy claro

  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF00BCD4);

  // Textos
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);

  // Bordes y divisores
  static const Color border = Color(0xFFBBDEFB);
  static const Color divider = Color(0xFFE3F2FD);

  // Gradientes
  static const List<Color> gradientPrimary = [
    Color(0xFF1976D2),
    Color(0xFF42A5F5),
  ];

  static const List<Color> gradientSecondary = [
    Color(0xFF42A5F5),
    Color(0xFF0288D1),
  ];
}