import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Tema Rock/Energético
  static const Color primary = Color(0xFFFF6B35); // Naranja vibrante
  static const Color primaryDark = Color(0xFFD32F2F); // Rojo oscuro
  static const Color secondary = Color(0xFF6A1B9A); // Púrpura oscuro
  static const Color accent = Color(0xFFFFD700); // Dorado
  static const Color surface = Color(0xFF1A1A1A); // Casi negro
  static const Color background = Color(0xFF0D0D0D); // Negro profundo
  
  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF00BCD4);
  
  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF757575);
  
  // Bordes y divisores
  static const Color border = Color(0xFF424242);
  static const Color divider = Color(0xFF303030);
  
  // Gradientes
  static const List<Color> gradientPrimary = [
    Color(0xFFFF6B35),
    Color(0xFFD32F2F),
  ];
  
  static const List<Color> gradientSecondary = [
    Color(0xFF6A1B9A),
    Color(0xFF3F51B5),
  ];
}