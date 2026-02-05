import 'package:flutter/material.dart';
import 'login.dart'; // 1. IMPORTANTE: Importamos tu archivo aquí

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      debugShowCheckedModeBanner: false, // Opcional: quita la etiqueta "Debug"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 2. IMPORTANTE: Aquí definimos tu pantalla de login como el inicio
      home: LoginPage(), 
    );
  }
}
