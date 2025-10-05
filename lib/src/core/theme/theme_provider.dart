import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  String? get _userId => _auth.currentUser?.uid;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      if (_userId == null) return;
      
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();
          
      if (doc.exists) {
        final preferences = doc.data()?['preferences'] as Map<String, dynamic>?;
        final theme = preferences?['theme'] as String?;
        
        if (theme == 'light') {
          _themeMode = ThemeMode.light;
        } else if (theme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();

    try {
      if (_userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'preferences.theme': _themeMode == ThemeMode.dark ? 'dark' : 'light',
      });
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      if (_userId == null) return;
      
      String themeValue;
      if (mode == ThemeMode.light) {
        themeValue = 'light';
      } else if (mode == ThemeMode.dark) {
        themeValue = 'dark';
      } else {
        themeValue = 'system';
      }
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'preferences.theme': themeValue,
      });
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }
}
