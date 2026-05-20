import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:RockMeet/config/Routes/approutes.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';
import 'package:RockMeet/core/api/firebase_options.dart';
import 'package:RockMeet/core/services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Supabase.initialize(
      url: 'https://xquqepkbpodwonxumete.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxdXFlcGticG9kd29ueHVtZXRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyMjI0NTQsImV4cCI6MjA5NDc5ODQ1NH0.5jALMMmZuzFRQ7w_izkCzJ-rG_nTcM2_pyN4dvmETTA',
    );
    runApp(const MyApp());
  } catch (error, stackTrace) {
    debugPrint('Firebase/Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(ErrorApp(errorMessage: error.toString()));
  }
}
//f8lB5SlHpNHKLfBp
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        PresenceService.instance.init();
      } else {
        PresenceService.instance.deactivate();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    PresenceService.instance.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RockMeet',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
 

class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo iniciar la app',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
