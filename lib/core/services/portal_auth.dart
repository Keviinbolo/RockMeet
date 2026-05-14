import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:RockMeet/config/Routes/approutes.dart';
import 'package:RockMeet/core/services/auth_service.dart';
import 'package:RockMeet/features/auth/screens/blocked_user_screen.dart';
import 'package:RockMeet/features/auth/screens/login.dart';
import 'package:RockMeet/features/auth/screens/pantalla_splash.dart';
import 'package:RockMeet/features/auth/screens/profile_setup_page.dart';
import 'package:RockMeet/features/home/screens/home_page.dart';
import 'package:RockMeet/features/home/screens/home_staff_page.dart';
import 'package:RockMeet/features/like/screens/like_page.dart';
import 'package:RockMeet/features/settings/screens/ajustes.dart';

class PortalAuth extends StatelessWidget {
  const PortalAuth({super.key});

  // Devuelve el widget correspondiente a la ruta actual de la URL (solo web).
  // Devuelve null si la ruta no es válida para este usuario.
  static Widget? _resolveWebRoute(
    String path,
    String userType,
    bool profileComplete,
  ) {
    if (!profileComplete) return null; // Forzar setup antes de cualquier ruta
    switch (path) {
      case AppRoutes.home:
        return userType == 'staff' ? null : const HomePage();
      case AppRoutes.homestaff:
        return userType == 'staff' ? const HomeStaffPage() : null;
      case AppRoutes.like:
        return userType == 'staff' ? null : const LikesPage();
      case AppRoutes.ajustes:
        return const SettingsScreen();
      default:
        return null;
    }
  }

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
                final profileComplete =
                    userData['profileComplete'] as bool? ?? true;

                Widget nextScreen;
                if (userType == 'staff') {
                  nextScreen = const HomeStaffPage();
                } else if (!profileComplete) {
                  nextScreen = const ProfileSetupPage();
                } else {
                  nextScreen = const HomePage();
                }

                // En web, restaurar la página donde estaba el usuario
                if (kIsWeb) {
                  final path = Uri.base.fragment; // e.g. '/home', '/like'
                  final restored =
                      _resolveWebRoute(path, userType, profileComplete);
                  if (restored != null) nextScreen = restored;
                }

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
