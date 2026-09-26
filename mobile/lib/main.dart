import 'package:flutter/material.dart';

import 'services/api.dart';
import 'screens/login_screen.dart';
import 'screens/customer_screen.dart';
import 'screens/executor_screen.dart';

void main() => runApp(const MoeDeloApp());

class MoeDeloApp extends StatefulWidget {
  const MoeDeloApp({super.key});
  @override
  State<MoeDeloApp> createState() => _MoeDeloAppState();
}

class _MoeDeloAppState extends State<MoeDeloApp> {
  bool _darkMode = false;

  void toggleTheme() => setState(() => _darkMode = !_darkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: FutureBuilder<String?>(
        future: Api.loadToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final token = snapshot.data;
          final role = Api.getRole();
          if (token != null && role != null) {
            return role == 'executor'
                ? const ExecutorScreen()
                : const CustomerScreen();
          }
          return LoginScreen(onToggleTheme: toggleTheme);
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A),
        primary: const Color(0xFF1E3A8A),
        secondary: const Color(0xFFDC2626),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 20),
        bodyMedium: TextStyle(fontSize: 18),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(60, 60),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
