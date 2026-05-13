import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/core/services/auth_service.dart';
import 'package:RockMeet/features/auth/screens/login.dart';

class BlockedUserScreen extends StatelessWidget {
  const BlockedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 88, color: Colors.red.shade400),
              const SizedBox(height: 20),
              Text(
                'Tu cuenta ha sido bloqueada',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No puedes acceder a la aplicación hasta que un miembro del staff revierta el bloqueo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
