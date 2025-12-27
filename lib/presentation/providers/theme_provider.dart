import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode preference
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Notifier for theme mode management
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Provider for theme mode
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Provider for actual ThemeMode to use in MaterialApp
final themeProvider = Provider<ThemeMode>((ref) {
  final themeNotifier = ref.watch(themeModeProvider.notifier);
  return themeNotifier.themeMode;
});
