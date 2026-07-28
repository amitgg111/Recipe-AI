import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/language_service.dart';

/// Every 2 minutes, checks the ROOT-LEVEL `recipes` collection for documents
/// belonging to the current user (`ownerId == uid`) that changed since the
/// last check (`updatedAt`), and — if the app's current language is
/// non-English — silently runs ML Kit translation on them so the on-device
/// cache is warm before the UI ever needs it.
///
/// Started ONCE from main() — NOT from Splash's State — so it survives past
/// splash disposal and keeps running for the whole app session.
class RecipeAutoTranslateService {
  RecipeAutoTranslateService._();
  static final RecipeAutoTranslateService instance =
      RecipeAutoTranslateService._();

  static const Duration _interval = Duration(minutes: 2);
  static const String _collectionPath = 'recipes'; // root-level collection

  Timer? _timer;
  bool _checking = false;
  DateTime _lastCheckedAt = DateTime.now();

  void start() {
    _timer?.cancel();
    _lastCheckedAt = DateTime.now();
    _timer = Timer.periodic(_interval, (_) => _tick());
    log('🕑 RecipeAutoTranslateService started (every ${_interval.inMinutes} min)');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_checking) return; // overlapping run ટાળવા
    _checking = true;
    try {
      await _checkAndTranslateNewRecipes();
    } catch (e) {
      log('❌ RecipeAutoTranslateService tick failed: $e');
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkAndTranslateNewRecipes() async {
    // English source ma translate ni jarur nathi.
    if (LanguageService.currentCode == 'en') return;
    if (!AiTranslationService.isTranslating) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final since = _lastCheckedAt;
    _lastCheckedAt = DateTime.now();

    final snap = await FirebaseFirestore.instance
        .collection(_collectionPath)
        .where('ownerId', isEqualTo: user.uid)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    if (snap.docs.isEmpty) return;

    log('🔄 Auto-translate: found ${snap.docs.length} new/changed recipe(s)');

    for (final doc in snap.docs) {
      final data = doc.data();
      await _translateRecipeFields(data);
      log('✅ Auto-translated recipe ${doc.id}');
    }
  }

  Future<void> _translateRecipeFields(Map<String, dynamic> data) async {
    final title = data['title'] as String?;
    final description = data['description'] as String?;
    final prepTime = data['prepTime'] as String?;
    final totalTime = data['totalTime'] as String?;

    final ingredients = (data['ingredients'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final instructions = (data['instructions'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    if (title != null) await AiTranslationService.translate(title);
    if (description != null) await AiTranslationService.translate(description);
    if (prepTime != null) await AiTranslationService.translate(prepTime);
    if (totalTime != null) await AiTranslationService.translate(totalTime);
    if (ingredients.isNotEmpty) {
      await AiTranslationService.translateList(ingredients);
    }
    if (instructions.isNotEmpty) {
      await AiTranslationService.translateList(instructions);
    }
  }
}