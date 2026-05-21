import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/widgets/settings_header.dart';

class CambiarContraseniaScreen extends StatefulWidget {
  const CambiarContraseniaScreen({Key? key}) : super(key: key);

  @override
  State<CambiarContraseniaScreen> createState() => _CambiarContraseniaScreenState();
}

class _CambiarContraseniaScreenState extends State<CambiarContraseniaScreen> {
  final TextEditingController _contraseniaActualController = TextEditingController();
  final TextEditingController _nuevaContraseniaController = TextEditingController();
  final TextEditingController _confirmarContraseniaController = TextEditingController();

  bool _mostrarContraseniaActual = false;
  bool _mostrarNuevaContrasenia = false;
  bool _mostrarConfirmarContrasenia = false;

  @override
  void dispose() {
    _contraseniaActualController.dispose();
    _nuevaContraseniaController.dispose();
    _confirmarContraseniaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const SettingsHeader(title: 'Cambiar Contraseña'),

          // Contenido
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Actualiza tu contraseña',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por tu seguridad, usa una contraseña fuerte y única',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  controller: _contraseniaActualController,
                  label: 'Contraseña Actual',
                  hint: 'Ingresa tu contraseña actual',
                  mostrar: _mostrarContraseniaActual,
                  onVisibilityChanged: () {
                    setState(() => _mostrarContraseniaActual = !_mostrarContraseniaActual);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _nuevaContraseniaController,
                  label: 'Nueva Contraseña',
                  hint: 'Ingresa una nueva contraseña',
                  mostrar: _mostrarNuevaContrasenia,
                  onVisibilityChanged: () {
                    setState(() => _mostrarNuevaContrasenia = !_mostrarNuevaContrasenia);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmarContraseniaController,
                  label: 'Confirmar Contraseña',
                  hint: 'Confirma tu nueva contraseña',
                  mostrar: _mostrarConfirmarContrasenia,
                  onVisibilityChanged: () {
                    setState(() => _mostrarConfirmarContrasenia = !_mostrarConfirmarContrasenia);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,

                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu contraseña debe tener al menos 8 caracteres',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? AppColors.primary : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _cambiarContrasenia,
                  child: Text(
                    'Cambiar Contraseña',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool mostrar,
    required VoidCallback onVisibilityChanged,
    required bool isDark,
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
          obscureText: !mostrar,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock, color: AppColors.primary),
            suffixIcon: GestureDetector(
              onTap: onVisibilityChanged,
              child: Icon(
                mostrar ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primary,
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
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
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _cambiarContrasenia() {
    final contraseniaActual = _contraseniaActualController.text;
    final nuevaContrasenia = _nuevaContraseniaController.text;
    final confirmarContrasenia = _confirmarContraseniaController.text;

    // Validaciones
    if (contraseniaActual.isEmpty || nuevaContrasenia.isEmpty || confirmarContrasenia.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }

    if (nuevaContrasenia.length < 8) {
      _mostrarError('La nueva contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (nuevaContrasenia != confirmarContrasenia) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    if (contraseniaActual == nuevaContrasenia) {
      _mostrarError('La nueva contraseña debe ser diferente a la actual');
      return;
    }

    // Si todas las validaciones pasan
    _mostrarExito();
    _contraseniaActualController.clear();
    _nuevaContraseniaController.clear();
    _confirmarContraseniaController.clear();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contraseña actualizada exitosamente',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
