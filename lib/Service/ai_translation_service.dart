import 'package:get/get.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:recipe_ai/Service/language_service.dart';

/// On-device translation of Firebase content (recipe titles, ingredients,
/// steps, categories …) from the stored English into the app's current
/// language, using Google ML Kit.
///
/// Firestore always stores English. This service turns that English into the
/// selected language for DISPLAY only — callers keep the English originals for
/// any logic (search, filtering, saving).
///
/// Three things make it actually work (all were missing before):
///  1. The target language MODEL is downloaded on demand — `translateText()`
///     fails silently to English without it. [ensureReady] handles that and
///     exposes [isPreparing] so the UI can show a "preparing translations"
///     state the first time a language is picked.
///  2. Results are cached in memory per language, so a string that appears in
///     many recipes (an ingredient, "Breakfast", a cuisine) is translated once
///     and always rendered the same way — consistent, natural tone.
///  3. [onLanguageChanged] rebuilds the translator for the new language so a
///     live language switch re-translates instead of showing stale text.
class AiTranslationService {
  AiTranslationService._();

  static const TranslateLanguage _source = TranslateLanguage.english;

  static OnDeviceTranslator? _translator;
  static String? _readyBcp; // target the translator+model are ready for
  static Future<bool>? _preparing; // de-dupes concurrent ensureReady() calls

  /// bcpCode -> { englishText : translatedText }. In-memory; ML Kit already
  /// caches the (expensive) model on disk, so per-string re-translation on a
  /// cold start is cheap.
  static final Map<String, Map<String, String>> _cache = {};

  /// True while a language model is being downloaded (first use of a language).
  static final RxBool isPreparing = false.obs;

  /// Whether the current language needs (and can use) translation at all.
  static bool get isTranslating => _mlKitFor(LanguageService.currentCode) != null;

  /// Maps an app language code to its ML Kit language, or null for English /
  /// anything ML Kit can't translate (then content simply stays English).
  static TranslateLanguage? _mlKitFor(String code) {
    switch (code) {
      case 'hi': return TranslateLanguage.hindi;
      case 'es': return TranslateLanguage.spanish;
      case 'de': return TranslateLanguage.german;
      case 'fr': return TranslateLanguage.french;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ar': return TranslateLanguage.arabic;
      case 'id': return TranslateLanguage.indonesian;
      case 'ru': return TranslateLanguage.russian;
      case 'ja': return TranslateLanguage.japanese;
      case 'zh': return TranslateLanguage.chinese;
      case 'ko': return TranslateLanguage.korean;
      case 'he': return TranslateLanguage.hebrew;
      case 'tr': return TranslateLanguage.turkish;
      case 'it': return TranslateLanguage.italian;
      case 'vi': return TranslateLanguage.vietnamese;
      case 'th': return TranslateLanguage.thai;
      case 'fil': return TranslateLanguage.tagalog;
      case 'bn': return TranslateLanguage.bengali;
      case 'ur': return TranslateLanguage.urdu;
      case 'fa': return TranslateLanguage.persian;
      case 'pl': return TranslateLanguage.polish;
      case 'nl': return TranslateLanguage.dutch;
      case 'ta': return TranslateLanguage.tamil;
      case 'ms': return TranslateLanguage.malay;
      case 'sw': return TranslateLanguage.swahili;
      case 'en':
      default:
        return null;
    }
  }

  static Map<String, String> _cacheFor(String bcp) =>
      _cache.putIfAbsent(bcp, () => <String, String>{});

  /// Ensure the model for the current language is downloaded and the translator
  /// is built. Idempotent and safe to call from many places at once. Returns
  /// false when there's nothing to do (English) or the model can't be obtained
  /// (offline first-run) — callers then just show English.
  static Future<bool> ensureReady() async {
    final target = _mlKitFor(LanguageService.currentCode);
    if (target == null) return false; // English / unsupported → no translation
    final bcp = target.bcpCode;
    if (_readyBcp == bcp && _translator != null) return true;
    // Collapse concurrent callers onto a single download+build.
    return _preparing ??= _prepare(target, bcp);
  }

  static Future<bool> _prepare(TranslateLanguage target, String bcp) async {
    isPreparing.value = true;
    try {
      final manager = OnDeviceTranslatorModelManager();
      if (!await manager.isModelDownloaded(bcp)) {
        // isWifiRequired:false so it also downloads on mobile data.
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
      return false; // e.g. offline with no model yet → stay English
    } finally {
      isPreparing.value = false;
      _preparing = null;
    }
  }

  /// Synchronous best-effort lookup for the FIRST frame: the already-cached
  /// translation if we have one, otherwise the English input unchanged. Widgets
  /// (see [TrText]) render this instantly, then call [translate] to fill in and
  /// rebuild — so repeat strings never flicker and new ones degrade to English
  /// for a moment instead of showing a blank.
  static String cachedOrSelf(String? text) {
    final input = text ?? '';
    if (input.trim().isEmpty) return input;
    final target = _mlKitFor(LanguageService.currentCode);
    if (target == null) return input;
    return _cacheFor(target.bcpCode)[input] ?? input;
  }

  /// Translate a single string. Returns the input unchanged for English, empty
  /// input, a cache hit's stored value, or any failure (so the UI never breaks).
  static Future<String> translate(String? text) async {
    final input = text ?? '';
    if (input.trim().isEmpty) return input;

    final target = _mlKitFor(LanguageService.currentCode);
    if (target == null) return input;
    final bcp = target.bcpCode;

    final cache = _cacheFor(bcp);
    final cached = cache[input];
    if (cached != null) return cached;

    if (_readyBcp != bcp || _translator == null) {
      final ok = await ensureReady();
      if (!ok || _translator == null) return input;
    }

    try {
      final out = await _translator!.translateText(input);
      if (out.trim().isNotEmpty) cache[input] = out;
      return out.trim().isEmpty ? input : out;
    } catch (_) {
      return input; // not cached → retried next time
    }
  }

  /// Translate a list, reusing the cache across items.
  static Future<List<String>> translateList(List<String> items) async {
    if (items.isEmpty) return items;
    if (_mlKitFor(LanguageService.currentCode) == null) return items;
    await ensureReady();
    return Future.wait(items.map(translate));
  }

  /// Call right after the app language changes: rebuild the translator for the
  /// new language and pre-download its model. Controllers should then re-run
  /// their translation pass (e.g. HomeController.refreshRecipesLanguage()).
  static Future<void> onLanguageChanged() async {
    await _translator?.close();
    _translator = null;
    _readyBcp = null;
    _preparing = null;
    await ensureReady();
  }

  static void reset() {
    _translator?.close();
    _translator = null;
    _readyBcp = null;
    _preparing = null;
  }

  static void dispose() => reset();
}
