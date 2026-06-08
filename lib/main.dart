import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AircraftsAdminApp());
}

class AircraftsAdminApp extends StatelessWidget {
  const AircraftsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aircrafts Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF0F1929),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2640),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E2D40)),
          ),
        ),
        dialogBackgroundColor: const Color(0xFF0F1929),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0F1929),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
