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
    FAQItem(
      question: '¿Cómo funcionan los intereses y el matching?',
      answer:
          'Nuestro algoritmo te muestra perfiles de personas que comparten tus intereses. Cuantos más intereses selecciones y completes tu perfil, mejores serán las recomendaciones que recibas.',
    ),
    FAQItem(
      question: '¿Es seguro compartir mi información personal?',
      answer:
          'Tu privacidad es nuestra prioridad. Todos tus datos están encriptados y protegidos. Nunca compartimos tu información con terceros sin tu consentimiento. Puedes revisar nuestras políticas en "Ajustes" > "Acerca de" > "Política y privacidad".',
    ),
    FAQItem(
      question: '¿Cómo sé que los perfiles son reales?',
      answer:
          'Todos los nuevos usuarios deben verificar su identidad. Recomendamos ver múltiples fotos, leer la biografía completa y conversar antes de conocer en persona. Si un perfil parece sospechoso, puedes reportarlo.',
    ),
    FAQItem(
      question: '¿Cómo bloqueo o reporto a un usuario?',
      answer:
          'Abre el perfil del usuario problemático y toca el icono de los tres puntos en la esquina. Selecciona "Bloquear" para evitar que se comunique contigo o "Reportar" para notificar a nuestro equipo sobre comportamiento inapropiado.',
    ),
    FAQItem(
      question: '¿Puedo ver quién visitó mi perfil?',
      answer:
          'Por ahora, no mostramos la lista de visitantes para mantener la privacidad de nuestros usuarios. Sin embargo, puedes ver cuando alguien te envía un mensaje o muestra interés en ti.',
    ),
    FAQItem(
      question: '¿Cómo configuro mis notificaciones?',
      answer:
          'Ve a "Ajustes" > "Notificaciones" donde puedes activar o desactivar notificaciones push y notificaciones por correo. También puedes elegir qué tipo de eventos deseas que te notifiquen.',
    ),
    FAQItem(
      question: '¿Puedo hacer mi perfil privado?',
      answer:
          'Sí, puedes controlar la visibilidad de tu perfil desde "Ajustes" > "Privacidad" > "Perfil público". Si lo desactivas, solo las personas que ya sigues podrán ver tu perfil completo.',
    ),
    FAQItem(
      question: '¿Qué hago si olvido mi contraseña?',
      answer:
          'En la pantalla de inicio de sesión, toca "¿Olvidaste tu contraseña?". Ingresa tu correo electrónico registrado y recibirás un enlace para restablecer tu contraseña. El enlace expira en 24 horas por seguridad.',
    ),
    FAQItem(
      question: '¿Cómo elimino mi cuenta?',
      answer:
          'Para eliminar tu cuenta, contacta al equipo de soporte desde "Ajustes" > "Ayuda" > "Contactar soporte" y solicita la eliminación. Ten en cuenta que esta acción es permanente y no se puede deshacer.',
    ),
    FAQItem(
      question: '¿Puedo usar RockMeet desde múltiples dispositivos?',
      answer:
          'Sí, puedes acceder a tu cuenta desde diferentes dispositivos usando tus credenciales. Sin embargo, por seguridad, si lo haces desde un dispositivo desconocido, recibirás una notificación.',
    ),
    FAQItem(
      question: '¿Hay límites en la cantidad de mensajes que puedo enviar?',
      answer:
          'No hay límite en la cantidad de mensajes que puedes enviar a otros usuarios. Sin embargo, si recibimos reportes de spam, podemos limitar temporalmente tu cuenta.',
    ),
    FAQItem(
      question: '¿Qué hago si la aplicación se comporta de manera extraña?',
      answer:
          '1. Intenta cerrar y abrir la app nuevamente\n2. Limpia el caché de la aplicación en tu dispositivo\n3. Actualiza la aplicación a la última versión disponible\n4. Si el problema persiste, contacta al soporte técnico.',
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
