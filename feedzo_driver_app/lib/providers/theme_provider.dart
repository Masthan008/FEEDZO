import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that manages theme mode (light/dark/system) across the driver app.
/// Critical for night driving safety - allows drivers to switch to dark mode.
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

  void setSystem() {
    _mode = ThemeMode.system;
    _savePreference();
    notifyListeners();
  }

  /// Quick toggle for drivers - automatically switches to dark mode
  void enableNightMode() {
    HapticFeedback.heavyImpact();
    _mode = ThemeMode.dark;
    _savePreference();
    notifyListeners();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('driver_theme_mode') ?? 'light';
    switch (value) {
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      case 'system':
        _mode = ThemeMode.system;
        break;
      default:
        _mode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = _mode == ThemeMode.dark
        ? 'dark'
        : _mode == ThemeMode.system
            ? 'system'
            : 'light';
    await prefs.setString('driver_theme_mode', value);
  }
}
