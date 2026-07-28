import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable app language.
class AppLanguage {
  final String code; // ISO code used for the Locale and translation maps
  final String native; // shown to the user (e.g. "हिन्दी")
  final String english; // English name (e.g. "Hindi")
  final bool isRtl; // right-to-left script (Arabic, Hebrew, Urdu, Persian)
  const AppLanguage(this.code, this.native, this.english, {this.isRtl = false});
}

/// Owns the app's language: the supported locales, loading the saved choice on
/// startup, switching instantly via [Get.updateLocale], and persisting it with
/// SharedPreferences so it survives a restart. Defaults to English.
class LanguageService {
  LanguageService._();

  static const String _prefKey = 'app_language_code';

  /// The full set of selectable languages. The `code` here is the same key used
  /// in the translation maps AND the [Locale] language code, so the three stay
  /// in lock-step. Right-to-left languages carry `isRtl: true`.
  static const List<AppLanguage> supported = [
    AppLanguage('en', 'English', 'English'),
    AppLanguage('es', 'Español', 'Spanish'),
    AppLanguage('hi', 'हिन्दी', 'Hindi'),
    AppLanguage('pt', 'Português (Brasil)', 'Portuguese (Brazil)'),
    AppLanguage('ar', 'العربية', 'Arabic', isRtl: true),
    AppLanguage('fr', 'Français', 'French'),
    AppLanguage('id', 'Bahasa Indonesia', 'Indonesian'),
    AppLanguage('ru', 'Русский', 'Russian'),
    AppLanguage('de', 'Deutsch', 'German'),
    AppLanguage('ja', '日本語', 'Japanese'),
    AppLanguage('zh', '简体中文', 'Chinese (Simplified)'),
    AppLanguage('ko', '한국어', 'Korean'),
    AppLanguage('he', 'עברית', 'Hebrew', isRtl: true),
    AppLanguage('tr', 'Türkçe', 'Turkish'),
    AppLanguage('it', 'Italiano', 'Italian'),
    AppLanguage('vi', 'Tiếng Việt', 'Vietnamese'),
    AppLanguage('th', 'ไทย', 'Thai'),
    AppLanguage('fil', 'Filipino', 'Filipino'),
    AppLanguage('bn', 'বাংলা', 'Bengali'),
    AppLanguage('ur', 'اردو', 'Urdu', isRtl: true),
    AppLanguage('fa', 'فارسی', 'Persian (Farsi)', isRtl: true),
    AppLanguage('pl', 'Polski', 'Polish'),
    AppLanguage('nl', 'Nederlands', 'Dutch'),
    AppLanguage('ta', 'தமிழ்', 'Tamil'),
    AppLanguage('ms', 'Bahasa Melayu', 'Malay'),
    AppLanguage('sw', 'Kiswahili', 'Swahili'),
  ];

  static const Map<String, List<String>> countryLanguages = {
    'IN': ['en', 'hi'],
    'JP': ['en', 'ja'],
    'FR': ['en', 'fr'],
    'DE': ['en', 'de'],
    'ES': ['en', 'es'],
    'IT': ['en', 'it'],
    'BR': ['en', 'pt'],
    'PT': ['en', 'pt'],
    'KR': ['en', 'ko'],
    'CN': ['en', 'zh'],
    'RU': ['en', 'ru'],
    'ID': ['en', 'id'],
    'TH': ['en', 'th'],
    'VN': ['en', 'vi'],
    'TR': ['en', 'tr'],
    'SA': ['en', 'ar'],
    'AE': ['en', 'ar'],
    'IL': ['en', 'he'],
    'IR': ['en', 'fa'],
    'BD': ['en', 'bn'],
    'PK': ['en', 'ur'],
    'NL': ['en', 'nl'],
    'PL': ['en', 'pl'],
    'MY': ['en', 'ms'],
    'TZ': ['en', 'sw'],
  };

  static const Locale fallbackLocale = Locale('en');

  static String _current = 'en';

  static String get currentCode => _current;
  static Locale get locale => Locale(_current);

  static List<Locale> get supportedLocales =>
      supported.map((l) => Locale(l.code)).toList();

  static bool _isSupported(String code) => supported.any((l) => l.code == code);

  /// Whether [code] is a right-to-left language (Arabic, Hebrew, Urdu, Persian).
  static bool isRtlCode(String code) {
    for (final l in supported) {
      if (l.code == code) return l.isRtl;
    }
    return false;
  }

  /// Whether the currently-selected language is right-to-left.
  static bool get isCurrentRtl => isRtlCode(_current);

  /// Load the saved language BEFORE runApp so the very first frame is already
  /// in the user's language. Falls back to English when nothing is saved.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && _isSupported(saved)) {
        _current = saved;
      } else {
        _current = 'en';
      }
    } catch (_) {
      _current = 'en';
    }
  }

  static String get deviceLanguageCode {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    return _isSupported(code) ? code : 'en';
  }

  static String get deviceCountryCode {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;

    return locale.countryCode?.toUpperCase() ?? '';
  }

  // static List<String> get deviceLanguages {
  //   final country = deviceCountryCode;

  //   return countryLanguages[country] ?? [deviceLanguageCode];
  // }
  static List<String> get deviceLanguages {
    final country = deviceCountryCode;

    if (country == 'IN' || country == 'GB') {
      return ['en', 'hi'];
    }

    return countryLanguages[country] ?? [deviceLanguageCode];
  }

  /// Switch the whole app to [code] immediately (no restart) and remember it.
  static Future<void> setLanguage(String code) async {
    if (!_isSupported(code)) return;
    _current = code;
    Get.updateLocale(Locale(code));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {
      // A failed write just means the choice won't persist; the live switch
      // above still applied, so we swallow it rather than crash.
    }
  }
}
