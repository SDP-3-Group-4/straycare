import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeIndex =
        prefs.getInt('themeMode') ?? 0; // 0: system, 1: light, 2: dark
    switch (themeIndex) {
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    // Load Locale
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    int themeIndex = 0;
    switch (mode) {
      case ThemeMode.light:
        themeIndex = 1;
        break;
      case ThemeMode.dark:
        themeIndex = 2;
        break;
      case ThemeMode.system:
      default:
        themeIndex = 0;
    }
    await prefs.setInt('themeMode', themeIndex);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }
}
