import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  static const ThemeMode _fixedTheme = ThemeMode.light;
  
  ThemeMode get themeMode => _fixedTheme;
  bool get isDarkMode => false;

  ThemeProvider();

  Future<void> toggleTheme() async {}
  Future<void> setTheme(ThemeMode mode) async {}
}
