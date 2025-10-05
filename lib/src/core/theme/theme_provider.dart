import 'package:flutter/material.dart';

/// Provider de tema FIXO em Light Mode
/// Não salva no Firebase, não carrega nada, não muda nunca
/// Criado para evitar bugs de carregamento e flash de tema escuro
class ThemeProvider extends ChangeNotifier {
  // TEMA PERMANENTEMENTE FIXO EM LIGHT
  static const ThemeMode _fixedTheme = ThemeMode.light;
  
  ThemeMode get themeMode => _fixedTheme;
  bool get isDarkMode => false;

  ThemeProvider();

  // Métodos mantidos para compatibilidade mas não fazem nada
  Future<void> toggleTheme() async {}
  Future<void> setTheme(ThemeMode mode) async {}
}
