import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/config/Theme/constants/text_styles.dart';
import 'package:myapp/core/widgets/validation_state_widget.dart';

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
  
  
  void _initializeApp() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _validationState = ValidationState.success);

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => widget.nextScreen),
          );
        });
      }
    });
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
                    height: 150,
                    decoration: AppTheme.primaryGradientBox,
                    child: const Icon(Icons.apps_sharp, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'RockMeet',
                    style: AppTextStyles.headlineLarge,
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
                errorMessage: _errorMessage.isEmpty ? "Error al cargar la app" : _errorMessage,
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
      await FirebaseFirestore.instance.collection('test').get();
      debugPrint('Conexión a Firestore exitosa');
    } catch (e) {
      debugPrint('Error al conectar a Firestore: $e');
    }
  }
}
