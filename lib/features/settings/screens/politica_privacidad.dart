import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({Key? key}) : super(key: key);

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
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                  'Política de Privacidad',
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
                  title: '1. Introducción',
                  content:
                      'En RockMeet, tu privacidad es nuestra prioridad. Esta Política de Privacidad explica cómo recopilamos, usamos, divulgamos y salvaguardamos tu información cuando utilizas nuestra aplicación móvil.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '2. Información que Recopilamos',
                  content:
                      'Podemos recopilar información sobre ti de manera directa e indirecta, automáticamente y cuando lo solicites voluntariamente. La información que recopilamos incluye:',
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint('Información personal (nombre, correo electrónico, teléfono)', isDark),
                      _buildBulletPoint('Información de perfil (fotos, bio, intereses)', isDark),
                      _buildBulletPoint('Datos de ubicación con tu consentimiento', isDark),
                      _buildBulletPoint('Información de dispositivo (tipo de dispositivo, OS, ID único)', isDark),
                      _buildBulletPoint('Registros de actividad y uso de la aplicación', isDark),
                    ],
                  ),
                ),
                _buildSection(
                  title: '3. Cómo Usamos tu Información',
                  content:
                      'Utilizamos la información que recopilamos para:',
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint('Proporcionar, operar y mantener la aplicación', isDark),
                      _buildBulletPoint('Mejorar, innovar y desarrollar nuevas características', isDark),
                      _buildBulletPoint('Procesamiento de transacciones y envío de información relacionada', isDark),
                      _buildBulletPoint('Entregas de notificaciones y mensajes', isDark),
                      _buildBulletPoint('Cumplir con requisitos legales y políticas internas', isDark),
                    ],
                  ),
                ),
                _buildSection(
                  title: '4. Divulgación de tu Información',
                  content:
                      'No vendemos, intercambiamos ni transferimos tu información personal a terceros sin tu consentimiento, excepto cuando sea necesario para proporcionar los servicios solicitados, cumplir con la ley o proteger nuestros derechos.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '5. Seguridad de tu Información',
                  content:
                      'Utilizamos cifrado de datos, firewalls seguros y otras medidas de seguridad física, electrónica y procedimentales para proteger tu información personal. Sin embargo, ningún método de transmisión por Internet o almacenamiento electrónico es 100% seguro.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '6. Derechos de Privacidad',
                  content:
                      'Según las leyes de privacidad aplicables, puedes tener derecho a acceder, actualizar o eliminar tu información personal en cualquier momento. Por favor, contacta con nosotros para ejercer estos derechos.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '7. Cookies y Tecnologías de Rastreo',
                  content:
                      'Podemos usar cookies y tecnologías similares para mejorar tu experiencia y recopilar datos sobre tus patrones de uso. Puedes controlar las cookies a través de la configuración de tu navegador o dispositivo.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '8. Retención de Datos',
                  content:
                      'Retenemos tu información personal solo durante el tiempo necesario para cumplir con los propósitos descritos en esta Política de Privacidad, a menos que la ley requiera un período de retención más largo.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '9. Cambios en esta Política',
                  content:
                      'Podemos actualizar esta Política de Privacidad de vez en cuando. Te notificaremos de cualquier cambio publicando la nueva Política de Privacidad en la aplicación.',
                  isDark: isDark,
                ),
                _buildSection(
                  title: '10. Contacto',
                  content:
                      'Si tienes preguntas o inquietudes sobre esta Política de Privacidad, por favor contáctanos a través de la sección de soporte en la aplicación.',
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
