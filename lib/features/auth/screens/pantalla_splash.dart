import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';
import 'package:RockMeet/core/widgets/validation_state_widget.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key, required this.nextScreen})
    : super(key: key);
  final Widget nextScreen;
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  ValidationState _validationState = ValidationState.loading;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkFireStoreConnection();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    //Simulación de validación (reemplazaremos luego esto con la lógica real)
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Esperar a que se verifique la conexión de Firestore
    await Future.delayed(const Duration(milliseconds: 500));

    // Si ya hay error de Firestore, no navegar
    if (_validationState == ValidationState.error) {
      return;
    }

    // Si la conexión fue exitosa, marcar como éxito
    if (mounted) {
      setState(() => _validationState = ValidationState.success);
    }

    // Dar tiempo para ver el mensaje de éxito antes de navegar
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => widget.nextScreen));
    }
  }

  void _retryInitialization() {
    setState(() {
      _validationState = ValidationState.loading;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Aquí va el Logo
                  Container(
                    width: 150,
                    
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(
                        'lib/config/Theme/Logo/RockMeetLogo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(
                        'lib/config/Theme/Logo/RockMeet.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_validationState != ValidationState.idle)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: ValidationStateWidget(
                state: _validationState,
                errorMessage: _errorMessage.isEmpty
                    ? "Error al cargar la app"
                    : _errorMessage,
                successMessage: "¡Bienvenido a RockMeet!",
                onRetry: _retryInitialization,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkFireStoreConnection() async {
    try {
      // Usa una colección que sí existe y tiene lectura permitida en reglas.
      await FirebaseFirestore.instance.collection('events').limit(1).get();
      debugPrint('Conexión a Firestore exitosa');
      // Si llegamos aquí, la conexión fue exitosa (el estado se actualiza en _initializeApp)
    } on FirebaseException catch (e) {
      debugPrint(
        'Error Firebase al conectar a Firestore: ${e.code} - ${e.message}',
      );
      if (!mounted) return;
      setState(() {
        _validationState = ValidationState.error;
        _errorMessage = 'No se pudo conectar con la base de datos';
      });
    } catch (e) {
      debugPrint('Error al conectar a Firestore: $e');
      if (!mounted) return;
      setState(() {
        _validationState = ValidationState.error;
        _errorMessage = 'Error inesperado al iniciar';
      });
    }
  }
}
