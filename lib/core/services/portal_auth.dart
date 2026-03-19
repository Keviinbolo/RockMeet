import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/features/auth/screens/login.dart';
import 'package:myapp/features/auth/screens/pantalla_splash.dart';

import 'package:myapp/features/home/screens/home_page.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Text('Ocurrio un error al verificar la autenticación');
          }
          if (snapshot.hasData) {
            return const AnimatedSplashScreen(nextScreen: HomePage());
          } else {
            return const AnimatedSplashScreen(nextScreen: LoginPage());
          }
        },
      ),
    );
  }
}
