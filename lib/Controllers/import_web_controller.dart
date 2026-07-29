// import 'dart:convert';
// import 'dart:developer';

// import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:recipe_ai/Service/ai_translation_service.dart';
// import 'package:recipe_ai/Widget/custom_snackbar.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:recipe_scraper/recipe_scraper.dart';
// import 'package:recipe_ai/Service/auth_service.dart';
// import 'package:recipe_ai/Model/recipe_section_model.dart';
// import 'package:recipe_ai/Controllers/home_controller.dart';

// enum ImportStage { landing, browsing }

// // ─────────────────────────────────────────────────────────────────────────────
// // Data model returned after scraping
// // ─────────────────────────────────────────────────────────────────────────────

// // class ScrapedRecipeData {
// //   final String title;
// //   final String? description;
// //   final String? imageUrl;
// //   final String sourceUrl;
// //   final String? prepTime;
// //   final String? cookTime;
// //   final String? totalTime;
// //   final String? servings;
// //   final String? category;
// //   final String? cuisine;
// //   final List<String> keywords;
// //   final List<IngredientSection> ingredientSections;
// //   final List<InstructionSection> instructionSections;

// //   ScrapedRecipeData({
// //     required this.title,
// //     required this.description,
// //     required this.imageUrl,
// //     required this.sourceUrl,
// //     required this.prepTime,
// //     required this.cookTime,
// //     required this.totalTime,
// //     required this.servings,
// //     required this.category,
// //     required this.cuisine,
// //     required this.keywords,
// //     required List<IngredientSection> ingredientSections,
// //     required this.instructionSections,
// //   }) : ingredientSections = ingredientSections.map((section) {
// //          return IngredientSection(
// //            name: section.name,
// //            items: section.items.map((item) => cleanIngredient(item)).toList(),
// //          );
// //        }).toList();

// //   static String cleanIngredient(String raw) {
// //     return raw
// //         .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), ' ')
// //         .replaceAll(RegExp(r'\s+'), ' ')
// //         .replaceAll(RegExp(r'[,;]+$'), '')
// //         .trim();
// //   }

// //   /// Flat list of all ingredients across all sections.
// //   List<String> get ingredients =>
// //       ingredientSections.expand((s) => s.items).toList();

// //   /// Flat list of all instruction steps across all sections.
// //   List<String> get instructions =>
// //       instructionSections.expand((s) => s.steps).toList();
// // }

// class ScrapedRecipeData {
//   final String title;
//   final String? description;
//   final String? imageUrl;
//   final String sourceUrl;
//   final String? prepTime;
//   final String? cookTime;
//   final String? totalTime;
//   final String? servings;
//   final String? category;
//   final String? cuisine;
//   final List<String> keywords;
//   final List<IngredientSection> ingredientSections;
//   final List<InstructionSection> instructionSections;

//   ScrapedRecipeData({
//     required this.title,
//     required this.description,
//     required this.imageUrl,
//     required this.sourceUrl,
//     required this.prepTime,
//     required this.cookTime,
//     required this.totalTime,
//     required this.servings,
//     required this.category,
//     required this.cuisine,
//     required this.keywords,
//     required List<IngredientSection> ingredientSections,
//     required List<InstructionSection> instructionSections,
//   }) : ingredientSections = _deduplicateIngredientSections(ingredientSections),
//        instructionSections = _deduplicateInstructionSections(
//          instructionSections,
//        );

//   // ─────────────────────────────────────────────────────────────────────────
//   // Ingredient cleaning
//   // ─────────────────────────────────────────────────────────────────────────

//   static String cleanIngredient(String raw) {
//     return raw
//         .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), ' ')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .replaceAll(RegExp(r'[,;]+$'), '')
//         .trim();
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Normalize text for duplicate comparison
//   // ─────────────────────────────────────────────────────────────────────────

//   static String _normalize(String value) {
//     return value
//         .toLowerCase()
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .replaceAll(RegExp(r'[.,;:]+$'), '')
//         .trim();
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Deduplicate ingredients
//   // ─────────────────────────────────────────────────────────────────────────

//   static List<IngredientSection> _deduplicateIngredientSections(
//     List<IngredientSection> sections,
//   ) {
//     final result = <IngredientSection>[];

//     // Global set:
//     // Same ingredient appearing in two different sections
//     // will also be removed.
//     final globalSeen = <String>{};

//     for (final section in sections) {
//       final uniqueItems = <String>[];

//       for (final rawItem in section.items) {
//         final cleaned = cleanIngredient(rawItem);

//         if (cleaned.isEmpty) continue;

//         final normalized = _normalize(cleaned);

//         if (globalSeen.add(normalized)) {
//           uniqueItems.add(cleaned);
//         }
//       }

//       if (uniqueItems.isNotEmpty) {
//         result.add(IngredientSection(name: section.name, items: uniqueItems));
//       }
//     }

//     return result;
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Deduplicate instructions
//   // ─────────────────────────────────────────────────────────────────────────

//   static List<InstructionSection> _deduplicateInstructionSections(
//     List<InstructionSection> sections,
//   ) {
//     final result = <InstructionSection>[];

//     final globalSeen = <String>{};

//     for (final section in sections) {
//       final uniqueSteps = <String>[];

//       for (final rawStep in section.steps) {
//         final cleaned = rawStep.replaceAll(RegExp(r'\s+'), ' ').trim();

//         if (cleaned.isEmpty) continue;

//         final normalized = _normalize(cleaned);

//         if (globalSeen.add(normalized)) {
//           uniqueSteps.add(cleaned);
//         }
//       }

//       if (uniqueSteps.isNotEmpty) {
//         result.add(InstructionSection(name: section.name, steps: uniqueSteps));
//       }
//     }

//     return result;
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // Flat ingredient list
//   // ─────────────────────────────────────────────────────────────────────────

//   List<String> get ingredients =>
//       ingredientSections.expand((s) => s.items).toList();

//   // ─────────────────────────────────────────────────────────────────────────
//   // Flat instruction list
//   // ─────────────────────────────────────────────────────────────────────────

//   List<String> get instructions =>
//       instructionSections.expand((s) => s.steps).toList();
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Controller
// // ─────────────────────────────────────────────────────────────────────────────

// class ImportWebController extends GetxController {
//   late final WebViewController webViewController;
//   final TextEditingController searchController = TextEditingController();

//   final Rx<ImportStage> stage = ImportStage.landing.obs;
//   final RxnString currentUrl = RxnString(null);
//   final RxBool isLoading = false.obs;
//   final RxBool isImporting = false.obs;

//   static const int freeRecipesTotal = 5;
//   final RxInt freeRecipesLeft = 5.obs;

//   /// Google `-site:` filters appended to name searches so video/social sites
//   /// (which don't show a readable, importable recipe) are excluded — only
//   /// recipe-detail websites appear.
//   static const String _excludeSites =
//       ' -site:youtube.com -site:youtu.be -site:instagram.com'
//       ' -site:tiktok.com -site:facebook.com -site:pinterest.com';

//   bool get showImportBar =>
//       stage.value == ImportStage.browsing &&
//       currentUrl.value != null &&
//       !currentUrl.value!.contains('google.com/search') &&
//       !currentUrl.value!.startsWith('about:blank');

//   // ── Lifecycle ──────────────────────────────────────────────────────────────

//   @override
//   void onInit() {
//     super.onInit();
//     webViewController = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (url) => isLoading.value = true,
//           onPageFinished: (url) {
//             isLoading.value = false;
//             if (!url.startsWith('about:blank')) {
//               currentUrl.value = url;
//               searchController.text = url;
//             } else {
//               currentUrl.value = null;
//             }
//             if (!url.startsWith('about:blank') &&
//                 stage.value == ImportStage.landing) {
//               stage.value = ImportStage.browsing;
//             }
//           },
//           onWebResourceError: (_) => isLoading.value = false,
//         ),
//       );

//     loadLandingPage();
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     super.onClose();
//   }

//   // ── Navigation ─────────────────────────────────────────────────────────────

//   void loadLandingPage() {
//     stage.value = ImportStage.landing;
//     currentUrl.value = null;
//     searchController.clear();
//     webViewController.loadHtmlString(_landingPageHtml);
//   }

//   void performSearch(String query) {
//     stage.value = ImportStage.browsing;
//     final directUri = _tryRecipeUri(query);
//     if (directUri != null) {
//       webViewController.loadRequest(directUri);
//       return;
//     }
//     // `udm=14` is Google's plain "Web" results mode: a classic list of website
//     // links with NO AI overview, video carousels, "People also ask", "People
//     // also search for" or short-video blocks. The `-site:` filters drop
//     // video/social sites so only recipe-detail websites remain.
//     final encoded = Uri.encodeQueryComponent('$query recipe$_excludeSites');
//     webViewController.loadRequest(
//       Uri.parse('https://www.google.com/search?q=$encoded&udm=14'),
//     );
//   }

//   // ── Scrape orchestration ───────────────────────────────────────────────────

//   Future<ScrapedRecipeData?> scrapeCurrentPage() async {
//     if (currentUrl.value == null) return null;

//     isImporting.value = true;
//     ScrapedRecipeData? recipeData;

//     try {
//       // 1️⃣  DOM-first: WPRM / Tasty / JSON-LD scraped from live page
//       recipeData = await _scrapeStructuredDataFromPage();

//       // 2️⃣  Fallback: recipe_scraper package
//       if (recipeData == null || recipeData.title.isEmpty) {
//         final recipe = await scrapeRecipe(currentUrl.value!);
//         if (recipe != null && recipe.title.isNotEmpty) {
//           final flatIngredients = recipe.ingredients.map((e) {
//             final qty = e.quantity > 0 ? '${e.quantity} ' : '';
//             final unit = e.unit != null && e.unit!.isNotEmpty
//                 ? '${e.unit} '
//                 : '';
//             return '$qty$unit${e.name}'.trim();
//           }).toList();

//           recipeData = ScrapedRecipeData(
//             title: recipe.title,
//             description: null,
//             imageUrl: recipe.imageUrls.isNotEmpty
//                 ? recipe.imageUrls.first
//                 : null,
//             sourceUrl: currentUrl.value!,
//             prepTime: null,
//             cookTime: null,
//             totalTime: null,
//             servings: null,
//             category: null,
//             cuisine: null,
//             keywords: const [],
//             ingredientSections: _detectIngredientSections(flatIngredients),
//             instructionSections: recipe.instructions.isEmpty
//                 ? []
//                 : [InstructionSection(steps: recipe.instructions)],
//           );
//         }
//       }

//       if (recipeData == null) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'No recipe found on this page',
//           type: SnackbarType.error,
//         );
//       }
//     } catch (e) {
//       if (recipeData == null) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'Could not read recipe: $e',
//           type: SnackbarType.error,
//         );
//       }
//     }

//     isImporting.value = false;
//     return recipeData;
//   }

//   Future<String?> uploadRecipeImage(String imageUrl, String uid) async {
//     try {
//       final response = await http.get(Uri.parse(imageUrl));

//       if (response.statusCode != 200) {
//         return null;
//       }

//       final bytes = response.bodyBytes;

//       final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';

//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('users')
//           .child(uid)
//           .child('recipes')
//           .child(fileName);

//       await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

//       return await ref.getDownloadURL();
//     } catch (e) {
//       log("IMAGE ERROR");
//       log(e.toString());
//       return null;
//     }
//   }

//   // ── Save to Firestore ──────────────────────────────────────────────────────

//   // Future<RecipeModel?> saveRecipe(ScrapedRecipeData recipe) async {
//   //   try {
//   //     final uid = AuthService.currentUser?.uid;

//   //     if (uid == null) {
//   //       CustomSnackbar.show(
//   //         title: 'Error',
//   //         message: 'You must be logged in to save recipes.',
//   //         type: SnackbarType.error,
//   //       );

//   //       return null;
//   //     }

//   //     String? firebaseImageUrl;

//   //     if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
//   //       firebaseImageUrl = await uploadRecipeImage(recipe.imageUrl!, uid);
//   //     }
//   //     log("Original Image: ${recipe.imageUrl}");
//   //     log("Firebase Image: $firebaseImageUrl");
//   //     final resolvedImageUrl = firebaseImageUrl ?? recipe.imageUrl;
//   //     final docRef = await FirebaseFirestore.instance.collection('recipes').add(
//   //       {
//   //         'title': recipe.title,
//   //         'description': recipe.description,

//   //         // Firebase Storage URL (fall back to the scraped URL only if the
//   //         // re-upload failed, so a saved recipe always has a usable image).
//   //         'imageUrl': resolvedImageUrl,

//   //         'sourceUrl': recipe.sourceUrl,
//   //         'prepTime': recipe.prepTime,
//   //         'cookTime': recipe.cookTime,
//   //         'totalTime': recipe.totalTime,
//   //         'servings': recipe.servings,
//   //         'category': recipe.category,
//   //         'cuisine': recipe.cuisine,
//   //         'keywords': recipe.keywords,

//   //         'ingredientSections': recipe.ingredientSections
//   //             .map((s) => s.toMap())
//   //             .toList(),

//   //         'instructionSections': recipe.instructionSections
//   //             .map((s) => s.toMap())
//   //             .toList(),

//   //         'ingredients': recipe.ingredients,
//   //         'instructions': recipe.instructions,

//   //         // Privacy: imported recipes are private by default.
//   //         'isPublic': false,
//   //         // Ownership: imported recipes MAY later be published by the user.
//   //         'recipeSource': 'imported',
//   //         'originalRecipeId': null,
//   //         'ownerId': uid,
//   //         'isDeleted': false,
//   //         'likesCount': 0,
//   //         'commentsCount': 0,
//   //         'savesCount': 0,
//   //         'sharesCount': 0,
//   //         'viewsCount': 0,
//   //         'createdAt': FieldValue.serverTimestamp(),
//   //         'updatedAt': FieldValue.serverTimestamp(),
//   //       },
//   //     );

//   //     if (freeRecipesLeft.value > 0) {
//   //       freeRecipesLeft.value--;
//   //     }
//   //     log('------------------------ok');
//   //     return RecipeModel(
//   //       id: docRef.id,
//   //       title: recipe.title,
//   //       description: recipe.description,
//   //       imageUrl: resolvedImageUrl,
//   //       sourceUrl: recipe.sourceUrl,
//   //       prepTime: recipe.prepTime,
//   //       cookTime: recipe.cookTime,
//   //       totalTime: recipe.totalTime,
//   //       servings: recipe.servings,
//   //       category: recipe.category,
//   //       cuisine: recipe.cuisine,
//   //       keywords: recipe.keywords,
//   //       ingredients: recipe.ingredients,
//   //       instructions: recipe.instructions,
//   //       ingredientSections: recipe.ingredientSections,
//   //       instructionSections: recipe.instructionSections,
//   //     );
//   //   } catch (e) {
//   //     log('-------------------------error');
//   //     CustomSnackbar.show(
//   //       title: 'Error',
//   //       message: 'Failed to save recipe: $e',
//   //       type: SnackbarType.error,
//   //     );

//   //     return null;
//   //   }
//   // }

//   Future<RecipeModel?> saveRecipe(ScrapedRecipeData recipe) async {
//     try {
//       final uid = AuthService.currentUser?.uid;

//       if (uid == null) {
//         CustomSnackbar.show(
//           title: 'Error',
//           message: 'You must be logged in to save recipes.',
//           type: SnackbarType.error,
//         );
//         return null;
//       }

//       // ============================================================
//       // ALWAYS convert scraped recipe to English BEFORE saving
//       // ============================================================

//       log('Translating imported recipe to English...');

//       final englishRecipe = await _translateRecipeToEnglish(recipe);

//       log('English recipe ready');
//       log('Title: ${englishRecipe.title}');

//       // ============================================================
//       // Upload image
//       // ============================================================

//       String? firebaseImageUrl;

//       if (englishRecipe.imageUrl != null &&
//           englishRecipe.imageUrl!.isNotEmpty) {
//         firebaseImageUrl = await uploadRecipeImage(
//           englishRecipe.imageUrl!,
//           uid,
//         );
//       }

//       final resolvedImageUrl = firebaseImageUrl ?? englishRecipe.imageUrl;

//       // ============================================================
//       // SAVE ONLY englishRecipe TO FIRESTORE
//       // ============================================================

//       final docRef = await FirebaseFirestore.instance.collection('recipes').add(
//         {
//           'title': englishRecipe.title,
//           'description': englishRecipe.description,

//           'imageUrl': resolvedImageUrl,
//           'sourceUrl': englishRecipe.sourceUrl,

//           // These are non-language values
//           'prepTime': englishRecipe.prepTime,
//           'cookTime': englishRecipe.cookTime,
//           'totalTime': englishRecipe.totalTime,
//           'servings': englishRecipe.servings,

//           // English only
//           'category': englishRecipe.category,
//           'cuisine': englishRecipe.cuisine,
//           'keywords': englishRecipe.keywords,

//           'ingredientSections': englishRecipe.ingredientSections
//               .map((section) => section.toMap())
//               .toList(),

//           'instructionSections': englishRecipe.instructionSections
//               .map((section) => section.toMap())
//               .toList(),

//           'ingredients': englishRecipe.ingredients,
//           'instructions': englishRecipe.instructions,

//           'isPublic': false,
//           'recipeSource': 'imported',
//           'originalRecipeId': null,
//           'ownerId': uid,
//           'isDeleted': false,

//           'likesCount': 0,
//           'commentsCount': 0,
//           'savesCount': 0,
//           'sharesCount': 0,
//           'viewsCount': 0,

//           'createdAt': FieldValue.serverTimestamp(),
//           'updatedAt': FieldValue.serverTimestamp(),
//         },
//       );

//       if (freeRecipesLeft.value > 0) {
//         freeRecipesLeft.value--;
//       }

//       return RecipeModel(
//         id: docRef.id,
//         title: englishRecipe.title,
//         description: englishRecipe.description,
//         imageUrl: resolvedImageUrl,
//         sourceUrl: englishRecipe.sourceUrl,
//         prepTime: englishRecipe.prepTime,
//         cookTime: englishRecipe.cookTime,
//         totalTime: englishRecipe.totalTime,
//         servings: englishRecipe.servings,
//         category: englishRecipe.category,
//         cuisine: englishRecipe.cuisine,
//         keywords: englishRecipe.keywords,
//         ingredients: englishRecipe.ingredients,
//         instructions: englishRecipe.instructions,
//         ingredientSections: englishRecipe.ingredientSections,
//         instructionSections: englishRecipe.instructionSections,
//       );
//     } catch (e, stackTrace) {
//       log('Failed to save recipe');
//       log('Error: $e');
//       log('StackTrace: $stackTrace');

//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to save recipe: $e',
//         type: SnackbarType.error,
//       );

//       return null;
//     }
//   }

//   Future<ScrapedRecipeData> _translateRecipeToEnglish(
//     ScrapedRecipeData recipe,
//   ) async {
//     // 1️⃣ Detect language ONCE using combined representative text.
//     final sample = <String>[
//       recipe.title,
//       if (recipe.description != null) recipe.description!,
//       ...recipe.ingredients.take(3),
//       ...recipe.instructions.take(2),
//     ];

//     final detected = await AiTranslationService.detectDominantLanguage(sample);
//     log('🌍 Recipe language: $detected');

//     if (detected == 'en' || detected == 'und') {
//       // Already English, or couldn't reliably tell — leave as-is.
//       return recipe;
//     }

//     // 2️⃣ One translator for the WHOLE recipe (no re-download / re-create per string).
//     final translator = await AiTranslationService.prepareTranslatorFor(
//       detected,
//     );
//     if (translator == null) {
//       log(
//         '⚠️ Could not prepare translator for $detected — saving original text',
//       );
//       return recipe;
//     }

//     Future<String> t(String? text) =>
//         AiTranslationService.translateWithTranslator(translator, text);

//     try {
//       final title = await t(recipe.title);
//       final description = recipe.description == null
//           ? null
//           : await t(recipe.description);
//       final category = recipe.category == null
//           ? null
//           : await t(recipe.category);
//       final cuisine = recipe.cuisine == null ? null : await t(recipe.cuisine);

//       final keywords = <String>[];
//       for (final keyword in recipe.keywords) {
//         final translated = await t(keyword);
//         if (translated.trim().isNotEmpty) keywords.add(translated.trim());
//       }

//       final ingredientSections = <IngredientSection>[];
//       for (final section in recipe.ingredientSections) {
//         final sectionName = section.name == null
//             ? null
//             : await t(section.name!);
//         final items = <String>[];
//         for (final item in section.items) {
//           final translated = await t(item);
//           if (translated.trim().isNotEmpty) items.add(translated.trim());
//         }
//         if (items.isNotEmpty) {
//           ingredientSections.add(
//             IngredientSection(name: sectionName?.trim(), items: items),
//           );
//         }
//       }

//       final instructionSections = <InstructionSection>[];
//       for (final section in recipe.instructionSections) {
//         final sectionName = section.name == null
//             ? null
//             : await t(section.name!);
//         final steps = <String>[];
//         for (final step in section.steps) {
//           final translated = await t(step);
//           if (translated.trim().isNotEmpty) steps.add(translated.trim());
//         }
//         if (steps.isNotEmpty) {
//           instructionSections.add(
//             InstructionSection(name: sectionName?.trim(), steps: steps),
//           );
//         }
//       }

//       log('✅ Recipe translated: ${title.trim()}');

//       return ScrapedRecipeData(
//         title: title.trim().isEmpty ? recipe.title : title.trim(),
//         description: description?.trim(),
//         imageUrl: recipe.imageUrl,
//         sourceUrl: recipe.sourceUrl,
//         prepTime: recipe.prepTime,
//         cookTime: recipe.cookTime,
//         totalTime: recipe.totalTime,
//         servings: recipe.servings,
//         category: category?.trim(),
//         cuisine: cuisine?.trim(),
//         keywords: keywords,
//         ingredientSections: ingredientSections,
//         instructionSections: instructionSections,
//       );
//     } finally {
//       await translator.close();
//     }
//   }

//   String? _extractImage(dynamic value) {
//     if (value == null) return null;

//     if (value is String) return value;

//     if (value is List && value.isNotEmpty) {
//       return _extractImage(value.first);
//     }

//     if (value is Map) {
//       return value['url']?.toString();
//     }

//     return null;
//   }

//   // ── URI helper ─────────────────────────────────────────────────────────────

//   Uri? _tryRecipeUri(String input) {
//     final trimmed = input.trim();
//     final withScheme = trimmed.startsWith(RegExp(r'https?://'))
//         ? trimmed
//         : 'https://$trimmed';
//     final uri = Uri.tryParse(withScheme);
//     if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
//     return uri;
//   }

//   // ── Core structured scraper (runs JS inside the WebView) ──────────────────

//   Future<ScrapedRecipeData?> _scrapeStructuredDataFromPage() async {
//     try {
//       // language=javascript
//       final raw = await webViewController.runJavaScriptReturningResult(r'''
//   JSON.stringify((function() {

//     // ── Helpers ────────────────────────────────────────────────────────────────

//     function txt(el) {
//       return el ? el.textContent.replace(/\s+/g, ' ').trim() : '';
//     }

//     function attr(el, a) {
//       return el ? (el.getAttribute(a) || '').trim() : '';
//     }

//     // ── 1. WPRM (WP Recipe Maker) ─────────────────────────────────────────────
//     // Used by indianhealthyrecipes.com, cookwithmanali.com, etc.

//     function getWprmMeta() {
//       var c = document.querySelector('.wprm-recipe-container, [class*="wprm-recipe"]');
//       if (!c) return null;

//       function wprmText(cls) {
//         var el = c.querySelector('.' + cls);
//         return el ? txt(el) : null;
//       }

//       function wprmTime(type) {
//         // <span class="wprm-recipe-prep_time-container">
//         //   <span class="wprm-recipe-prep_time">15</span>
//         //   <span class="wprm-recipe-prep_time-unit">minutes</span>
//         // </span>
//         var val = c.querySelector('.wprm-recipe-' + type + '_time');
//         var unit = c.querySelector('.wprm-recipe-' + type + '_time-unit');
//         if (!val) return null;
//         var v = txt(val);
//         var u = unit ? txt(unit) : '';
//         return (v + ' ' + u).trim() || null;
//       }

//       return {
//         title:    wprmText('wprm-recipe-name'),
//         desc:     wprmText('wprm-recipe-summary'),
//         servings: wprmText('wprm-recipe-servings-with-unit') ||
//                   (function(){
//                     var s = c.querySelector('.wprm-recipe-servings');
//                     var u = c.querySelector('.wprm-recipe-servings-unit');
//                     if (!s) return null;
//                     return (txt(s) + ' ' + (u ? txt(u) : '')).trim();
//                   })(),
//         prepTime:  wprmTime('prep'),
//         cookTime:  wprmTime('cook'),
//         totalTime: wprmTime('total'),
//         category:  wprmText('wprm-recipe-course'),
//         cuisine:   wprmText('wprm-recipe-cuisine'),
//         image: (function() {
//           var img = c.querySelector('.wprm-recipe-image img');
//           if (img) return img.getAttribute('src') || img.getAttribute('data-src') || '';
//           return '';
//         })(),
//       };
//     }

//     // ── 2. WPRM Ingredients ────────────────────────────────────────────────────

//     function getWprmIngredients() {
//       var groups = [];
//     var groupEls = document.querySelectorAll(
//     '.wprm-recipe-ingredient-group'
//   );

//   if (groupEls.length === 0) {
//     groupEls = document.querySelectorAll(
//       '.wprm-recipe-ingredients-container .wprm-recipe-block-container-columns'
//     );
//   }

//       if (groupEls.length === 0) return null;

//       groupEls.forEach(function(group) {
//         // group header name
//         var nameEl = group.querySelector(
//           '.wprm-recipe-ingredient-group-name, .wprm-recipe-ingredient-group-title, .wprm-recipe-block-header'
//         );
//         var name = nameEl ? txt(nameEl) : '';

//         var items = [];
//         group.querySelectorAll('.wprm-recipe-ingredient').forEach(function(ing) {
//           var parts = [];

//           var amount = ing.querySelector('.wprm-recipe-ingredient-amount');
//           var unit   = ing.querySelector('.wprm-recipe-ingredient-unit');
//           var iName  = ing.querySelector('.wprm-recipe-ingredient-name');
//           var notes  = ing.querySelector('.wprm-recipe-ingredient-notes');

//           if (amount) parts.push(txt(amount));
//           if (unit)   parts.push(txt(unit));
//           if (iName)  parts.push(txt(iName));
//           if (notes) {
//             var n = txt(notes);
//             // parenthesise notes if not already
//             if (n && !n.startsWith('(')) n = '(' + n + ')';
//             if (n) parts.push(n);
//           }

//           var full = parts.join(' ').replace(/\s+/g, ' ').trim();
//           if (full) items.push(full);
//         });

//         if (items.length > 0) {
//           groups.push({ name: name, items: items });
//         }
//       });

//       return groups.length > 0 ? groups : null;
//     }

//     // ── 3. WPRM Instructions ──────────────────────────────────────────────────

//     function getWprmInstructions() {
//       var groups = [];
//     var groupEls = document.querySelectorAll(
//     '.wprm-recipe-instruction-group'
//   );

//   if (groupEls.length === 0) {
//     groupEls = document.querySelectorAll(
//       '.wprm-recipe-instructions-container .wprm-recipe-block-container-columns'
//     );
//   }
//       if (groupEls.length === 0) return null;

//       groupEls.forEach(function(group) {
//         var nameEl = group.querySelector(
//           '.wprm-recipe-instruction-group-name, .wprm-recipe-instruction-group-title, .wprm-recipe-block-header'
//         );
//         var name = nameEl ? txt(nameEl) : '';

//         var steps = [];
//         group.querySelectorAll('.wprm-recipe-instruction-text').forEach(function(step) {
//           // Some WPRM setups have images inside – strip them, keep text only
//           var clone = step.cloneNode(true);
//           clone.querySelectorAll('img, figure').forEach(function(n){ n.remove(); });
//           var t = clone.textContent.replace(/\s+/g, ' ').trim();
//           if (t && steps.indexOf(t) === -1) steps.push(t);
//         });

//         if (steps.length > 0) {
//           groups.push({ name: name, steps: steps });
//         }
//       });

//       return groups.length > 0 ? groups : null;
//     }

//     // ── 4. Tasty Recipes plugin ────────────────────────────────────────────────

//     function getTastyIngredients() {
//       var container = document.querySelector('.tasty-recipes-ingredients');
//       if (!container) return null;
//       var groups = [], currentHeader = '', currentItems = [];
//       container.querySelectorAll('h4, ul').forEach(function(node) {
//         if (node.tagName === 'H4') {
//           if (currentItems.length > 0) {
//             groups.push({ name: currentHeader, items: currentItems });
//             currentItems = [];
//           }
//           currentHeader = txt(node);
//         } else if (node.tagName === 'UL') {
//           node.querySelectorAll('li').forEach(function(li) {
//             var t = txt(li); if (t) currentItems.push(t);
//           });
//         }
//       });
//       if (currentItems.length > 0) groups.push({ name: currentHeader, items: currentItems });
//       return groups.length > 0 ? groups : null;
//     }

//     function getTastyInstructions() {
//       var container = document.querySelector('.tasty-recipes-instructions');
//       if (!container) return null;
//       var groups = [], currentHeader = '', currentSteps = [];
//       container.querySelectorAll('h4, ol').forEach(function(node) {
//         if (node.tagName === 'H4') {
//           if (currentSteps.length > 0) {
//             groups.push({ name: currentHeader, steps: currentSteps });
//             currentSteps = [];
//           }
//           currentHeader = txt(node);
//         } else if (node.tagName === 'OL') {
//           node.querySelectorAll('li').forEach(function(li) {
//             var t = txt(li); if (t) currentSteps.push(t);
//           });
//         }
//       });
//       if (currentSteps.length > 0) groups.push({ name: currentHeader, steps: currentSteps });
//       return groups.length > 0 ? groups : null;
//     }

//     // ── 5. Generic recipe card fallback ───────────────────────────────────────
//     // Handles sites like allrecipes, food52, etc. that use simple lists

//     function getGenericIngredients() {
//       var selectors = [
//         '[class*="ingredient"] li',
//         '[id*="ingredient"] li',
//         '.ingredients li',
//         '.recipe-ingredients li',
//       ];
//       for (var i = 0; i < selectors.length; i++) {
//         var els = document.querySelectorAll(selectors[i]);
//         if (els.length > 0) {
//           var items = [];
//           els.forEach(function(li) {
//             var t = txt(li); if (t) items.push(t);
//           });
//           if (items.length > 0) return [{ name: '', items: items }];
//         }
//       }
//       return null;
//     }

//     function getGenericInstructions() {
//       var selectors = [
//         '[class*="instruction"] li',
//         '[class*="direction"] li',
//         '[class*="step"] li',
//         '.instructions li',
//         '.directions li',
//         '.recipe-directions li',
//         '.steps li',
//       ];
//       for (var i = 0; i < selectors.length; i++) {
//         var els = document.querySelectorAll(selectors[i]);
//         if (els.length > 3) {          // require at least 3 steps to avoid false matches
//           var steps = [];
//           els.forEach(function(li) {
//             var t = txt(li); if (t) steps.push(t);
//           });
//           if (steps.length > 0) return [{ name: '', steps: steps }];
//         }
//       }
//       return null;
//     }

//     // ── 6. Open Graph / page-level meta ───────────────────────────────────────

//     function ogMeta(prop) {
//       var el = document.querySelector('meta[property="' + prop + '"]') ||
//               document.querySelector('meta[name="' + prop + '"]');
//       return el ? (el.getAttribute('content') || '').trim() : '';
//     }

//     // ── 7. JSON-LD blocks ─────────────────────────────────────────────────────

//     var jsonLd = Array.from(
//       document.querySelectorAll('script[type="application/ld+json"]')
//     ).map(function(s) { return s.textContent || ''; });

//     // ── Assemble and return ───────────────────────────────────────────────────

//     var wprmMeta = getWprmMeta();

//     return {
//       // WPRM structured meta
//       wprmMeta: wprmMeta,

//       // Ingredient groups from WPRM, Tasty, or generic fallback
//       wprmIngs:    getWprmIngredients(),
//       tastyIngs:   getTastyIngredients(),
//       genericIngs: getGenericIngredients(),

//       // Instruction groups from WPRM, Tasty, or generic fallback
//       wprmIns:    getWprmInstructions(),
//       tastyIns:   getTastyInstructions(),
//       genericIns: getGenericInstructions(),

//       // Page-level fallbacks
//       title:       ogMeta('og:title') || document.title || '',
//       description: ogMeta('og:description') || ogMeta('description') || '',
//       image:       ogMeta('og:image') || ogMeta('twitter:image') || '',

//       jsonLd: jsonLd,
//     };
//   })())
//   ''');

//       final payload = _decodeJavaScriptJson(raw);
//       if (payload == null) return null;

//       // ── Resolve title ──────────────────────────────────────────────────────
//       final wprmMeta = payload['wprmMeta'] as Map<String, dynamic>?;

//       final title =
//           _text(wprmMeta?['title']) ??
//           _findRecipeJsonField(payload['jsonLd'], 'name') ??
//           _text(payload['title']);
//       if (title == null || title.isEmpty) return null;

//       // ── Resolve ingredient sections ────────────────────────────────────────
//       // Prefer structured sources (WPRM / Tasty plugins, then schema.org
//       // JSON-LD) over the greedy generic DOM grab, which can otherwise scoop up
//       // share/action buttons ("Print", "Add Cooksnap", …) as "ingredients".
//       final jsonLdIngs = _extractIngredientSections(
//         _findRecipeJsonRaw(payload['jsonLd'], 'recipeIngredient'),
//       );
//       final ingredientSections =
//           _parseDomSections(payload['wprmIngs']) ??
//           _parseDomSections(payload['tastyIngs']) ??
//           (jsonLdIngs.isNotEmpty ? jsonLdIngs : null) ??
//           _parseDomSections(payload['genericIngs']) ??
//           <IngredientSection>[];

//       // ── Resolve instruction sections ───────────────────────────────────────
//       final instructionSections =
//           _parseDomInstructions(payload['wprmIns']) ??
//           _parseDomInstructions(payload['tastyIns']) ??
//           _parseDomInstructions(payload['genericIns']) ??
//           _extractInstructionSections(
//             _findRecipeJsonRaw(payload['jsonLd'], 'recipeInstructions'),
//           );

//       // ── Resolve image ─────────────────────────────────────────────────────
//       final rawImage =
//           _text(wprmMeta?['image']) ??
//           _extractImage(_findRecipeJsonRaw(payload['jsonLd'], 'image')) ??
//           _text(payload['image']) ??
//           _text(payload['firstLargeImage']);

//       // ── Resolve times ──────────────────────────────────────────────────────
//       final prepTime =
//           _text(wprmMeta?['prepTime']) ??
//           _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'prepTime'));
//       final cookTime =
//           _text(wprmMeta?['cookTime']) ??
//           _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'cookTime'));
//       final totalTime =
//           _text(wprmMeta?['totalTime']) ??
//           _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'totalTime'));

//       // ── Resolve servings ───────────────────────────────────────────────────
//       final servings =
//           _text(wprmMeta?['servings']) ??
//           _extractServings(
//             _findRecipeJsonRaw(payload['jsonLd'], 'recipeYield'),
//           );

//       return ScrapedRecipeData(
//         title: title,
//         description:
//             _text(wprmMeta?['desc']) ??
//             _findRecipeJsonField(payload['jsonLd'], 'description') ??
//             _text(payload['description']),
//         imageUrl: _absoluteUrl(rawImage),
//         sourceUrl: currentUrl.value!,
//         prepTime: prepTime,
//         cookTime: cookTime,
//         totalTime: totalTime,
//         servings: servings,
//         category:
//             _text(wprmMeta?['category']) ??
//             _findRecipeJsonField(payload['jsonLd'], 'recipeCategory'),
//         cuisine:
//             _text(wprmMeta?['cuisine']) ??
//             _findRecipeJsonField(payload['jsonLd'], 'recipeCuisine'),
//         keywords: _extractKeywords(
//           _findRecipeJsonRaw(payload['jsonLd'], 'keywords'),
//         ),
//         ingredientSections: ingredientSections,
//         instructionSections: instructionSections,
//       );
//     } catch (_) {
//       return null;
//     }
//   }

//   // ── DOM section parsers ────────────────────────────────────────────────────

//   /// Converts [{name, items}] DOM list → List<IngredientSection>
//   List<IngredientSection>? _parseDomSections(dynamic list) {
//     if (list is! List || list.isEmpty) return null;
//     try {
//       final sections = list.map((item) {
//         final name = _text(item['name']);
//         final items = List<String>.from(item['items'] ?? []);
//         return IngredientSection(
//           name: (name != null && name.isNotEmpty) ? name : null,
//           items: items,
//         );
//       }).toList();
//       // Only return if there are actual items
//       final hasItems = sections.any((s) => s.items.isNotEmpty);
//       return hasItems ? sections : null;
//     } catch (_) {
//       return null;
//     }
//   }

//   /// Converts [{name, steps}] DOM list → List<InstructionSection>
//   List<InstructionSection>? _parseDomInstructions(dynamic list) {
//     if (list is! List || list.isEmpty) return null;
//     try {
//       final sections = list.map((item) {
//         final name = _text(item['name']);
//         final steps = List<String>.from(item['steps'] ?? []);
//         return InstructionSection(
//           name: (name != null && name.isNotEmpty) ? name : null,
//           steps: steps,
//         );
//       }).toList();
//       final hasSteps = sections.any((s) => s.steps.isNotEmpty);
//       return hasSteps ? sections : null;
//     } catch (_) {
//       return null;
//     }
//   }

//   // ── JSON-LD helpers ────────────────────────────────────────────────────────

//   Map<String, dynamic>? _decodeJavaScriptJson(Object raw) {
//     try {
//       final rawText = raw.toString();
//       final decoded = jsonDecode(rawText);
//       final value = decoded is String ? jsonDecode(decoded) : decoded;
//       return value is Map<String, dynamic> ? value : null;
//     } catch (_) {
//       return null;
//     }
//   }

//   /// Find the first Recipe node inside JSON-LD blocks and return a named field.
//   String? _findRecipeJsonField(dynamic jsonLdBlocks, String field) {
//     final recipe = _findRecipeJson(jsonLdBlocks);
//     return _text(recipe?[field]);
//   }

//   dynamic _findRecipeJsonRaw(dynamic jsonLdBlocks, String field) {
//     final recipe = _findRecipeJson(jsonLdBlocks);
//     return recipe?[field];
//   }

//   Map<String, dynamic>? _findRecipeJson(dynamic jsonLdBlocks) {
//     if (jsonLdBlocks is! List) return null;
//     for (final block in jsonLdBlocks) {
//       try {
//         final decoded = jsonDecode(block.toString());
//         final recipe = _findRecipeNode(decoded);
//         if (recipe != null) return recipe;
//       } catch (_) {
//         continue;
//       }
//     }
//     return null;
//   }

//   Map<String, dynamic>? _findRecipeNode(dynamic node) {
//     if (node is List) {
//       for (final item in node) {
//         final r = _findRecipeNode(item);
//         if (r != null) return r;
//       }
//       return null;
//     }
//     if (node is! Map) return null;
//     final map = Map<String, dynamic>.from(node);
//     final type = map['@type'];
//     final isRecipe =
//         type == 'Recipe' ||
//         (type is List && type.map((e) => e.toString()).contains('Recipe'));
//     if (isRecipe) return map;
//     return _findRecipeNode(map['@graph']) ?? _findRecipeNode(map['mainEntity']);
//   }

//   // ── Ingredient section parsing (flat list → sections) ─────────────────────

//   List<IngredientSection> _detectIngredientSections(List<String> flatList) {
//     if (flatList.isEmpty) return [];

//     final sections = <IngredientSection>[];
//     String? currentName;
//     final currentItems = <String>[];

//     for (final item in flatList) {
//       if (_isIngredientSectionHeader(item)) {
//         if (currentItems.isNotEmpty) {
//           sections.add(
//             IngredientSection(
//               name: currentName,
//               items: List.from(currentItems),
//             ),
//           );
//           currentItems.clear();
//         }
//         currentName = item.endsWith(':')
//             ? item.substring(0, item.length - 1).trim()
//             : item.trim();
//       } else {
//         currentItems.add(item);
//       }
//     }

//     if (currentItems.isNotEmpty) {
//       sections.add(
//         IngredientSection(name: currentName, items: List.from(currentItems)),
//       );
//     }

//     return sections.isEmpty ? [IngredientSection(items: flatList)] : sections;
//   }

//   bool _isIngredientSectionHeader(String text) {
//     final t = text.trim();
//     if (t.endsWith(':') && t.length <= 80 && !t.contains(RegExp(r'\d'))) {
//       return true;
//     }
//     if (t.isNotEmpty &&
//         t == t.toUpperCase() &&
//         t.length <= 40 &&
//         !t.contains(RegExp(r'\d'))) {
//       return true;
//     }
//     return false;
//   }

//   List<IngredientSection> _extractIngredientSections(dynamic value) {
//     final flat = _stringList(value);
//     return _detectIngredientSections(flat);
//   }

//   // ── Instruction section parsing (JSON-LD) ─────────────────────────────────

//   List<InstructionSection> _extractInstructionSections(dynamic value) {
//     if (value == null) return [];

//     if (value is String) {
//       final steps = _splitInstructionText(value);
//       return steps.isEmpty ? [] : [InstructionSection(steps: steps)];
//     }

//     if (value is! List) return [];

//     final sections = <InstructionSection>[];
//     final pendingSteps = <String>[];

//     void flushPending() {
//       if (pendingSteps.isNotEmpty) {
//         sections.add(InstructionSection(steps: List.from(pendingSteps)));
//         pendingSteps.clear();
//       }
//     }

//     for (final item in value) {
//       if (item is String) {
//         pendingSteps.addAll(_splitInstructionText(item));
//       } else if (item is Map) {
//         final type = item['@type']?.toString() ?? '';
//         if (type == 'HowToSection') {
//           flushPending();
//           final name = _text(item['name']);
//           final sub = _extractInstructionSections(item['itemListElement']);
//           sections.add(
//             InstructionSection(
//               name: name,
//               steps: sub.expand((s) => s.steps).toList(),
//             ),
//           );
//         } else {
//           final text = _text(item['text']) ?? _text(item['name']);
//           if (text != null && text.isNotEmpty) {
//             pendingSteps.add(text);
//           } else if (item['itemListElement'] != null) {
//             final sub = _extractInstructionSections(item['itemListElement']);
//             pendingSteps.addAll(sub.expand((s) => s.steps));
//           }
//         }
//       }
//     }

//     flushPending();
//     return sections;
//   }

//   List<String> _splitInstructionText(String text) {
//     return text
//         .split(RegExp(r'(?<=[.!?])\s+|\n+'))
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();
//   }

//   // ── Misc helpers ───────────────────────────────────────────────────────────

//   List<String> _stringList(dynamic value) {
//     if (value is String) return [value];
//     if (value is List) {
//       return value
//           .map((e) => e.toString().trim())
//           .where((e) => e.isNotEmpty)
//           .toList();
//     }
//     return const [];
//   }

//   List<String> _extractKeywords(dynamic value) {
//     if (value is List) return _stringList(value);
//     if (value is String) {
//       return value
//           .split(',')
//           .map((e) => e.trim())
//           .where((e) => e.isNotEmpty)
//           .toList();
//     }
//     return const [];
//   }

//   String? _extractServings(dynamic value) {
//     if (value is List && value.isNotEmpty) return _text(value.first);
//     return _text(value);
//   }

//   /// Converts ISO-8601 duration (PT15M, PT1H30M) → human string (15m / 1h 30m).
//   String? _formatDuration(dynamic value) {
//     final text = _text(value);
//     if (text == null) return null;

//     final match = RegExp(
//       r'^P(?:\d+D)?T?(?:(\d+)H)?(?:(\d+)M)?',
//       caseSensitive: false,
//     ).firstMatch(text);
//     if (match == null) return text;

//     final hours = int.tryParse(match.group(1) ?? '') ?? 0;
//     final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
//     if (hours == 0 && minutes == 0) return text;
//     if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
//     if (hours > 0) return '${hours}h';
//     return '${minutes}m';
//   }

//   String? _text(dynamic value) {
//     final text = value?.toString().trim();
//     return (text == null || text.isEmpty) ? null : text;
//   }

//   String? _absoluteUrl(String? url) {
//     if (url == null || url.isEmpty) return null;
//     if (url.startsWith('data:')) return null; // skip base64 placeholders
//     final base = Uri.tryParse(currentUrl.value ?? '');
//     final parsed = Uri.tryParse(url);
//     if (parsed == null) return null;
//     return base?.resolveUri(parsed).toString() ?? parsed.toString();
//   }

//   // ── Landing page HTML ──────────────────────────────────────────────────────

//   static const String _landingPageHtml =
//       '''
//   <!DOCTYPE html>
//   <html>
//   <head>
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <style>
//       * { box-sizing: border-box; }

//       body {
//         margin: 0;
//         background: #f5f0e4;
//         font-family: -apple-system, Roboto, sans-serif;
//         color: #191713;
//       }

//       .hero {
//         min-height: 100vh;
//         display: flex;
//         flex-direction: column;
//         align-items: center;
//         justify-content: center;
//         padding: 24px;
//       }

//       .brand {
//         width: 100%;
//         max-width: 700px;
//         font-family: Georgia, 'Times New Roman', serif;
//         font-size: clamp(30px, 6vw, 50px);
//         line-height: 1.1;
//         margin-bottom: 24px;
//         color: #191713;
//         text-align: center;
//       }

//       .g-blue   { color: #4285f4; font-family: Arial, sans-serif; font-weight: 600; }
//       .g-red    { color: #ea4335; font-family: Arial, sans-serif; font-weight: 600; }
//       .g-yellow { color: #fbbc05; font-family: Arial, sans-serif; font-weight: 600; }
//       .g-green  { color: #34a853; font-family: Arial, sans-serif; font-weight: 600; }

//       form { width: 100%; max-width: 700px; }

//       .search-box {
//         background: #ffffff;
//         border: 2px solid #d3cec3;
//         border-radius: 999px;
//         min-height: 70px;
//         padding: 0 24px;
//         display: flex;
//         align-items: center;
//         gap: 16px;
//       }

//       .search-icon {
//         width: 24px;
//         height: 24px;
//         border: 3px solid #8d8880;
//         border-radius: 50%;
//         position: relative;
//         flex-shrink: 0;
//       }
//       .search-icon:after {
//         content: '';
//         position: absolute;
//         width: 12px; height: 3px;
//         background: #8d8880;
//         right: -8px; bottom: -4px;
//         transform: rotate(45deg);
//         border-radius: 2px;
//       }

//       input {
//         border: none; outline: none; width: 100%;
//         background: transparent; color: #1f1b16; font-size: 18px;
//       }
//       input::placeholder { color: #8d8880; }

//       @media (max-width: 520px) {
//         .hero { padding: 20px; }
//         .brand { font-size: 28px; margin-bottom: 18px; }
//         .search-box { min-height: 58px; padding: 0 18px; }
//         .search-icon { width: 20px; height: 20px; }
//         input { font-size: 16px; }
//       }
//     </style>
//   </head>
//   <body>
//     <main class="hero">
//       <div class="brand">
//         <span class="g-blue">G</span><span class="g-red">o</span><span
//           class="g-yellow">o</span><span class="g-blue">g</span><span
//           class="g-green">l</span><span class="g-red">e</span> a recipe
//       </div>

//       <form id="recipeSearch">
//         <label class="search-box">
//           <span class="search-icon"></span>
//           <input
//             id="query"
//             type="search"
//             placeholder="Search for a recipe or paste a URL"
//             autofocus
//           />
//         </label>
//       </form>
//     </main>

//     <script>
//       document.getElementById('recipeSearch').addEventListener('submit', function(e) {
//         e.preventDefault();
//         var query = document.getElementById('query').value.trim();
//         if (!query) return;
//         var target = query;
//         if (!/^https?:\\/\\//i.test(target) && target.indexOf('.') !== -1) {
//           target = 'https://' + target;
//         }
//         if (!/^https?:\\/\\//i.test(target)) {
//           target = 'https://www.google.com/search?q=' +
//             encodeURIComponent(query + ' recipe$_excludeSites') + '&udm=14';
//         }
//         window.location.href = target;
//       });
//     </script>
//   </body>
//   </html>
//   ''';
// }

import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_scraper/recipe_scraper.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';

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
    required List<InstructionSection> instructionSections,
  }) : ingredientSections = _deduplicateIngredientSections(ingredientSections),
       instructionSections = _deduplicateInstructionSections(
         instructionSections,
       );

  // ─────────────────────────────────────────────────────────────────────────
  // Ingredient cleaning
  // ─────────────────────────────────────────────────────────────────────────

  static String cleanIngredient(String raw) {
    return raw
        .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[,;]+$'), '')
        .trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Normalize text for duplicate comparison
  // ─────────────────────────────────────────────────────────────────────────

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,;:]+$'), '')
        .trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Deduplicate ingredients
  // ─────────────────────────────────────────────────────────────────────────

  static List<IngredientSection> _deduplicateIngredientSections(
    List<IngredientSection> sections,
  ) {
    final result = <IngredientSection>[];

    // Global set:
    // Same ingredient appearing in two different sections
    // will also be removed.
    final globalSeen = <String>{};

    for (final section in sections) {
      final uniqueItems = <String>[];

      for (final rawItem in section.items) {
        final cleaned = cleanIngredient(rawItem);

        if (cleaned.isEmpty) continue;

        final normalized = _normalize(cleaned);

        if (globalSeen.add(normalized)) {
          uniqueItems.add(cleaned);
        }
      }

      if (uniqueItems.isNotEmpty) {
        result.add(IngredientSection(name: section.name, items: uniqueItems));
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Deduplicate instructions
  // ─────────────────────────────────────────────────────────────────────────

  static List<InstructionSection> _deduplicateInstructionSections(
    List<InstructionSection> sections,
  ) {
    final result = <InstructionSection>[];

    final globalSeen = <String>{};

    for (final section in sections) {
      final uniqueSteps = <String>[];

      for (final rawStep in section.steps) {
        final cleaned = rawStep.replaceAll(RegExp(r'\s+'), ' ').trim();

        if (cleaned.isEmpty) continue;

        final normalized = _normalize(cleaned);

        if (globalSeen.add(normalized)) {
          uniqueSteps.add(cleaned);
        }
      }

      if (uniqueSteps.isNotEmpty) {
        result.add(InstructionSection(name: section.name, steps: uniqueSteps));
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Flat ingredient list
  // ─────────────────────────────────────────────────────────────────────────

  List<String> get ingredients =>
      ingredientSections.expand((s) => s.items).toList();

  // ─────────────────────────────────────────────────────────────────────────
  // Flat instruction list
  // ─────────────────────────────────────────────────────────────────────────

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

  /// Google `-site:` filters appended to name searches so video/social sites
  /// (which don't show a readable, importable recipe) are excluded — only
  /// recipe-detail websites appear.
  static const String _excludeSites =
      ' -site:youtube.com -site:youtu.be -site:instagram.com'
      ' -site:tiktok.com -site:facebook.com -site:pinterest.com';

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
    // `udm=14` is Google's plain "Web" results mode: a classic list of website
    // links with NO AI overview, video carousels, "People also ask", "People
    // also search for" or short-video blocks. The `-site:` filters drop
    // video/social sites so only recipe-detail websites remain.
    final encoded = Uri.encodeQueryComponent('$query recipe$_excludeSites');
    webViewController.loadRequest(
      Uri.parse('https://www.google.com/search?q=$encoded&udm=14'),
    );
  }

  // ── Scrape orchestration ───────────────────────────────────────────────────

  Future<ScrapedRecipeData?> scrapeCurrentPage() async {
    if (currentUrl.value == null) return null;

    isImporting.value = true;
    ScrapedRecipeData? recipeData;

    try {
      // 1️⃣  DOM-first: WPRM / Tasty / Microdata / JSON-LD scraped from live page
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

  Future<RecipeModel?> saveRecipe(ScrapedRecipeData recipe) async {
    try {
      final uid = AuthService.currentUser?.uid;

      if (uid == null) {
        CustomSnackbar.show(
          title: 'Error',
          message: 'You must be logged in to save recipes.',
          type: SnackbarType.error,
        );
        return null;
      }

      // ============================================================
      // ALWAYS convert scraped recipe to English BEFORE saving
      // ============================================================

      log('Translating imported recipe to English...');

      final englishRecipe = await _translateRecipeToEnglish(recipe);

      log('English recipe ready');
      log('Title: ${englishRecipe.title}');

      // ============================================================
      // Upload image
      // ============================================================

      String? firebaseImageUrl;

      if (englishRecipe.imageUrl != null &&
          englishRecipe.imageUrl!.isNotEmpty) {
        firebaseImageUrl = await uploadRecipeImage(
          englishRecipe.imageUrl!,
          uid,
        );
      }

      final resolvedImageUrl = firebaseImageUrl ?? englishRecipe.imageUrl;

      // ============================================================
      // SAVE ONLY englishRecipe TO FIRESTORE
      // ============================================================

      final docRef = await FirebaseFirestore.instance.collection('recipes').add(
        {
          'title': englishRecipe.title,
          'description': englishRecipe.description,

          'imageUrl': resolvedImageUrl,
          'sourceUrl': englishRecipe.sourceUrl,

          // These are non-language values
          'prepTime': englishRecipe.prepTime,
          'cookTime': englishRecipe.cookTime,
          'totalTime': englishRecipe.totalTime,
          'servings': englishRecipe.servings,

          // English only
          'category': englishRecipe.category,
          'cuisine': englishRecipe.cuisine,
          'keywords': englishRecipe.keywords,

          'ingredientSections': englishRecipe.ingredientSections
              .map((section) => section.toMap())
              .toList(),

          'instructionSections': englishRecipe.instructionSections
              .map((section) => section.toMap())
              .toList(),

          'ingredients': englishRecipe.ingredients,
          'instructions': englishRecipe.instructions,

          'isPublic': false,
          'recipeSource': 'imported',
          'originalRecipeId': null,
          'ownerId': uid,
          'isDeleted': false,

          'likesCount': 0,
          'commentsCount': 0,
          'savesCount': 0,
          'sharesCount': 0,
          'viewsCount': 0,

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (freeRecipesLeft.value > 0) {
        freeRecipesLeft.value--;
      }

      return RecipeModel(
        id: docRef.id,
        title: englishRecipe.title,
        description: englishRecipe.description,
        imageUrl: resolvedImageUrl,
        sourceUrl: englishRecipe.sourceUrl,
        prepTime: englishRecipe.prepTime,
        cookTime: englishRecipe.cookTime,
        totalTime: englishRecipe.totalTime,
        servings: englishRecipe.servings,
        category: englishRecipe.category,
        cuisine: englishRecipe.cuisine,
        keywords: englishRecipe.keywords,
        ingredients: englishRecipe.ingredients,
        instructions: englishRecipe.instructions,
        ingredientSections: englishRecipe.ingredientSections,
        instructionSections: englishRecipe.instructionSections,
      );
    } catch (e, stackTrace) {
      log('Failed to save recipe');
      log('Error: $e');
      log('StackTrace: $stackTrace');

      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to save recipe: $e',
        type: SnackbarType.error,
      );

      return null;
    }
  }

  // Future<ScrapedRecipeData> _translateRecipeToEnglish(
  //   ScrapedRecipeData recipe,
  // ) async {
  //   // 1️⃣ Detect language ONCE using combined representative text.
  //   final sample = <String>[
  //     recipe.title,
  //     if (recipe.description != null) recipe.description!,
  //     ...recipe.ingredients.take(3),
  //     ...recipe.instructions.take(2),
  //   ];

  //   final detected = await AiTranslationService.detectDominantLanguage(sample);
  //   log('🌍 Recipe language: $detected');

  //   if (detected == 'en' || detected == 'und') {
  //     // Already English, or couldn't reliably tell — leave as-is.
  //     return recipe;
  //   }

  //   // 2️⃣ One translator for the WHOLE recipe (no re-download / re-create per string).
  //   final translator = await AiTranslationService.prepareTranslatorFor(
  //     detected,
  //   );
  //   if (translator == null) {
  //     log(
  //       '⚠️ Could not prepare translator for $detected — saving original text',
  //     );
  //     return recipe;
  //   }

  //   Future<String> t(String? text) =>
  //       AiTranslationService.translateWithTranslator(translator, text);

  //   try {
  //     final title = await t(recipe.title);
  //     final description = recipe.description == null
  //         ? null
  //         : await t(recipe.description);
  //     final category = recipe.category == null
  //         ? null
  //         : await t(recipe.category);
  //     final cuisine = recipe.cuisine == null ? null : await t(recipe.cuisine);

  //     final keywords = <String>[];
  //     for (final keyword in recipe.keywords) {
  //       final translated = await t(keyword);
  //       if (translated.trim().isNotEmpty) keywords.add(translated.trim());
  //     }

  //     final ingredientSections = <IngredientSection>[];
  //     for (final section in recipe.ingredientSections) {
  //       final sectionName = section.name == null
  //           ? null
  //           : await t(section.name!);
  //       final items = <String>[];
  //       for (final item in section.items) {
  //         final translated = await t(item);
  //         if (translated.trim().isNotEmpty) items.add(translated.trim());
  //       }
  //       if (items.isNotEmpty) {
  //         ingredientSections.add(
  //           IngredientSection(name: sectionName?.trim(), items: items),
  //         );
  //       }
  //     }

  //     final instructionSections = <InstructionSection>[];
  //     for (final section in recipe.instructionSections) {
  //       final sectionName = section.name == null
  //           ? null
  //           : await t(section.name!);
  //       final steps = <String>[];
  //       for (final step in section.steps) {
  //         final translated = await t(step);
  //         if (translated.trim().isNotEmpty) steps.add(translated.trim());
  //       }
  //       if (steps.isNotEmpty) {
  //         instructionSections.add(
  //           InstructionSection(name: sectionName?.trim(), steps: steps),
  //         );
  //       }
  //     }

  //     log('✅ Recipe translated: ${title.trim()}');

  //     return ScrapedRecipeData(
  //       title: title.trim().isEmpty ? recipe.title : title.trim(),
  //       description: description?.trim(),
  //       imageUrl: recipe.imageUrl,
  //       sourceUrl: recipe.sourceUrl,
  //       prepTime: recipe.prepTime,
  //       cookTime: recipe.cookTime,
  //       totalTime: recipe.totalTime,
  //       servings: recipe.servings,
  //       category: category?.trim(),
  //       cuisine: cuisine?.trim(),
  //       keywords: keywords,
  //       ingredientSections: ingredientSections,
  //       instructionSections: instructionSections,
  //     );
  //   } finally {
  //     await translator.close();
  //   }
  // }

  Future<ScrapedRecipeData> _translateRecipeToEnglish(
    ScrapedRecipeData recipe,
  ) async {
    // 1️⃣ Detect language ONCE using combined representative text.
    final sample = <String>[
      recipe.title,
      if (recipe.description != null) recipe.description!,
      ...recipe.ingredients.take(3),
      ...recipe.instructions.take(2),
    ];

    final detected = await AiTranslationService.detectDominantLanguage(sample);
    log('🌍 Recipe language: $detected');

    if (detected == 'en' || detected == 'und') {
      // Already English, or couldn't reliably tell — leave as-is.
      return recipe;
    }

    // 2️⃣ One translator for the WHOLE recipe (no re-download / re-create per string).
    final translator = await AiTranslationService.prepareTranslatorFor(
      detected,
    );
    if (translator == null) {
      log(
        '⚠️ Could not prepare translator for $detected — saving original text',
      );
      return recipe;
    }

    Future<String> t(String? text) =>
        AiTranslationService.translateWithTranslator(translator, text);

    try {
      final title = await t(recipe.title);
      final description = recipe.description == null
          ? null
          : await t(recipe.description);
      final category = recipe.category == null
          ? null
          : await t(recipe.category);
      final cuisine = recipe.cuisine == null ? null : await t(recipe.cuisine);

      // Time/servings can carry non-numeric words in the source language
      // (e.g. "૧૫ મિનિટ", "૪ પીરસવાનું") — translate these too instead of
      // saving them as-is.
      final prepTime = recipe.prepTime == null
          ? null
          : await t(recipe.prepTime);
      final cookTime = recipe.cookTime == null
          ? null
          : await t(recipe.cookTime);
      final totalTime = recipe.totalTime == null
          ? null
          : await t(recipe.totalTime);
      final servings = recipe.servings == null
          ? null
          : await t(recipe.servings);

      final keywords = <String>[];
      for (final keyword in recipe.keywords) {
        final translated = await t(keyword);
        if (translated.trim().isNotEmpty) keywords.add(translated.trim());
      }

      final ingredientSections = <IngredientSection>[];
      for (final section in recipe.ingredientSections) {
        final sectionName = section.name == null
            ? null
            : await t(section.name!);
        final items = <String>[];
        for (final item in section.items) {
          final translated = await t(item);
          if (translated.trim().isNotEmpty) items.add(translated.trim());
        }
        if (items.isNotEmpty) {
          ingredientSections.add(
            IngredientSection(name: sectionName?.trim(), items: items),
          );
        }
      }

      final instructionSections = <InstructionSection>[];
      for (final section in recipe.instructionSections) {
        final sectionName = section.name == null
            ? null
            : await t(section.name!);
        final steps = <String>[];
        for (final step in section.steps) {
          final translated = await t(step);
          if (translated.trim().isNotEmpty) steps.add(translated.trim());
        }
        if (steps.isNotEmpty) {
          instructionSections.add(
            InstructionSection(name: sectionName?.trim(), steps: steps),
          );
        }
      }

      log('✅ Recipe translated: ${title.trim()}');

      return ScrapedRecipeData(
        title: title.trim().isEmpty ? recipe.title : title.trim(),
        description: description?.trim(),
        imageUrl: recipe.imageUrl,
        sourceUrl: recipe.sourceUrl,
        prepTime: prepTime?.trim(),
        cookTime: cookTime?.trim(),
        totalTime: totalTime?.trim(),
        servings: servings?.trim(),
        category: category?.trim(),
        cuisine: cuisine?.trim(),
        keywords: keywords,
        ingredientSections: ingredientSections,
        instructionSections: instructionSections,
      );
    } finally {
      await translator.close();
    }
  }
  
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

  // Buttons / share-widgets / prompts that generic list-scraping can
  // accidentally scoop up as "ingredients" or "instructions".
  var IRRELEVANT_TEXT = /^(print|pin|save|share|rate this|jump to recipe|leave a (comment|review)|subscribe|follow us)\b/i;

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
  '.wprm-recipe-ingredient-group'
);

if (groupEls.length === 0) {
  groupEls = document.querySelectorAll(
    '.wprm-recipe-ingredients-container .wprm-recipe-block-container-columns'
  );
}
    
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
  '.wprm-recipe-instruction-group'
);

if (groupEls.length === 0) {
  groupEls = document.querySelectorAll(
    '.wprm-recipe-instructions-container .wprm-recipe-block-container-columns'
  );
}
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
          var t = txt(li);
          if (t && !IRRELEVANT_TEXT.test(t)) items.push(t);
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
          var t = txt(li);
          if (t && !IRRELEVANT_TEXT.test(t)) steps.push(t);
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

  // ── 7b. Microdata (schema.org itemprop) ───────────────────────────────────
  // Handles sites that mark up Recipe schema directly in HTML attributes
  // instead of JSON-LD or a plugin (common on custom-theme blogs).

  function getMicrodataRoot() {
    return document.querySelector(
      '[itemtype*="schema.org/Recipe" i], [itemtype$="Recipe" i]'
    );
  }

  function microdataProp(root, prop) {
    if (!root) return null;
    var el = root.querySelector('[itemprop="' + prop + '"]');
    if (!el) return null;
    if (el.tagName === 'META') return (el.getAttribute('content') || '').trim();
    if (el.tagName === 'TIME') {
      return (el.getAttribute('datetime') || txt(el)).trim();
    }
    if (el.tagName === 'IMG') {
      return (el.getAttribute('src') || el.getAttribute('data-src') || '').trim();
    }
    if (el.hasAttribute('content')) return (el.getAttribute('content') || '').trim();
    return txt(el);
  }

  function microdataPropAll(root, prop) {
    if (!root) return [];
    var out = [];
    root.querySelectorAll('[itemprop="' + prop + '"]').forEach(function(el) {
      var v = el.hasAttribute('content') ? el.getAttribute('content') : txt(el);
      v = (v || '').trim();
      if (v) out.push(v);
    });
    return out;
  }

  function getMicrodataMeta() {
    var root = getMicrodataRoot();
    if (!root) return null;
    return {
      title:    microdataProp(root, 'name'),
      desc:     microdataProp(root, 'description'),
      image:    microdataProp(root, 'image'),
      prepTime: microdataProp(root, 'prepTime'),
      cookTime: microdataProp(root, 'cookTime'),
      totalTime:microdataProp(root, 'totalTime'),
      servings: microdataProp(root, 'recipeYield') || microdataProp(root, 'yield'),
      category: microdataProp(root, 'recipeCategory'),
      cuisine:  microdataProp(root, 'recipeCuisine'),
      keywords: microdataProp(root, 'keywords'),
    };
  }

  function getMicrodataIngredients() {
    var root = getMicrodataRoot();
    if (!root) return null;
    var items = microdataPropAll(root, 'recipeIngredient');
    if (items.length === 0) items = microdataPropAll(root, 'ingredients');
    return items.length > 0 ? [{ name: '', items: items }] : null;
  }

  function getMicrodataInstructions() {
    var root = getMicrodataRoot();
    if (!root) return null;
    var stepEls = root.querySelectorAll('[itemprop="recipeInstructions"]');
    if (stepEls.length === 0) return null;

    if (stepEls.length === 1) {
      var nested = stepEls[0].querySelectorAll('[itemprop="itemListElement"], li');
      if (nested.length > 1) {
        var steps = [];
        nested.forEach(function(n) { var t = txt(n); if (t) steps.push(t); });
        return steps.length ? [{ name: '', steps: steps }] : null;
      }
      var single = txt(stepEls[0]);
      return single ? [{ name: '', steps: [single] }] : null;
    }

    var multi = [];
    stepEls.forEach(function(el) { var t = txt(el); if (t) multi.push(t); });
    return multi.length ? [{ name: '', steps: multi }] : null;
  }

  // ── 7c. Generic labeled-text fallback ─────────────────────────────────────
  // Last-resort for simple templates with no plugin/microdata/JSON-LD at all —
  // scans short text nodes for "Prep Time: 15 mins", "Servings: 4", etc.

  function getLabeledMeta() {
    var labelMap = {
      prepTime:  ['prep time', 'preparation time'],
      cookTime:  ['cook time', 'cooking time'],
      totalTime: ['total time', 'ready in'],
      servings:  ['servings', 'serves', 'yield'],
      category:  ['course', 'category'],
      cuisine:   ['cuisine'],
    };
    var nodes = document.querySelectorAll('li, p, span, div, dt, dd, td, th');
    var maxLen = 60;
    var result = {};

    Object.keys(labelMap).forEach(function(key) {
      var labels = labelMap[key];
      for (var i = 0; i < nodes.length && !result[key]; i++) {
        var t = txt(nodes[i]);
        if (!t || t.length > maxLen) continue;
        var lower = t.toLowerCase();
        for (var j = 0; j < labels.length; j++) {
          if (lower.indexOf(labels[j]) === 0) {
            var rest = t.slice(labels[j].length).replace(/^[:\s-]+/, '').trim();
            if (rest && rest.length < maxLen) { result[key] = rest; break; }
          }
        }
      }
    });

    return result;
  }

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

    // Microdata (schema.org itemprop) + labeled-text fallback layers
    microdataMeta: getMicrodataMeta(),
    microdataIngs: getMicrodataIngredients(),
    microdataIns:  getMicrodataInstructions(),
    labeledMeta:   getLabeledMeta(),

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

      final wprmMeta = payload['wprmMeta'] as Map<String, dynamic>?;
      final microdataMeta = payload['microdataMeta'] as Map<String, dynamic>?;
      final labeledMeta = payload['labeledMeta'] as Map<String, dynamic>?;

      // ── Resolve title ────────────────────────────────────────────────────
      final title =
          _text(wprmMeta?['title']) ??
          _findRecipeJsonField(payload['jsonLd'], 'name') ??
          _text(microdataMeta?['title']) ??
          _text(payload['title']);
      if (title == null || title.isEmpty) return null;

      // ── Resolve ingredient sections ─────────────────────────────────────
      // Merge every structured source that found something (instead of only
      // keeping the first) so a site that splits ingredients across a
      // plugin AND schema.org markup doesn't lose either half. Only fall
      // back to the greedy generic DOM grab if NONE of the structured
      // sources produced anything.
      final jsonLdIngs = _extractIngredientSections(
        _findRecipeJsonRawMerged(payload['jsonLd'], 'recipeIngredient'),
      );

      var ingredientSections = _mergeIngredientSections([
        _parseDomSections(payload['wprmIngs']),
        _parseDomSections(payload['tastyIngs']),
        jsonLdIngs.isNotEmpty ? jsonLdIngs : null,
        _parseDomSections(payload['microdataIngs']),
      ]);

      if (ingredientSections.isEmpty) {
        ingredientSections =
            _parseDomSections(payload['genericIngs']) ?? <IngredientSection>[];
      }

      // ── Resolve instruction sections ────────────────────────────────────
      final jsonLdIns = _extractInstructionSections(
        _findRecipeJsonRawMerged(payload['jsonLd'], 'recipeInstructions'),
      );

      var instructionSections = _mergeInstructionSections([
        _parseDomInstructions(payload['wprmIns']),
        _parseDomInstructions(payload['tastyIns']),
        jsonLdIns.isNotEmpty ? jsonLdIns : null,
        _parseDomInstructions(payload['microdataIns']),
      ]);

      if (instructionSections.isEmpty) {
        instructionSections =
            _parseDomInstructions(payload['genericIns']) ??
            <InstructionSection>[];
      }

      // ── Resolve image ────────────────────────────────────────────────────
      final rawImage =
          _text(wprmMeta?['image']) ??
          _extractImage(_findRecipeJsonRaw(payload['jsonLd'], 'image')) ??
          _text(microdataMeta?['image']) ??
          _text(payload['image']) ??
          _text(payload['firstLargeImage']);

      // ── Resolve times (WPRM -> JSON-LD -> microdata -> labeled text) ────
      final prepTime =
          _text(wprmMeta?['prepTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'prepTime')) ??
          _formatDuration(microdataMeta?['prepTime']) ??
          _text(labeledMeta?['prepTime']);

      final cookTime =
          _text(wprmMeta?['cookTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'cookTime')) ??
          _formatDuration(microdataMeta?['cookTime']) ??
          _text(labeledMeta?['cookTime']);

      final totalTime =
          _text(wprmMeta?['totalTime']) ??
          _formatDuration(_findRecipeJsonRaw(payload['jsonLd'], 'totalTime')) ??
          _formatDuration(microdataMeta?['totalTime']) ??
          _text(labeledMeta?['totalTime']);

      // ── Resolve servings ──────────────────────────────────────────────────
      final servings =
          _text(wprmMeta?['servings']) ??
          _extractServings(
            _findRecipeJsonRaw(payload['jsonLd'], 'recipeYield'),
          ) ??
          _text(microdataMeta?['servings']) ??
          _text(labeledMeta?['servings']);

      // ── Resolve category / cuisine ──────────────────────────────────────
      final category =
          _text(wprmMeta?['category']) ??
          _findRecipeJsonField(payload['jsonLd'], 'recipeCategory') ??
          _text(microdataMeta?['category']) ??
          _text(labeledMeta?['category']);

      final cuisine =
          _text(wprmMeta?['cuisine']) ??
          _findRecipeJsonField(payload['jsonLd'], 'recipeCuisine') ??
          _text(microdataMeta?['cuisine']) ??
          _text(labeledMeta?['cuisine']);

      // ── Resolve keywords (union across JSON-LD + microdata, deduped) ────
      final keywords = <String>{
        ..._extractKeywords(_findRecipeJsonRaw(payload['jsonLd'], 'keywords')),
        ..._extractKeywords(microdataMeta?['keywords']),
      }.toList();

      // ── Resolve description ──────────────────────────────────────────────
      final description =
          _text(wprmMeta?['desc']) ??
          _findRecipeJsonField(payload['jsonLd'], 'description') ??
          _text(microdataMeta?['desc']) ??
          _text(payload['description']);

      return ScrapedRecipeData(
        title: title,
        description: description,
        imageUrl: _absoluteUrl(rawImage),
        sourceUrl: currentUrl.value!,
        prepTime: prepTime,
        cookTime: cookTime,
        totalTime: totalTime,
        servings: servings,
        category: category,
        cuisine: cuisine,
        keywords: keywords,
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

  /// Merges ingredient sections from every STRUCTURED source that produced
  /// something (WPRM, Tasty, JSON-LD, microdata) instead of only keeping the
  /// first match — a site may render ingredients via one system and
  /// instructions via another. Sections sharing the same name (including
  /// unnamed "") are combined into one; duplicate items across sources are
  /// removed later by [ScrapedRecipeData]'s global dedup, so merging never
  /// produces visible repeats.
  List<IngredientSection> _mergeIngredientSections(
    List<List<IngredientSection>?> candidates,
  ) {
    final order = <String>[];
    final displayNames = <String, String?>{};
    final itemsByKey = <String, List<String>>{};

    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      for (final section in candidate) {
        final key = (section.name ?? '').trim().toLowerCase();
        if (!itemsByKey.containsKey(key)) {
          itemsByKey[key] = [];
          displayNames[key] = section.name;
          order.add(key);
        }
        itemsByKey[key]!.addAll(section.items);
      }
    }

    return order
        .map(
          (key) => IngredientSection(
            name: displayNames[key],
            items: itemsByKey[key]!,
          ),
        )
        .toList();
  }

  /// Same idea as [_mergeIngredientSections], for instruction sections.
  List<InstructionSection> _mergeInstructionSections(
    List<List<InstructionSection>?> candidates,
  ) {
    final order = <String>[];
    final displayNames = <String, String?>{};
    final stepsByKey = <String, List<String>>{};

    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      for (final section in candidate) {
        final key = (section.name ?? '').trim().toLowerCase();
        if (!stepsByKey.containsKey(key)) {
          stepsByKey[key] = [];
          displayNames[key] = section.name;
          order.add(key);
        }
        stepsByKey[key]!.addAll(section.steps);
      }
    }

    return order
        .map(
          (key) => InstructionSection(
            name: displayNames[key],
            steps: stepsByKey[key]!,
          ),
        )
        .toList();
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

  /// Collects EVERY Recipe node found across ALL `<script type="ld+json">`
  /// blocks on the page — not just the first one. Some sites emit more than
  /// one JSON-LD Recipe block (e.g. an auto-generated partial one plus a
  /// manually authored complete one), so scanning only the first can silently
  /// drop fields that only exist in a later block.
  List<Map<String, dynamic>> _findAllRecipeJson(dynamic jsonLdBlocks) {
    final nodes = <Map<String, dynamic>>[];
    if (jsonLdBlocks is! List) return nodes;

    for (final block in jsonLdBlocks) {
      try {
        final decoded = jsonDecode(block.toString());
        _collectRecipeNodes(decoded, nodes);
      } catch (_) {
        continue;
      }
    }
    return nodes;
  }

  void _collectRecipeNodes(dynamic node, List<Map<String, dynamic>> out) {
    if (node is List) {
      for (final item in node) {
        _collectRecipeNodes(item, out);
      }
      return;
    }
    if (node is! Map) return;

    final map = Map<String, dynamic>.from(node);
    final type = map['@type'];
    final isRecipe =
        type == 'Recipe' ||
        (type is List && type.map((e) => e.toString()).contains('Recipe'));

    if (isRecipe) out.add(map);

    if (map['@graph'] != null) _collectRecipeNodes(map['@graph'], out);
    if (map['mainEntity'] != null) _collectRecipeNodes(map['mainEntity'], out);
  }

  /// First non-null scalar field found, checked across ALL Recipe nodes in
  /// document order — so a field missing from one block falls through to the
  /// next block instead of returning null outright.
  String? _findRecipeJsonField(dynamic jsonLdBlocks, String field) {
    for (final node in _findAllRecipeJson(jsonLdBlocks)) {
      final value = _text(node[field]);
      if (value != null) return value;
    }
    return null;
  }

  /// Same as [_findRecipeJsonField] but returns the raw (untyped) value —
  /// for fields that may be a String, List, or nested Map (image, duration).
  dynamic _findRecipeJsonRaw(dynamic jsonLdBlocks, String field) {
    for (final node in _findAllRecipeJson(jsonLdBlocks)) {
      final value = node[field];
      if (value != null) return value;
    }
    return null;
  }

  /// For LIST-valued fields (recipeIngredient / recipeInstructions):
  /// concatenates the field across every Recipe node instead of stopping at
  /// the first, so a partial block never shadows a fuller one elsewhere on
  /// the page. Callers still get duplicates removed downstream via
  /// [ScrapedRecipeData]'s global dedup.
  dynamic _findRecipeJsonRawMerged(dynamic jsonLdBlocks, String field) {
    final merged = [];
    for (final node in _findAllRecipeJson(jsonLdBlocks)) {
      final value = node[field];
      if (value == null) continue;
      if (value is List) {
        merged.addAll(value);
      } else {
        merged.add(value);
      }
    }
    return merged.isEmpty ? null : merged;
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

  static const String _landingPageHtml =
      '''
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
          encodeURIComponent(query + ' recipe$_excludeSites') + '&udm=14';
      }
      window.location.href = target;
    });
  </script>
</body>
</html>
''';
}
