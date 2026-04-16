import 'package:flutter/material.dart';
import '../core/widgets/validation_state_widget.dart';
import '../core/widgets/validation_text_field.dart';

class ValidationDemoPage extends StatefulWidget {
  const ValidationDemoPage({Key? key}) : super(key: key);

  @override
  State<ValidationDemoPage> createState() => _ValidationDemoPageState();
}

class _ValidationDemoPageState extends State<ValidationDemoPage> {
  ValidationState _currentState = ValidationState.idle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validaciones Visuales'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Botones para cambiar estado
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentState = ValidationState.idle),
                    child: const Text('Idle'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentState = ValidationState.loading),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Loading'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentState = ValidationState.error),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Error'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentState = ValidationState.success),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Success'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Container con estado actual
              Container(
                constraints: const BoxConstraints(minHeight: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ValidationStateWidget(
                  state: _currentState,
                  errorMessage: 'El correo electrónico no es válido',
                  successMessage: '¡Formulario enviado correctamente!',
                  onRetry: () {
                    setState(() => _currentState = ValidationState.loading);
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() => _currentState = ValidationState.success);
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 30),

              // Ejemplo de formulario con validación visual en campos
              const Text(
                'Formulario con Validación en Campos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFormularioEjemplo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioEjemplo() {
    return Column(
      children: [
        ValidationTextField(
          label: 'Correo Electrónico',
          prefixIcon: Icons.email,
          showValidation: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El correo es requerido';
            }
            if (!value.contains('@')) {
              return 'Ingresa un correo válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ValidationTextField(
          label: 'Contraseña',
          prefixIcon: Icons.lock,
          showValidation: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La contraseña es requerida';
            }
            if (value.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }
}