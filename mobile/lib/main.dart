import 'package:flutter/material.dart';
import 'storage.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const MoeDeloApp());

class MoeDeloApp extends StatefulWidget {
  const MoeDeloApp({super.key});
  @override
  State<MoeDeloApp> createState() => _MoeDeloAppState();
}

class _MoeDeloAppState extends State<MoeDeloApp> {
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    Storage.isDarkMode().then((v) => setState(() => _dark = v));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
