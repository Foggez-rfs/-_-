import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF1E3A8A);
  static const blueLight = Color(0xFF3B5BC7);
  static const red = Color(0xFFDC2626);
  static const redDark = Color(0xFFB91C1C);
  static const lightBg = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFF59E0B);
  static const grey = Color(0xFF64748B);
}

class AppSizes {
  static const minButton = 60.0;
  static const fontSize = 20.0;
  static const padding = 20.0;
  static const radius = 16.0;
}

ThemeData lightTheme() => _build(Brightness.light);
ThemeData darkTheme() => _build(Brightness.dark);

ThemeData _build(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.red,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 20),
      bodyMedium: TextStyle(fontSize: 18),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(AppSizes.minButton, AppSizes.minButton),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      labelStyle: const TextStyle(fontSize: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide(color: AppColors.blue.withOpacity(0.3), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: const BorderSide(color: AppColors.blue, width: 2.5),
      ),
    ),
  );
}
