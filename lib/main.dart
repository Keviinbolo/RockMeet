import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/config/Routes/approutes.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/core/api/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const MyApp());
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(ErrorApp(errorMessage: error.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
