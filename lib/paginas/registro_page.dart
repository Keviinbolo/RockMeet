import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/Theme/app_theme.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RegistroScreen(),
    );
  }
}

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _courseController = TextEditingController();
  final _tutorCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;
  String? _ageError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _courseController.dispose();
    _tutorCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 18) {
      setState(() {
        _ageError = 'Debes ser mayor de 18 años para crear una cuenta';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    print('Registro:');
    print('Nombre: ${_nameController.text}');
    print('Email: ${_emailController.text}');
    print('Edad: ${_ageController.text}');
    print('Curso: ${_courseController.text}');
    print('Código tutor: ${_tutorCodeController.text}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro exitoso'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildNameField(),
                            const SizedBox(height: 20),
                            _buildEmailField(),
                            const SizedBox(height: 20),
                            _buildAgeField(),
                            const SizedBox(height: 20),
                            _buildCourseField(),
                            const SizedBox(height: 20),
                            _buildTutorCodeField(),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 20),
                            _buildConfirmPasswordField(),
                            const SizedBox(height: 16),
                            _buildTermsCheckbox(),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                            const SizedBox(height: 24),
                            _buildLoginLink(),
                            const SizedBox(height: 16),
                            _buildDivider(),
                            const SizedBox(height: 16),
                            _buildSocialButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa tus datos para registrarte',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _buildInputField(
      label: 'Nombre completo',
      hint: 'Tu nombre',
      controller: _nameController,
      icon: Icons.person,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _buildInputField(
      label: 'Correo electrónico',
      hint: 'tu@email.com',
      controller: _emailController,
      icon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        if (!value.contains('@')) {
          return 'Ingresa un email válido';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edad',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Tu edad',
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
          ),
          onChanged: (value) {
            setState(() {
              _ageError = null;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        if (_ageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _ageError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseField() {
    return _buildInputField(
      label: 'Curso',
      hint: 'Ej: FP, Bachillerato...',
      controller: _courseController,
      icon: Icons.school,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildTutorCodeField() {
    return _buildInputField(
      label: 'Código de tutor',
      hint: 'Código de 6 dígitos',
      controller: _tutorCodeController,
      icon: Icons.vpn_key,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        if (value.length != 6) {
          return 'El código debe tener 6 dígitos';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contraseña', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: 'Mínimo 8 caracteres',
            prefixIcon: const Icon(Icons.lock, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.length < 8) {
              return 'La contraseña debe tener mínimo 8 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirmar contraseña', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Repite tu contraseña',
            prefixIcon: const Icon(Icons.lock, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'Acepto los '),
                TextSpan(
                  text: 'Términos y Condiciones',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {},
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Política de Privacidad',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Crear cuenta',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Inicia sesión',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lightGray)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O regístrate con',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.lightGray)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton('Google'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton('Facebook'),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label) {
    return OutlinedButton(
      onPressed: () {},
      child: Text(label),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

