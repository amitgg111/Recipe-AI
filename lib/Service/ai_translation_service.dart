import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
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
  // Tracks which languages (by bcp code) have EVERY current recipe cached,
  // so a manual switch can go straight to cache instead of live-translating.
  static final Set<String> _fullyPrewarmedBcp = {};
  static final Map<String, Completer<void>> _prewarmCompleters = {};

  // Serializes downloadModel() calls per bcp code. Without this, the live
  // _prepare() (triggered by a manual language switch) and the background
  // prewarmLanguage() sweep can both call downloadModel() for the SAME
  // language at the same instant — ML Kit's native side doesn't handle that
  // cleanly and one call throws, silently leaving _translator null forever
  // with no retry. Every caller now shares the same in-flight download.
  // Serializes downloadModel() calls per bcp. Without this, two callers
  // racing on the SAME language (e.g. splash's background sweep + a
  // manual switch, or two overlapping sweeps) both call downloadModel()
  // for it at once — ML Kit's native side doesn't handle that cleanly,
  // one call errors, and the live translator's _prepare() can get stuck
  // with no automatic recovery.
  static final Map<String, Future<void>> _modelDownloadLocks = {};

  static Future<void> _ensureModelDownloaded(String bcp) {
    final existing = _modelDownloadLocks[bcp];
    if (existing != null) return existing;

    final future = () async {
      final manager = OnDeviceTranslatorModelManager();
      if (!await manager.isModelDownloaded(bcp)) {
        await manager.downloadModel(bcp, isWifiRequired: false);
      }
    }();

    _modelDownloadLocks[bcp] = future;
    future.whenComplete(() => _modelDownloadLocks.remove(bcp));
    return future;
  }

  /// True once prewarm has finished caching every recipe for this language.
  /// English / unsupported codes are always "ready" (nothing to translate).
  static bool isPrewarmed(String code) {
    final target = _mlKitFor(code);
    if (target == null) return true;
    return _fullyPrewarmedBcp.contains(target.bcpCode);
  }

  /// Resolves immediately if already prewarmed; otherwise waits for the
  /// in-flight splash-time prewarm to finish. Call this right before a
  /// manual switch so the UI can show a brief spinner instead of falling
  /// back to a screen full of live translateText() calls.
  static Future<void> waitUntilPrewarmed(String code) {
    final target = _mlKitFor(code);
    if (target == null) return Future.value();
    final bcp = target.bcpCode;
    if (_fullyPrewarmedBcp.contains(bcp)) return Future.value();
    return (_prewarmCompleters[bcp] ??= Completer<void>()).future;
  }

  static void _markPrewarmed(String bcp) {
    _fullyPrewarmedBcp.add(bcp);
    final c = _prewarmCompleters.remove(bcp);
    if (c != null && !c.isCompleted) c.complete();
  }

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
  static Future<void> prewarmLanguage(
    String code, {
    int? maxRecipes,
    User? knownUser,
  }) async {
    final target = _mlKitFor(code);
    if (target == null) return; // English, or a language ML Kit can't do

    // Only prewarm the language(s) this user's COUNTRY is actually rolled out
    // to (e.g. India -> hi). Any other language — even if passed in by a
    // caller that loops over all 26 supported languages — is skipped outright,
    // so no model ever downloads and no recipe text ever gets translated for
    // it. This makes the guard live at the single choke point every prewarm
    // path goes through, instead of depending on every caller filtering first.
    if (!LanguageService.preloadLanguages.contains(code)) {
      log(
        '⏭️ Prewarm[$code]: not this country\'s alternate language — skipped',
      );
      return;
    }

    final bcp = target.bcpCode;

    try {
      await _ensureModelDownloaded(
        bcp,
      ); // <-- shared lock thi download, direct manager call nahi
    } catch (e) {
      log('❌ Prewarm: model download failed [$code]: $e');
      return;
    }
    final user = knownUser ?? FirebaseAuth.instance.currentUser;

    if (user == null) {
      log('⏭️ Prewarm[$code]: signed out — model ready, no text to cache');
      return;
    }

    final cache = _cacheFor(bcp);

    try {
      var query = FirebaseFirestore.instance
          .collection('recipes')
          .where('ownerId', isEqualTo: user.uid);
      if (maxRecipes != null) query = query.limit(maxRecipes);
      final snap = await query.get();
      final texts = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        for (final key in const [
          'title',
          'description',
          'prepTime',
          'totalTime',
        ]) {
          final value = data[key];
          if (value is String && value.trim().isNotEmpty) {
            texts.add(value.trim());
          }
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

      final translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: target,
      );

      try {
        const batchSize = 8;
        for (int i = 0; i < missing.length; i += batchSize) {
          final batch = missing.skip(i).take(batchSize).toList();
          final results = await Future.wait(
            batch.map((text) async {
              try {
                return MapEntry(
                  text,
                  (await translator.translateText(text)).trim(),
                );
              } catch (_) {
                return MapEntry(text, '');
              }
            }),
          );
          for (final entry in results) {
            if (entry.value.isEmpty) continue;
            cache[entry.key] = entry.value;
          }
        }
        await _saveCache();
      } finally {
        await translator.close();
      }
      if (missing.isEmpty) {
        _markPrewarmed(bcp);
        return;
      }

      log('✅ Prewarm[$code]: cache warm, ${cache.length} entries');
      _markPrewarmed(bcp);
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

    if (languages.isEmpty) {
      log(
        '✅ No alternate languages for this country/rollout — nothing to prepare',
      );
      return;
    }

    // Resolve auth ONCE for the whole batch instead of per language.
    final user =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);

    if (user == null) {
      log(
        '⏭️ Prewarm: no signed-in user yet — models will still download, recipe cache skipped',
      );
    }

    for (final language in languages) {
      await prewarmLanguage(language, knownUser: user);
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

  // static Future<bool> _prepare(TranslateLanguage target, String bcp) async {
  //   isPreparing.value = true;

  //   try {
  //     final manager = OnDeviceTranslatorModelManager();

  //     final downloaded = await manager.isModelDownloaded(bcp);

  //     if (!downloaded) {
  //       await manager.downloadModel(bcp, isWifiRequired: false);
  //     }

  //     await _translator?.close();

  //     _translator = OnDeviceTranslator(
  //       sourceLanguage: _source,
  //       targetLanguage: target,
  //     );

  //     _readyBcp = bcp;

  //     _cacheFor(bcp);

  //     return true;
  //   } catch (_) {
  //     return false;
  //   } finally {
  //     isPreparing.value = false;
  //     _preparing = null;
  //   }
  // }
  static Future<bool> _prepare(TranslateLanguage target, String bcp) async {
    isPreparing.value = true;
    try {
      await _ensureModelDownloaded(bcp);

      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: _source,
        targetLanguage: target,
      );
      _readyBcp = bcp;
      _cacheFor(bcp);
      return true;
    } catch (e) {
      log('❌ _prepare failed for $bcp: $e');
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
      await _ensureModelDownloaded(bcp);
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

  static Future<void>? _savePending;

  /// Persist the cache, coalescing bursts into a single write.
  ///
  /// Every cache miss used to trigger its own full rewrite of the entire
  /// multi-language blob, on the UI isolate. A screen with 20 [TrText] rows
  /// therefore re-encoded and re-wrote the whole cache 20 times in one frame,
  /// which is the bulk of the "translation is slow / janky" symptom.
  ///
  /// GetStorage holds `_cache` BY REFERENCE and serializes at flush time, so a
  /// write already queued in this microtask turn will include anything added
  /// before it runs — riding on it is not just cheaper, it is equivalent.
  static Future<void> _saveCache() {
    return _savePending ??= Future.microtask(() async {
      _savePending = null;
      await _storage.write(_cacheKey, _cache);
    });
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
            // Empty marks a failure. Never cache the English source as though
            // it were the translation: the miss check above is
            // `!cache.containsKey(text)`, so doing that pins the string to
            // English permanently with no retry. One flaky moment would leave
            // a single line stubbornly English inside a translated recipe —
            // exactly the "some texts don't translate" symptom.
            return MapEntry(text, '');
          }
        }),
      );

      for (final entry in results) {
        if (entry.value.isEmpty) continue; // failed — retry on a later render
        cache[entry.key] = entry.value;
      }
    }

    // ONE disk write per call instead of one per batch of 8. GetStorage holds
    // `_cache` by reference and serializes at flush time, so every
    // intermediate write was re-encoding the entire multi-language blob for
    // nothing — on the UI isolate.
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

  static final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );

  static Future<String> translateToEnglish(String? text) async {
    final input = text?.trim() ?? '';

    if (input.isEmpty) return input;

    try {
      // Detect source language
      final detectedLanguage = await _languageIdentifier.identifyLanguage(
        input,
      );

      log('🌍 Detected language: $detectedLanguage');

      // Already English
      if (detectedLanguage == 'en') {
        return input;
      }

      // Unknown language
      if (detectedLanguage == 'und') {
        return input;
      }

      final sourceLanguage = _sourceLanguageFor(detectedLanguage);

      // Unsupported language
      if (sourceLanguage == null) {
        log('⚠️ Unsupported source language: $detectedLanguage');
        return input;
      }

      final manager = OnDeviceTranslatorModelManager();

      final sourceBcp = sourceLanguage.bcpCode;
      final englishBcp = TranslateLanguage.english.bcpCode;

      // Download source language model if required
      if (!await manager.isModelDownloaded(sourceBcp)) {
        await manager.downloadModel(sourceBcp, isWifiRequired: false);
      }

      // Download English model if required
      if (!await manager.isModelDownloaded(englishBcp)) {
        await manager.downloadModel(englishBcp, isWifiRequired: false);
      }

      final translator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: TranslateLanguage.english,
      );

      try {
        final result = await translator.translateText(input);

        final translated = result.trim();

        return translated.isEmpty ? input : translated;
      } finally {
        await translator.close();
      }
    } catch (e) {
      log('❌ translateToEnglish error: $e');

      // Translation fail થાય તો original data ગુમાવવું નહીં.
      return input;
    }
  }
  // AiTranslationService ma umero:

  /// Fast, dependency-free source-language guess from the Unicode script of
  /// the text. Doesn't rely on the ML Kit language-identifier plugin at all —
  /// so it works even if that plugin's native side isn't registered
  /// (MissingPluginException), and it's instant/offline.
  static TranslateLanguage? _scriptBasedLanguage(String text) {
    bool hasRange(String pattern) => RegExp(pattern).hasMatch(text);

    if (hasRange(r'[\u0A80-\u0AFF]')) return TranslateLanguage.gujarati;
    if (hasRange(r'[\u0900-\u097F]')) {
      return TranslateLanguage.hindi; // Devanagari (Hindi/Marathi)
    }
    if (hasRange(r'[\u0980-\u09FF]')) return TranslateLanguage.bengali;
    if (hasRange(r'[\u0B80-\u0BFF]')) return TranslateLanguage.tamil;
    if (hasRange(r'[\u0C00-\u0C7F]')) return TranslateLanguage.telugu;
    if (hasRange(r'[\u0C80-\u0CFF]')) return TranslateLanguage.kannada;
    if (hasRange(r'[\u0600-\u06FF]')) return TranslateLanguage.arabic;
    if (hasRange(r'[\u0590-\u05FF]')) return TranslateLanguage.hebrew;
    if (hasRange(r'[\u0400-\u04FF]')) return TranslateLanguage.russian;
    if (hasRange(r'[\u4E00-\u9FFF]')) return TranslateLanguage.chinese;
    if (hasRange(r'[\u3040-\u30FF]')) return TranslateLanguage.japanese;
    if (hasRange(r'[\uAC00-\uD7AF]')) return TranslateLanguage.korean;
    if (hasRange(r'[\u0E00-\u0E7F]')) return TranslateLanguage.thai;

    return null; // Latin script or unrecognized -> let ML Kit / assume English
  }

  /// Detects the dominant language using COMBINED representative text
  /// (title + description + a few ingredients/steps) instead of one string
  /// at a time — short strings like a single ingredient are unreliable for
  /// language identification.
  static Future<String> detectDominantLanguage(List<String> sampleTexts) async {
    final combined = sampleTexts
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(6)
        .join('. ');

    if (combined.isEmpty) return 'und';
    final scriptLang = _scriptBasedLanguage(combined);
    if (scriptLang != null) {
      final code = _codeFor(scriptLang);
      log('🌍 Script-detected language: $code');
      return code;
    }
    try {
      final detected = await _languageIdentifier.identifyLanguage(combined);
      log('🌍 Dominant language detected: $detected (sample: "$combined")');
      return detected;
    } catch (e) {
      log('❌ detectDominantLanguage error: $e');
      return 'und';
    }
  }

  static String _codeFor(TranslateLanguage lang) {
    const map = {
      TranslateLanguage.gujarati: 'gu',
      TranslateLanguage.hindi: 'hi',
      TranslateLanguage.bengali: 'bn',
      TranslateLanguage.tamil: 'ta',
      TranslateLanguage.telugu: 'te',
      TranslateLanguage.kannada: 'kn',
      TranslateLanguage.arabic: 'ar',
      TranslateLanguage.hebrew: 'he',
      TranslateLanguage.russian: 'ru',
      TranslateLanguage.chinese: 'zh',
      TranslateLanguage.japanese: 'ja',
      TranslateLanguage.korean: 'ko',
      TranslateLanguage.thai: 'th',
    };
    return map[lang] ?? 'und';
  }

  /// Downloads models (if needed) and returns a ready-to-use translator for
  /// [languageCode] -> English. Returns null if unsupported or download fails.
  static Future<OnDeviceTranslator?> prepareTranslatorFor(
    String languageCode,
  ) async {
    if (languageCode == 'en' || languageCode == 'und') return null;

    final sourceLanguage = _sourceLanguageFor(languageCode);
    if (sourceLanguage == null) {
      log('⚠️ Unsupported source language: $languageCode');
      return null;
    }

    final manager = OnDeviceTranslatorModelManager();
    final sourceBcp = sourceLanguage.bcpCode;
    final englishBcp = TranslateLanguage.english.bcpCode;

    try {
      if (!await manager.isModelDownloaded(sourceBcp)) {
        await manager.downloadModel(sourceBcp, isWifiRequired: false);
      }
      if (!await manager.isModelDownloaded(englishBcp)) {
        await manager.downloadModel(englishBcp, isWifiRequired: false);
      }
    } catch (e) {
      log('❌ Model download failed for $languageCode: $e');
      return null;
    }

    return OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: TranslateLanguage.english,
    );
  }

  /// Translates one string using an already-prepared translator (reused
  /// across a whole recipe instead of creating a new one per string).
  static Future<String> translateWithTranslator(
    OnDeviceTranslator? translator,
    String? text,
  ) async {
    final input = text?.trim() ?? '';
    if (input.isEmpty || translator == null) return input;

    try {
      final result = (await translator.translateText(input)).trim();
      return result.isEmpty ? input : result;
    } catch (e) {
      log('❌ translateWithTranslator failed: $e');
      return input;
    }
  }

  /// One sequence, called exactly once, that covers everything
  /// AiTranslationService needs to do at startup:
  /// 1. Download + fully cache every alternate language this user's country
  ///    is rolled out to (e.g. India -> Hindi) — no recipe-count cap.
  /// 2. Top up the cache for whatever language is ALREADY active (covers the
  ///    case where a returning user's saved language isn't English).

  static TranslateLanguage? _sourceLanguageFor(String code) {
    switch (code.toLowerCase()) {
      case 'af':
        return TranslateLanguage.afrikaans;

      case 'sq':
        return TranslateLanguage.albanian;

      case 'ar':
        return TranslateLanguage.arabic;

      case 'be':
        return TranslateLanguage.belarusian;

      case 'bn':
        return TranslateLanguage.bengali;

      case 'bg':
        return TranslateLanguage.bulgarian;

      case 'ca':
        return TranslateLanguage.catalan;

      case 'zh':
        return TranslateLanguage.chinese;

      case 'hr':
        return TranslateLanguage.croatian;

      case 'cs':
        return TranslateLanguage.czech;

      case 'da':
        return TranslateLanguage.danish;

      case 'nl':
        return TranslateLanguage.dutch;

      case 'en':
        return TranslateLanguage.english;

      case 'eo':
        return TranslateLanguage.esperanto;

      case 'et':
        return TranslateLanguage.estonian;

      case 'fi':
        return TranslateLanguage.finnish;

      case 'fr':
        return TranslateLanguage.french;

      case 'gl':
        return TranslateLanguage.galician;

      case 'ka':
        return TranslateLanguage.georgian;

      case 'de':
        return TranslateLanguage.german;

      case 'el':
        return TranslateLanguage.greek;

      case 'gu':
        return TranslateLanguage.gujarati;

      case 'ht':
        return TranslateLanguage.haitian;

      case 'he':
        return TranslateLanguage.hebrew;

      case 'hi':
        return TranslateLanguage.hindi;

      case 'hu':
        return TranslateLanguage.hungarian;

      case 'is':
        return TranslateLanguage.icelandic;

      case 'id':
        return TranslateLanguage.indonesian;

      case 'ga':
        return TranslateLanguage.irish;

      case 'it':
        return TranslateLanguage.italian;

      case 'ja':
        return TranslateLanguage.japanese;

      case 'kn':
        return TranslateLanguage.kannada;

      case 'ko':
        return TranslateLanguage.korean;

      case 'lv':
        return TranslateLanguage.latvian;

      case 'lt':
        return TranslateLanguage.lithuanian;

      case 'mk':
        return TranslateLanguage.macedonian;

      case 'ms':
        return TranslateLanguage.malay;

      case 'mt':
        return TranslateLanguage.maltese;

      case 'mr':
        return TranslateLanguage.marathi;

      case 'no':
        return TranslateLanguage.norwegian;

      case 'fa':
        return TranslateLanguage.persian;

      case 'pl':
        return TranslateLanguage.polish;

      case 'pt':
        return TranslateLanguage.portuguese;

      case 'ro':
        return TranslateLanguage.romanian;

      case 'ru':
        return TranslateLanguage.russian;

      case 'sk':
        return TranslateLanguage.slovak;

      case 'sl':
        return TranslateLanguage.slovenian;

      case 'es':
        return TranslateLanguage.spanish;

      case 'sw':
        return TranslateLanguage.swahili;

      case 'sv':
        return TranslateLanguage.swedish;

      case 'tl':
      case 'fil':
        return TranslateLanguage.tagalog;

      case 'ta':
        return TranslateLanguage.tamil;

      case 'te':
        return TranslateLanguage.telugu;

      case 'th':
        return TranslateLanguage.thai;

      case 'tr':
        return TranslateLanguage.turkish;

      case 'uk':
        return TranslateLanguage.ukrainian;

      case 'ur':
        return TranslateLanguage.urdu;

      case 'vi':
        return TranslateLanguage.vietnamese;

      case 'cy':
        return TranslateLanguage.welsh;

      default:
        return null;
    }
  }

  /// Every supported language (26, minus English) — NOT gated by country.
  /// Used so background prewarm covers any language the user could ever
  /// pick from the Language screen, regardless of rollout.
  static Future<void> prepareAllSupportedLanguages() async {
    final languages = LanguageService.supportedLocales
        .map((l) => l.languageCode)
        .where((c) => c != 'en')
        .toSet()
        .toList();

    log('🌐 Preparing ALL supported languages: $languages');

    // Resolve auth ONCE — not per language. A guest (onboarding, not signed
    // in yet) was making every single prewarmLanguage() call independently
    // wait up to 8s for a user that may never arrive, turning a 25-language
    // loop into minutes of dead time.
    final user =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 8), onTimeout: () => null);

    if (user == null) {
      log(
        '⏭️ No signed-in user yet — downloading models only, skipping recipe cache',
      );
    }

    // Bounded parallelism: 4 languages at a time instead of fully sequential.
    // Model downloads + translateText calls are network/IO bound, so this cuts
    // wall-clock time roughly 4x without hammering the device.
    const concurrency = 4;
    for (var i = 0; i < languages.length; i += concurrency) {
      final batch = languages.skip(i).take(concurrency);
      await Future.wait(
        batch.map((lang) => prewarmLanguage(lang, knownUser: user)),
      );
    }

    log('✅ All supported languages prepared');
  }

  /// Single entry point, called ONCE from Splash's initState:
  /// 1. Download + fully cache EVERY supported language's model + recipe
  ///    translations (not just the country's rollout language) — so
  ///    switching to ANY language from the Language screen is instant.
  /// 2. Top up the cache for whatever language is already active right now.
  /// Single entry point, called ONCE from Splash's initState:
  /// 1. If this user's country has an alternate language (e.g. India -> Hindi),
  ///    fire its model download + recipe-cache warm-up immediately, unawaited —
  ///    that's the language they're actually likely to switch to, so it must
  ///    not sit behind the full 26-language sweep below.
  /// 2. Top up the cache for whatever language is already active right now.
  /// 3. Only after that, sweep every other supported language so switching to
  ///    ANY language from the Language screen is eventually instant too.
  static Future<void> prepareTranslationsInBackground() async {
    final alternates = LanguageService.preloadLanguages;
    if (alternates.isNotEmpty) {
      log(
        '🌐 Alternate language(s) for this country: $alternates — prioritizing',
      );
      unawaited(prepareAlternateLanguages());
    }

    await prewarmExistingRecipesTranslation();
    await prepareAllSupportedLanguages();
  }
}
