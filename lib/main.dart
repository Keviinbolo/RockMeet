import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:RockMeet/config/Routes/approutes.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';
import 'package:RockMeet/core/api/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
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
 
