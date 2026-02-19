import 'package:flutter/material.dart';
import 'package:myapp/config/Routes/approutes.dart';
import 'package:myapp/config/Theme/app_theme.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RockMeet',
      debugShowCheckedModeBanner: false, 
      initialRoute: AppRoutes.home,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
