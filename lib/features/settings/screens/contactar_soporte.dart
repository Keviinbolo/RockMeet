import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/widgets/settings_header.dart';

class ContactarSoporteScreen extends StatefulWidget {
  const ContactarSoporteScreen({Key? key}) : super(key: key);

  @override
  State<ContactarSoporteScreen> createState() => _ContactarSoporteScreenState();
}

class _ContactarSoporteScreenState extends State<ContactarSoporteScreen> {
  final TextEditingController _asuntoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _emailController.text = email;
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _mensajeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const SettingsHeader(title: 'Atención al Cliente'),

          // Contenido
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Sección de información de contacto
                _buildSection(
                  title: 'Información de Atención al Cliente',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                
                // Horario de atención
                _buildContactCard(
                  icon: Icons.schedule,
                  title: 'Horario de Atención',
                  content: 'Lunes a Viernes: 8:00 - 20:00\nSábado: 9:00 - 18:00\nDomingo: Cerrado',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Email principal
                _buildContactCard(
                  icon: Icons.email,
                  title: 'Email Principal',
                  content: 'support@rockmeet.com',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Teléfono de soporte
                _buildContactCard(
                  icon: Icons.phone,
                  title: 'Teléfono de Soporte',
                  content: '+34 900 XXX XXX',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Tiempo de respuesta
                _buildContactCard(
                  icon: Icons.timer,
                  title: 'Tiempo Promedio de Respuesta',
                  content: 'Dentro de 24-48 horas',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // Formulario de c ontacto
                _buildSection(
                  title: 'Envía tu duda o comentario',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  hint: 'ejemplo@email.com',
                  icon: Icons.email,
                  isDark: isDark,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _asuntoController,
                  label: 'Asunto',
                  hint: 'Describe brevemente tu consulta',
                  icon: Icons.subject,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _mensajeController,
                  label: 'Mensaje',
                  hint: 'Explica tu problema en detalle...',
                  icon: Icons.message,
                  isDark: isDark,
                  maxLines: 5,
                ),
                const SizedBox(height: 24),

                // Botón enviar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Enviar Mensaje',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Información Importante',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Intenta describir tu problema de forma clara y detallada\n'
                        '• Revisa nuestras Preguntas Frecuentes antes de contactar',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
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
    required bool isDark,
  }) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: readOnly
                ? (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: readOnly
                  ? BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    )
                  : const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_asuntoController.text.isEmpty || _mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor completa todos los campos',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('support_messages').add({
        'fromUserId': user?.uid ?? '',
        'fromEmail': _emailController.text.trim(),
        'subject': _asuntoController.text.trim(),
        'message': _mensajeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      _asuntoController.clear();
      _mensajeController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mensaje enviado. Un tutor se pondrá en contacto contigo.',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al enviar el mensaje. Inténtalo de nuevo.',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
