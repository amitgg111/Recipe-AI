import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();

  static const String themeKey = 'theme_mode';

  // Single-theme app: always the orange (light) theme. Dark mode removed.
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  bool get isDark => false;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    // Always resolve to the orange (light) theme, ignoring any previously
    // saved value or the device setting.
    themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
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
