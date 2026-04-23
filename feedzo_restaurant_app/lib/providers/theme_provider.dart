import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that manages theme mode (light/dark) across the restaurant app.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;

  ThemeProvider() {
    _loadPreference();
  }

  void toggleTheme() {
    HapticFeedback.lightImpact();
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreference();
    notifyListeners();
  }

  void setDark() {
    _mode = ThemeMode.dark;
    _savePreference();
    notifyListeners();
  }

  void setLight() {
    _mode = ThemeMode.light;
    _savePreference();
    notifyListeners();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('restaurant_theme_mode') ?? 'light';
    _mode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'restaurant_theme_mode', _mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
