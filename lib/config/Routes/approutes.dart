import 'package:flutter/material.dart';
import 'package:myapp/paginas/login.dart';
import 'package:myapp/paginas/pantalla_splash.dart';
import 'package:myapp/paginas/registro_page.dart';
import 'package:myapp/paginas/validation_demo_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String prueba = '/prueba';
  static const String login = '/login';
  static const String register = '/register';
  
  static Map<String, String> get routes => {
    splash: '/splash',
    login: '/login',
    register: '/register',
    prueba: '/prueba',
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const AnimatedSplashScreen(
            nextScreen: LoginPage(),
          ),
        );
        case prueba:
        return MaterialPageRoute(builder: (_) => const ValidationDemoPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegistroScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}