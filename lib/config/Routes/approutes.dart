import 'package:flutter/material.dart';
import 'package:myapp/paginas/login.dart';
import 'package:myapp/paginas/pantalla_splash.dart';
import 'package:myapp/paginas/registro_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  
  static Map<String, String> get routes => {
    splash: '/splash',
    login: '/login',
    register: '/register',
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const AnimatedSplashScreen(
            nextScreen: LoginPage(),
          ),
        );
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