import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _defaultTheme = 'light';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? _defaultTheme;
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  static Future<Map<String, dynamic>> getThemeConfig(String themeName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('themes')
        .doc(themeName)
        .get();

    if (!snapshot.exists) {
      return _getDefaultTheme(themeName);
    }

    return snapshot.data() as Map<String, dynamic>;
  }

  static Map<String, dynamic> _getDefaultTheme(String themeName) {
    if (themeName == 'dark') {
      return {
        'primaryColor': '#2196F3',
        'backgroundColor': '#121212',
        'cardColor': '#1E1E1E',
        'textColor': '#FFFFFF',
        'secondaryTextColor': '#B3B3B3',
      };
    } else {
      return {
        'primaryColor': '#2196F3',
        'backgroundColor': '#FFFFFF',
        'cardColor': '#FFFFFF',
        'textColor': '#000000',
        'secondaryTextColor': '#757575',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableThemes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('themes')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'],
        'displayName': data['displayName'],
        'isDark': data['isDark'] ?? false,
      };
    }).toList();
  }
}
