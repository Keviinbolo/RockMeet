import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';

class AppTheme {
  // ===== DECORACIONES PREDETERMINADAS =====
  
  static BoxDecoration get primaryGradientBox => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.gradientPrimary,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.6),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  static BoxDecoration get secondaryGradientBox => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.gradientSecondary,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.secondary.withOpacity(0.6),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  static BoxDecoration get cardBox => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration get accentBox => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.primary, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  );

  // ===== DECORACIONES PARA EVENTOS =====
  
  static BoxDecoration get eventCardBox => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration get eventHeaderGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.gradientPrimary,
    ),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
  );

  static BoxDecoration get filterButtonActive => BoxDecoration(
    color: AppColors.primary,
    border: Border.all(
      color: AppColors.primary,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration get filterButtonInactive => BoxDecoration(
    color: Colors.transparent,
    border: Border.all(
      color: AppColors.border,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
  );

  // ===== TEXT STYLES PARA EVENTOS =====
  
  static TextStyle get eventTitle => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle get eventDescription => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle get eventLabel => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.primary,
  );

  static TextStyle get eventDetailLabel => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.primary,
  );

  static TextStyle get eventDetailValue => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static TextStyle get filterButtonLabel => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get emptyStateTitle => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ===== LIGHT THEME =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      error: AppColors.error,
      background: AppColors.background,
    ),
    appBarTheme: AppBarTheme(
      elevation: 2,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE8F4FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.outfit(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.focused)) {
          return AppColors.primary;
        }
        return AppColors.textSecondary;
      }),
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
    ),
  );

  // ===== DARK THEME =====
  // Paleta ahora blanco/azul — brightness.light para que los textos sean oscuros
  // sobre fondos claros, manteniendo ThemeMode.dark como modo activo.
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      ),
      centerTitle: true,
      shadowColor: AppColors.primary.withOpacity(0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE8F4FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.outfit(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.outfit(
        color: AppColors.textHint,
      ),
      prefixIconColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.focused)) {
          return AppColors.primary;
        }
        return AppColors.textSecondary;
      }),
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: AppColors.surface,
      shadowColor: AppColors.primary.withOpacity(0.15),
    ),
  );
}