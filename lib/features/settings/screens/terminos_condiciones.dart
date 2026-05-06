import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header con gradiente
          Container(
            decoration: AppTheme.primaryGradientBox,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'Términos y Condiciones',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Contenido desplazable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection(
                  title: '1. Aceptación de los Términos',
                  content:
                      'Al acceder y utilizar RockMeet, aceptas estar vinculado por estos términos y condiciones. Si no estás de acuerdo con alguna parte de estos términos, no debes utilizar nuestra aplicación.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '2. Uso de la Aplicación',
                  content:
                      'Te comprometes a utilizar RockMeet solo con fines legales y de una manera que no infrinja los derechos de otros o restrinja su uso y disfrute. El comportamiento prohibido incluye acosar o causar angustia o inconveniencia a cualquier persona, trasmitir obscenidades u contenido ofensivo, o perturbar el ritmo normal del diálogo dentro de nuestra plataforma.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '3. Contenido del Usuario',
                  content:
                      'Eres responsable de todo el contenido que publiques en RockMeet. Declaras y garantizas que posees o tienes el control necesario sobre todo el contenido que envías. El contenido que publiques no debe:',
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint('Ser obsceno o pornográfico', isDark),
                      _buildBulletPoint('Contener abuso o explotación de menores', isDark),
                      _buildBulletPoint('Infringir derechos de propiedad intelectual', isDark),
                      _buildBulletPoint('Contener virus o código malicioso', isDark),
                    ],
                  ),
                ),
                _buildSection(
                  title: '4. Privacidad',
                  content:
                      'Tu privacidad es importante para nosotros. Consulta nuestra Política de Privacidad para entender nuestras prácticas respecto a la recopilación y el uso de tu información personal.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '5. Limitación de Responsabilidad',
                  content:
                      'RockMeet se proporciona "tal cual" sin garantías de ningún tipo. No somos responsables de ningún daño indirecto, incidental, especial o consecuente que resulte del uso o la incapacidad de usar la aplicación.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '6. Cambios en los Términos',
                  content:
                      'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán efectivos inmediatamente después de su publicación. Tu uso continuado de RockMeet indica tu aceptación de cualquier cambio.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '7. Contacto',
                  content:
                      'Si tienes preguntas sobre estos términos, por favor contáctanos a través de la sección de soporte en la aplicación.',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
