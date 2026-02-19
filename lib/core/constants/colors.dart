import 'package:flutter/material.dart';

class AppColors {
  // ============================================
  // COLORES PRINCIPALES DE ROCAMEET
  // ============================================
  
  // Amarillo vibrante - Color principal (energía, juventud)
  static const Color primary = Color(0xFFFFC629);
  static const Color primaryDark = Color(0xFFE6B024);
  static const Color primaryLight = Color(0xFFFFD454);
  
  // Naranja - Color de acción (like, énfasis)
  static const Color orange = Color(0xFFFF6036);
  static const Color orangeDark = Color(0xFFE6562F);
  static const Color orangeLight = Color(0xFFFF7D5C);
  
  // Rosa/Magenta - Color secundario (matches, amor)
  static const Color secondary = Color(0xFFFF3D8E);
  static const Color secondaryDark = Color(0xFFE6377F);
  static const Color secondaryLight = Color(0xFFFF5FA1);
  
  // Verde oscuro - Color de contraste y texto principal
  static const Color dark = Color(0xFF1D2E2D);
  static const Color darkLight = Color(0xFF2A4140);
  
  // Gris claro - Fondos y elementos secundarios
  static const Color lightGray = Color(0xFFD0D0D0);
  static const Color gray = Color(0xFFE8E8E8);
  static const Color grayDark = Color(0xFFB0B0B0);
  
  // Blanco - Fondos principales
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  
  // ============================================
  // APLICACIÓN DE COLORES POR CONTEXTO
  // ============================================
  
  // Fondos
  static const Color background = Color(0xFFFAFAFA); // Off-white suave
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Textos
  static const Color textPrimary = Color(0xFF1D2E2D); // Verde oscuro
  static const Color textSecondary = Color(0xFF6B7C7B); // Verde oscuro claro
  static const Color textHint = Color(0xFFB0B0B0); // Gris
  static const Color textOnPrimary = Color(0xFF1D2E2D); // Texto sobre amarillo
  static const Color textOnDark = Color(0xFFFFFFFF); // Texto sobre verde oscuro
  
  // Estados y acciones
  static const Color success = Color(0xFF4CAF50); // Verde estándar
  static const Color error = Color(0xFFFF6036); // Naranja (reutilizado)
  static const Color warning = Color(0xFFFFC629); // Amarillo (reutilizado)
  static const Color info = Color(0xFF2196F3); // Azul estándar
  
  // Acciones específicas
  static const Color like = Color(0xFFFF3D8E); // Rosa para likes/matches
  static const Color dislike = Color(0xFFD0D0D0); // Gris para skip
  static const Color superLike = Color(0xFFFFC629); // Amarillo para super like
  
  // ============================================
  // GRADIENTES
  // ============================================
  
  // Gradiente principal (amarillo a naranja)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFC629), Color(0xFFFF6036)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradiente secundario (naranja a rosa)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFF6036), Color(0xFFFF3D8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Gradiente suave para fondos
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Gradiente para overlays oscuros
  static LinearGradient darkOverlay = LinearGradient(
    colors: [
      const Color(0xFF1D2E2D).withOpacity(0.0),
      const Color(0xFF1D2E2D).withOpacity(0.8),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.4, 1.0],
  );
  
  // Gradiente vibrante para CTAs
  static const LinearGradient vibrantGradient = LinearGradient(
    colors: [Color(0xFFFFC629), Color(0xFFFF3D8E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // ============================================
  // SOMBRAS
  // ============================================
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1D2E2D).withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF1D2E2D).withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: const Color(0xFF1D2E2D).withOpacity(0.16),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Sombras de colores para efectos especiales
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: const Color(0xFFFFC629).withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get likeShadow => [
    BoxShadow(
      color: const Color(0xFFFF3D8E).withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  // ============================================
  // CATEGORÍAS DE EVENTOS
  // ============================================
  
  static Color getEventCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'deportes':
        return const Color(0xFF4CAF50); // Verde
      case 'cultura':
        return const Color(0xFFFF3D8E); // Rosa
      case 'académico':
      case 'academico':
        return const Color(0xFFFFC629); // Amarillo
      case 'tecnología':
      case 'tecnologia':
        return const Color(0xFF2196F3); // Azul
      case 'social':
        return const Color(0xFFFF6036); // Naranja
      default:
        return const Color(0xFFD0D0D0); // Gris
    }
  }
  
  // ============================================
  // UTILIDADES
  // ============================================
  
  // Obtener color con opacidad
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // Verificar si un color es claro u oscuro
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
  
  // Obtener color de texto apropiado según el fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLightColor(backgroundColor) ? textPrimary : white;
  }
}