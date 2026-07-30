import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:recipe_ai/Service/language_service.dart';

class AiTranslationService {
  AiTranslationService._();

  static const TranslateLanguage _source = TranslateLanguage.english;

  static OnDeviceTranslator? _translator;
  static String? _readyBcp;
  static Future<bool>? _preparing;

  static final Map<String, Map<String, String>> _cache = {};
  static final GetStorage _storage = GetStorage();

  static const String _cacheKey = 'ai_translation_cache';
  static final RxBool isPreparing = false.obs;

  static bool get isTranslating =>
      _mlKitFor(LanguageService.currentCode) != null;

  static TranslateLanguage? _mlKitFor(String code) {
    switch (code) {
      case 'hi':
        return TranslateLanguage.hindi;
      case 'es':
        return TranslateLanguage.spanish;
      case 'de':
        return TranslateLanguage.german;
      case 'fr':
        return TranslateLanguage.french;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'ru':
        return TranslateLanguage.russian;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'he':
        return TranslateLanguage.hebrew;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'it':
        return TranslateLanguage.italian;
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'th':
        return TranslateLanguage.thai;
      case 'fil':
        return TranslateLanguage.tagalog;
      case 'bn':
        return TranslateLanguage.bengali;
      case 'ur':
        return TranslateLanguage.urdu;
      case 'fa':
        return TranslateLanguage.persian;
      case 'pl':
        return TranslateLanguage.polish;
      case 'nl':
        return TranslateLanguage.dutch;
      case 'ta':
        return TranslateLanguage.tamil;
      case 'ms':
        return TranslateLanguage.malay;
      case 'sw':
        return TranslateLanguage.swahili;
      default:
        return null;
    }
  }

  static Map<String, String> _cacheFor(String bcp) {
    final existing = _cache[bcp];

    if (existing != null) {
      return existing;
    }

    final saved = _storage.read<Map>(_cacheKey);

    final languageCache = Map<String, String>.from(
      (saved?[bcp] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
    );

    _cache[bcp] = languageCache;

    return languageCache;
  }

  /// Pre-warm the translation cache for ALL of the user's existing recipes in
  /// the background — same idea as model preload, but for actual TEXT. Meant
  /// to be fired (unawaited) from splash so that by the time the user opens
  /// any recipe, `cachedOrSelf()` already has a hit and no live translate()
  /// call (like the one in your log) runs on the UI thread.
  static Future<void> prewarmExistingRecipesTranslation() async {
    final target = _mlKitFor(LanguageService.currentCode);
    if (target == null) return; // English -> nothing to pre-translate

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // logged out user pase recipes j nathi

    try {
      final snap = await FirebaseFirestore.instance
          .collection('recipes')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      log('🌐 Prewarm: found ${snap.docs.length} existing recipe(s) to cache');

      for (final doc in snap.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        final prepTime = data['prepTime'] as String?;
        final totalTime = data['totalTime'] as String?;
        final ingredients =
            (data['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
        final instructions =
            (data['instructions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];

        if (title != null) await translate(title);
        if (prepTime != null) await translate(prepTime);
        if (totalTime != null) await translate(totalTime);
        if (ingredients.isNotEmpty) await translateList(ingredients);
        if (instructions.isNotEmpty) await translateList(instructions);
      }

      log('✅ Prewarm: existing recipes cache warm');
    } catch (e) {
      log('❌ Prewarm existing recipes failed: $e');
    }
  }

  /// Warm the cache for a language the user has NOT switched to yet.
  ///
  /// [prewarmExistingRecipesTranslation] can only ever warm the *current*
  /// language, so at startup — when everyone is on English — it returns
  /// immediately and warms nothing. This does the opposite: it downloads the
  /// model for [code] and pre-translates the user's recipes into it using a
  /// throwaway translator, leaving the live one untouched. By the time the
  /// user taps "हिन्दी", the strings are already cached and the switch is
  /// instant instead of a screen full of live `translateText()` calls.
  ///
  /// Capped so a large library can't turn app start into a long CPU burn.
  static Future<void> prewarmLanguage(String code, {int maxRecipes = 40}) async {
    final target = _mlKitFor(code);
    if (target == null) return; // English, or a language ML Kit can't do

    final bcp = target.bcpCode;

    try {
      final manager = OnDeviceTranslatorModelManager();
      if (!await manager.isModelDownloaded(bcp)) {
        log('⬇️ Prewarm: downloading model for $code ($bcp)');
        await manager.downloadModel(bcp, isWifiRequired: false);
      }
    } catch (e) {
      log('❌ Prewarm: model download failed [$code]: $e');
      return; // no model, nothing else to do
    }

    // On a cold start Firebase restores the session asynchronously, so
    // `currentUser` is usually still null at splash time. The model download
    // above doesn't care, but pre-translating the user's recipes does — so
    // give auth a moment to settle rather than silently skipping the cache.
    final user =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 8), onTimeout: () => null);

    if (user == null) {
      log('⏭️ Prewarm[$code]: signed out — model ready, no text to cache');
      return;
    }

    final cache = _cacheFor(bcp);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('recipes')
          .where('ownerId', isEqualTo: user.uid)
          .limit(maxRecipes)
          .get();

      // Collect every translatable string once, then drop the ones already
      // cached from a previous run.
      final texts = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        for (final key in const ['title', 'description', 'prepTime', 'totalTime']) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) texts.add(value.trim());
        }
        for (final key in const ['ingredients', 'instructions']) {
          final list = data[key] as List?;
          if (list == null) continue;
          for (final item in list) {
            final text = item.toString().trim();
            if (text.isNotEmpty) texts.add(text);
          }
        }
      }

      final missing = texts.where((t) => !cache.containsKey(t)).toList();

      log(
        '🌐 Prewarm[$code]: ${snap.docs.length} recipe(s), '
        '${texts.length} string(s), ${missing.length} to translate',
      );

      if (missing.isEmpty) return;

      // A dedicated translator so we never disturb the live one, which may be
      // pointed at a different language (usually English = null).
      final translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: target,
      );

      try {
        const batchSize = 8;
        var failures = 0;
        for (int i = 0; i < missing.length; i += batchSize) {
          final batch = missing.skip(i).take(batchSize).toList();
          final results = await Future.wait(
            batch.map((text) async {
              try {
                return MapEntry(text, (await translator.translateText(text)).trim());
              } catch (_) {
                // Empty marks a failure. Caching the English source here would
                // be permanent: the `missing` check is `!cache.containsKey`,
                // so a dropped connection mid-prewarm would silently pin the
                // whole recipe library to English forever, and every later
                // launch would report the cache warm and do nothing.
                return MapEntry(text, '');
              }
            }),
          );
          for (final entry in results) {
            if (entry.value.isEmpty) {
              failures++;
              continue; // leave absent so a later run retries it
            }
            cache[entry.key] = entry.value;
          }
        }
        if (failures > 0) {
          log('⚠️ Prewarm[$code]: $failures string(s) failed, will retry next launch');
        }
        await _saveCache();
      } finally {
        await translator.close();
      }

      log('✅ Prewarm[$code]: cache warm, ${cache.length} entries');
    } catch (e) {
      log('❌ Prewarm[$code] failed: $e');
    }
  }

  /// Download models and warm the cache for every language this user could
  /// switch to. Fire-and-forget from splash.
  static Future<void> prepareAlternateLanguages() async {
    final languages = LanguageService.preloadLanguages;

    log('🌍 Country: ${LanguageService.resolvedCountryCode}');
    log('🌐 Alternate languages to prepare: $languages');

    for (final language in languages) {
      await prewarmLanguage(language);
    }

    log('✅ Alternate language preparation completed');
  }

  static Future<bool> ensureReady() async {
    final target = _mlKitFor(LanguageService.currentCode);

    if (target == null) return false;

    final bcp = target.bcpCode;

    if (_readyBcp == bcp && _translator != null) {
      return true;
    }

    return _preparing ??= _prepare(target, bcp);
  }

  static Future<bool> _prepare(TranslateLanguage target, String bcp) async {
    isPreparing.value = true;

    try {
      final manager = OnDeviceTranslatorModelManager();

      final downloaded = await manager.isModelDownloaded(bcp);

      if (!downloaded) {
        await manager.downloadModel(bcp, isWifiRequired: false);
      }

      await _translator?.close();

      _translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: target,
      );

      _readyBcp = bcp;

      _cacheFor(bcp);

      return true;
    } catch (_) {
      return false;
    } finally {
      isPreparing.value = false;
      _preparing = null;
    }
  }

  static Future<bool> activateLanguage(String code) async {
    final target = _mlKitFor(code);

    if (target == null || code == 'en') {
      return true;
    }

    final bcp = target.bcpCode;

    try {
      final manager = OnDeviceTranslatorModelManager();

      final downloaded = await manager.isModelDownloaded(bcp);

      if (!downloaded) {
        log('❌ Language model NOT preloaded: $code ($bcp)');
        return false;
      }

      await _translator?.close();

      _translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: target,
      );

      _readyBcp = bcp;
      _cacheFor(bcp);

      log('✅ Language model already downloaded: $code ($bcp)');

      return true;
    } catch (e) {
      log('❌ activateLanguage error [$code]: $e');
      return false;
    }
  }

  static String cachedOrSelf(String? text) {
    final input = text?.trim() ?? '';

    if (input.isEmpty) return input;

    final target = _mlKitFor(LanguageService.currentCode);

    if (target == null) return input;

    return _cacheFor(target.bcpCode)[input] ?? input;
  }

  static Future<void> preloadLanguageModel(String code) async {
    if (code == 'en') return;

    final target = _mlKitFor(code);
    if (target == null) return;

    final bcp = target.bcpCode;

    try {
      final manager = OnDeviceTranslatorModelManager();

      final downloaded = await manager.isModelDownloaded(bcp);

      log('🌐 Preload check: $code ($bcp) downloaded=$downloaded');

      if (!downloaded) {
        log('⬇️ Background downloading: $code ($bcp)');

        await manager.downloadModel(bcp, isWifiRequired: false);

        log('✅ Background download completed: $code');
      }
    } catch (e) {
      log('❌ Background preload failed [$code]: $e');
    }
  }

  static Future<void> preloadDeviceLanguages() async {
    final languages = LanguageService.preloadLanguages;

    log('🌍 Locale: ${WidgetsBinding.instance.platformDispatcher.locale}');
    log('🌍 Resolved country: ${LanguageService.resolvedCountryCode}');
    log('🌐 Models to preload: $languages');

    for (final language in languages) {
      log('🔄 Preparing language model: $language');
      await preloadLanguageModel(language);
    }

    log('✅ Device language preload completed');
  }

  static Future<void> prepareSplashLanguages() async {
    final languages = LanguageService.deviceLanguages;

    log('🚀 Splash language preparation started');
    log('🌍 Country: ${LanguageService.deviceCountryCode}');
    log('🌐 Languages: $languages');

    for (final language in languages) {
      if (language == 'en') {
        continue;
      }

      log('📥 Preparing language: $language');

      await preloadLanguageModel(language);

      log('✅ Model ready: $language');
    }

    log('🎉 Splash language preparation completed');
  }

  static Future<String> translate(String? text) async {
    final input = text?.trim() ?? '';

    if (input.isEmpty) return input;

    final target = _mlKitFor(LanguageService.currentCode);

    if (target == null) return input;

    final bcp = target.bcpCode;
    final cache = _cacheFor(bcp);

    final cached = cache[input];

    if (cached != null) {
      return cached;
    }

    final ready = await ensureReady();

    if (!ready || _translator == null) {
      return input;
    }

    try {
      final result = await _translator!.translateText(input);

      final translated = result.trim();

      if (translated.isNotEmpty) {
        cache[input] = translated;

        await _saveCache();

        return translated;
      }

      return input;
    } catch (_) {
      return input;
    }
  }

  static Future<void> _saveCache() async {
    await _storage.write(_cacheKey, _cache);
  }

  /// FAST BATCH TRANSLATION
  static Future<List<String>> translateList(List<String> items) async {
    if (items.isEmpty) return items;

    final target = _mlKitFor(LanguageService.currentCode);

    if (target == null) return items;

    final bcp = target.bcpCode;
    final cache = _cacheFor(bcp);

    // Remove empty + duplicate strings.
    final uniqueTexts = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final missing = uniqueTexts
        .where((text) => !cache.containsKey(text))
        .toList();

    if (missing.isEmpty) {
      return items.map((e) => cache[e.trim()] ?? e).toList();
    }

    final ready = await ensureReady();

    if (!ready || _translator == null) {
      return items;
    }

    // Translate only missing values.
    //
    // Small batches prevent too many simultaneous ML Kit calls.
    const batchSize = 8;

    for (int i = 0; i < missing.length; i += batchSize) {
      final batch = missing.skip(i).take(batchSize).toList();

      final results = await Future.wait(
        batch.map((text) async {
          try {
            final result = await _translator!.translateText(text);

            return MapEntry(text, result.trim());
          } catch (_) {
            // Empty marks a failure. Never cache the English source as if it
            // were the translation: the miss check above is
            // `!cache.containsKey(text)`, so doing that would pin the string
            // to English permanently, with no retry, ever. One flaky moment
            // would leave a single line stubbornly untranslated inside an
            // otherwise-Hindi recipe.
            return MapEntry(text, '');
          }
        }),
      );

      for (final entry in results) {
        if (entry.value.isEmpty) continue; // failed — retry on a later open
        cache[entry.key] = entry.value;
      }
    }

    // One write per call instead of one per batch of 8. GetStorage stores
    // `_cache` by reference and serializes at flush time, so every
    // intermediate write was doing the whole box again for nothing.
    await _saveCache();

    return items.map((text) {
      final key = text.trim();
      return cache[key] ?? text;
    }).toList();
  }

  static Future<void> onLanguageChanged() async {
    await _translator?.close();

    _translator = null;
    _readyBcp = null;
    _preparing = null;

    // Model download + translator initialization.
    // Cache is kept per language.
    await ensureReady();
  }

  static void reset() {
    _translator?.close();

    _translator = null;
    _readyBcp = null;
    _preparing = null;
  }

  static void dispose() {
    reset();
  }
}
