import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const _themeModeKey = 'app_theme_mode';
  static const _languageKey = 'app_language';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('id');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = preferences.getBool(_themeModeKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
    _locale = Locale(preferences.getString(_languageKey) ?? 'id');
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeModeKey, themeMode == ThemeMode.dark);
    _themeMode = themeMode;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, locale.languageCode);
    _locale = locale;
    notifyListeners();
  }
}
