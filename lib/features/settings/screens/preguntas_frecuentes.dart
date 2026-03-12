import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';

class PreguntasFrecuentesScreen extends StatefulWidget {
  const PreguntasFrecuentesScreen({Key? key}) : super(key: key);

  @override
  State<PreguntasFrecuentesScreen> createState() =>
      _PreguntasFrecuentesScreenState();
}

class _PreguntasFrecuentesScreenState extends State<PreguntasFrecuentesScreen> {
  final List<FAQItem> faqItems = [
    FAQItem(
      question: '¿Qué es RockMeet?',
      answer:
          'RockMeet es una aplicación de citas moderna diseñada para ayudarte a conectar con personas que comparten tus intereses, especialmente en música, deportes, películas, lectura y viajes.',
    ),
    FAQItem(
      question: '¿Cómo creo una cuenta en RockMeet?',
      answer:
          '1. Descarga la aplicación desde App Store o Google Play\n2. Abre la pantalla de registro\n3. Ingresa tu correo electrónico y contraseña\n4. Completa tu perfil con una foto, biografía e intereses\n5. ¡Listo! Tu cuenta estará activa',
    ),
    FAQItem(
      question: '¿Es gratuita la aplicación?',
      answer:
          'Sí, RockMeet es completamente gratuita. Puedes crear una cuenta, explorar perfiles, enviar mensajes y conectar con otros usuarios sin costo alguno.',
    ),
    FAQItem(
      question: '¿Puedo cambiar mi información personal?',
      answer:
          'Sí, puedes editar en cualquier momento tu nombre, biografía, fotos de perfil y otros detalles personales. Solo ve a tu perfil y haz clic en "Editar perfil".',
    ),
    FAQItem(
      question: '¿Cómo cambio mi contraseña?',
      answer:
          'Puedes cambiar tu contraseña desde el apartado "Ajustes" > "Cuenta" > "Cambiar contraseña". Ingresa tu contraseña actual y la nueva contraseña que desees utilizar.',
    ),
    FAQItem(
      question: '¿Cómo contacto al equipo de soporte?',
      answer:
          'Ve a "Ajustes" > "Ayuda" > "Contactar soporte" donde podrás enviar un mensaje directo a nuestro equipo de soporte. Responderemos a tu consulta lo antes posible.',
    ),
  ];

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
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'Preguntas Frecuentes',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Lista de FAQs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                return _buildFAQTile(faqItems[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(FAQItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: ExpansionTile(
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            item.question,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          leading: Icon(
            Icons.help_outline,
            color: AppColors.primary,
            size: 20,
          ),
          children: [
            Text(
              item.answer,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
