import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_scraper/recipe_scraper.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';

enum ImportStage { landing, browsing }

// ─────────────────────────────────────────────────────────────────────────────
// Data model returned after scraping
// ─────────────────────────────────────────────────────────────────────────────

class ScrapedRecipeData {
  final String title;
  final String? description;
  final String? imageUrl;
  final String sourceUrl;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final String? servings;
  final String? category;
  final String? cuisine;
  final List<String> keywords;
  final List<IngredientSection> ingredientSections;
  final List<InstructionSection> instructionSections;

  ScrapedRecipeData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.sourceUrl,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.category,
    required this.cuisine,
    required this.keywords,
    required List<IngredientSection> ingredientSections,
    required this.instructionSections,
  }) : ingredientSections = ingredientSections.map((section) {
         return IngredientSection(
           name: section.name,
           items: section.items.map((item) => cleanIngredient(item)).toList(),
         );
       }).toList();

  static String cleanIngredient(String raw) {
    return raw
        .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[,;]+$'), '')
        .trim();
  }

  /// Flat list of all ingredients across all sections.
  List<String> get ingredients =>
      ingredientSections.expand((s) => s.items).toList();

  /// Flat list of all instruction steps across all sections.
  List<String> get instructions =>
      instructionSections.expand((s) => s.steps).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class ImportWebController extends GetxController {
  late final WebViewController webViewController;
  final TextEditingController searchController = TextEditingController();

  final Rx<ImportStage> stage = ImportStage.landing.obs;
  final RxnString currentUrl = RxnString(null);
  final RxBool isLoading = false.obs;
  final RxBool isImporting = false.obs;

  static const int freeRecipesTotal = 5;
  final RxInt freeRecipesLeft = 5.obs;

  bool get showImportBar =>
      stage.value == ImportStage.browsing &&
      currentUrl.value != null &&
      !currentUrl.value!.contains('google.com/search') &&
      !currentUrl.value!.startsWith('about:blank');

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => isLoading.value = true,
          onPageFinished: (url) {
            isLoading.value = false;
            if (!url.startsWith('about:blank')) {
              currentUrl.value = url;
              searchController.text = url;
            } else {
              currentUrl.value = null;
            }
            if (!url.startsWith('about:blank') &&
                stage.value == ImportStage.landing) {
              stage.value = ImportStage.browsing;
            }
          },
          onWebResourceError: (_) => isLoading.value = false,
        ),
      );

    loadLandingPage();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void loadLandingPage() {
    stage.value = ImportStage.landing;
    currentUrl.value = null;
    searchController.clear();
    webViewController.loadHtmlString(_landingPageHtml);
  }

  void performSearch(String query) {
    stage.value = ImportStage.browsing;
    final directUri = _tryRecipeUri(query);
    if (directUri != null) {
      webViewController.loadRequest(directUri);
      return;
    }
    final encoded = Uri.encodeQueryComponent('$query recipe');
    webViewController.loadRequest(
      Uri.parse('https://www.google.com/search?q=$encoded'),
    );
  }

  // ── Scrape orchestration ───────────────────────────────────────────────────

  Future<ScrapedRecipeData?> scrapeCurrentPage() async {
    if (currentUrl.value == null) return null;

    isImporting.value = true;
    ScrapedRecipeData? recipeData;

    try {
      // 1️⃣  DOM-first: WPRM / Tasty / JSON-LD scraped from live page
      recipeData = await _scrapeStructuredDataFromPage();

      // 2️⃣  Fallback: recipe_scraper package
      if (recipeData == null || recipeData.title.isEmpty) {
        final recipe = await scrapeRecipe(currentUrl.value!);
        if (recipe != null && recipe.title.isNotEmpty) {
          final flatIngredients = recipe.ingredients.map((e) {
            final qty = e.quantity > 0 ? '${e.quantity} ' : '';
            final unit = e.unit != null && e.unit!.isNotEmpty
                ? '${e.unit} '
                : '';
            return '$qty$unit${e.name}'.trim();
          }).toList();

          recipeData = ScrapedRecipeData(
            title: recipe.title,
            description: null,
            imageUrl: recipe.imageUrls.isNotEmpty
                ? recipe.imageUrls.first
                : null,
            sourceUrl: currentUrl.value!,
            prepTime: null,
            cookTime: null,
            totalTime: null,
            servings: null,
            category: null,
            cuisine: null,
            keywords: const [],
            ingredientSections: _detectIngredientSections(flatIngredients),
            instructionSections: recipe.instructions.isEmpty
                ? []
                : [InstructionSection(steps: recipe.instructions)],
          );
        }
      }

      if (recipeData == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'No recipe found on this page',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      if (recipeData == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'Could not read recipe: $e',
          type: SnackbarType.error,
        );
      }
    }

    isImporting.value = false;
    return recipeData;
  }

  Future<String?> uploadRecipeImage(String imageUrl, String uid) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        return null;
      }

      final bytes = response.bodyBytes;

      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('recipes')
          .child(fileName);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      return await ref.getDownloadURL();
    } catch (e) {
      log("IMAGE ERROR");
      log(e.toString());
      return null;
    }
  }

  // ── Save to Firestore ──────────────────────────────────────────────────────

  Future<bool> saveRecipe(ScrapedRecipeData recipe) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'You must be logged in to save recipes.',
          type: SnackbarType.error,
        );

        return false;
      }

      String? firebaseImageUrl;

      if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
        firebaseImageUrl = await uploadRecipeImage(recipe.imageUrl!, uid);
      }
      log("Original Image: ${recipe.imageUrl}");
      log("Firebase Image: $firebaseImageUrl");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .add({
            'title': recipe.title,
            'description': recipe.description,

            // Firebase Storage URL
            'imageUrl': recipe.imageUrl,

            'sourceUrl': recipe.sourceUrl,
            'prepTime': recipe.prepTime,
            'cookTime': recipe.cookTime,
            'totalTime': recipe.totalTime,
            'servings': recipe.servings,
            'category': recipe.category,
            'cuisine': recipe.cuisine,
            'keywords': recipe.keywords,

            'ingredientSections': recipe.ingredientSections
                .map((s) => s.toMap())
                .toList(),

            'instructionSections': recipe.instructionSections
                .map((s) => s.toMap())
                .toList(),

            'ingredients': recipe.ingredients,
            'instructions': recipe.instructions,

            // Privacy: imported recipes are private by default.
            'visibility': 'private',
            'isPublic': false,
            'ownerId': uid,
            'isDeleted': false,
            'likesCount': 0,
            'commentsCount': 0,
            'savesCount': 0,
            'sharesCount': 0,
            'viewsCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (freeRecipesLeft.value > 0) {
        freeRecipesLeft.value--;
      }
      log('------------------------ok');
      return true;
    } catch (e) {
      log('-------------------------error');
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to save recipe: $e',
        type: SnackbarType.error,
      );

      return false;
    }
  }

  // Future<bool> saveRecipe(ScrapedRecipeData recipe) async {
  //   try {
  //     final uid = AuthService.currentUser!.uid;

  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid)
  //         .collection('recipes')
  //         .add({
  //           'title': recipe.title,
  //           'imageUrl': recipe.imageUrl, // direct URL
  //           'ingredients': recipe.ingredients,
  //           'instructions': recipe.instructions,
  //           'createdAt': FieldValue.serverTimestamp(),
  //         });

  //     return true;
  //   } catch (e) {
  //     log(e.toString());
  //     return false;
  //   }
  // }

  String? _extractImage(dynamic value) {
    if (value == null) return null;

    if (value is String) return value;

    if (value is List && value.isNotEmpty) {
      return _extractImage(value.first);
    }

    if (value is Map) {
      return value['url']?.toString();
    }

    return null;
  }

  // ── URI helper ─────────────────────────────────────────────────────────────

  Uri? _tryRecipeUri(String input) {
    final trimmed = input.trim();
    final withScheme = trimmed.startsWith(RegExp(r'https?://'))
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
    return uri;
  }

  // ── Core structured scraper (runs JS inside the WebView) ──────────────────

  Future<ScrapedRecipeData?> _scrapeStructuredDataFromPage() async {
    try {
      // language=javascript
      final raw = await webViewController.runJavaScriptReturningResult(r'''
JSON.stringify((function() {

  // ── Helpers ────────────────────────────────────────────────────────────────

  function txt(el) {
    return el ? el.textContent.replace(/\s+/g, ' ').trim() : '';
  }

  function attr(el, a) {
    return el ? (el.getAttribute(a) || '').trim() : '';
  }

  // ── 1. WPRM (WP Recipe Maker) ─────────────────────────────────────────────
  // Used by indianhealthyrecipes.com, cookwithmanali.com, etc.

  function getWprmMeta() {
    var c = document.querySelector('.wprm-recipe-container, [class*="wprm-recipe"]');
    if (!c) return null;

    function wprmText(cls) {
      var el = c.querySelector('.' + cls);
      return el ? txt(el) : null;
    }

    function wprmTime(type) {
      // <span class="wprm-recipe-prep_time-container">
      //   <span class="wprm-recipe-prep_time">15</span>
      //   <span class="wprm-recipe-prep_time-unit">minutes</span>
      // </span>
      var val = c.querySelector('.wprm-recipe-' + type + '_time');
      var unit = c.querySelector('.wprm-recipe-' + type + '_time-unit');
      if (!val) return null;
      var v = txt(val);
      var u = unit ? txt(unit) : '';
      return (v + ' ' + u).trim() || null;
    }

    return {
      title:    wprmText('wprm-recipe-name'),
      desc:     wprmText('wprm-recipe-summary'),
      servings: wprmText('wprm-recipe-servings-with-unit') ||
                (function(){
                  var s = c.querySelector('.wprm-recipe-servings');
                  var u = c.querySelector('.wprm-recipe-servings-unit');
                  if (!s) return null;
                  return (txt(s) + ' ' + (u ? txt(u) : '')).trim();
                })(),
      prepTime:  wprmTime('prep'),
      cookTime:  wprmTime('cook'),
      totalTime: wprmTime('total'),
      category:  wprmText('wprm-recipe-course'),
      cuisine:   wprmText('wprm-recipe-cuisine'),
      image: (function() {
        var img = c.querySelector('.wprm-recipe-image img');
        if (img) return img.getAttribute('src') || img.getAttribute('data-src') || '';
        return '';
      })(),
    };
  }

  // ── 2. WPRM Ingredients ────────────────────────────────────────────────────

  function getWprmIngredients() {
    var groups = [];
    var groupEls = document.querySelectorAll(
      '.wprm-recipe-ingredient-group, .wprm-recipe-ingredients-container .wprm-recipe-block-container-columns'
    );
    if (groupEls.length === 0) return null;

    groupEls.forEach(function(group) {
      // group header name
      var nameEl = group.querySelector(
        '.wprm-recipe-ingredient-group-name, .wprm-recipe-ingredient-group-title, .wprm-recipe-block-header'
      );
      var name = nameEl ? txt(nameEl) : '';

      var items = [];
      group.querySelectorAll('.wprm-recipe-ingredient').forEach(function(ing) {
        var parts = [];

        var amount = ing.querySelector('.wprm-recipe-ingredient-amount');
        var unit   = ing.querySelector('.wprm-recipe-ingredient-unit');
        var iName  = ing.querySelector('.wprm-recipe-ingredient-name');
        var notes  = ing.querySelector('.wprm-recipe-ingredient-notes');

        if (amount) parts.push(txt(amount));
        if (unit)   parts.push(txt(unit));
        if (iName)  parts.push(txt(iName));
        if (notes) {
          var n = txt(notes);
          // parenthesise notes if not already
          if (n && !n.startsWith('(')) n = '(' + n + ')';
          if (n) parts.push(n);
        }

        var full = parts.join(' ').replace(/\s+/g, ' ').trim();
        if (full) items.push(full);
      });

      if (items.length > 0) {
        groups.push({ name: name, items: items });
      }
    });

    return groups.length > 0 ? groups : null;
  }

  // ── 3. WPRM Instructions ──────────────────────────────────────────────────

  function getWprmInstructions() {
    var groups = [];
    var groupEls = document.querySelectorAll(
      '.wprm-recipe-instruction-group, .wprm-recipe-instructions-container .wprm-recipe-block-container-columns'
    );
    if (groupEls.length === 0) return null;

    groupEls.forEach(function(group) {
      var nameEl = group.querySelector(
        '.wprm-recipe-instruction-group-name, .wprm-recipe-instruction-group-title, .wprm-recipe-block-header'
      );
      var name = nameEl ? txt(nameEl) : '';

      var steps = [];
      group.querySelectorAll('.wprm-recipe-instruction-text').forEach(function(step) {
        // Some WPRM setups have images inside – strip them, keep text only
        var clone = step.cloneNode(true);
        clone.querySelectorAll('img, figure').forEach(function(n){ n.remove(); });
        var t = clone.textContent.replace(/\s+/g, ' ').trim();
        if (t && steps.indexOf(t) === -1) steps.push(t);
      });

      if (steps.length > 0) {
        groups.push({ name: name, steps: steps });
      }
    });

    return groups.length > 0 ? groups : null;
  }

  // ── 4. Tasty Recipes plugin ────────────────────────────────────────────────

  function getTastyIngredients() {
    var container = document.querySelector('.tasty-recipes-ingredients');
    if (!container) return null;
    var groups = [], currentHeader = '', currentItems = [];
    container.querySelectorAll('h4, ul').forEach(function(node) {
      if (node.tagName === 'H4') {
        if (currentItems.length > 0) {
          groups.push({ name: currentHeader, items: currentItems });
          currentItems = [];
        }
        currentHeader = txt(node);
      } else if (node.tagName === 'UL') {
        node.querySelectorAll('li').forEach(function(li) {
          var t = txt(li); if (t) currentItems.push(t);
        });
      }
    });
    if (currentItems.length > 0) groups.push({ name: currentHeader, items: currentItems });
    return groups.length > 0 ? groups : null;
  }

  function getTastyInstructions() {
    var container = document.querySelector('.tasty-recipes-instructions');
    if (!container) return null;
    var groups = [], currentHeader = '', currentSteps = [];
    container.querySelectorAll('h4, ol').forEach(function(node) {
      if (node.tagName === 'H4') {
        if (currentSteps.length > 0) {
          groups.push({ name: currentHeader, steps: currentSteps });
          currentSteps = [];
        }
        currentHeader = txt(node);
      } else if (node.tagName === 'OL') {
        node.querySelectorAll('li').forEach(function(li) {
          var t = txt(li); if (t) currentSteps.push(t);
        });
      }
    });
    if (currentSteps.length > 0) groups.push({ name: currentHeader, steps: currentSteps });
    return groups.length > 0 ? groups : null;
  }

  // ── 5. Generic recipe card fallback ───────────────────────────────────────
  // Handles sites like allrecipes, food52, etc. that use simple lists

  function getGenericIngredients() {
    var selectors = [
      '[class*="ingredient"] li',
      '[id*="ingredient"] li',
      '.ingredients li',
      '.recipe-ingredients li',
    ];
    for (var i = 0; i < selectors.length; i++) {
      var els = document.querySelectorAll(selectors[i]);
      if (els.length > 0) {
        var items = [];
        els.forEach(function(li) {
          var t = txt(li); if (t) items.push(t);
        });
        if (items.length > 0) return [{ name: '', items: items }];
      }
    }
    return null;
  }

  function getGenericInstructions() {
    var selectors = [
      '[class*="instruction"] li',
      '[class*="direction"] li',
      '[class*="step"] li',
      '.instructions li',
      '.directions li',
      '.recipe-directions li',
      '.steps li',
    ];
    for (var i = 0; i < selectors.length; i++) {
      var els = document.querySelectorAll(selectors[i]);
      if (els.length > 3) {          // require at least 3 steps to avoid false matches
        var steps = [];
        els.forEach(function(li) {
          var t = txt(li); if (t) steps.push(t);
        });
        if (steps.length > 0) return [{ name: '', steps: steps }];
      }
    }
    return null;
  }

  // ── 6. Open Graph / page-level meta ───────────────────────────────────────

  function ogMeta(prop) {
    var el = document.querySelector('meta[property="' + prop + '"]') ||
             document.querySelector('meta[name="' + prop + '"]');
    return el ? (el.getAttribute('content') || '').trim() : '';
  }

  // ── 7. JSON-LD blocks ─────────────────────────────────────────────────────

  var jsonLd = Array.from(
    document.querySelectorAll('script[type="application/ld+json"]')
  ).map(function(s) { return s.textContent || ''; });

  // ── Assemble and return ───────────────────────────────────────────────────

  var wprmMeta = getWprmMeta();

  return {
    // WPRM structured meta
    wprmMeta: wprmMeta,

    // Ingredient groups from WPRM, Tasty, or generic fallback
    wprmIngs:    getWprmIngredients(),
    tastyIngs:   getTastyIngredients(),
    genericIngs: getGenericIngredients(),

    // Instruction groups from WPRM, Tasty, or generic fallback
    wprmIns:    getWprmInstructions(),
    tastyIns:   getTastyInstructions(),
    genericIns: getGenericInstructions(),

    // Page-level fallbacks
    title:       ogMeta('og:title') || document.title || '',
    description: ogMeta('og:description') || ogMeta('description') || '',
    image:       ogMeta('og:image') || ogMeta('twitter:image') || '',

    jsonLd: jsonLd,
  };
})())
''');

      final payload = _decodeJavaScriptJson(raw);
      if (payload == null) return null;

      // ── Resolve title ──────────────────────────────────────────────────────
      final wprmMeta = payload['wprmMeta'] as Map<String, dynamic>?;

      final title =
          _text(wprmMeta?['title']) ??
          _findRecipeJsonField(payload['jsonLd'], 'name') ??
          _text(payload['title']);
      if (title == null || title.isEmpty) return null;

      // ── Resolve ingredient sections ────────────────────────────────────────
      final ingredientSections =
          _parseDomSections(payload['wprmIngs']) ??
          _parseDomSections(payload['tastyIngs']) ??
          _parseDomSections(payload['genericIngs']) ??
          _extractIngredientSections(
            _findRecipeJsonRaw(payload['jsonLd'], 'recipeIngredient'),
          );

      // ── Resolve instruction sections ───────────────────────────────────────
      final instructionSections =
          _parseDomInstructions(payload['wprmIns']) ??
          _parseDomInstructions(payload['tastyIns']) ??
          _parseDomInstructions(payload['genericIns']) ??
          _extractInstructionSections(
            _findRecipeJsonRaw(payload['jsonLd'], 'recipeInstructions'),
          );

      // ── Resolve image ─────────────────────────────────────────────────────
      final rawImage =
          _text(wprmMeta?['image']) ??
          _extractImage(_findRecipeJsonRaw(payload['jsonLd'], 'image')) ??
          _text(payload['image']) ??
          _text(payload['firstLargeImage']);

      // ── Resolve times ──────────────────────────────────────────────────────
      final prepTime =
          _text(wprmMeta?['prepTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'prepTime'));
      final cookTime =
          _text(wprmMeta?['cookTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'cookTime'));
      final totalTime =
          _text(wprmMeta?['totalTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'totalTime'));

      // ── Resolve servings ───────────────────────────────────────────────────
      final servings =
          _text(wprmMeta?['servings']) ??
          _extractServings(
            _findRecipeJsonRaw(payload['jsonLd'], 'recipeYield'),
          );

      return ScrapedRecipeData(
        title: title,
        description:
            _text(wprmMeta?['desc']) ??
            _findRecipeJsonField(payload['jsonLd'], 'description') ??
            _text(payload['description']),
        imageUrl: _absoluteUrl(rawImage),
        sourceUrl: currentUrl.value!,
        prepTime: prepTime,
        cookTime: cookTime,
        totalTime: totalTime,
        servings: servings,
        category:
            _text(wprmMeta?['category']) ??
            _findRecipeJsonField(payload['jsonLd'], 'recipeCategory'),
        cuisine:
            _text(wprmMeta?['cuisine']) ??
            _findRecipeJsonField(payload['jsonLd'], 'recipeCuisine'),
        keywords: _extractKeywords(
          _findRecipeJsonRaw(payload['jsonLd'], 'keywords'),
        ),
        ingredientSections: ingredientSections,
        instructionSections: instructionSections,
      );
    } catch (_) {
      return null;
    }
  }

  // ── DOM section parsers ────────────────────────────────────────────────────

  /// Converts [{name, items}] DOM list → List<IngredientSection>
  List<IngredientSection>? _parseDomSections(dynamic list) {
    if (list is! List || list.isEmpty) return null;
    try {
      final sections = list.map((item) {
        final name = _text(item['name']);
        final items = List<String>.from(item['items'] ?? []);
        return IngredientSection(
          name: (name != null && name.isNotEmpty) ? name : null,
          items: items,
        );
      }).toList();
      // Only return if there are actual items
      final hasItems = sections.any((s) => s.items.isNotEmpty);
      return hasItems ? sections : null;
    } catch (_) {
      return null;
    }
  }

  /// Converts [{name, steps}] DOM list → List<InstructionSection>
  List<InstructionSection>? _parseDomInstructions(dynamic list) {
    if (list is! List || list.isEmpty) return null;
    try {
      final sections = list.map((item) {
        final name = _text(item['name']);
        final steps = List<String>.from(item['steps'] ?? []);
        return InstructionSection(
          name: (name != null && name.isNotEmpty) ? name : null,
          steps: steps,
        );
      }).toList();
      final hasSteps = sections.any((s) => s.steps.isNotEmpty);
      return hasSteps ? sections : null;
    } catch (_) {
      return null;
    }
  }

  // ── JSON-LD helpers ────────────────────────────────────────────────────────

  Map<String, dynamic>? _decodeJavaScriptJson(Object raw) {
    try {
      final rawText = raw.toString();
      final decoded = jsonDecode(rawText);
      final value = decoded is String ? jsonDecode(decoded) : decoded;
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// Find the first Recipe node inside JSON-LD blocks and return a named field.
  String? _findRecipeJsonField(dynamic jsonLdBlocks, String field) {
    final recipe = _findRecipeJson(jsonLdBlocks);
    return _text(recipe?[field]);
  }

  dynamic _findRecipeJsonRaw(dynamic jsonLdBlocks, String field) {
    final recipe = _findRecipeJson(jsonLdBlocks);
    return recipe?[field];
  }

  Map<String, dynamic>? _findRecipeJson(dynamic jsonLdBlocks) {
    if (jsonLdBlocks is! List) return null;
    for (final block in jsonLdBlocks) {
      try {
        final decoded = jsonDecode(block.toString());
        final recipe = _findRecipeNode(decoded);
        if (recipe != null) return recipe;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findRecipeNode(dynamic node) {
    if (node is List) {
      for (final item in node) {
        final r = _findRecipeNode(item);
        if (r != null) return r;
      }
      return null;
    }
    if (node is! Map) return null;
    final map = Map<String, dynamic>.from(node);
    final type = map['@type'];
    final isRecipe =
        type == 'Recipe' ||
        (type is List && type.map((e) => e.toString()).contains('Recipe'));
    if (isRecipe) return map;
    return _findRecipeNode(map['@graph']) ?? _findRecipeNode(map['mainEntity']);
  }

  // ── Ingredient section parsing (flat list → sections) ─────────────────────

  List<IngredientSection> _detectIngredientSections(List<String> flatList) {
    if (flatList.isEmpty) return [];

    final sections = <IngredientSection>[];
    String? currentName;
    final currentItems = <String>[];

    for (final item in flatList) {
      if (_isIngredientSectionHeader(item)) {
        if (currentItems.isNotEmpty) {
          sections.add(
            IngredientSection(
              name: currentName,
              items: List.from(currentItems),
            ),
          );
          currentItems.clear();
        }
        currentName = item.endsWith(':')
            ? item.substring(0, item.length - 1).trim()
            : item.trim();
      } else {
        currentItems.add(item);
      }
    }

    if (currentItems.isNotEmpty) {
      sections.add(
        IngredientSection(name: currentName, items: List.from(currentItems)),
      );
    }

    return sections.isEmpty ? [IngredientSection(items: flatList)] : sections;
  }

  bool _isIngredientSectionHeader(String text) {
    final t = text.trim();
    if (t.endsWith(':') && t.length <= 80 && !t.contains(RegExp(r'\d'))) {
      return true;
    }
    if (t.isNotEmpty &&
        t == t.toUpperCase() &&
        t.length <= 40 &&
        !t.contains(RegExp(r'\d'))) {
      return true;
    }
    return false;
  }

  List<IngredientSection> _extractIngredientSections(dynamic value) {
    final flat = _stringList(value);
    return _detectIngredientSections(flat);
  }

  // ── Instruction section parsing (JSON-LD) ─────────────────────────────────

  List<InstructionSection> _extractInstructionSections(dynamic value) {
    if (value == null) return [];

    if (value is String) {
      final steps = _splitInstructionText(value);
      return steps.isEmpty ? [] : [InstructionSection(steps: steps)];
    }

    if (value is! List) return [];

    final sections = <InstructionSection>[];
    final pendingSteps = <String>[];

    void flushPending() {
      if (pendingSteps.isNotEmpty) {
        sections.add(InstructionSection(steps: List.from(pendingSteps)));
        pendingSteps.clear();
      }
    }

    for (final item in value) {
      if (item is String) {
        pendingSteps.addAll(_splitInstructionText(item));
      } else if (item is Map) {
        final type = item['@type']?.toString() ?? '';
        if (type == 'HowToSection') {
          flushPending();
          final name = _text(item['name']);
          final sub = _extractInstructionSections(item['itemListElement']);
          sections.add(
            InstructionSection(
              name: name,
              steps: sub.expand((s) => s.steps).toList(),
            ),
          );
        } else {
          final text = _text(item['text']) ?? _text(item['name']);
          if (text != null && text.isNotEmpty) {
            pendingSteps.add(text);
          } else if (item['itemListElement'] != null) {
            final sub = _extractInstructionSections(item['itemListElement']);
            pendingSteps.addAll(sub.expand((s) => s.steps));
          }
        }
      }
    }

    flushPending();
    return sections;
  }

  List<String> _splitInstructionText(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ── Misc helpers ───────────────────────────────────────────────────────────

  List<String> _stringList(dynamic value) {
    if (value is String) return [value];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<String> _extractKeywords(dynamic value) {
    if (value is List) return _stringList(value);
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String? _extractServings(dynamic value) {
    if (value is List && value.isNotEmpty) return _text(value.first);
    return _text(value);
  }

  /// Converts ISO-8601 duration (PT15M, PT1H30M) → human string (15m / 1h 30m).
  String? _formatDuration(dynamic value) {
    final text = _text(value);
    if (text == null) return null;

    final match = RegExp(
      r'^P(?:\d+D)?T?(?:(\d+)H)?(?:(\d+)M)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return text;

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    if (hours == 0 && minutes == 0) return text;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  String? _absoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) return null; // skip base64 placeholders
    final base = Uri.tryParse(currentUrl.value ?? '');
    final parsed = Uri.tryParse(url);
    if (parsed == null) return null;
    return base?.resolveUri(parsed).toString() ?? parsed.toString();
  }

  // ── Landing page HTML ──────────────────────────────────────────────────────

  static const String _landingPageHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }

    body {
      margin: 0;
      background: #f5f0e4;
      font-family: -apple-system, Roboto, sans-serif;
      color: #191713;
    }

    .hero {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }

    .brand {
      width: 100%;
      max-width: 700px;
      font-family: Georgia, 'Times New Roman', serif;
      font-size: clamp(30px, 6vw, 50px);
      line-height: 1.1;
      margin-bottom: 24px;
      color: #191713;
      text-align: center;
    }

    .g-blue   { color: #4285f4; font-family: Arial, sans-serif; font-weight: 600; }
    .g-red    { color: #ea4335; font-family: Arial, sans-serif; font-weight: 600; }
    .g-yellow { color: #fbbc05; font-family: Arial, sans-serif; font-weight: 600; }
    .g-green  { color: #34a853; font-family: Arial, sans-serif; font-weight: 600; }

    form { width: 100%; max-width: 700px; }

    .search-box {
      background: #ffffff;
      border: 2px solid #d3cec3;
      border-radius: 999px;
      min-height: 70px;
      padding: 0 24px;
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .search-icon {
      width: 24px;
      height: 24px;
      border: 3px solid #8d8880;
      border-radius: 50%;
      position: relative;
      flex-shrink: 0;
    }
    .search-icon:after {
      content: '';
      position: absolute;
      width: 12px; height: 3px;
      background: #8d8880;
      right: -8px; bottom: -4px;
      transform: rotate(45deg);
      border-radius: 2px;
    }

    input {
      border: none; outline: none; width: 100%;
      background: transparent; color: #1f1b16; font-size: 18px;
    }
    input::placeholder { color: #8d8880; }

    @media (max-width: 520px) {
      .hero { padding: 20px; }
      .brand { font-size: 28px; margin-bottom: 18px; }
      .search-box { min-height: 58px; padding: 0 18px; }
      .search-icon { width: 20px; height: 20px; }
      input { font-size: 16px; }
    }
  </style>
</head>
<body>
  <main class="hero">
    <div class="brand">
      <span class="g-blue">G</span><span class="g-red">o</span><span
        class="g-yellow">o</span><span class="g-blue">g</span><span
        class="g-green">l</span><span class="g-red">e</span> a recipe
    </div>

    <form id="recipeSearch">
      <label class="search-box">
        <span class="search-icon"></span>
        <input
          id="query"
          type="search"
          placeholder="Search for a recipe or paste a URL"
          autofocus
        />
      </label>
    </form>
  </main>

  <script>
    document.getElementById('recipeSearch').addEventListener('submit', function(e) {
      e.preventDefault();
      var query = document.getElementById('query').value.trim();
      if (!query) return;
      var target = query;
      if (!/^https?:\\/\\//i.test(target) && target.indexOf('.') !== -1) {
        target = 'https://' + target;
      }
      if (!/^https?:\\/\\//i.test(target)) {
        target = 'https://www.google.com/search?q=' +
          encodeURIComponent(query + ' recipe');
      }
      window.location.href = target;
    });
  </script>
</body>
</html>
''';
}
