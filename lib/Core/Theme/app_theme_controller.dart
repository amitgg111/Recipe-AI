import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();

  static const String themeKey = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isDark => themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _storage.read(themeKey);

    switch (savedTheme) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;

      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;

      case 'system':
      default:
        themeMode.value = ThemeMode.system;
    }

    Get.changeThemeMode(themeMode.value);
  }

  void _saveTheme(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);

    String value;

    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;

      case ThemeMode.dark:
        value = 'dark';
        break;

      case ThemeMode.system:
        value = 'system';
        break;
    }

    _storage.write(themeKey, value);
  }

  void toggleTheme() {
    if (themeMode.value == ThemeMode.dark) {
      _saveTheme(ThemeMode.light);
    } else {
      _saveTheme(ThemeMode.dark);
    }
  }

  void setLightTheme() => _saveTheme(ThemeMode.light);

  void setDarkTheme() => _saveTheme(ThemeMode.dark);

  void setSystemTheme() => _saveTheme(ThemeMode.system);
}
