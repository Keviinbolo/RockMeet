import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/config/Theme/constants/text_styles.dart';


class MatchModal extends StatelessWidget {
  final Map profile; // Reemplaza con tu modelo Profile
  final VoidCallback onClose;
  final VoidCallback onSendMessage;

  const MatchModal({
    super.key,
    required this.profile,
    required this.onClose,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ============================================================
          // EFECTO 1:  CAYENDO (Confetti)
          // ============================================================
          ...List.generate(20, (index) => const _FallingHeart()),

          // Botón de cerrar (X)
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: AppColors.textPrimary,
              onPressed: onClose,
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ============================================================
                  // EFECTO 2: TEXTO "¡Es un Match!"
                  // ============================================================
                  ElasticInDown(
                    delay: const Duration(milliseconds: 200),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.gradientPrimary,
                      ).createShader(bounds),
                      child: Text(
                        '¡Es un Match!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayLarge.copyWith(
                          fontSize: 48,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ============================================================
                  // EFECTO 3: FOTOS DE PERFILES
                  // ============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tu Foto (Izquierda)
                      BounceInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: const _ProfileAvatar(
                          imageUrl:
                              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&h=400&fit=crop',
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Corazón Central con Brillo
                      ZoomIn(
                        delay: const Duration(milliseconds: 600),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows,
                            color: AppColors.primary,
                            size: 60,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Foto del Match (Derecha)
                      BounceInRight(
                        delay: const Duration(milliseconds: 400),
                        child: _ProfileAvatar(imageUrl: profile['image']),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ============================================================
                  // EFECTO 4: MENSAJE DE CONFIRMACIÓN
                  // ============================================================
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: Text(
                      '¡A ${profile['name']} también le gustas!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ============================================================
                  // EFECTO 5: BOTONES DE ACCIÓN
                  // ============================================================
                  FadeInUp(
                    delay: const Duration(seconds: 1),
                    child: Column(
                      children: [
                        _ActionButton(
                          text: 'Enviar mensaje',
                          isGradient: true,
                          icon: Icons.message,
                          onPressed: () {
                            Navigator.pop(context);
                            onSendMessage();
                          },
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          text: 'Seguir viendo',
                          isGradient: false,
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para las fotos circulares
class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  const _ProfileAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 4,
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Widget auxiliar para los corazones que caen
class _FallingHeart extends StatelessWidget {
  const _FallingHeart();

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final double startX =
        random.nextDouble() * MediaQuery.of(context).size.width;
    final int duration = 3 + random.nextInt(2);

    return FadeInDown(
      duration: Duration(seconds: duration),
      from: -50,
      child: Container(
        alignment: Alignment(
          (startX / MediaQuery.of(context).size.width) * 2 - 1,
          -1.2,
        ),
        child: TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 3),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(
                0,
                value * MediaQuery.of(context).size.height * 1.2,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Widget para botones estilizados
class _ActionButton extends StatelessWidget {
  final String text;
  final bool isGradient;
  final IconData? icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.isGradient,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = isGradient
        ? AppTheme.primaryGradientBox.copyWith(
            borderRadius: BorderRadius.circular(30),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.textPrimary,
            ),
          );

    final TextStyle textStyle = AppTextStyles.button.copyWith(
      fontSize: 16,
      color: isGradient ? Colors.white : AppColors.textPrimary,
    );

    final Color iconColor =
        isGradient ? Colors.white : AppColors.textPrimary;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}
