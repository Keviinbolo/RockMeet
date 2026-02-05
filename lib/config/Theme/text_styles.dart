import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // ============================================
  // CONFIGURACIÓN DE FUENTE BASE
  // ============================================
  
  // Usando Poppins: Moderna, amigable, legible y versátil
  // Perfecta para apps juveniles y dinámicas
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  
  // ============================================
  // TÍTULOS Y ENCABEZADOS
  // ============================================
  
  // Display - Para splash screens y pantallas destacadas
  static TextStyle display = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // H1 - Títulos principales de pantalla
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  // H2 - Títulos secundarios
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  // H3 - Subtítulos importantes
  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );
  
  // H4 - Subtítulos de sección
  static TextStyle h4 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // H5 - Títulos de cards
  static TextStyle h5 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // ============================================
  // TEXTOS DE CUERPO
  // ============================================
  
  // Body Large - Texto principal grande
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  // Body Medium - Texto principal estándar
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  // Body Small - Texto secundario
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Caption - Textos muy pequeños (metadatos, timestamps)
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Overline - Texto decorativo superior
  static TextStyle overline = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 1.2,
  );
  
  // ============================================
  // BOTONES Y LABELS
  // ============================================
  
  // Button Large - Botones principales
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // Button Medium - Botones estándar
  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.3,
  );
  
  // Button Small - Botones pequeños
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.3,
  );
  
  // Label - Etiquetas de formularios
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  // ============================================
  // ESTILOS ESPECIALES
  // ============================================
  
  // Para nombres en tarjetas de perfil
  static TextStyle profileName = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.2,
    shadows: [
      Shadow(
        color: AppColors.dark.withOpacity(0.3),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ],
  );
  
  // Para porcentajes de compatibilidad
  static TextStyle compatibility = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.2,
  );
  
  // Para tags/chips de intereses
  static TextStyle chip = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Para mensajes de chat
  static TextStyle chatMessage = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Para timestamps en chat
  static TextStyle chatTimestamp = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.2,
  );
  
  // ============================================
  // UTILIDADES
  // ============================================
  
  // Aplicar color personalizado a cualquier estilo
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  // Aplicar peso personalizado
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  // Aplicar tamaño personalizado
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}