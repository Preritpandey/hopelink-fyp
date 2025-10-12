import 'package:flutter/material.dart';
import 'package:hope_link/features/Home/pages/home_screen.dart';
import 'package:hope_link/features/Onboarding/pages/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hope Link',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
