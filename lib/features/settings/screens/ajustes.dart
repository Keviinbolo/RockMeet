import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/services/auth_service.dart';
import 'terminos_condiciones.dart';
import 'politica_privacidad.dart';
import 'cambiar_contrasenia.dart';
import 'contactar_soporte.dart';
import 'preguntas_frecuentes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;

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
                  'Ajustes',
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

          // Lista de desplegables
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Desplegable Cuenta
                CustomExpansionTile(
                  icon: Icons.person,
                  title: 'Cuenta',
                  subtitle: 'Información personal, email',
                  children: [
                    _buildEmailInfoTile(),
                    _buildAccountTile(
                      icon: Icons.lock,
                      title: 'Cambiar contraseña',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CambiarContraseniaScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Desplegable Notificaciones
                CustomExpansionTile(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Configura tus alertas',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_active,
                      title: 'Notificaciones push',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.email,
                      title: 'Notificaciones por email',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                      },
                    ),
                  ],
                ),

                // Desplegable Seguridad
                CustomExpansionTile(
                  icon: Icons.security,
                  title: 'Seguridad',
                  subtitle: 'Información de seguridad',
                  children: [
                    _buildAccountTile(
                      icon: Icons.shield,
                      title: 'Consejos de seguridad',
                      onTap: () => _showSecurityTipsDialog(),
                    ),
                    _buildAccountTile(
                      icon: Icons.groups,
                      title: 'Reglas de la comunidad',
                      onTap: () => _showCommunityRulesDialog(),
                    ),
                  ],
                ),

                // Desplegable Ayuda
                CustomExpansionTile(
                  icon: Icons.help,
                  title: 'Ayuda',
                  subtitle: 'Soporte y preguntas frecuentes',
                  children: [
                    _buildAccountTile(
                      icon: Icons.help_outline,
                      title: 'Preguntas frecuentes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreguntasFrecuentesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAccountTile(
                      icon: Icons.support_agent,
                      title: 'Contactar soporte',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactarSoporteScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                

                // Desplegable Acerca de
                CustomExpansionTile(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  children: [
                    _buildVersionTile(),
                    _buildAccountTile(
                      icon: Icons.code,
                      title: 'Términos y condiciones',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TerminosCondicionesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAccountTile(
                      icon: Icons.privacy_tip,
                      title: 'Política y privacidad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PoliticaPrivacidadScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const LogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityTipsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          title: Text(
            'Consejos de seguridad',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSecurityTip('🔐', 'Usa una contraseña fuerte y única para tu cuenta.'),
                _buildSecurityTip('🚫', 'Nunca compartas tu contraseña con nadie.'),
                _buildSecurityTip('📸', 'Verifica que las fotos de otros usuarios sean reales antes de interactuar.'),
                _buildSecurityTip('💬', 'No compartas información personal en los primeros mensajes.'),
                _buildSecurityTip('⚠️', 'Reporta perfiles sospechosos o con contenido inapropiado.'),
                _buildSecurityTip('🔔', 'Mantén tus notificaciones activadas para alertas de seguridad.'),
                _buildSecurityTip('📍', 'No compartas tu ubicación exacta en el perfil.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.outfit(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityRulesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          title: Text(
            'Reglas de la comunidad',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRuleTile('1. Respeto', 'Trata a todos los usuarios con respeto y consideración.'),
                _buildRuleTile('2. Autenticidad', 'Usa fotos reales y proporciona información verídica.'),
                _buildRuleTile('3. Prohibiciones', 'No se permite contenido sexual, violento o discriminatorio.'),
                _buildRuleTile('4. Privacidad', 'Respeta la privacidad de otros usuarios.'),
                _buildRuleTile('5. Acoso', 'No está permitido el acoso, amenazas o difamación.'),
                _buildRuleTile('6. Spam', 'No envíes mensajes spam o promocionales.'),
                _buildRuleTile('7. Incumplimiento', 'El incumplimiento puede resultar en la suspensión de la cuenta.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.outfit(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityTip(String emoji, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTile(String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, 
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, 
                size: 18
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200
          ),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primary : (isDark ? Colors.grey.shade600 : Colors.grey.shade600),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildVersionTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versión de la app',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1.0.0',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInfoTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserEmail = AuthService().currentUser?.email ?? 'No disponible';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.email, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email registrado',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUserEmail,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const CustomExpansionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded 
              ? AppColors.primary 
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: _isExpanded ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? AppColors.primary.withOpacity(isDark ? 0.3 : 0.2)
                  : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: _isExpanded ? 12 : 4,
              spreadRadius: _isExpanded ? 0 : 0,
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (value) {
              setState(() => _isExpanded = value);
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: 20),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              widget.subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            children: widget.children,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFEE5A3F),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutConfirmationDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'Cerrar sesión',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '¿Seguro que quieres salir? Puedes volver a iniciar sesión cuando quieras',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cerrar sesión',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sesión cerrada exitosamente',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.grey.shade800,
                    duration: const Duration(seconds: 2),
                  ),
                );
                AuthService().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Cerrar sesión',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}