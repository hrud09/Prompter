import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences) {
    _themeMode = _readStoredMode();
  }

  static const String _storageKey = 'theme_mode';

  final SharedPreferences _preferences;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _preferences.setString(_storageKey, mode.name);
  }

  ThemeMode _readStoredMode() {
    final String? stored = _preferences.getString(_storageKey);
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }
}
