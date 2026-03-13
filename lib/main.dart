import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/config/Routes/approutes.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/core/doc/api/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //Probar la conexión a Firestore
  try {
    await FirebaseFirestore.instance.collection('test').get();
    print('Conexión a Firestore exitosa');
  } catch (e) {
    print('Error al conectar a Firestore: $e');
  }

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
