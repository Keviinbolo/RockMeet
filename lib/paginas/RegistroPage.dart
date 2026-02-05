import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/config/Theme/colors.dart';
import 'package:myapp/config/Theme/text_styles.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({Key? key}) : super(key: key);

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;
  
  final Map<String, String> _formData = {
    'name': '',
    'email': '',
    'password': '',
    'confirmPassword': ''
  };

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _acceptedTerms) {
      _formKey.currentState!.save();
      print('Registro: $_formData');
      // Aquí iría la lógica de registro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    // Logo/Header
                    _buildHeader(),
                    const SizedBox(height: 32),
                    
                    // Form Card
                    _buildFormCard(),
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
              colors: [AppColors.dark, AppColors.secondaryDark],//logo
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon( // Icono de usuario
            Icons.person_outline,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Crear Cuenta',
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 8),
        Text(
          'Completa tus datos para registrarte',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre completo
            _buildTextField(
              label: 'Nombre completo',
              icon: Icons.person_outline,
              hintText: 'Tu nombre',
              onSaved: (value) => _formData['name'] = value ?? '',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            _buildTextField(
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
              hintText: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => _formData['email'] = value ?? '',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Contraseña
            _buildPasswordField(
              label: 'Contraseña',
              hintText: 'Mínimo 8 caracteres',
              isPassword: true,
              showPassword: _showPassword,
              onTogglePassword: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              onSaved: (value) => _formData['password'] = value ?? '',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirmar contraseña
            _buildPasswordField(
              label: 'Confirmar contraseña',
              hintText: 'Repite tu contraseña',
              isPassword: true,
              showPassword: _showConfirmPassword,
              onTogglePassword: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
              onSaved: (value) => _formData['confirmPassword'] = value ?? '',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirma tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Términos y condiciones
            _buildTermsCheckbox(),
            const SizedBox(height: 24),

            // Botón de registro
            _buildRegisterButton(),
            const SizedBox(height: 24),

            // Ya tienes cuenta
            _buildLoginLink(),
            const SizedBox(height: 24),

            // Divider
            _buildDivider(),
            const SizedBox(height: 24),

            // Social login
            _buildSocialButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onSaved: onSaved,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.grey.shade400,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required bool isPassword,
    required bool showPassword,
    required VoidCallback onTogglePassword,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onSaved: onSaved,
          validator: validator,
          obscureText: isPassword && !showPassword,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            activeColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptedTerms = !_acceptedTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y Condiciones',
                    style: const TextStyle(
                      color: Colors.purple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: const TextStyle(
                      color: Colors.purple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _handleSubmit,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.purple, Colors.blue],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _handleSubmit,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withOpacity(0.2),
            child: const Center(
              child: Text(
                'Crear cuenta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          children: [
            const TextSpan(text: '¿Ya tienes cuenta? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  // Navegar a pantalla de login
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  'Inicia sesión',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Stack(
      children: [
        const Divider(
          color: Colors.grey,
          thickness: 1,
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: const Text(
              'O regístrate con',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: _buildGoogleIcon(),
            text: 'Google',
            onPressed: () {
              // Lógica para Google
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: _buildFacebookIcon(),
            text: 'Facebook',
            onPressed: () {
              // Lógica para Facebook
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade200),
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/google_logo.png'), // Asegúrate de tener este asset
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFacebookIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/facebook_logo.png'), // Asegúrate de tener este asset
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// Alternativa si no tienes los assets de los logos
Widget _buildGoogleIconAlternative() {
  return const Icon(
    Icons.g_mobiledata,
    size: 24,
    color: Color(0xFF4285F4),
  );
}

Widget _buildFacebookIconAlternative() {
  return const Icon(
    Icons.facebook,
    size: 24,
    color: Color(0xFF1877F2),
  );
}