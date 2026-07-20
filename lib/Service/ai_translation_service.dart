import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:recipe_ai/Service/language_service.dart';

class AiTranslationService {
  AiTranslationService._();

  static OnDeviceTranslator? _translator;

  static TranslateLanguage? _currentSource;
  static TranslateLanguage? _currentTarget;

  static const TranslateLanguage _sourceLanguage = TranslateLanguage.english;

  static TranslateLanguage _targetLanguage() {
    switch (LanguageService.currentCode) {
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

      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  static Future<void> _ensureTranslator() async {
    final targetLanguage = _targetLanguage();

    if (targetLanguage == _sourceLanguage) {
      return;
    }

    if (_translator != null &&
        _currentSource == _sourceLanguage &&
        _currentTarget == targetLanguage) {
      return;
    }

    _translator?.close();

    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: targetLanguage,
    );

    _currentSource = _sourceLanguage;
    _currentTarget = targetLanguage;
  }

  static Future<String> translate(String? text) async {
    if (text == null || text.trim().isEmpty) {
      return text ?? '';
    }

    final targetLanguage = _targetLanguage();

    if (targetLanguage == _sourceLanguage) {
      return text;
    }

    try {
      await _ensureTranslator();

      return await _translator!.translateText(text);
    } catch (e) {
      return text;
    }
  }

  static Future<List<String>> translateList(List<String> items) async {
    if (items.isEmpty) return items;

    return Future.wait(items.map((item) => translate(item)));
  }

  static void reset() {
    _translator?.close();
    _translator = null;
    _currentSource = null;
    _currentTarget = null;
  }

  static void dispose() {
    reset();
  }
}
