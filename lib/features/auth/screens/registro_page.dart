import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:RockMeet/core/services/auth_service.dart';

class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistroScreen();
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
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _courseController = TextEditingController();
  final _tutorCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final TextEditingController _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;

  bool _acceptedTerms = false;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _birthDateController.addListener(() {
      if (_ageError != null) setState(() => _ageError = null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _courseController.dispose();
    _tutorCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int month, int year) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    const days31 = [1, 3, 5, 7, 8, 10, 12];
    return days31.contains(month) ? 31 : 30;
  }

  Future<void> _selectDate(BuildContext context) async {
    int tempDay = 1;
    int tempMonth = 1;
    int tempYear = 2000;

    final List<String> monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final DateTime? picked = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int maxDays = _getDaysInMonth(tempMonth, tempYear);
            if (tempDay > maxDays) tempDay = maxDays;

            return AlertDialog(
              title: const Text('Selecciona tu fecha de nacimiento'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Día'),
                              DropdownButton<int>(
                                value: tempDay,
                                items: List.generate(maxDays, (i) => i + 1)
                                    .map((day) => DropdownMenuItem(
                                          value: day,
                                          child: Text(day.toString()),
                                        ))
                                    .toList(),
                                onChanged: (newDay) {
                                  setStateDialog(() {
                                    tempDay = newDay!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Mes'),
                              DropdownButton<int>(
                                value: tempMonth,
                                items: List.generate(12, (i) => i + 1)
                                    .map((month) => DropdownMenuItem(
                                          value: month,
                                          child: Text(monthNames[month - 1]),
                                        ))
                                    .toList(),
                                onChanged: (newMonth) {
                                  setStateDialog(() {
                                    tempMonth = newMonth!;
                                    int newMax = _getDaysInMonth(tempMonth, tempYear);
                                    if (tempDay > newMax) tempDay = newMax;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Año'),
                              DropdownButton<int>(
                                value: tempYear,
                                items: List.generate(
                                  DateTime.now().year - 1900 + 1,
                                  (i) => 1900 + i,
                                ).map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    )).toList(),
                                onChanged: (newYear) {
                                  setStateDialog(() {
                                    tempYear = newYear!;
                                    int newMax = _getDaysInMonth(tempMonth, tempYear);
                                    if (tempDay > newMax) tempDay = newMax;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final selectedDate = DateTime(tempYear, tempMonth, tempDay);
                    Navigator.pop(dialogContext, selectedDate);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        String fechaFormateada = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        _birthDateController.text = fechaFormateada;
        _ageError = null;
      });
      print("Fecha seleccionada: ${_birthDateController.text}");
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _handleSubmit() {
    if (_selectedBirthDate == null) {
      setState(() {
        _ageError = 'Debes seleccionar tu fecha de nacimiento';
      });
      return;
    }

    final age = _calculateAge(_selectedBirthDate!);
    if (age < 18) {
      setState(() {
        _ageError = 'Debes ser mayor de 18 años para crear una cuenta';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    AuthService().register(_emailController.text, _passwordController.text, _nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Registro exitoso'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.secondary.withOpacity(0.2),
              theme.colorScheme.primary.withOpacity(0.2),
            ],
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
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
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
                            _buildLastNameField(), // Campo Apellidos añadido aquí
                            const SizedBox(height: 20),
                            _buildEmailField(),
                            const SizedBox(height: 20),
                            _buildBirthDateField(),
                            const SizedBox(height: 20),
                            _buildCourseField(),
                            const SizedBox(height: 20),
                            _buildTutorCodeField(),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 20),
                            _buildConfirmPasswordField(),
                            const SizedBox(height: 16),
                            _buildTermsCheckbox(theme),
                            const SizedBox(height: 24),
                            _buildSubmitButton(theme),
                            const SizedBox(height: 24),
                            _buildLoginLink(theme),
                            const SizedBox(height: 16),
                            _buildDivider(theme),
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

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person,
            color: theme.colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Crear cuenta',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Completa tus datos para registrarte',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _buildInputField(
      label: 'Nombre',
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

  Widget _buildLastNameField() {
    return _buildInputField(
      label: 'Apellidos',
      hint: 'Tus apellidos',
      controller: _lastNameController,
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

  Widget _buildBirthDateField() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de nacimiento', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,          
          onTap: () => _selectDate(context),
          decoration: const InputDecoration(
            hintText: 'DD/MM/AAAA',
            prefixIcon: Icon(Icons.calendar_today, size: 20),
          ),
          validator: (value) {
            if (_selectedBirthDate == null) {
              return 'Selecciona tu fecha de nacimiento';
            }
            return null;
          },
        ),
        if (_selectedBirthDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Fecha guardada: ${_birthDateController.text}',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        if (_ageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _ageError!,
              style: TextStyle(
                color: theme.colorScheme.error,
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contraseña', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Mínimo 8 caracteres',
            prefixIcon: Icon(Icons.lock, size: 20),
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirmar contraseña', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Repite tu contraseña',
            prefixIcon: Icon(Icons.lock, size: 20),
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

  Widget _buildTermsCheckbox(ThemeData theme) {
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
          activeColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              children: [
                const TextSpan(text: 'Acepto los '),
                TextSpan(
                  text: 'Términos y Condiciones',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Política de Privacidad',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _handleSubmit,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Crear cuenta',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
          child: Text(
            'Inicia sesión',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O regístrate con',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
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