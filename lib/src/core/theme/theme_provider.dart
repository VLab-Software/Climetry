import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // TEMA FIXO LIGHT - NÃO MUDA MAIS
  ThemeMode get themeMode => ThemeMode.light; // SEMPRE LIGHT
  bool get isDarkMode => false; // SEMPRE FALSE

  ThemeProvider();

  Future<void> toggleTheme() async {
    // NÃO FAZ NADA - TEMA FIXO
  }

  Future<void> setTheme(ThemeMode mode) async {
    // NÃO FAZ NADA - TEMA FIXO
  }
}
