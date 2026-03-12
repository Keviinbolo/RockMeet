import 'package:flutter/material.dart';
import 'package:myapp/features/home/screens/home_staff_page.dart';
import 'package:myapp/features/like/screens/like_page.dart';
import 'package:myapp/features/settings/screens/ajustes.dart';
import 'package:myapp/features/home/screens/home_page.dart';
import 'package:myapp/features/auth/screens/login.dart';
import 'package:myapp/features/auth/screens/pantalla_splash.dart';
import 'package:myapp/features/auth/screens/registro_page.dart';
import 'package:myapp/features/validation_demo_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String prueba = '/prueba';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String ajustes = '/settings';
  static const String homestaff = '/homestaff';
  static const String like = '/like';

  static Map<String, String> get routes => {
    splash: '/splash',
    login: '/login',
    register: '/register',
    prueba: '/prueba',
    home: '/home',
    ajustes: '/settings',
    homestaff: '/homestaff',
    like: '/like',
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const AnimatedSplashScreen(nextScreen: LoginPage()),
        );
      case prueba:
        return MaterialPageRoute(builder: (_) => const ValidationDemoPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegistroScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case ajustes:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case homestaff:
        return MaterialPageRoute(builder: (_) => const HomeStaffPage());
      case like:
        return MaterialPageRoute(builder: (_) => const LikesPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
