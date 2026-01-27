import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PresentSirApp());
}

class PresentSirApp extends StatelessWidget {
  const PresentSirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound-Only Check-in',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
