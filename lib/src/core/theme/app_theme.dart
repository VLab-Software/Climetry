import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF00D9FF);
  static const _bg = Color(0xFF0A0E1A);
  static const _surface = Color(0xFF1A1F2E);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    primaryColor: _primary,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      surface: _surface,
      onSurface: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    useMaterial3: true,
  );
}