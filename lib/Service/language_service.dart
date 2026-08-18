import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
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
  static final RxInt languageVersion = 0.obs;

  /// The full set of selectable languages. The `code` here is the same key used
  /// in the translation maps AND the [Locale] language code, so the three stay
  /// in lock-step. Right-to-left languages carry `isRtl: true`.
  static const List<AppLanguage> supported = [
    AppLanguage('en', 'English', 'English'),
    AppLanguage('es', 'Español', 'Spanish'),
    AppLanguage('hi', 'हिन्दी', 'Hindi'),
    AppLanguage('gu', 'ગુજરાતી', 'Gujarati'),
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
    'IN': ['en', 'hi', 'gu'],
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

  /// ---------------------------------------------------------------------
  /// ROLLOUT GATE
  ///
  /// Only users in these countries are offered a second language; everyone
  /// else stays on English-only. India first — to widen the rollout, add the
  /// country code here (the language mapping already exists in
  /// [countryLanguages], so this set is the only switch).
  /// ---------------------------------------------------------------------
  static const Set<String> enabledCountries = {'IN'};

  /// Forces a country for testing (e.g. `'IN'` on a US device). Debug only —
  /// set it before [detectCountry] runs. Never set in production code.
  static String? debugCountryOverride;

  /// Maps an IANA timezone to a country, used when the device locale carries
  /// no usable country — e.g. an Indian user whose phone is set to
  /// "English (United States)" still sits in `Asia/Kolkata`.
  static const Map<String, String> _timezoneCountries = {
    'Asia/Kolkata': 'IN',
    'Asia/Calcutta': 'IN', // legacy alias still reported by some Android builds
    'Asia/Tokyo': 'JP',
    'Europe/Paris': 'FR',
    'Europe/Berlin': 'DE',
    'Europe/Madrid': 'ES',
    'Europe/Rome': 'IT',
    'America/Sao_Paulo': 'BR',
    'Europe/Lisbon': 'PT',
    'Asia/Seoul': 'KR',
    'Asia/Shanghai': 'CN',
    'Europe/Moscow': 'RU',
    'Asia/Jakarta': 'ID',
    'Asia/Bangkok': 'TH',
    'Asia/Ho_Chi_Minh': 'VN',
    'Europe/Istanbul': 'TR',
    'Asia/Riyadh': 'SA',
    'Asia/Dubai': 'AE',
    'Asia/Jerusalem': 'IL',
    'Asia/Tehran': 'IR',
    'Asia/Dhaka': 'BD',
    'Asia/Karachi': 'PK',
    'Europe/Amsterdam': 'NL',
    'Europe/Warsaw': 'PL',
    'Asia/Kuala_Lumpur': 'MY',
    'Africa/Dar_es_Salaam': 'TZ',
  };

  static const Locale fallbackLocale = Locale('en');

  static const String _countryPrefKey = 'detected_country_code';

  static String _current = 'en';

  static String _resolvedCountry = '';

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
      // Last known country, so the very first frame already has the right
      // language options even before [detectCountry] finishes.
      _resolvedCountry = prefs.getString(_countryPrefKey) ?? '';

      log(_countryPrefKey);
    } catch (_) {
      _current = 'en';
    }
  }

  /// Resolve which country the user is in, and remember it.
  ///
  /// The device locale is checked first because it is synchronous and free.
  /// When it doesn't yield a country we're rolling out to, the timezone is
  /// consulted as a second opinion — that's what catches the very common case
  /// of an Indian user whose phone language is "English (United States)" but
  /// whose clock is on `Asia/Kolkata`.
  ///
  /// Safe to call before `runApp`; failures fall back to the locale country.
  static Future<String> detectCountry() async {
    if (debugCountryOverride != null) {
      _resolvedCountry = debugCountryOverride!.toUpperCase();
      return _resolvedCountry;
    }

    var country = deviceCountryCode;

    // Only pay for the platform channel when the locale hasn't already put us
    // in a rollout country.
    if (!enabledCountries.contains(country)) {
      final fromZone = await _countryFromTimezone();
      if (fromZone.isNotEmpty &&
          (country.isEmpty || enabledCountries.contains(fromZone))) {
        country = fromZone;
      }
    }

    if (country.isNotEmpty) {
      _resolvedCountry = country;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_countryPrefKey, country);
      } catch (_) {
        // Not persisting just means we re-detect next launch — harmless.
      }
    }
    log(_resolvedCountry);
    return _resolvedCountry;
  }

  static Future<String> _countryFromTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 2),
      );
      return _timezoneCountries[zone] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// The country we believe the user is in. Falls back to the locale country
  /// when [detectCountry] hasn't run or couldn't resolve one.
  static String get resolvedCountryCode =>
      debugCountryOverride?.toUpperCase() ??
      (_resolvedCountry.isNotEmpty ? _resolvedCountry : deviceCountryCode);

  /// The languages actually offered in the Language screen.
  ///
  /// English is always present and always first. A second language is added
  /// only for countries inside the [enabledCountries] rollout. The user's
  /// current language is always included too, so someone who picked a language
  /// before the rollout gate existed can still see and change it.
  static List<AppLanguage> get selectableLanguages {
    final codes = <String>{'en', _current};

    final country = resolvedCountryCode;
    if (enabledCountries.contains(country)) {
      codes.addAll(countryLanguages[country] ?? const <String>[]);
    }

    final list = supported.where((l) => codes.contains(l.code)).toList();
    // Keep English pinned to the top; the rest follow [supported] order.
    list.sort((a, b) {
      if (a.code == 'en') return -1;
      if (b.code == 'en') return 1;
      return 0;
    });
    return list;
  }

  /// Non-English languages worth pre-downloading for this user, in priority
  /// order. Empty for users outside the rollout — they never leave English, so
  /// downloading a model would waste their data.
  static List<String> get preloadLanguages =>
      selectableLanguages.map((l) => l.code).where((c) => c != 'en').toList();

  static String get deviceLanguageCode {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    return _isSupported(code) ? code : 'en';
  }

  static String get deviceCountryCode {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;

    return locale.countryCode?.toUpperCase() ?? '';
  }

  /// Languages available to this user, as plain codes. Gated by
  /// [enabledCountries] so users outside the rollout stay English-only.
  static List<String> get deviceLanguages =>
      selectableLanguages.map((l) => l.code).toList();

  /// Switch the whole app to [code] immediately (no restart) and remember it.
  static Future<void> setLanguage(String code) async {
    if (!_isSupported(code)) return;
    _current = code;
    Get.updateLocale(Locale(code));
    languageVersion.value++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {
      // A failed write just means the choice won't persist; the live switch
      // above still applied, so we swallow it rather than crash.
    }
  }
}
