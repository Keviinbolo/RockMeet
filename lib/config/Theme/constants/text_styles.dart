import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Headline
  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFF6B35),
    letterSpacing: 0.5,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFF6B35),
  );

  static TextStyle headlineSmall = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Title
  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle titleSmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFB0B0B0),
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16,
    color: Colors.white,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14,
    color: Colors.white,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12,
    color: const Color(0xFFB0B0B0),
  );

  // Label
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFF6B35),
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFB0B0B0),
  );

  // Button
  static TextStyle button = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}