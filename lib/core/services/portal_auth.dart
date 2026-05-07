import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/features/auth/screens/blocked_user_screen.dart';
import 'package:myapp/features/auth/screens/login.dart';
import 'package:myapp/features/auth/screens/pantalla_splash.dart';

import 'package:myapp/features/home/screens/home_page.dart';
import 'package:myapp/features/home/screens/home_staff_page.dart';

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
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const AnimatedSplashScreen(nextScreen: LoginPage());
            }

            return StreamBuilder<Map<String, dynamic>?>(
              stream: AuthService().getUserDataStream(currentUser.uid),
              builder: (context, userDataSnapshot) {
                if (userDataSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = userDataSnapshot.data;
                if (userData == null) {
                  return const AnimatedSplashScreen(nextScreen: LoginPage());
                }

                final blockedBy = List<String>.from(
                  userData['blockedBy'] as List? ?? const <String>[],
                );
                if (blockedBy.isNotEmpty) {
                  return const BlockedUserScreen();
                }

                final userType = (userData['type'] as String?) ?? 'user';
                final nextScreen = userType == 'staff'
                    ? const HomeStaffPage()
                    : const HomePage();

                return AnimatedSplashScreen(nextScreen: nextScreen);
              },
            );
          } else {
            return const AnimatedSplashScreen(nextScreen: LoginPage());
          }
        },
      ),
    );
  }
}
