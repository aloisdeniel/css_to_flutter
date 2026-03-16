import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CssToFlutterApp());
}

class CssToFlutterApp extends StatelessWidget {
  const CssToFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSS to Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1B26),
      ),
      home: const HomeScreen(),
    );
  }
}
