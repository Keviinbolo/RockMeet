
import 'package:flutter/material.dart';
import 'package:myapp/paginas/login.dart';
import 'package:myapp/paginas/pantalla_splash.dart';
import 'package:myapp/paginas/registro_page.dart';

class AppRoutes  {
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  
  static Map<String, String> get routes => {
    home: '/home',
    login: '/login',
    register: '/register',
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) =>  AnimatedSplashScreen(nextScreen: const LoginPage()));
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegistroPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
  
}