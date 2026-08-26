// import 'dart:developer';
// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show listEquals;
// import 'package:recipe_ai/Model/recipe_section_model.dart';

// import 'package:recipe_ai/screens/recipe/export_pdf_sheet.dart';
// import 'package:recipe_ai/widgets/app_logo.dart';
// import 'package:recipe_ai/widgets/app_network_image.dart';
// import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
// import 'dart:math' as math;
// import 'dart:ui' as ui;
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:recipe_ai/Controllers/cookbook_controller.dart';
// import 'package:recipe_ai/Controllers/home_controller.dart';
// import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
// import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
// import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
// import 'package:recipe_ai/View/Home/cookbook_recipes_screen.dart';
// import 'package:recipe_ai/View/Home/home_screen.dart';
// import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
// import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
// import 'package:recipe_ai/Helper/unit_converter.dart';
// import 'package:recipe_ai/Helper/instruction_scaler.dart';
// import 'package:recipe_ai/Helper/premium_gate.dart';
// import 'package:recipe_ai/Controllers/settings_controller.dart';
// import 'package:recipe_ai/widgets/custom_snackbar.dart';
// import 'package:recipe_ai/Service/subscription_service.dart';
// import 'package:recipe_ai/Service/recipe_localizer.dart';
// import 'package:recipe_ai/widgets/premium_lock_overlay.dart';
// import 'package:recipe_ai/Controllers/nutrition_controller.dart';
// import 'package:recipe_ai/widgets/nutrition_preview_card.dart';
// import 'package:recipe_ai/widgets/nutrition_locked_card.dart';
// import 'package:recipe_ai/View/Home/nutrition/nutrition_screen.dart';
// import 'package:recipe_ai/Controllers/ai_assistant_controller.dart';
// import 'package:recipe_ai/View/Home/ai_assistant_screen.dart';
// import 'package:recipe_ai/widgets/cannot_publish_dialog.dart';
// import 'package:recipe_ai/widgets/comments_sheet.dart';
// import 'package:recipe_ai/Service/auth_service.dart';
// import 'package:recipe_ai/Helper/recipe_publish_policy.dart';
// import 'package:recipe_ai/theme/app_dimensions.dart';
// import 'package:recipe_ai/utils/validation_helper.dart';
// import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:path_provider/path_provider.dart';

// import 'package:http/http.dart' as http;
// import 'dart:typed_data';

// // ─────────────────────────────────────────────────────────────────────────────
// // Design constants (matched to the HTML "Recipe detail" design)
// // ─────────────────────────────────────────────────────────────────────────────
// class _C {
//   static const bg = Color(0xFFFBF4EA);
//   static const card = Colors.white;
//   static const border = Color(0xFFEFE6D6);
//   static const borderInner = Color(0xFFE7DECE);
//   static const rowLine = Color(0xFFF4ECDF);
//   static const surfaceLight = Color(0xFFFBF7F0);
//   static const primary = Color(0xFFF2623E);
//   static const primaryDark = Color(0xFFE0481F);
//   static const textDark = Color(0xFF2A211B);
//   static const textMedium = Color(0xFF8A7E70);
//   static const textHint = Color(0xFFA89F90);
//   static const textBody = Color(0xFF5A5147);
//   static const textBodyDark = Color(0xFF3A352D);
//   static const green = Color(0xFF1F7A5E);
//   static const greenBg = Color(0xFFEAF6F0);
//   static const greenBorder = Color(0xFFCFE9DD);
//   static const purple = Color(0xFF8B5CF6);
//   static const purpleBg = Color(0xFFF4EEFD);
//   static const purpleBorder = Color(0xFFE0D2F7);
//   static const goldBg = Color(0xFFFBF1E4);
//   static const noteBg = Color(0xFFFCE3DB);

//   static const double outerPad = 22.0;
//   static const double cardPad = 16.0;
//   static const double cardRadius = 20.0;
//   static const double cardSpacing = 16.0;
// }

// TextStyle _font(double size, FontWeight w, Color c, {double? h, double? ls}) =>
//     GoogleFonts.plusJakartaSans(
//       fontSize: size,
//       fontWeight: w,
//       color: c,
//       height: h,
//       letterSpacing: ls,
//     );

// BoxDecoration _cardDeco() => BoxDecoration(
//   color: _C.card,
//   borderRadius: BorderRadius.circular(_C.cardRadius),
//   border: Border.all(color: _C.border),
//   boxShadow: [
//     BoxShadow(
//       color: const Color(0xFF2A211B).withValues(alpha: 0.16),
//       blurRadius: 26,
//       offset: const Offset(0, 12),
//       spreadRadius: -22,
//     ),
//   ],
// );

// // ═══════════════════════════════════════════════════════════════════════════════
// // RECIPE DETAIL SCREEN
// // ═══════════════════════════════════════════════════════════════════════════════

// class RecipeDetailScreen extends StatefulWidget {
//   final RecipeModel recipe;

//   /// When opened from a comment notification, the id of the comment to reveal —
//   /// the comments sheet opens automatically and highlights it.
//   final String? focusCommentId;
//   const RecipeDetailScreen({
//     super.key,
//     required this.recipe,
//     this.focusCommentId,
//   });

//   @override
//   State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
// }

// class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
//   late int _initialServings;
//   late int _servings;
//   String _note = '';
//   bool _menuOpen = false;
//   late bool _isPublic;
//   final Set<int> _checkedIngredients = {};
//   final SettingsController _settings = Get.find<SettingsController>();
//   final GroceryStore _grocery = Get.find<GroceryStore>();
//   final HomeController _home = Get.find<HomeController>();

//   File? _cachedShareFile;
//   Uint8List? _cachedImageBytes;

//   // Share preparation already running હોય તો આ Future reuse થશે.
//   Future<void>? _sharePreparationFuture;

//   bool _isPreparingShare = false;

//   // Live copy of the recipe. Starts from the one passed in, then refreshes in
//   // real time whenever the owner saves edits: the editor writes to Firestore,
//   // HomeController.recipes re-emits, and the worker below pulls the fresh copy.
//   late RecipeModel _recipe = widget.recipe;
//   Worker? _recipeWorker;
//   // True once we've begun closing this screen because its recipe was deleted —
//   // guards the pop-to-Home from firing more than once.
//   bool _closing = false;
//   // Whether this recipe has been present in the owner's list. Only a recipe
//   // that was seen and then vanished counts as "deleted" — a detail opened from
//   // a source not backed by the recipes stream must never auto-close spuriously.
//   bool _seenInList = false;

//   // ── Language display (owner sees original-language text, everyone else
//   // sees the English canonical copy translated into their own selected app
//   // language) — resolved once from the raw Firestore doc and refreshed
//   // whenever the underlying recipe changes. See RecipeLocalizer.
//   LocalizedRecipe? _localized;
//   bool _localizing = false;

//   RecipeModel get recipe => _recipe;
//   final ScreenshotController _shareController = ScreenshotController();

//   // ── Display getters — use these instead of `recipe.*` anywhere text is
//   // actually shown to the user, so the language rule (owner = original,
//   // everyone else = translated) is applied consistently. Falls back to the
//   // plain `recipe` fields while the localized copy is still loading.
//   String get _displayTitle => _localized?.title ?? recipe.title;
//   String? get _displayPrepTime => _localized?.prepTime ?? recipe.prepTime;
//   String? get _displayCookTime => _localized?.cookTime ?? recipe.cookTime;
//   String? get _displayTotalTime => _localized?.totalTime ?? recipe.totalTime;
//   String? get _displayServings => _localized?.servings ?? recipe.servings;
//   List<String> get _displayIngredients =>
//       _localized?.ingredients ?? recipe.ingredients;
//   List<String> get _displayInstructions =>
//       _localized?.instructions ?? recipe.instructions;
//   List<IngredientSection> get _displayIngredientSections =>
//       _localized?.ingredientSections ?? recipe.ingredientSections;
//   List<InstructionSection> get _displayInstructionSections =>
//       _localized?.instructionSections ?? recipe.instructionSections;

//   @override
//   void initState() {
//     super.initState();
//     _isPublic = recipe.isPublic;
//     // Migration: back-fill `visibility` on legacy docs when opened.
//     if (!recipe.visibilityWasStored) {
//       _home.migrateVisibility(recipe.id, recipe.visibility);
//     }
//     _initialServings = _parseServings(recipe);
//     _servings = _initialServings;
//     _note = _recipe.note ?? '';
//     _seenInList = _home.recipes.any((r) => r.id == _recipe.id);

//     // Resolve which language to show this recipe in (owner → original,
//     // everyone else → English translated into their own selected language).
//     _loadLocalizedText();

//     // Keep this screen in sync with the recipe stream:
//     //  • edits → pull the fresh copy in (live, no manual refresh),
//     //  • deletion (here or on another device) → close back to Home so a detail
//     //    of a gone recipe is never shown and Back can't return to it.
//     _recipeWorker = ever<List<RecipeModel>>(_home.recipes, (list) {
//       final idx = list.indexWhere((r) => r.id == _recipe.id);
//       if (idx == -1) {
//         if (_seenInList) _handleRecipeDeleted();
//         return;
//       }
//       _seenInList = true;
//       final r = list[idx];
//       if (!_recipeChanged(r) || !mounted) return;
//       final servingsChanged = r.servings != _recipe.servings;
//       setState(() {
//         _recipe = r;
//         _isPublic = r.isPublic;
//         if (servingsChanged) {
//           _initialServings = _parseServings(r);
//           _servings = _initialServings;
//         }
//       });
//       // The recipe text itself may have changed (owner just edited it) —
//       // re-resolve the localized copy so it doesn't go stale.
//       _loadLocalizedText();
//     });

//     // Opened from a comment notification → reveal the comments (owner is the
//     // current user, so ownerId == our uid) and highlight the tapped comment.
//     final focusId = widget.focusCommentId;
//     if (focusId != null && focusId.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final uid = AuthService.currentUser?.uid;
//         if (!mounted || uid == null) return;
//         CommentsSheet.show(
//           context,
//           ownerId: uid,
//           recipeId: _recipe.id,
//           highlightCommentId: focusId,
//         );
//       });
//     }
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startSharePreparation();
//     });
//     _prepareShareFile();
//   }

//   void _startSharePreparation() {
//     if (_sharePreparationFuture != null) return;
//     _sharePreparationFuture = _prepareShareFile();
//     _sharePreparationFuture!.whenComplete(() {
//       _sharePreparationFuture = null;
//     });
//   }

//   /// Fetches the raw Firestore document (which carries the `original` /
//   /// `originalLanguageCode` snapshot alongside the English canonical fields)
//   /// and resolves what to actually show via [RecipeLocalizer]. Safe to call
//   /// repeatedly — re-entrant calls are skipped while one is already in
//   /// flight, and the result only ever refines what's shown (never blocks
//   /// the screen — everything already renders from `recipe.*` in the
//   /// meantime via the `_display*` getters' fallback).
//   Future<void> _loadLocalizedText() async {
//     if (_localizing) return;
//     _localizing = true;
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('recipes')
//           .doc(_recipe.id)
//           .get();
//       final data = doc.data();
//       if (data == null) return;

//       final localized = await RecipeLocalizer.resolve(
//         data,
//         currentUid: AuthService.currentUser?.uid,
//       );
//       if (!mounted) return;
//       setState(() => _localized = localized);
//     } catch (e) {
//       log('Localize recipe text failed: $e');
//     } finally {
//       _localizing = false;
//     }
//   }

//   Future<void> _prepareShareFile({bool force = false}) async {
//     // Already preparing હોય તો એ જ Future complete થવા દો.
//     if (!force && _sharePreparationFuture != null) {
//       await _sharePreparationFuture;
//       return;
//     }

//     if (!force && _cachedShareFile != null) {
//       if (await _cachedShareFile!.exists()) {
//         return;
//       }
//     }

//     final future = _doPrepareShareFile(force: force);

//     _sharePreparationFuture = future;

//     try {
//       await future;
//     } finally {
//       if (identical(_sharePreparationFuture, future)) {
//         _sharePreparationFuture = null;
//       }
//     }
//   }

//   Future<void> _doPrepareShareFile({bool force = false}) async {
//     if (_isPreparingShare) return;

//     _isPreparingShare = true;

//     try {
//       final directory = await getApplicationDocumentsDirectory();

//       final file = File('${directory.path}/recipe_share_${recipe.id}.png');

//       // -----------------------------------------
//       // 1. Check local cached share image
//       // -----------------------------------------
//       if (!force && await file.exists()) {
//         final length = await file.length();

//         if (length > 0) {
//           _cachedShareFile = file;

//           log('✅ Share image loaded from local cache');
//           log('📁 ${file.path}');

//           return;
//         }
//       }

//       // -----------------------------------------
//       // 2. Reset image cache
//       // -----------------------------------------
//       _cachedShareFile = null;
//       _cachedImageBytes = null;

//       // -----------------------------------------
//       // 3. Download recipe image
//       // -----------------------------------------
//       final imgUrl = recipe.imageUrl?.trim();

//       log('🖼️ Image URL: $imgUrl');

//       if (imgUrl != null && imgUrl.isNotEmpty) {
//         try {
//           final response = await http
//               .get(Uri.parse(imgUrl))
//               .timeout(const Duration(seconds: 8));

//           log('Image status: ${response.statusCode}');
//           log('Image bytes: ${response.bodyBytes.length}');

//           if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
//             _cachedImageBytes = response.bodyBytes;
//           }
//         } catch (e) {
//           log('⚠️ Image download failed: $e');
//         }
//       }

//       // -----------------------------------------
//       // 4. Generate share card
//       // -----------------------------------------
//       log('🎨 Generating share card...');

//       final cardBytes = await _shareController.captureFromWidget(
//         _buildShareRecipeCard(_cachedImageBytes),
//         delay: const Duration(milliseconds: 150),
//         pixelRatio: 2.0,
//         targetSize: const Size(1080, 1700),
//       );

//       if (cardBytes.isEmpty) {
//         throw Exception('Share card generated empty');
//       }

//       // -----------------------------------------
//       // 5. Save permanently in app local storage
//       // -----------------------------------------
//       await file.writeAsBytes(cardBytes, flush: true);

//       _cachedShareFile = file;

//       log('✅ Share card ready');
//       log('📁 Saved: ${file.path}');
//     } catch (e, stackTrace) {
//       log('❌ Prepare share failed: $e', stackTrace: stackTrace);
//     } finally {
//       _isPreparingShare = false;
//     }
//   }

//   /// The recipe backing this screen is gone from the stream (deleted). Close
//   /// every recipe route back to Home exactly once — Back can't return to the
//   /// stale detail, and no "recipe not found" state is ever rendered.
//   void _handleRecipeDeleted() {
//     if (_closing || !mounted) return;
//     _closing = true;
//     // Navigate after the current frame — the worker fires during a stream
//     // update, when synchronous navigation would be unsafe.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Get.until((route) => route.isFirst);
//     });
//   }

//   @override
//   void dispose() {
//     _recipeWorker?.dispose();
//     super.dispose();
//   }

//   int _parseServings(RecipeModel r) {
//     int parsed = 2;
//     if (r.servings != null) {
//       final m = RegExp(r'\d+').firstMatch(r.servings!);
//       if (m != null) parsed = int.tryParse(m.group(0)!) ?? 2;
//     }
//     return parsed <= 0 ? 2 : parsed;
//   }

//   /// Whether [r] differs from the current recipe in any displayed field — used
//   /// to skip needless rebuilds (the stream re-emits new instances for every
//   /// recipe on any change, most of which are identical here).
//   bool _recipeChanged(RecipeModel r) =>
//       r.title != _recipe.title ||
//       r.description != _recipe.description ||
//       r.imageUrl != _recipe.imageUrl ||
//       r.servings != _recipe.servings ||
//       r.prepTime != _recipe.prepTime ||
//       r.cookTime != _recipe.cookTime ||
//       r.totalTime != _recipe.totalTime ||
//       r.category != _recipe.category ||
//       r.isPublic != _recipe.isPublic ||
//       !listEquals(r.ingredients, _recipe.ingredients) ||
//       !listEquals(r.instructions, _recipe.instructions);

//   // Ask for confirmation, then flip public/private (owner only).
//   void _toggleVisibility() {
//     final makePublic = !_isPublic;
//     // A recipe saved from Discover can never be published: show the block
//     // popup, leave the toggle OFF, and change nothing.
//     if (makePublic && !recipe.canBePublished) {
//       showCannotPublishDialog();
//       return;
//     }
//     showDialog(
//       context: context,
//       builder: (ctx) => _VisibilityConfirmDialog(
//         makePublic: makePublic,
//         onConfirm: () {
//           Navigator.pop(ctx);
//           _applyVisibility(makePublic);
//         },
//       ),
//     );
//   }

//   void _applyVisibility(bool makePublic) {
//     setState(() => _isPublic = makePublic);
//     Get.find<HomeController>().updateRecipeVisibility(recipe.id, makePublic);
//     CustomSnackbar.show(
//       title: makePublic
//           ? 'recipe_is_now_public'.tr
//           : 'recipe_is_now_private'.tr,
//       type: SnackbarType.success,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final topPad = MediaQuery.of(context).padding.top;
//     const heroH = 300.0;

//     return Scaffold(
//       backgroundColor: _C.bg,
//       body: Stack(
//         children: [
//           // ── Scrollable content ──────────────────────────────────────
//           SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHero(heroH),
//                 Transform.translate(
//                   offset: const Offset(0, -10),
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(
//                       _C.outerPad - 5,
//                       6,
//                       _C.outerPad - 5,
//                       34,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Title
//                         Text(
//                           _displayTitle,
//                           style: _font(
//                             26,
//                             FontWeight.w800,
//                             _C.textDark,
//                             h: 1.12,
//                             ls: -0.5,
//                           ),
//                         ),

//                         // Source
//                         if (recipe.sourceUrl.isNotEmpty) ...[
//                           const SizedBox(height: 8),
//                           _buildSourceRow(),
//                         ],

//                         // Visibility pill
//                         const SizedBox(height: 12),
//                         _buildVisibilityPill(),

//                         // Meta row
//                         const SizedBox(height: 13),
//                         _buildMetaRow(),
//                         const SizedBox(height: 20),

//                         // AI swap / scale applied banner (with Undo)
//                         _aiBanner(),

//                         // Quick action tiles
//                         _buildActionTiles(),
//                         const SizedBox(height: 18),

//                         // Cookbooks card
//                         _buildCookbooksCard(),
//                         const SizedBox(height: _C.cardSpacing),

//                         // Add a note card
//                         _buildNoteCard(),
//                         const SizedBox(height: _C.cardSpacing),

//                         // Ingredients card
//                         _buildIngredientsCard(),
//                         const SizedBox(height: _C.cardSpacing),

//                         // Instructions card
//                         _buildInstructionsCard(),
//                         const SizedBox(height: _C.cardSpacing),

//                         // Cook step-by-step
//                         _buildCookButton(),
//                         const SizedBox(height: _C.cardSpacing),

//                         // Nutrition (Plus)
//                         _buildNutritionCard(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ── Floating top buttons ────────────────────────────────────
//           Positioned(
//             top: topPad + 8,
//             left: 18,
//             right: 18,
//             child: Row(
//               children: [
//                 _floatingBtn('back', () => Get.back()),
//                 const Spacer(),
//                 _floatingBtn(
//                   'pencil',
//                   () => Get.to(() => RecipeEditorScreen(recipe: recipe)),
//                 ),
//                 const SizedBox(width: 9),
//                 _floatingBtn('dots', _showRecipeMenuPopup, active: _menuOpen),
//               ],
//             ),
//           ),

//           // ── Plus-only "Ask AI" floating button (design 75) ──────────
//           Positioned(
//             right: 18,
//             bottom: 20,
//             child: Obx(() {
//               if (!SubscriptionService.instance.isPlusListenable.value) {
//                 return const SizedBox.shrink();
//               }
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   _askAiHintPill(),
//                   const SizedBox(height: 10),
//                   GestureDetector(
//                     onTap: () =>
//                         Get.to(() => AiAssistantScreen(recipe: recipe)),
//                     behavior: HitTestBehavior.opaque,
//                     child: Container(
//                       height: 54,
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(27),
//                         gradient: const LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(
//                               0xFF8B5CF6,
//                             ).withValues(alpha: 0.6),
//                             blurRadius: 26,
//                             offset: const Offset(0, 12),
//                             spreadRadius: -6,
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const OnboardingLineIcon(
//                             'chat',
//                             size: 19,
//                             color: Colors.white,
//                           ),
//                           const SizedBox(width: 9),
//                           Text(
//                             'ask_ai'.tr,
//                             style: GoogleFonts.plusJakartaSans(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   // AI swap / scale applied banner + Undo (design 79). Reactive on the
//   // assistant's last change for this recipe.
//   Widget _aiBanner() {
//     return Obx(() {
//       final ctrl = AiAssistantController.to;
//       ctrl.swaps.length; // establish reactive dependency on the swap list
//       final recipeSwaps = ctrl.swapsFor(recipe.id);
//       final scaleChange = ctrl.changeFor(recipe.id); // scale-only now

//       // Prefer the scale banner when a scale is active; otherwise the swap
//       // banner (whose Undo reverts every swap at once — mockup 79).
//       final bool isSwap = scaleChange == null && recipeSwaps.isNotEmpty;
//       if (scaleChange == null && recipeSwaps.isEmpty) {
//         return const SizedBox.shrink();
//       }

//       final String summary;
//       if (isSwap) {
//         if (recipeSwaps.length == 1) {
//           final e = recipeSwaps.first;
//           summary = '${e.oldName} → ${_shortName(e.newName)}';
//         } else {
//           summary = '${recipeSwaps.length} ingredients';
//         }
//       } else {
//         summary = scaleChange!.summary;
//       }

//       return Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF4EEFD),
//           border: Border.all(color: const Color(0xFFE0D2F7)),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 34,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 gradient: const LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
//                 ),
//               ),
//               child: Icon(
//                 isSwap ? Icons.swap_horiz_rounded : Icons.straighten_rounded,
//                 size: 18,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(width: 11),
//             Expanded(
//               child: Text.rich(
//                 TextSpan(
//                   style: _font(
//                     12.5,
//                     FontWeight.w600,
//                     const Color(0xFF5A4A78),
//                     h: 1.4,
//                   ),
//                   children: [
//                     TextSpan(text: isSwap ? 'AI swapped ' : 'AI scaled '),
//                     TextSpan(
//                       text: summary,
//                       style: _font(
//                         12.5,
//                         FontWeight.w800,
//                         const Color(0xFF5A4A78),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: () async {
//                 if (isSwap) {
//                   await ctrl.undoAllSwaps(recipe);
//                 } else {
//                   await ctrl.undo();
//                 }
//                 if (!mounted) return;
//                 CustomSnackbar.show(
//                   title: 'Undone',
//                   message: 'The change was reverted.',
//                   type: SnackbarType.info,
//                 );
//               },
//               behavior: HitTestBehavior.opaque,
//               child: Text(
//                 'undo'.tr,
//                 style: _font(12.5, FontWeight.w800, const Color(0xFF7A45E0)),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   /// First part of a replacement name for the banner ("heavy cream + …" →
//   /// "heavy cream").
//   String _shortName(String n) =>
//       n.split(RegExp(r'\s*\+|\s+and\s+')).first.trim();

//   // ═══════════════════════════════════════════════════════════════════════════
//   // HERO
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildHero(double height) {
//     return SizedBox(
//       width: double.infinity,
//       height: height,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
//               ? AppNetworkImage(
//                   recipe.imageUrl!,
//                   fit: BoxFit.cover,
//                   cacheWidth: 900,
//                   placeholder: _imagePlaceholder(),
//                   error: _imagePlaceholder(),
//                 )
//               : _imagePlaceholder(),
//           // Gradient: dark at top, fades to background at the bottom
//           const DecoratedBox(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0x66140F0A),
//                   Color(0x00140F0A),
//                   Color(0x00140F0A),
//                   Color(0xFFFBF4EA),
//                 ],
//                 stops: [0.0, 0.32, 0.7, 1.0],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _imagePlaceholder() => Container(
//     color: const Color(0xFFF0E6D6),
//     child: const Center(
//       child: Icon(Icons.restaurant_rounded, size: 60, color: Color(0xFFC7BCAC)),
//     ),
//   );

//   /// Small hint pill above the Ask AI button (design 75) — also opens the chat.
//   Widget _askAiHintPill() {
//     return Container(
//       margin: const EdgeInsets.only(right: 4),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFEFE6D6)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.07),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Text.rich(
//         TextSpan(
//           children: [
//             TextSpan(
//               text: 'Need a swap or help? ',
//               style: GoogleFonts.plusJakartaSans(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF6B6156),
//               ),
//             ),
//             TextSpan(
//               text: 'Ask AI ',
//               style: GoogleFonts.plusJakartaSans(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w800,
//                 color: const Color(0xFF7A45E0),
//               ),
//             ),
//             const TextSpan(text: '✨', style: TextStyle(fontSize: 12.5)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _floatingBtn(String icon, VoidCallback onTap, {bool active = false}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 42,
//         height: 42,
//         decoration: BoxDecoration(
//           color: active ? _C.primary : Colors.white.withValues(alpha: 0.92),
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: OnboardingLineIcon(
//             icon,
//             size: 20,
//             color: active ? Colors.white : _C.textDark,
//           ),
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // SOURCE ROW
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildSourceRow() {
//     return GestureDetector(
//       onTap: () async {
//         final uri = Uri.tryParse(recipe.sourceUrl);
//         if (uri != null && uri.hasScheme) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         }
//       },
//       behavior: HitTestBehavior.opaque,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const OnboardingLineIcon('globe', size: 15, color: _C.textHint),
//           const SizedBox(width: 6),
//           Flexible(
//             child: Text(
//               _sourceLabel(recipe.sourceUrl),
//               style: _font(13, FontWeight.w600, _C.textMedium),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(width: 2),
//           const OnboardingLineIcon('chevR', size: 16, color: Color(0xFFC7BCAC)),
//         ],
//       ),
//     );
//   }

//   String _sourceLabel(String url) {
//     if (url.contains('instagram')) {
//       return 'from_source'.trParams({'source': 'instagram.com'});
//     }
//     if (url.contains('tiktok')) {
//       return 'from_source'.trParams({'source': 'tiktok.com'});
//     }
//     if (url.contains('facebook')) {
//       return 'from_source'.trParams({'source': 'facebook.com'});
//     }
//     if (url.contains('gemini_image')) return 'from_photo_import'.tr;
//     if (url.contains('recipe_name')) return 'ai_generated_recipe'.tr;

//     return 'from_recipe_ai'.tr;
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // VISIBILITY PILL  (reflects recipe.isPublic — tap opens editor to change)
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildVisibilityPill() {
//     final isPublic = _isPublic;
//     // Recipes saved from Discover can never be published.
//     final discovered = recipe.isDiscoveredCopy;
//     final fg = isPublic ? _C.green : _C.textMedium;
//     final bg = isPublic ? _C.greenBg : _C.surfaceLight;
//     final bd = isPublic ? _C.greenBorder : _C.border;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         GestureDetector(
//           onTap: _toggleVisibility,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: bd),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 OnboardingLineIcon(
//                   isPublic ? 'globe' : 'lock',
//                   size: 14,
//                   color: fg,
//                 ),
//                 const SizedBox(width: 7),
//                 Text(
//                   isPublic ? 'public'.tr : 'private'.tr,
//                   style: _font(12.5, FontWeight.w800, fg),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   discovered ? '· ${'locked'.tr}' : '· ${'tap_to_change'.tr}',
//                   style: _font(11, FontWeight.w600, fg.withValues(alpha: 0.75)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Small info text under the Public toggle for saved-from-Discover
//         // recipes (they can be used privately but never published).
//         if (discovered) ...[
//           const SizedBox(height: 6),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const OnboardingLineIcon('lock', size: 11, color: _C.textHint),
//               const SizedBox(width: 5),
//               Text(
//                 RecipePublishPolicy.savedFromDiscoverHint,
//                 style: _font(10.5, FontWeight.w600, _C.textHint),
//               ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // META ROW
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildMetaRow() {
//     // Pick the first NON-EMPTY time. `??` alone is wrong here: imported recipes
//     // often store totalTime as "" (empty, not null) while cook/prep have values,
//     // and `?? ` only falls through on null — so the time would never show.
//     final time = _firstNonEmpty([
//       _displayTotalTime,
//       _displayCookTime,
//       _displayPrepTime,
//     ]);
//     final children = <Widget>[];
//     if (time != null) {
//       children.add(Expanded(child: _metaItem('clock', time)));
//     }
//     children.add(
//       Expanded(
//         child: _metaItem(
//           'friend',
//           'n_servings'.trParams({'count': '$_servings'}),
//         ),
//       ),
//     );
//     children.add(Expanded(child: _metaItem('spark', _difficultyLabel())));

//     final row = <Widget>[];
//     for (var i = 0; i < children.length; i++) {
//       row.add(children[i]);
//       if (i < children.length - 1) {
//         row.add(
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 9),
//             child: Text(
//               '·',
//               style: _font(14, FontWeight.w700, const Color(0xFFD8CFC0)),
//             ),
//           ),
//         );
//       }
//     }
//     return Row(children: row);
//   }

//   Widget _metaItem(String icon, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         OnboardingLineIcon(icon, size: 16, color: _C.primary),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             label,
//             style: _font(11, FontWeight.w700, _C.textBody),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   /// First value that is non-null AND not blank (empty strings are skipped).
//   String? _firstNonEmpty(List<String?> values) {
//     for (final v in values) {
//       if (v != null && v.trim().isNotEmpty) return v.trim();
//     }
//     return null;
//   }

//   /// Minutes parsed from the recipe's time string(s): handles "20 mins",
//   /// "1h 20m", "1 hr 30 min" and a bare "45".
//   int _totalMinutes() {
//     final t = _firstNonEmpty([
//       _displayTotalTime,
//       _displayCookTime,
//       _displayPrepTime,
//     ]);
//     if (t == null) return 0;
//     final hourMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(t);
//     final minMatch = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(t);
//     var total = 0;
//     if (hourMatch != null) {
//       total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 60;
//     }
//     if (minMatch != null) total += int.tryParse(minMatch.group(1)!) ?? 0;
//     if (total == 0) {
//       final bare = RegExp(r'\d+').firstMatch(t);
//       if (bare != null) total = int.tryParse(bare.group(0)!) ?? 0;
//     }
//     return total;
//   }

//   /// A real Easy / Medium / Hard label derived from the recipe's complexity —
//   /// the import source never provides one, so it's estimated from the number of
//   /// ingredients, number of steps, and total time.
//   String _difficultyLabel() {
//     final ingredients = _displayIngredients.length;
//     final steps = _displayInstructions.length;
//     final mins = _totalMinutes();
//     var score = 0;
//     if (ingredients >= 13) {
//       score += 2;
//     } else if (ingredients >= 8) {
//       score += 1;
//     }
//     if (steps >= 11) {
//       score += 2;
//     } else if (steps >= 6) {
//       score += 1;
//     }
//     if (mins >= 90) {
//       score += 2;
//     } else if (mins >= 45) {
//       score += 1;
//     }
//     if (score >= 4) return 'hard'.tr;
//     if (score >= 2) return 'medium'.tr;
//     return 'easy'.tr;
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ACTION TILES (Cookbook / Meal Plan / Share)
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildActionTiles() {
//     return Row(
//       children: [
//         _actionTile('book', 'cookbook'.tr, _showAddToCookbookSheet),
//         const SizedBox(width: 8),
//         _actionTile('cal', 'meal_plan'.tr, _showMealPlanPicker),
//         const SizedBox(width: 8),
//         _actionTile('share', 'share'.tr, _shareRecipe),
//       ],
//     );
//   }

//   Widget _actionTile(String icon, String label, VoidCallback onTap) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         behavior: HitTestBehavior.opaque,
//         child: Column(
//           children: [
//             Container(
//               width: 52,
//               height: 52,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: _C.card,
//                 borderRadius: BorderRadius.circular(17),
//                 border: Border.all(color: _C.border),
//               ),
//               child: OnboardingLineIcon(icon, size: 22, color: _C.primary),
//             ),
//             const SizedBox(height: 7),
//             Text(label, style: _font(11, FontWeight.w600, _C.textMedium)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // COOKBOOKS CARD
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildCookbooksCard() {
//     final cookbookCtrl = Get.find<CookbookController>();

//     return Obx(() {
//       final containing = cookbookCtrl.cookbooks
//           .where((cb) => cb.recipeIds.contains(recipe.id))
//           .toList();

//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(_C.cardPad),
//         decoration: _cardDeco(),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'cookbooks'.tr,
//               style: _font(18, FontWeight.w800, _C.textDark),
//             ),
//             const SizedBox(height: 12),
//             if (containing.isNotEmpty)
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: containing.map((cb) {
//                   return GestureDetector(
//                     onTap: () =>
//                         Get.to(() => CookbookRecipesScreen(cookbook: cb)),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 13,
//                         vertical: 7,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF2EEE6),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const OnboardingLineIcon(
//                             'book',
//                             size: 15,
//                             color: _C.primary,
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             cb.name,
//                             style: _font(13, FontWeight.w700, _C.textBody),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               )
//             else
//               GestureDetector(
//                 onTap: _showAddToCookbookSheet,
//                 behavior: HitTestBehavior.opaque,
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const OnboardingLineIcon(
//                       'plus',
//                       size: 16,
//                       color: _C.primary,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       'add_to_cookbook'.tr,
//                       style: _font(13, FontWeight.w700, _C.primary),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       );
//     });
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ADD A NOTE CARD
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildNoteCard() {
//     final hasNote = _note.isNotEmpty;
//     return GestureDetector(
//       onTap: _showAddNoteSheet,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
//         decoration: _cardDeco(),
//         child: Row(
//           children: [
//             Container(
//               width: 38,
//               height: 38,
//               decoration: BoxDecoration(
//                 color: _C.noteBg,
//                 borderRadius: BorderRadius.circular(11),
//               ),
//               alignment: Alignment.center,
//               child: const OnboardingLineIcon(
//                 'pencil',
//                 size: 18,
//                 color: _C.primary,
//               ),
//             ),
//             const SizedBox(width: 13),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     hasNote ? 'your_note'.tr : 'add_a_note'.tr,
//                     style: _font(14, FontWeight.w700, _C.textDark),
//                   ),
//                   const SizedBox(height: 1),
//                   Text(
//                     hasNote ? _note : 'note_placeholder'.tr,
//                     style: _font(
//                       12.5,
//                       FontWeight.w400,
//                       const Color(0xFF9A938A),
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             const OnboardingLineIcon(
//               'chevR',
//               size: 18,
//               color: Color(0xFFC7BCAC),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // INGREDIENTS CARD
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildIngredientsCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(_C.cardPad),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 'ingredients'.tr,
//                 style: _font(18, FontWeight.w800, _C.textDark),
//               ),
//               const Spacer(),
//               _buildStepper(),
//             ],
//           ),
//           const SizedBox(height: 6),
//           // Text(
//           //   'Tap to check off · amounts scale with servings',
//           //   style: _font(12, FontWeight.w500, const Color(0xFF9A938A)),
//           // ),
//           const SizedBox(height: 12),
//           // Units switcher + ingredient list rebuild reactively when the user
//           // toggles Metric/US (globally via SettingsController), so every
//           // quantity + unit recalculates instantly.
//           Obx(() {
//             final system = _settings.unitSystem;
//             // Depend on the swap list too, so applying/undoing a swap redraws
//             // the inline "SWAPPED" tag on the affected row.
//             AiAssistantController.to.swaps.length;
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildUnitsBanner(),
//                 const SizedBox(height: 4),
//                 ..._buildIngredientsList(system),
//               ],
//             );
//           }),
//           const SizedBox(height: 14),
//           GestureDetector(
//             onTap: _showGrocerySelectionSheet,
//             child: Container(
//               height: 46,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF3EF),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: _C.primary, width: 1.5),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const OnboardingLineIcon('cart', size: 18, color: _C.primary),
//                   const SizedBox(width: 9),
//                   Text(
//                     'add_to_groceries'.tr,
//                     style: _font(14, FontWeight.w700, _C.primary),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Plus-only unit switcher (visual — matches the HTML locked control)
//   Widget _buildUnitsBanner() {
//     // Metric/Imperial is a Plus feature (PremiumGate → SubscriptionService).
//     // Free users see the blurred, locked banner; tapping opens the upgrade flow.
//     if (!PremiumGate.unitConversionUnlocked) {
//       return GestureDetector(
//         onTap: () => showUpgradeDialog(context, feature: 'unit_converter'.tr),
//         behavior: HitTestBehavior.opaque,
//         child: _buildLockedUnitsBanner(),
//       );
//     }

//     final isUS = _settings.units.value == 'US';
//     return Container(
//       padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
//       decoration: BoxDecoration(
//         color: _C.purpleBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _C.purpleBorder),
//       ),
//       child: Row(
//         children: [
//           const OnboardingLineIcon('ruler', size: 16, color: _C.purple),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Text(
//               'units'.tr,
//               style: _font(12.5, FontWeight.w700, const Color(0xFF5B3E8C)),
//             ),
//           ),
//           Container(
//             width: 116,
//             height: 32,
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(9),
//             ),
//             child: Stack(
//               children: [
//                 // Sliding purple background
//                 AnimatedAlign(
//                   duration: const Duration(milliseconds: 500),
//                   curve: Curves.easeOutCubic,
//                   alignment: isUS
//                       ? Alignment.centerLeft
//                       : Alignment.centerRight,
//                   child: Container(
//                     width: isUS ? 36 : 75,
//                     height: 28,
//                     decoration: BoxDecoration(
//                       color: _C.purple,
//                       borderRadius: BorderRadius.circular(7),
//                     ),
//                   ),
//                 ),

//                 // Labels
//                 Row(
//                   children: [
//                     Expanded(child: _unitChip('US', isUS)),

//                     Expanded(flex: 2, child: _unitChip('Metric', !isUS)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _unitChip(String label, bool selected) {
//     return GestureDetector(
//       onTap: () => _settings.setUnits(label),
//       behavior: HitTestBehavior.opaque,
//       child: SizedBox(
//         height: 28,
//         child: Center(
//           child: AnimatedDefaultTextStyle(
//             duration: const Duration(milliseconds: 180),
//             style: _font(
//               11,
//               selected ? FontWeight.w800 : FontWeight.w700,
//               selected ? Colors.white : const Color(0xFF9A938A),
//             ),
//             child: Text(label),
//           ),
//         ),
//       ),
//     );
//   }

//   // The original locked (Plus paywall) banner — shown when the premium flag is
//   // off. Preserved so re-gating is a one-line flag change.
//   Widget _buildLockedUnitsBanner() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
//       decoration: BoxDecoration(
//         color: _C.purpleBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _C.purpleBorder),
//       ),
//       child: Row(
//         children: [
//           const OnboardingLineIcon('ruler', size: 16, color: _C.purple),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Text(
//               'units'.tr,
//               style: _font(12.5, FontWeight.w700, const Color(0xFF5B3E8C)),
//             ),
//           ),
//           ImageFiltered(
//             imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
//             child: Opacity(
//               opacity: 0.7,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 11,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _C.purple,
//                         borderRadius: BorderRadius.circular(7),
//                       ),
//                       child: Text(
//                         'US',
//                         style: _font(11, FontWeight.w800, Colors.white),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 11),
//                       child: Text(
//                         'Metric',
//                         style: _font(
//                           11,
//                           FontWeight.w700,
//                           const Color(0xFF9A938A),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           _plusBadge(),
//         ],
//       ),
//     );
//   }

//   Widget _plusBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: _C.purple,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const OnboardingLineIcon('crown', size: 10, color: Colors.white),
//           const SizedBox(width: 3),
//           Text('PLUS', style: _font(9, FontWeight.w800, Colors.white)),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildIngredientsList(UnitSystem system) {
//     final multiplier = _servings / _initialServings;
//     final ingredientSections = _displayIngredientSections;
//     final ingredients = _displayIngredients;
//     final hasSections = ingredientSections.any((s) => s.items.isNotEmpty);

//     final widgets = <Widget>[];
//     if (hasSections) {
//       int globalIdx = 0;
//       for (final section in ingredientSections) {
//         if (section.items.isEmpty) continue;
//         if (section.name != null && section.name!.isNotEmpty) {
//           widgets.add(_sectionHeader(section.name!));
//         }
//         for (var i = 0; i < section.items.length; i++) {
//           final scaled = UnitConverter.scaleAndConvert(
//             section.items[i],
//             multiplier,
//             system,
//           );
//           widgets.add(_ingredientRow(scaled, globalIdx, section.items[i]));
//           globalIdx++;
//         }
//       }
//       return widgets;
//     }

//     for (var i = 0; i < ingredients.length; i++) {
//       final scaled = UnitConverter.scaleAndConvert(
//         ingredients[i],
//         multiplier,
//         system,
//       );
//       widgets.add(_ingredientRow(scaled, i, ingredients[i]));
//     }
//     return widgets;
//   }

//   Widget _buildStepper() {
//     return Container(
//       decoration: BoxDecoration(
//         color: _C.surfaceLight,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _C.borderInner),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _stepBtn(
//             'minus',
//             _servings > 1,
//             () => setState(() => _servings--),
//             _C.textDark,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 1),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.baseline,
//               textBaseline: TextBaseline.alphabetic,
//               children: [
//                 Text(
//                   '$_servings',
//                   style: _font(14, FontWeight.w800, _C.textDark),
//                 ),
//                 const SizedBox(width: 3),
//                 Text(
//                   'serv'.tr,
//                   style: _font(10, FontWeight.w600, const Color(0xFF9A938A)),
//                 ),
//               ],
//             ),
//           ),
//           _stepBtn('plus', true, () => setState(() => _servings++), _C.primary),
//         ],
//       ),
//     );
//   }

//   Widget _stepBtn(String icon, bool enabled, VoidCallback onTap, Color color) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: enabled ? onTap : null,
//       child: SizedBox(
//         width: 40,
//         height: 36,
//         child: Center(
//           child: OnboardingLineIcon(
//             icon,
//             size: 16,
//             color: enabled ? color : _C.textHint,
//           ),
//         ),
//       ),
//     );
//   }

//   /// Emoji for the ingredient at flat [index], matched on its ENGLISH original.
//   /// [emojiForIngredient] is an English-keyword dictionary, so a translated name
//   /// misses and falls back to a generic category emoji. Translation preserves
//   /// ingredient order/structure, so we look the English line up by index and
//   /// match on that. Falls back to [displayName] when no English original exists
//   /// (English mode, or a recipe not loaded via HomeController).
//   String _ingredientEmoji(int index, String displayName) {
//     final en = _home.englishRecipe(recipe.id);
//     if (en != null) {
//       final hasSections = en.ingredientSections.any((s) => s.items.isNotEmpty);
//       final flat = hasSections
//           ? [for (final s in en.ingredientSections) ...s.items]
//           : en.ingredients;
//       if (index >= 0 && index < flat.length) {
//         return _grocery.emojiForIngredient(flat[index]);
//       }
//     }
//     return _grocery.emojiForIngredient(displayName);
//   }

//   Widget _ingredientRow(String text, int index, [String? rawLine]) {
//     // Inline "SWAPPED" tag + per-ingredient Undo when this line came from an AI
//     // swap (mockup 79). Falls back to the normal row otherwise.
//     final swap = rawLine == null
//         ? null
//         : AiAssistantController.to.activeSwapForLine(recipe.id, rawLine);
//     if (swap != null) return _swappedIngredientRow(text, swap);

//     final checked = _checkedIngredients.contains(index);
//     final parts = _parseIngredient(text);

//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 9),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: _C.rowLine)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Grocery category icon (same emoji the Groceries screen uses),
//           // detected from the ingredient name.
//           Container(
//             width: 28,
//             height: 28,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: _C.goldBg,
//               borderRadius: BorderRadius.circular(9),
//             ),
//             child: Text(
//               _ingredientEmoji(index, parts.$2),
//               style: const TextStyle(fontSize: 15),
//             ),
//           ),
//           const SizedBox(width: 12),
//           // Quantity (bold)
//           if (parts.$1 != null) ...[
//             ConstrainedBox(
//               constraints: const BoxConstraints(minWidth: 54),
//               child: Text(
//                 "${parts.$1!}  ",
//                 style:
//                     _font(
//                       14,
//                       FontWeight.w800,
//                       checked ? _C.textHint : _C.textDark,
//                     ).copyWith(
//                       decoration: checked ? TextDecoration.lineThrough : null,
//                     ),
//               ),
//             ),
//           ],
//           // Name
//           Expanded(
//             child: Text(
//               parts.$2,
//               style:
//                   _font(
//                     14,
//                     FontWeight.w500,
//                     checked ? _C.textHint : _C.textBody,
//                     h: 1.35,
//                   ).copyWith(
//                     decoration: checked ? TextDecoration.lineThrough : null,
//                   ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// A swapped ingredient row: purple-tinted card, swap icon, the new line with
//   /// a "SWAPPED" badge, the struck-through original ("was …"), and inline Undo.

//   Widget _swappedIngredientRow(String text, SwapEntry swap) {
//     final parts = _parseIngredient(text);
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF6F1FE),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE6DAF9)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 28,
//             height: 28,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: const Color(0xFFEDE3FC),
//               borderRadius: BorderRadius.circular(9),
//             ),
//             child: const Icon(
//               Icons.swap_horiz_rounded,
//               size: 17,
//               color: Color(0xFF8B5CF6),
//             ),
//           ),
//           const SizedBox(width: 12),
//           // Title now gets the FULL remaining width, so it wraps cleanly
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text.rich(
//                   TextSpan(
//                     children: [
//                       if (parts.$1 != null)
//                         TextSpan(
//                           text: '${parts.$1!} ',
//                           style: _font(14, FontWeight.w800, _C.textDark),
//                         ),
//                       TextSpan(
//                         text: parts.$2,
//                         style: _font(14, FontWeight.w700, _C.textDark),
//                       ),
//                     ],
//                   ),
//                   style: const TextStyle(height: 1.3),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'was ${swap.oldLine}',
//                   style: _font(
//                     12,
//                     FontWeight.w500,
//                     const Color(0xFF9A8FB0),
//                   ).copyWith(decoration: TextDecoration.lineThrough),
//                 ),
//                 const SizedBox(height: 5),
//                 // Bottom row: badge on left, Undo on right — its own dedicated row
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEDE3FC),
//                         borderRadius: BorderRadius.circular(5),
//                       ),
//                       child: Text(
//                         'swapped'.tr,
//                         style: _font(
//                           9,
//                           FontWeight.w800,
//                           const Color(0xFF7A45E0),
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: () async {
//                         await AiAssistantController.to.undoSwap(recipe, swap);
//                         if (!mounted) return;
//                         CustomSnackbar.show(
//                           title: 'Undone',
//                           message: 'Restored ${swap.oldName}.',
//                           type: SnackbarType.info,
//                         );
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFEDE3FC),
//                           borderRadius: BorderRadius.circular(7),
//                           border: Border.all(color: const Color(0xFFE6DAF9)),
//                         ),
//                         child: Text(
//                           'undo'.tr,
//                           style: _font(
//                             12,
//                             FontWeight.w800,
//                             const Color(0xFF7A45E0),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   (String?, String) _parseIngredient(String text) {
//     final match = RegExp(
//       r'^([\d½¼¾⅓⅔⅛⅜⅝⅞/.\s]+(?:\s*(?:cup|cups|tbsp|tsp|oz|lb|lbs|g|kg|ml|l|piece|pieces|clove|cloves|inch|pinch|bunch|handful|can|cans|packet|packets|slice|slices|medium|large|small)\b)?)\s+(.*)$',
//       caseSensitive: false,
//     ).firstMatch(text);
//     if (match != null) {
//       final qty = match.group(1)!.trim();
//       final rest = match.group(2)!.trim();
//       if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
//     }
//     final simple = RegExp(r'^([\d½¼¾⅓⅔⅛/.\s]+)\s+(.*)$').firstMatch(text);
//     if (simple != null) {
//       final qty = simple.group(1)!.trim();
//       final rest = simple.group(2)!.trim();
//       if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
//     }
//     return (null, text);
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // INSTRUCTIONS CARD
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildInstructionsCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(_C.cardPad),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'instructions'.tr,
//             style: _font(18, FontWeight.w800, _C.textDark),
//           ),
//           const SizedBox(height: 6),
//           // Steps rebuild reactively on unit change; serving changes rebuild the
//           // whole screen via setState. Quantities + timers in the text scale to
//           // match the ingredient list.
//           Obx(() {
//             final multiplier = _servings / _initialServings;
//             final system = _settings.unitSystem;
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: _buildInstructionsList(multiplier, system),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildInstructionsList(double multiplier, UnitSystem system) {
//     final instructionSections = _displayInstructionSections;
//     final instructions = _displayInstructions;
//     final hasSections = instructionSections.any((s) => s.steps.isNotEmpty);

//     final widgets = <Widget>[];
//     if (hasSections) {
//       var stepNum = 1;
//       for (final section in instructionSections) {
//         if (section.steps.isEmpty) continue;
//         if (section.name != null && section.name!.isNotEmpty) {
//           widgets.add(_sectionHeader(section.name!));
//         }
//         for (var i = 0; i < section.steps.length; i++) {
//           widgets.add(
//             _instructionRow(
//               stepNum,
//               InstructionScaler.scale(section.steps[i], multiplier, system),
//             ),
//           );
//           stepNum++;
//         }
//       }
//       return widgets;
//     }

//     for (var i = 0; i < instructions.length; i++) {
//       widgets.add(
//         _instructionRow(
//           i + 1,
//           InstructionScaler.scale(instructions[i], multiplier, system),
//         ),
//       );
//     }
//     return widgets;
//   }

//   Widget _instructionRow(int number, String text) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: _C.rowLine)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 25,
//             height: 25,
//             // padding: EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               color: _C.noteBg,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Center(
//               child: Text(
//                 '$number',
//                 style: _font(10, FontWeight.w800, _C.primary),
//               ),
//             ),
//           ),
//           const SizedBox(width: 13),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 2),
//               child: Text(
//                 text,
//                 style: _font(14, FontWeight.w500, _C.textBodyDark, h: 1.45),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _sectionHeader(String name) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 12, bottom: 8),
//       child: Row(
//         children: [
//           Container(
//             width: 7,
//             height: 7,
//             decoration: BoxDecoration(
//               color: _C.primary,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               name,
//               style: _font(14, FontWeight.w800, _C.textDark),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // COOK BUTTON (inline)
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildCookButton() {
//     return GestureDetector(
//       onTap: () => Get.to(
//         () => CookModeScreen(recipe: recipe),
//         transition: Transition.downToUp,
//       ),
//       child: Container(
//         height: 54,
//         decoration: BoxDecoration(
//           color: _C.primary,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: _C.primary.withValues(alpha: 0.7),
//               blurRadius: 26,
//               offset: const Offset(0, 14),
//               spreadRadius: -10,
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const OnboardingLineIcon('play', color: Colors.white, size: 22),
//             const SizedBox(width: 9),
//             Text(
//               'cook_step_by_step'.tr,
//               style: _font(16, FontWeight.w700, Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // NUTRITION CARD (Plus — visual/locked)
//   // ═══════════════════════════════════════════════════════════════════════════

//   Widget _buildNutritionCard() {
//     // Nutrition is a Plus feature (design 32d). Plus members see the real
//     // preview + can open the full flow; free users see the "NUTRITION · Per 1
//     // serving" heading with a yellow "Subscribe now" banner and the donut/macros
//     // blurred underneath (NutritionLockedCard) — tapping opens the upgrade
//     // dialog. Values are estimated from the recipe ingredients by
//     // NutritionEstimator, using the live serving count (_servings) so changing
//     // the stepper recalculates without reopening (spec step 7). Reacts live to
//     // the plan via Obx, so upgrading swaps in the real card immediately.
//     // Estimate from the ENGLISH original: the food database is English-keyed, so
//     // a translated ingredient line would miss and drop from the breakdown.
//     // Display of the (English) ingredient names is translated separately.
//     final n = NutritionController.to.calculateNutrition(
//       _home.englishRecipe(recipe.id) ?? recipe,
//       servingsOverride: _servings,
//     );
//     if (n.isEmpty) return const SizedBox.shrink();
//     return Obx(() {
//       final isPlus = SubscriptionService.instance.isPlusListenable.value;
//       if (!isPlus) {
//         return NutritionLockedCard(
//           nutrition: n,
//           onTap: () =>
//               showUpgradeDialog(context, feature: 'nutrition_calculator'.tr),
//         );
//       }
//       return NutritionPreviewCard(
//         nutrition: n,
//         servings: n.servings,
//         onViewBreakdown: () {
//           Get.to(
//             () => NutritionScreen(recipeName: _displayTitle, nutrition: n),
//             transition: Transition.fadeIn,
//             duration: const Duration(milliseconds: 320),
//             curve: Curves.easeOutCubic,
//           );
//         },
//       );
//     });
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ACTIONS  (business logic preserved verbatim)
//   // ═══════════════════════════════════════════════════════════════════════════

//   // Future<void> _shareRecipe() async {
//   //   try {
//   //     // If preload is not finished, prepare once.
//   //     if (_cachedShareFile == null) {
//   //       await _prepareShareFile();
//   //     }

//   //     if (_cachedShareFile == null) {
//   //       Get.snackbar('Error', 'Unable to prepare recipe for sharing.');
//   //       return;
//   //     }

//   //     const appLink = 'https://yourapp.page.link/recipe';

//   //     final shareText =
//   //         '''
//   // 🍴 $_displayTitle

//   // View the full recipe, ingredients, instructions and more in the app 👇

//   // $appLink
//   // ''';

//   //     await Share.shareXFiles(
//   //       [XFile(_cachedShareFile!.path)],
//   //       text: shareText,
//   //       subject: _displayTitle,
//   //     );
//   //   } catch (e) {
//   //     log('Share recipe error: $e');
//   //   }
//   // }

//   Future<void> _shareRecipe() async {
//     try {
//       // -----------------------------------------
//       // Wait for preload if still running
//       // -----------------------------------------
//       if (_cachedShareFile == null || !await _cachedShareFile!.exists()) {
//         log('⏳ Waiting for share content...');

//         await _prepareShareFile();
//       }

//       // -----------------------------------------
//       // Final safety check
//       // -----------------------------------------
//       final shareFile = _cachedShareFile;

//       if (shareFile == null || !await shareFile.exists()) {
//         Get.snackbar('Error', 'Unable to prepare recipe for sharing.');
//         return;
//       }

//       const appLink = 'https://yourapp.page.link/recipe';

//       final shareText =
//           '''
// 🍴 $_displayTitle

// View the full recipe, ingredients, instructions and more in the app 👇

// $appLink
// ''';

//       await Share.shareXFiles(
//         [XFile(shareFile.path)],
//         text: shareText,
//         subject: _displayTitle,
//       );
//     } catch (e, stackTrace) {
//       log('❌ Share recipe error: $e', stackTrace: stackTrace);

//       Get.snackbar('Error', 'Unable to share recipe. Please try again.');
//     }
//   }

//   Widget _buildShareRecipeCard([Uint8List? imageBytes]) {
//     final time =
//         _firstNonEmpty([
//           _displayTotalTime,
//           _displayCookTime,
//           _displayPrepTime,
//         ]) ??
//         '';

//     return Material(
//       color: Colors.white,
//       child: SizedBox(
//         width: 1080,
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(40),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(40),
//                   topRight: Radius.circular(40),
//                 ),
//                 child: _buildRecipeImage(imageBytes),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(48),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Row(
//                       children: [
//                         AppLogo(size: 42),
//                         SizedBox(width: 16),
//                         Text(
//                           'Recipe-AI',
//                           style: TextStyle(
//                             fontSize: 34,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 36),
//                     Text(
//                       _displayTitle,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 56,
//                         fontWeight: FontWeight.w800,
//                         height: 1.15,
//                       ),
//                     ),
//                     const SizedBox(height: 36),
//                     Row(
//                       children: [
//                         _shareInfoItem(
//                           icon: Icons.people_outline,
//                           title: 'Servings',
//                           value: _displayServings ?? '-',
//                         ),
//                         const SizedBox(width: 24),
//                         _shareInfoItem(
//                           icon: Icons.access_time,
//                           title: 'Time',
//                           value: time.isEmpty ? '-' : time,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 42),
//                     const Divider(),
//                     const SizedBox(height: 28),
//                     const Text(
//                       'View the full recipe in RecipeNest',
//                       style: TextStyle(
//                         fontSize: 30,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Ingredients, instructions and more inside the app.',
//                       style: TextStyle(fontSize: 26, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 32),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 24,
//                         horizontal: 28,
//                       ),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         color: Colors.black,
//                       ),
//                       child: const Center(
//                         child: Text(
//                           'Download the app to view full recipe',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 28,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecipeImage(Uint8List? imageBytes) {
//     log("Image Bytes in Widget: ${imageBytes?.length}");

//     if (imageBytes == null) {
//       return _shareImagePlaceholder();
//     }

//     return SizedBox(
//       width: 1080,
//       height: 600,
//       child: Image.memory(
//         imageBytes,
//         width: 1080,
//         height: 600,
//         fit: BoxFit.cover,
//         frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
//           if (wasSynchronouslyLoaded || frame != null) {
//             return child;
//           }

//           return _shareImagePlaceholder();
//         },
//       ),
//     );
//   }

//   Widget _shareImagePlaceholder() {
//     return Container(
//       width: 1080,
//       height: 600,
//       color: const Color(0xFFF0E6D6),
//       alignment: Alignment.center,
//       child: const Icon(
//         Icons.restaurant_rounded,
//         size: 100,
//         color: Color(0xFFC7BCAC),
//       ),
//     );
//   }

//   // Overflow-safe info item — value 1 line + ellipsis, Expanded so Row ma
//   // space properly divide thay
//   Widget _shareInfoItem({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Expanded(
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 42),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(fontSize: 24, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showGrocerySelectionSheet() {
//     final system = _settings.unitSystem;
//     final multiplier = _servings / _initialServings;
//     // Display list (owner's language / viewer's translated language) — used
//     // ONLY for rendering the checklist. Adding to the grocery store still
//     // uses `recipe.ingredients` (the canonical English list) below, exactly
//     // as before, so downstream grocery-emoji matching keeps working.
//     final displayIngredients = _displayIngredients;
//     final displaySections = _displayIngredientSections;
//     // Compute the flat count from the display lists (sections or flat) so
//     // selectedIndices length matches the rows the user actually sees.
//     final hasSectionsForCount = displaySections.any((s) => s.items.isNotEmpty);
//     final flatDisplayCount = hasSectionsForCount
//         ? displaySections.fold<int>(0, (sum, s) => sum + s.items.length)
//         : displayIngredients.length;
//     final selectedIndices = List<bool>.generate(flatDisplayCount, (_) => true);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       barrierColor: const Color(0x801E1B18),
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateSheet) {
//             final checkedCount = selectedIndices.where((c) => c).length;
//             final hasSections = displaySections.any((s) => s.items.isNotEmpty);

//             final widgets = <Widget>[];

//             void toggleIndex(int idx) {
//               setStateSheet(() {
//                 selectedIndices[idx] = !selectedIndices[idx];
//               });
//             }

//             Widget selectionRow(String text, int globalIdx) {
//               final isChecked = selectedIndices[globalIdx];
//               final parts = _parseIngredient(text);
//               return GestureDetector(
//                 onTap: () => toggleIndex(globalIdx),
//                 behavior: HitTestBehavior.opaque,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: const BoxDecoration(
//                     border: Border(bottom: BorderSide(color: _C.rowLine)),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 22,
//                         height: 22,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: isChecked ? _C.primary : Colors.transparent,
//                           border: isChecked
//                               ? null
//                               : Border.all(color: _C.borderInner, width: 2),
//                         ),
//                         child: isChecked
//                             ? const Center(
//                                 child: OnboardingLineIcon(
//                                   'check',
//                                   color: Colors.white,
//                                   size: 14,
//                                 ),
//                               )
//                             : null,
//                       ),
//                       const SizedBox(width: 12),
//                       Container(
//                         width: 28,
//                         height: 28,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: _C.goldBg,
//                           borderRadius: BorderRadius.circular(9),
//                         ),
//                         child: Text(
//                           _ingredientEmoji(globalIdx, parts.$2),
//                           style: const TextStyle(fontSize: 15),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       if (parts.$1 != null) ...[
//                         ConstrainedBox(
//                           constraints: const BoxConstraints(minWidth: 54),
//                           child: Text(
//                             "${parts.$1!}  ",
//                             style: _font(
//                               14,
//                               FontWeight.w800,
//                               isChecked ? _C.textDark : _C.textHint,
//                             ),
//                           ),
//                         ),
//                       ],
//                       Expanded(
//                         child: Text(
//                           parts.$2,
//                           style: _font(
//                             14,
//                             FontWeight.w500,
//                             isChecked ? _C.textBody : _C.textHint,
//                             h: 1.35,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }

//             if (hasSections) {
//               int globalIdx = 0;
//               for (final section in displaySections) {
//                 if (section.items.isEmpty) continue;
//                 if (section.name != null && section.name!.isNotEmpty) {
//                   widgets.add(
//                     Padding(
//                       padding: const EdgeInsets.only(top: 14, bottom: 6),
//                       child: Text(
//                         section.name!.toUpperCase(),
//                         style: _font(
//                           11.5,
//                           FontWeight.w800,
//                           _C.primary,
//                           ls: 0.8,
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//                 for (var i = 0; i < section.items.length; i++) {
//                   final scaled = UnitConverter.scaleAndConvert(
//                     section.items[i],
//                     multiplier,
//                     system,
//                   );
//                   widgets.add(selectionRow(scaled, globalIdx));
//                   globalIdx++;
//                 }
//               }
//             } else {
//               for (var i = 0; i < displayIngredients.length; i++) {
//                 final scaled = UnitConverter.scaleAndConvert(
//                   displayIngredients[i],
//                   multiplier,
//                   system,
//                 );
//                 widgets.add(selectionRow(scaled, i));
//               }
//             }

//             final allChecked = selectedIndices.every((c) => c);

//             return Container(
//               height: MediaQuery.of(ctx).size.height * 0.75,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
//               ),
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Center(
//                           child: Container(
//                             width: 42,
//                             height: 5,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFE7E0D2),
//                               borderRadius: BorderRadius.circular(3),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 18),
//                         Row(
//                           children: [
//                             Text(
//                               'add_to_groceries_title'.tr,
//                               style: _font(
//                                 20,
//                                 FontWeight.w800,
//                                 _C.textDark,
//                                 ls: -0.4,
//                               ),
//                             ),
//                             const Spacer(),
//                             GestureDetector(
//                               onTap: () => Navigator.pop(ctx),
//                               child: Container(
//                                 width: 34,
//                                 height: 34,
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFFF4F1EA),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: const OnboardingLineIcon(
//                                   'x',
//                                   size: 17,
//                                   color: _C.textMedium,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'select_items_to_purchase'.tr,
//                               style: _font(
//                                 13.5,
//                                 FontWeight.w600,
//                                 _C.textMedium,
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () {
//                                 setStateSheet(() {
//                                   final target = !allChecked;
//                                   for (
//                                     var i = 0;
//                                     i < selectedIndices.length;
//                                     i++
//                                   ) {
//                                     selectedIndices[i] = target;
//                                   }
//                                 });
//                               },
//                               child: Text(
//                                 allChecked
//                                     ? 'deselect_all'.tr
//                                     : 'select_all'.tr,
//                                 style: _font(13, FontWeight.w700, _C.primary),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(color: _C.rowLine, height: 1, thickness: 1),
//                   Expanded(
//                     child: ListView(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 22,
//                         vertical: 8,
//                       ),
//                       children: widgets,
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.fromLTRB(
//                       22,
//                       12,
//                       22,
//                       MediaQuery.of(ctx).padding.bottom + 16,
//                     ),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       border: Border(top: BorderSide(color: _C.rowLine)),
//                     ),
//                     child: GestureDetector(
//                       onTap: checkedCount == 0
//                           ? null
//                           : () {
//                               Navigator.pop(ctx);
//                               final groceryController =
//                                   Get.find<GroceryStore>();
//                               final toAdd = <String>[];
//                               // Build the flat canonical (English) list in the
//                               // same section/flat order as the display list so
//                               // indices stay 1:1 — grocery items are stored in
//                               // English regardless of which language was shown.
//                               final canonicalFlat = <String>[];
//                               final canonSections = recipe.ingredientSections;
//                               final hasCanonSections = canonSections.any(
//                                 (s) => s.items.isNotEmpty,
//                               );
//                               if (hasCanonSections) {
//                                 for (final s in canonSections) {
//                                   canonicalFlat.addAll(s.items);
//                                 }
//                               } else {
//                                 canonicalFlat.addAll(recipe.ingredients);
//                               }
//                               for (
//                                 var i = 0;
//                                 i < canonicalFlat.length &&
//                                     i < selectedIndices.length;
//                                 i++
//                               ) {
//                                 if (selectedIndices[i]) {
//                                   final scaledIng =
//                                       IngredientScaleHelper.scaleIngredient(
//                                         canonicalFlat[i],
//                                         multiplier,
//                                       );
//                                   toAdd.add(scaledIng);
//                                 }
//                               }

//                               groceryController.addFromRecipe(recipe.id, toAdd);

//                               CustomSnackbar.show(
//                                 title: 'n_ingredients_added'.trParams({
//                                   'count': '$checkedCount',
//                                 }),
//                                 actionText: 'view'.tr,
//                                 onAction: () {
//                                   Get.offUntil(
//                                     MaterialPageRoute(
//                                       builder: (_) =>
//                                           const HomeScreen(initialIndex: 3),
//                                     ),
//                                     (route) => route.isFirst,
//                                   );
//                                 },
//                               );
//                             },
//                       child: Container(
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: checkedCount == 0
//                               ? const Color(0xFFF4F1EA)
//                               : _C.primary,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           checkedCount == 0
//                               ? 'select_items_to_add'.tr
//                               : checkedCount == 1
//                               ? 'add_1_item_to_groceries'.tr
//                               : 'add_n_items_to_groceries'.trParams({
//                                   'count': '$checkedCount',
//                                 }),
//                           style: _font(
//                             15,
//                             FontWeight.w700,
//                             checkedCount == 0 ? _C.textHint : Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // ADD NOTE — bottom sheet (note kept in memory, matching prior behavior)
//   // ═══════════════════════════════════════════════════════════════════════════

//   void _showAddNoteSheet() {
//     final ctrl = TextEditingController(text: _note);
//     final noteFormKey = GlobalKey<FormState>();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       barrierColor: const Color(0x801E1B18),
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(ctx).viewInsets.bottom,
//           ),
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
//             ),
//             padding: EdgeInsets.fromLTRB(
//               22,
//               14,
//               22,
//               MediaQuery.of(ctx).padding.bottom + 24,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 42,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE7E0D2),
//                       borderRadius: BorderRadius.circular(3),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 18),
//                 Row(
//                   children: [
//                     Text(
//                       'add_a_note'.tr,
//                       style: _font(20, FontWeight.w800, _C.textDark, ls: -0.4),
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       onTap: () => Navigator.pop(ctx),
//                       child: Container(
//                         width: 34,
//                         height: 34,
//                         decoration: const BoxDecoration(
//                           color: Color(0xFFF4F1EA),
//                           shape: BoxShape.circle,
//                         ),
//                         alignment: Alignment.center,
//                         child: const OnboardingLineIcon(
//                           'x',
//                           size: 17,
//                           color: _C.textMedium,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   constraints: const BoxConstraints(minHeight: 120),
//                   decoration: BoxDecoration(
//                     color: _C.surfaceLight,
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: _C.primary, width: 1.5),
//                     boxShadow: [
//                       BoxShadow(
//                         color: _C.primary.withValues(alpha: 0.1),
//                         blurRadius: 0,
//                         spreadRadius: 4,
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.all(14),
//                   child: StatefulBuilder(
//                     builder: (c, setSheet) {
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Form(
//                             key: noteFormKey,
//                             autovalidateMode:
//                                 AutovalidateMode.onUserInteraction,
//                             child: TextFormField(
//                               controller: ctrl,
//                               autofocus: true,
//                               maxLines: 4,
//                               maxLength: 300,
//                               keyboardType: TextInputType.multiline,
//                               cursorColor: _C.primary,
//                               validator: (v) => ValidationHelper.notes(
//                                 v,
//                                 max: 500,
//                                 field: 'Note',
//                               ),
//                               style: _font(
//                                 15,
//                                 FontWeight.w400,
//                                 _C.textDark,
//                                 h: 1.5,
//                               ),
//                               onChanged: (_) => setSheet(() {}),
//                               decoration: InputDecoration(
//                                 hintText: 'note_hint_example'.tr,
//                                 hintStyle: _font(
//                                   15,
//                                   FontWeight.w400,
//                                   _C.textHint,
//                                   h: 1.5,
//                                 ),
//                                 isDense: true,
//                                 filled: false,
//                                 border: InputBorder.none,
//                                 enabledBorder: InputBorder.none,
//                                 focusedBorder: InputBorder.none,
//                                 contentPadding: EdgeInsets.zero,
//                                 counterText: '',
//                               ),
//                             ),
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'saved_to_this_recipe'.tr,
//                                 style: _font(
//                                   12,
//                                   FontWeight.w600,
//                                   const Color(0xFF9A938A),
//                                 ),
//                               ),
//                               Text(
//                                 '${ctrl.text.characters.length} / 300',
//                                 style: _font(
//                                   12,
//                                   FontWeight.w600,
//                                   const Color(0xFFB0A899),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 18),
//                 GestureDetector(
//                   onTap: () {
//                     if (!(noteFormKey.currentState?.validate() ?? false)) {
//                       return;
//                     }
//                     final text = ctrl.text.trim();
//                     setState(() => _note = text);
//                     // Persist to Firestore so the note survives restarts.
//                     _home.setNote(_recipe.id, text);
//                     Navigator.pop(ctx);
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: _C.primary,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: _C.primary.withValues(alpha: 0.7),
//                           blurRadius: 26,
//                           offset: const Offset(0, 14),
//                           spreadRadius: -10,
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: Text(
//                         'save_note'.tr,
//                         style: _font(17, FontWeight.w600, Colors.white),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // RECIPE MENU — anchored dropdown popup
//   // ═══════════════════════════════════════════════════════════════════════════

//   void _showRecipeMenuPopup() {
//     final topPad = MediaQuery.of(context).padding.top;
//     final top = topPad + 8 + 42 + 10; // below the floating buttons
//     setState(() => _menuOpen = true);
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: 'menu',
//       barrierColor: const Color(0x661E1B18),
//       transitionDuration: const Duration(milliseconds: 130),
//       pageBuilder: (_, __, ___) => const SizedBox.shrink(),
//       transitionBuilder: (ctx, anim, __, ___) {
//         return Stack(
//           children: [
//             // Pointer arrow
//             Positioned(
//               top: top,
//               right: 20,
//               child: ScaleTransition(
//                 scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
//                 alignment: Alignment.topRight,
//                 child: FadeTransition(
//                   opacity: anim,
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Container(
//                       width: 222,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(18),
//                         border: Border.all(color: _C.border),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(
//                               0xFF1E1B18,
//                             ).withValues(alpha: 0.28),
//                             blurRadius: 50,
//                             offset: const Offset(0, 24),
//                             spreadRadius: -16,
//                           ),
//                         ],
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _menuVisibilityRow(),
//                           _menuDivider(),
//                           _menuRow('share', 'share_recipe_link'.tr, () {
//                             Navigator.pop(ctx);
//                             _shareRecipe();
//                           }),
//                           _menuDivider(),
//                           _menuRow('file', 'export_pdf'.tr, () {
//                             Navigator.pop(ctx);
//                             if (!SubscriptionService.instance.canExportPDF()) {
//                               showUpgradeDialog(
//                                 context,
//                                 feature: 'export_pdf'.tr,
//                               );
//                             } else {
//                               ExportPdfSheet.open(_recipe, note: _note);
//                             }
//                           }, plus: true),
//                           _menuDivider(),
//                           _menuRow('print', 'print_recipe'.tr, () {
//                             Navigator.pop(ctx);
//                             if (!SubscriptionService.instance
//                                 .canPrintRecipe()) {
//                               showUpgradeDialog(
//                                 context,
//                                 feature: 'print_recipe'.tr,
//                               );
//                             } else {
//                               ExportPdfSheet.open(_recipe, note: _note);
//                             }
//                           }, plus: true),
//                           _menuDivider(),
//                           _menuRow('trash', 'delete_recipe'.tr, () {
//                             Navigator.pop(ctx);
//                             _confirmDelete();
//                           }, destructive: true),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     ).then((_) {
//       if (mounted) setState(() => _menuOpen = false);
//     });
//   }

//   Widget _menuVisibilityRow() {
//     return StatefulBuilder(
//       builder: (ctx, setRow) {
//         final isPublic = _isPublic;
//         return InkWell(
//           onTap: () {
//             Get.back(); // close the menu, then confirm
//             _toggleVisibility();
//           },
//           child: Container(
//             color: isPublic ? _C.greenBg : Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             child: Row(
//               children: [
//                 OnboardingLineIcon(
//                   isPublic ? 'globe' : 'lock',
//                   size: 18,
//                   color: isPublic ? _C.green : _C.textBody,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     isPublic ? 'public_recipe'.tr : 'private_recipe'.tr,
//                     style: _font(15, FontWeight.w700, _C.textDark),
//                   ),
//                 ),
//                 // Functional on/off switch
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 180),
//                   width: 38,
//                   height: 23,
//                   padding: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     color: isPublic ? _C.green : const Color(0xFFE7DECE),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: AnimatedAlign(
//                     duration: const Duration(milliseconds: 180),
//                     curve: Curves.easeInOut,
//                     alignment: isPublic
//                         ? Alignment.centerRight
//                         : Alignment.centerLeft,
//                     child: Container(
//                       width: 17,
//                       height: 17,
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _menuDivider() => Container(
//     height: 1,
//     margin: const EdgeInsets.symmetric(horizontal: 14),
//     color: _C.rowLine,
//   );

//   Widget _menuRow(
//     String icon,
//     String label,
//     VoidCallback onTap, {
//     bool plus = false,
//     bool destructive = false,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           children: [
//             OnboardingLineIcon(
//               icon,
//               size: 18,
//               color: destructive ? _C.primaryDark : _C.textBody,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 label,
//                 style: _font(
//                   15,
//                   FontWeight.w600,
//                   destructive ? _C.primaryDark : _C.textDark,
//                 ),
//               ),
//             ),
//             if (plus && !SubscriptionService.instance.isPlus)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEFE6FB),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const OnboardingLineIcon(
//                       'crown',
//                       size: 10,
//                       color: Color(0xFF7A45E0),
//                     ),
//                     const SizedBox(width: 3),
//                     Text(
//                       'PLUS',
//                       style: _font(9, FontWeight.w800, const Color(0xFF7A45E0)),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // SHEETS  (business logic preserved verbatim)
//   // ═══════════════════════════════════════════════════════════════════════════

//   void _showAddToCookbookSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => CookbookPickerSheet(
//         cookbookController: Get.find<CookbookController>(),
//         recipeId: recipe.id,
//         recipeImageUrl: recipe.imageUrl,
//       ),
//     );
//   }

//   void _showMealPlanPicker() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => _MealPlanPickerSheet(
//         mealPlanController: Get.find<MealPlanController>(),
//         recipe: recipe,
//         displayTitle: _displayTitle,
//       ),
//     );
//   }

//   void _confirmDelete() {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return Dialog(
//           backgroundColor: _C.card,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24),
//           ),
//           insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 56,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFEE2E2),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   alignment: Alignment.center,
//                   child: const OnboardingLineIcon(
//                     'trash',
//                     color: Colors.red,
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'delete_this_recipe'.tr,
//                   style: _font(18, FontWeight.w800, _C.textDark),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'delete_recipe_confirm'.trParams({'title': _displayTitle}),
//                   textAlign: TextAlign.center,
//                   style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () => Navigator.pop(ctx),
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: _C.border),
//                             borderRadius: BorderRadius.circular(
//                               AppDimensions.radiusButton,
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               'cancel'.tr,
//                               style: _font(15, FontWeight.w700, _C.textDark),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () async {
//                           Navigator.pop(ctx); // close the confirm dialog
//                           final deleted = await Get.find<HomeController>()
//                               .deleteRecipe(recipe);
//                           // On success, close the detail (and any recipe routes)
//                           // back to Home — never leave a deleted recipe's detail
//                           // in the stack.
//                           if (deleted) {
//                             Get.until((route) => route.isFirst);
//                           }
//                         },
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             borderRadius: BorderRadius.circular(
//                               AppDimensions.radiusButton,
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               'delete'.tr,
//                               style: _font(15, FontWeight.w700, Colors.white),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // MEAL PLAN PICKER SHEET
// // ═══════════════════════════════════════════════════════════════════════════════

// class _MealPlanPickerSheet extends StatefulWidget {
//   final MealPlanController mealPlanController;
//   final RecipeModel recipe;

//   /// The title to SHOW in this sheet (owner's original language, or the
//   /// viewer's translated language) — the meal plan item itself is still
//   /// saved with `recipe.title` (canonical English) below, unchanged.
//   final String? displayTitle;

//   const _MealPlanPickerSheet({
//     required this.mealPlanController,
//     required this.recipe,
//     this.displayTitle,
//   });

//   @override
//   State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
// }

// class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
//   DateTime _selectedDay = DateTime.now();
//   late DateTime _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);
//   String _selectedMealType = 'Dinner';
//   bool _isAdding = false;

//   static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
//   static const Map<String, Color> _mealColors = {
//     'Breakfast': Color(0xFFF59E0B),
//     'Lunch': Color(0xFF10B981),
//     'Dinner': Color(0xFF6366F1),
//     'Snack': Color(0xFFEF4444),
//   };
//   static const Map<String, IconData> _mealIcons = {
//     'Breakfast': Icons.wb_sunny_outlined,
//     'Lunch': Icons.lunch_dining_outlined,
//     'Dinner': Icons.dinner_dining_outlined,
//     'Snack': Icons.cookie_outlined,
//   };

//   bool _sameDay(DateTime a, DateTime b) =>
//       a.day == b.day && a.month == b.month && a.year == b.year;

//   static const _monthNames = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December',
//   ];

//   String get _title => widget.displayTitle ?? widget.recipe.title;

//   // ── Month calendar (matches the Meal Plan calendar) ────────────────────────
//   // Past dates (before today) are shown greyed out and can't be selected — you
//   // can only plan meals for today onwards.
//   Widget _calendar(Color color) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final month = _visibleMonth;
//     final firstOfMonth = DateTime(month.year, month.month, 1);
//     final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
//     final leading = firstOfMonth.weekday - 1; // Monday-first blanks

//     // Never let the user page back into a month that's entirely in the past.
//     final canGoPrev =
//         month.year > today.year ||
//         (month.year == today.year && month.month > today.month);

//     final cells = <Widget>[];
//     for (var i = 0; i < leading; i++) {
//       cells.add(const SizedBox.shrink());
//     }
//     for (var d = 1; d <= daysInMonth; d++) {
//       final date = DateTime(month.year, month.month, d);
//       cells.add(
//         _dayCell(
//           date,
//           d,
//           isPast: date.isBefore(today),
//           isSelected: _sameDay(date, _selectedDay),
//           isToday: _sameDay(date, today),
//           color: color,
//         ),
//       );
//     }

//     return Column(
//       children: [
//         // Month header with prev/next arrows.
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               _navArrow(
//                 Icons.chevron_left,
//                 canGoPrev
//                     ? () => setState(
//                         () => _visibleMonth = DateTime(
//                           month.year,
//                           month.month - 1,
//                         ),
//                       )
//                     : null,
//               ),
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     '${_monthNames[month.month - 1]} ${month.year}',
//                     style: _font(15.5, FontWeight.w800, _C.textDark),
//                   ),
//                 ),
//               ),
//               _navArrow(
//                 Icons.chevron_right,
//                 () => setState(
//                   () => _visibleMonth = DateTime(month.year, month.month + 1),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         // Weekday header (Monday-first).
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18),
//           child: Row(
//             children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
//                 .map(
//                   (w) => Expanded(
//                     child: Center(
//                       child: Text(
//                         w,
//                         style: _font(11, FontWeight.w700, _C.textHint),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//         ),
//         const SizedBox(height: 4),
//         // Day grid.
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 7,
//             childAspectRatio: 1.05,
//             children: cells,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _dayCell(
//     DateTime date,
//     int day, {
//     required bool isPast,
//     required bool isSelected,
//     required bool isToday,
//     required Color color,
//   }) {
//     return GestureDetector(
//       onTap: isPast ? null : () => setState(() => _selectedDay = date),
//       behavior: HitTestBehavior.opaque,
//       child: Center(
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           width: 38,
//           height: 38,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: isSelected ? color : Colors.transparent,
//             shape: BoxShape.circle,
//             border: (isToday && !isSelected)
//                 ? Border.all(color: color, width: 1.4)
//                 : null,
//           ),
//           child: Text(
//             '$day',
//             style: _font(
//               14,
//               (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
//               isSelected
//                   ? Colors.white
//                   : isPast
//                   ? _C.textHint.withValues(alpha: 0.4)
//                   : _C.textDark,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _navArrow(IconData icon, VoidCallback? onTap) {
//     final enabled = onTap != null;
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Container(
//         width: 34,
//         height: 34,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: _C.surfaceLight,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(
//           icon,
//           size: 20,
//           color: enabled ? _C.textDark : _C.textHint.withValues(alpha: 0.35),
//         ),
//       ),
//     );
//   }

//   Future<void> _confirm() async {
//     setState(() => _isAdding = true);
//     try {
//       await widget.mealPlanController.addMealPlanItem(
//         date: _selectedDay,
//         mealType: _selectedMealType,
//         recipeId: widget.recipe.id,
//         // Saved canonically (unchanged) — the meal plan itself always keeps
//         // the English title; only what's SHOWN in this sheet uses _title.
//         recipeTitle: widget.recipe.title,
//         recipeImageUrl: widget.recipe.imageUrl,
//       );
//       // Point the Meal Plan tab at the day we just added to, so the new meal is
//       // visible immediately even when it falls outside the week currently shown.
//       widget.mealPlanController.selectDate(_selectedDay);
//       if (mounted) Get.back();
//       CustomSnackbar.show(
//         title: 'added_to_meal'.trParams({'meal': _selectedMealType}),
//         message: 'recipe_added_to_meal_plan'.trParams({'title': _title}),
//         type: SnackbarType.success,
//       );
//     } catch (_) {
//       if (mounted) setState(() => _isAdding = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // The sheet's accent (calendar highlight + Add button) stays the app
//     // primary — only the meal-type TAB shows its own colour.
//     return SafeArea(
//       child: Container(
//         decoration: const BoxDecoration(
//           color: _C.card,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//         ),
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//         ),
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.9,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     margin: const EdgeInsets.only(top: 12, bottom: 4),
//                     width: 50,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'add_to_meal_plan'.tr,
//                               style: _font(18, FontWeight.w800, _C.textDark),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               _title,
//                               style: _font(12, FontWeight.w500, _C.textMedium),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const OnboardingLineIcon(
//                           'x',
//                           size: 20,
//                           color: _C.textMedium,
//                         ),
//                         onPressed: () => Get.back(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20, bottom: 10),
//                   child: Text(
//                     'select_date'.tr.toUpperCase(),
//                     style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
//                   ),
//                 ),
//                 _calendar(_C.primary),
//                 const SizedBox(height: 20),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20, bottom: 10),
//                   child: Text(
//                     'meal_type'.tr.toUpperCase(),
//                     style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
//                   ),
//                 ),
//                 // Colored pill tabs — each meal type keeps its own colour; the
//                 // selected one fills solid, the rest show a light tint. Only these
//                 // tabs are coloured (the calendar + button stay the app primary).
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 14),
//                   child: Row(
//                     children: _mealTypes.map((type) {
//                       final sel = _selectedMealType == type;
//                       final c = _mealColors[type]!;
//                       return Expanded(
//                         child: GestureDetector(
//                           onTap: () => setState(() => _selectedMealType = type),
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 200),
//                             margin: const EdgeInsets.symmetric(horizontal: 4),
//                             padding: const EdgeInsets.symmetric(vertical: 11),
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               color: sel ? c : c.withValues(alpha: 0.13),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               type,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               textAlign: TextAlign.center,
//                               style: _font(
//                                 12.5,
//                                 sel ? FontWeight.w800 : FontWeight.w700,
//                                 sel ? Colors.white : c,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: GestureDetector(
//                     onTap: _isAdding ? null : _confirm,
//                     child: Container(
//                       width: double.infinity,
//                       height: AppDimensions.buttonHeight,
//                       decoration: BoxDecoration(
//                         color: _C.primary,
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radiusButton,
//                         ),
//                       ),
//                       child: Center(
//                         child: _isAdding
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     _mealIcons[_selectedMealType] ??
//                                         Icons.restaurant,
//                                     size: 18,
//                                     color: Colors.white,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'add_to_meal'.trParams({
//                                       'meal': _selectedMealType,
//                                     }),
//                                     style: _font(
//                                       15,
//                                       FontWeight.w700,
//                                       Colors.white,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // COOKBOOK PICKER SHEET
// // ═══════════════════════════════════════════════════════════════════════════════

// class CookbookPickerSheet extends StatefulWidget {
//   final CookbookController cookbookController;
//   final String recipeId;
//   final String? recipeImageUrl;

//   const CookbookPickerSheet({
//     super.key,
//     required this.cookbookController,
//     required this.recipeId,
//     required this.recipeImageUrl,
//   });

//   @override
//   State<CookbookPickerSheet> createState() => _CookbookPickerSheetState();
// }

// class _CookbookPickerSheetState extends State<CookbookPickerSheet> {
//   late final Set<String> _initial;
//   final Set<String> _selected = {};
//   bool _saving = false;

//   @override
//   void initState() {
//     super.initState();
//     _initial = widget.cookbookController.cookbooks
//         .where((c) => c.recipeIds.contains(widget.recipeId))
//         .map((c) => c.id)
//         .toSet();
//     _selected.addAll(_initial);
//   }

//   Future<void> _apply() async {
//     if (_saving) return;
//     setState(() => _saving = true);
//     final toAdd = _selected.difference(_initial);
//     final toRemove = _initial.difference(_selected);
//     for (final id in toAdd) {
//       await widget.cookbookController.addRecipeToCookbook(
//         id,
//         widget.recipeId,
//         widget.recipeImageUrl,
//         showToast: false,
//       );
//     }
//     for (final id in toRemove) {
//       await widget.cookbookController.removeRecipeFromCookbook(
//         id,
//         widget.recipeId,
//         showToast: false,
//       );
//     }
//     if (!mounted) return;
//     Navigator.pop(context, _selected.length);
//     if (toAdd.isNotEmpty) {
//       CustomSnackbar.show(
//         title: 'saved'.tr,
//         message: toAdd.length == 1
//             ? 'added_to_1_cookbook'.tr
//             : 'added_to_n_cookbooks'.trParams({'count': '${toAdd.length}'}),
//         type: SnackbarType.success,
//       );
//     } else if (toRemove.isNotEmpty) {
//       CustomSnackbar.show(
//         title: 'updated'.tr,
//         message: 'cookbook_selection_updated'.tr,
//         type: SnackbarType.success,
//       );
//     }
//   }

//   // 2×2 image collage thumbnail (design 36), built from the cookbook's recipe
//   // images with an empty-tile fallback.
//   Widget _thumb(CookbookModel cb) {
//     final home = Get.find<HomeController>();
//     final imgs = <String>[];
//     for (final id in cb.recipeIds) {
//       final url = home.recipes.firstWhereOrNull((e) => e.id == id)?.imageUrl;
//       if (url != null && url.isNotEmpty) imgs.add(url);
//       if (imgs.length == 4) break;
//     }
//     Widget cell(int i) => i < imgs.length
//         ? RecipeImage(imageUrl: imgs[i])
//         : Container(color: const Color(0xFFE7DECE));
//     return Container(
//       width: 42,
//       height: 42,
//       decoration: BoxDecoration(
//         color: const Color(0xFFEDE5D7),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         children: [
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(child: cell(0)),
//                 const SizedBox(width: 1),
//                 Expanded(child: cell(1)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 1),
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(child: cell(2)),
//                 const SizedBox(width: 1),
//                 Expanded(child: cell(3)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
//         ),
//         padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Grab handle
//             Center(
//               child: Container(
//                 width: 42,
//                 height: 5,
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE7E0D2),
//                   borderRadius: BorderRadius.circular(3),
//                 ),
//               ),
//             ),
//             // Header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 6),
//               child: Row(
//                 children: [
//                   Text(
//                     'add_to_cookbook'.tr,
//                     style: GoogleFonts.plusJakartaSans(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                       color: const Color(0xFF2A211B),
//                       letterSpacing: -0.4,
//                     ),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () => Get.back(),
//                     child: Container(
//                       width: 34,
//                       height: 34,
//                       alignment: Alignment.center,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFFF4F1EA),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const OnboardingLineIcon(
//                         'x',
//                         size: 19,
//                         color: Color(0xFF8A7E70),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 14),
//             // Cookbook list
//             Flexible(
//               child: Obx(() {
//                 final cbs = widget.cookbookController.cookbooks;
//                 if (cbs.isEmpty) {
//                   return Padding(
//                     padding: const EdgeInsets.fromLTRB(6, 16, 6, 16),
//                     child: Text(
//                       'no_cookbooks_yet_create'.tr,
//                       style: _font(13.5, FontWeight.w500, _C.textMedium),
//                     ),
//                   );
//                 }
//                 return ListView.separated(
//                   shrinkWrap: true,
//                   padding: EdgeInsets.zero,
//                   itemCount: cbs.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 2),
//                   itemBuilder: (_, i) {
//                     final cb = cbs[i];
//                     final selected = _selected.contains(cb.id);
//                     final count = cb.recipeIds.length;
//                     return GestureDetector(
//                       onTap: () => setState(() {
//                         selected
//                             ? _selected.remove(cb.id)
//                             : _selected.add(cb.id);
//                       }),
//                       behavior: HitTestBehavior.opaque,
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: selected
//                               ? const Color(0xFFFFF3EF)
//                               : Colors.transparent,
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: Row(
//                           children: [
//                             _thumb(cb),
//                             const SizedBox(width: 13),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     cb.name,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: GoogleFonts.plusJakartaSans(
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w700,
//                                       color: const Color(0xFF2A211B),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 1),
//                                   Text(
//                                     count == 1
//                                         ? 'n_recipe'.trParams({
//                                             'count': '$count',
//                                           })
//                                         : 'n_recipes'.trParams({
//                                             'count': '$count',
//                                           }),
//                                     style: GoogleFonts.plusJakartaSans(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: const Color(0xFF9A938A),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Container(
//                               width: 26,
//                               height: 26,
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(13),
//                                 color: selected
//                                     ? const Color(0xFFF2623E)
//                                     : Colors.transparent,
//                                 border: selected
//                                     ? null
//                                     : Border.all(
//                                         color: const Color(0xFFE2D8C7),
//                                         width: 2,
//                                       ),
//                               ),
//                               child: selected
//                                   ? const OnboardingLineIcon(
//                                       'check',
//                                       color: Colors.white,
//                                       size: 16,
//                                     )
//                                   : null,
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               }),
//             ),
//             // New cookbook
//             GestureDetector(
//               onTap: () {
//                 showNewCookbookSheet(context);
//                 // AddCookbookSheet.show(context);
//               },
//               behavior: HitTestBehavior.opaque,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 13,
//                 ),
//                 child: Row(
//                   children: [
//                     const SizedBox(
//                       width: 42,
//                       height: 42,
//                       child: CustomPaint(
//                         painter: _DashedRRectPainter(
//                           color: Color(0xFFD8CFBE),
//                           radius: 12,
//                           strokeWidth: 1.5,
//                         ),
//                         child: Center(
//                           child: OnboardingLineIcon(
//                             'plus',
//                             size: 22,
//                             color: Color(0xFFF2623E),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 13),
//                     Text(
//                       'new_cookbook'.tr,
//                       style: GoogleFonts.plusJakartaSans(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         color: const Color(0xFFF2623E),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Done button
//             GestureDetector(
//               onTap: _apply,
//               child: Container(
//                 width: double.infinity,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF2623E),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFFF2623E).withValues(alpha: 0.4),
//                       blurRadius: 26,
//                       offset: const Offset(0, 14),
//                       spreadRadius: -10,
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: _saving
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : Text(
//                           'done'.tr,
//                           style: GoogleFonts.plusJakartaSans(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Dashed rounded-rectangle border (for the "New cookbook" tile in design 36).
// class _DashedRRectPainter extends CustomPainter {
//   final Color color;
//   final double radius;
//   final double strokeWidth;

//   const _DashedRRectPainter({
//     required this.color,
//     required this.radius,
//     required this.strokeWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;
//     final path = Path()
//       ..addRRect(
//         RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
//       );
//     const dash = 4.0, gap = 3.0;
//     for (final metric in path.computeMetrics()) {
//       double dist = 0;
//       while (dist < metric.length) {
//         final len = math.min(dash, metric.length - dist);
//         canvas.drawPath(metric.extractPath(dist, dist + len), paint);
//         dist += dash + gap;
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _DashedRRectPainter old) =>
//       old.color != color ||
//       old.radius != radius ||
//       old.strokeWidth != strokeWidth;
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // PUBLIC DELETE DIALOG
// // ═══════════════════════════════════════════════════════════════════════════════

// void showDeleteRecipeDialog(
//   RecipeModel recipe,
//   HomeController controller, {
//   String? displayTitle,
// }) {
//   final title = displayTitle ?? recipe.title;
//   Get.dialog(
//     Dialog(
//       backgroundColor: _C.card,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFEE2E2),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               alignment: Alignment.center,
//               child: const OnboardingLineIcon(
//                 'trash',
//                 color: Colors.red,
//                 size: 28,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'delete_this_recipe'.tr,
//               style: _font(18, FontWeight.w800, _C.textDark),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'delete_recipe_confirm_short'.trParams({'title': title}),
//               textAlign: TextAlign.center,
//               style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () => Get.back(),
//                     child: Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: _C.border),
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radiusButton,
//                         ),
//                       ),
//                       child: Center(
//                         child: Text(
//                           'cancel'.tr,
//                           style: _font(15, FontWeight.w700, _C.textDark),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () async {
//                       Get.back(); // close the confirm dialog
//                       final deleted = await controller.deleteRecipe(recipe);
//                       if (deleted) {
//                         Get.until((route) => route.isFirst);
//                       }
//                     },
//                     child: Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radiusButton,
//                         ),
//                       ),
//                       child: Center(
//                         child: Text(
//                           'delete'.tr,
//                           style: _font(15, FontWeight.w700, Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // VISIBILITY CONFIRM DIALOG
// // ═══════════════════════════════════════════════════════════════════════════════

// class _VisibilityConfirmDialog extends StatelessWidget {
//   final bool makePublic;
//   final VoidCallback onConfirm;

//   const _VisibilityConfirmDialog({
//     required this.makePublic,
//     required this.onConfirm,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final accent = makePublic ? _C.green : _C.primary;
//     final title = makePublic
//         ? 'make_recipe_public_q'.tr
//         : 'make_recipe_private_q'.tr;
//     final body = makePublic ? 'make_public_desc'.tr : 'make_private_desc'.tr;
//     final action = makePublic ? 'make_public'.tr : 'make_private'.tr;

//     return Dialog(
//       backgroundColor: _C.card,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: accent.withValues(alpha: 0.12),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Center(
//                 child: OnboardingLineIcon(
//                   makePublic ? 'globe' : 'lock',
//                   color: accent,
//                   size: 28,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(title, style: _font(18, FontWeight.w800, _C.textDark)),
//             const SizedBox(height: 10),
//             Text(
//               body,
//               textAlign: TextAlign.center,
//               style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () => Get.back(),
//                     child: Container(
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: _C.border),
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radiusButton,
//                         ),
//                       ),
//                       child: Text(
//                         'cancel'.tr,
//                         style: _font(15, FontWeight.w700, _C.textDark),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: onConfirm,
//                     child: Container(
//                       height: 48,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         color: accent,
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radiusButton,
//                         ),
//                       ),
//                       child: Text(
//                         action,
//                         style: _font(15, FontWeight.w700, Colors.white),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:recipe_ai/Model/recipe_section_model.dart';

import 'package:recipe_ai/screens/recipe/export_pdf_sheet.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/cookbook_recipes_screen.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';
import 'package:recipe_ai/Helper/instruction_scaler.dart';
import 'package:recipe_ai/Helper/premium_gate.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/widgets/premium_lock_overlay.dart';
import 'package:recipe_ai/Controllers/nutrition_controller.dart';
import 'package:recipe_ai/widgets/nutrition_preview_card.dart';
import 'package:recipe_ai/widgets/nutrition_locked_card.dart';
import 'package:recipe_ai/View/Home/nutrition/nutrition_screen.dart';
import 'package:recipe_ai/Controllers/ai_assistant_controller.dart';
import 'package:recipe_ai/View/Home/ai_assistant_screen.dart';
import 'package:recipe_ai/widgets/cannot_publish_dialog.dart';
import 'package:recipe_ai/widgets/comments_sheet.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Helper/recipe_publish_policy.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;
import 'dart:typed_data';

// ── NEW IMPORTS FOR TRANSLATION ──────────────────────────────────────────
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/language_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants (matched to the HTML "Recipe detail" design)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const border = Color(0xFFEFE6D6);
  static const borderInner = Color(0xFFE7DECE);
  static const rowLine = Color(0xFFF4ECDF);
  static const surfaceLight = Color(0xFFFBF7F0);
  static const primary = Color(0xFFF2623E);
  static const primaryDark = Color(0xFFE0481F);
  static const textDark = Color(0xFF2A211B);
  static const textMedium = Color(0xFF8A7E70);
  static const textHint = Color(0xFFA89F90);
  static const textBody = Color(0xFF5A5147);
  static const textBodyDark = Color(0xFF3A352D);
  static const green = Color(0xFF1F7A5E);
  static const greenBg = Color(0xFFEAF6F0);
  static const greenBorder = Color(0xFFCFE9DD);
  static const purple = Color(0xFF8B5CF6);
  static const purpleBg = Color(0xFFF4EEFD);
  static const purpleBorder = Color(0xFFE0D2F7);
  static const goldBg = Color(0xFFFBF1E4);
  static const noteBg = Color(0xFFFCE3DB);

  static const double outerPad = 22.0;
  static const double cardPad = 16.0;
  static const double cardRadius = 20.0;
  static const double cardSpacing = 16.0;
}

TextStyle _font(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

BoxDecoration _cardDeco() => BoxDecoration(
  color: _C.card,
  borderRadius: BorderRadius.circular(_C.cardRadius),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF2A211B).withValues(alpha: 0.16),
      blurRadius: 26,
      offset: const Offset(0, 12),
      spreadRadius: -22,
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════════
// RECIPE DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  /// When opened from a comment notification, the id of the comment to reveal —
  /// the comments sheet opens automatically and highlights it.
  final String? focusCommentId;
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.focusCommentId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _initialServings;
  late int _servings;
  String _note = '';
  bool _menuOpen = false;
  late bool _isPublic;
  final Set<int> _checkedIngredients = {};
  final SettingsController _settings = Get.find<SettingsController>();
  final GroceryStore _grocery = Get.find<GroceryStore>();
  final HomeController _home = Get.find<HomeController>();

  File? _cachedShareFile;
  Uint8List? _cachedImageBytes;

  // Share preparation already running હોય તો આ Future reuse થશે.
  Future<void>? _sharePreparationFuture;

  bool _isPreparingShare = false;

  // Live copy of the recipe. Starts from the one passed in, then refreshes in
  // real time whenever the owner saves edits: the editor writes to Firestore,
  // HomeController.recipes re-emits, and the worker below pulls the fresh copy.
  late RecipeModel _recipe = widget.recipe;
  Worker? _recipeWorker;
  // True once we've begun closing this screen because its recipe was deleted —
  // guards the pop-to-Home from firing more than once.
  bool _closing = false;
  // Whether this recipe has been present in the owner's list. Only a recipe
  // that was seen and then vanished counts as "deleted" — a detail opened from
  // a source not backed by the recipes stream must never auto-close spuriously.
  bool _seenInList = false;

  // ── Language display (owner sees original-language text, everyone else
  // sees the English canonical copy translated into their own selected app
  // language) — resolved once from the raw Firestore doc and refreshed
  // whenever the underlying recipe changes. See RecipeLocalizer.
  LocalizedRecipe? _localized;
  bool _localizing = false;

  RecipeModel get recipe => _recipe;
  final ScreenshotController _shareController = ScreenshotController();

  // ── Display getters — use these instead of `recipe.*` anywhere text is
  // actually shown to the user, so the language rule (owner = original,
  // everyone else = translated) is applied consistently. Falls back to the
  // plain `recipe` fields while the localized copy is still loading.
  String get _displayTitle => _localized?.title ?? recipe.title;
  String? get _displayPrepTime => _localized?.prepTime ?? recipe.prepTime;
  String? get _displayCookTime => _localized?.cookTime ?? recipe.cookTime;
  String? get _displayTotalTime => _localized?.totalTime ?? recipe.totalTime;
  String? get _displayServings => _localized?.servings ?? recipe.servings;
  List<String> get _displayIngredients =>
      _localized?.ingredients ?? recipe.ingredients;
  List<String> get _displayInstructions =>
      _localized?.instructions ?? recipe.instructions;
  List<IngredientSection> get _displayIngredientSections =>
      _localized?.ingredientSections ?? recipe.ingredientSections;
  List<InstructionSection> get _displayInstructionSections =>
      _localized?.instructionSections ?? recipe.instructionSections;

  @override
  void initState() {
    super.initState();
    _isPublic = recipe.isPublic;
    // Migration: back-fill `visibility` on legacy docs when opened.
    if (!recipe.visibilityWasStored) {
      _home.migrateVisibility(recipe.id, recipe.visibility);
    }
    _initialServings = _parseServings(recipe);
    _servings = _initialServings;
    _note = _recipe.note ?? '';
    _seenInList = _home.recipes.any((r) => r.id == _recipe.id);

    // Resolve which language to show this recipe in (owner → original,
    // everyone else → English translated into their own selected language).
    _loadLocalizedText();

    // Keep this screen in sync with the recipe stream:
    //  • edits → pull the fresh copy in (live, no manual refresh),
    //  • deletion (here or on another device) → close back to Home so a detail
    //    of a gone recipe is never shown and Back can't return to it.
    _recipeWorker = ever<List<RecipeModel>>(_home.recipes, (list) {
      final idx = list.indexWhere((r) => r.id == _recipe.id);
      if (idx == -1) {
        if (_seenInList) _handleRecipeDeleted();
        return;
      }
      _seenInList = true;
      final r = list[idx];
      if (!_recipeChanged(r) || !mounted) return;
      final servingsChanged = r.servings != _recipe.servings;
      setState(() {
        _recipe = r;
        _isPublic = r.isPublic;
        if (servingsChanged) {
          _initialServings = _parseServings(r);
          _servings = _initialServings;
        }
      });
      // The recipe text itself may have changed (owner just edited it) —
      // re-resolve the localized copy so it doesn't go stale.
      _loadLocalizedText();
    });

    // Opened from a comment notification → reveal the comments (owner is the
    // current user, so ownerId == our uid) and highlight the tapped comment.
    final focusId = widget.focusCommentId;
    if (focusId != null && focusId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uid = AuthService.currentUser?.uid;
        if (!mounted || uid == null) return;
        CommentsSheet.show(
          context,
          ownerId: uid,
          recipeId: _recipe.id,
          highlightCommentId: focusId,
        );
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSharePreparation();
    });
    _prepareShareFile();
  }

  void _startSharePreparation() {
    if (_sharePreparationFuture != null) return;
    _sharePreparationFuture = _prepareShareFile();
    _sharePreparationFuture!.whenComplete(() {
      _sharePreparationFuture = null;
    });
  }

  /// Fetches the raw Firestore document (which carries the `original` /
  /// `originalLanguageCode` snapshot alongside the English canonical fields)
  /// and resolves what to actually show via [RecipeLocalizer]. Safe to call
  /// repeatedly — re-entrant calls are skipped while one is already in
  /// flight, and the result only ever refines what's shown (never blocks
  /// the screen — everything already renders from `recipe.*` in the
  /// meantime via the `_display*` getters' fallback).
  Future<void> _loadLocalizedText() async {
    if (_localizing) return;
    _localizing = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(_recipe.id)
          .get();
      final data = doc.data();
      if (data == null) return;

      final localized = await RecipeLocalizer.resolve(
        data,
        currentUid: AuthService.currentUser?.uid,
      );
      if (!mounted) return;
      setState(() => _localized = localized);
    } catch (e) {
      log('Localize recipe text failed: $e');
    } finally {
      _localizing = false;
    }
  }

  Future<void> _prepareShareFile({bool force = false}) async {
    // Already preparing હોય તો એ જ Future complete થવા દો.
    if (!force && _sharePreparationFuture != null) {
      await _sharePreparationFuture;
      return;
    }

    if (!force && _cachedShareFile != null) {
      if (await _cachedShareFile!.exists()) {
        return;
      }
    }

    final future = _doPrepareShareFile(force: force);

    _sharePreparationFuture = future;

    try {
      await future;
    } finally {
      if (identical(_sharePreparationFuture, future)) {
        _sharePreparationFuture = null;
      }
    }
  }

  Future<void> _doPrepareShareFile({bool force = false}) async {
    if (_isPreparingShare) return;

    _isPreparingShare = true;

    try {
      final directory = await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/recipe_share_${recipe.id}.png');

      // -----------------------------------------
      // 1. Check local cached share image
      // -----------------------------------------
      if (!force && await file.exists()) {
        final length = await file.length();

        if (length > 0) {
          _cachedShareFile = file;

          log('✅ Share image loaded from local cache');
          log('📁 ${file.path}');

          return;
        }
      }

      // -----------------------------------------
      // 2. Reset image cache
      // -----------------------------------------
      _cachedShareFile = null;
      _cachedImageBytes = null;

      // -----------------------------------------
      // 3. Download recipe image
      // -----------------------------------------
      final imgUrl = recipe.imageUrl?.trim();

      log('🖼️ Image URL: $imgUrl');

      if (imgUrl != null && imgUrl.isNotEmpty) {
        try {
          final response = await http
              .get(Uri.parse(imgUrl))
              .timeout(const Duration(seconds: 8));

          log('Image status: ${response.statusCode}');
          log('Image bytes: ${response.bodyBytes.length}');

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            _cachedImageBytes = response.bodyBytes;
          }
        } catch (e) {
          log('⚠️ Image download failed: $e');
        }
      }

      // -----------------------------------------
      // 4. Generate share card
      // -----------------------------------------
      log('🎨 Generating share card...');

      final cardBytes = await _shareController.captureFromWidget(
        _buildShareRecipeCard(_cachedImageBytes),
        delay: const Duration(milliseconds: 150),
        pixelRatio: 2.0,
        targetSize: const Size(1080, 1700),
      );

      if (cardBytes.isEmpty) {
        throw Exception('Share card generated empty');
      }

      // -----------------------------------------
      // 5. Save permanently in app local storage
      // -----------------------------------------
      await file.writeAsBytes(cardBytes, flush: true);

      _cachedShareFile = file;

      log('✅ Share card ready');
      log('📁 Saved: ${file.path}');
    } catch (e, stackTrace) {
      log('❌ Prepare share failed: $e', stackTrace: stackTrace);
    } finally {
      _isPreparingShare = false;
    }
  }

  /// The recipe backing this screen is gone from the stream (deleted). Close
  /// every recipe route back to Home exactly once — Back can't return to the
  /// stale detail, and no "recipe not found" state is ever rendered.
  void _handleRecipeDeleted() {
    if (_closing || !mounted) return;
    _closing = true;
    // Navigate after the current frame — the worker fires during a stream
    // update, when synchronous navigation would be unsafe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.until((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _recipeWorker?.dispose();
    super.dispose();
  }

  int _parseServings(RecipeModel r) {
    int parsed = 2;
    if (r.servings != null) {
      final m = RegExp(r'\d+').firstMatch(r.servings!);
      if (m != null) parsed = int.tryParse(m.group(0)!) ?? 2;
    }
    return parsed <= 0 ? 2 : parsed;
  }

  /// Whether [r] differs from the current recipe in any displayed field — used
  /// to skip needless rebuilds (the stream re-emits new instances for every
  /// recipe on any change, most of which are identical here).
  bool _recipeChanged(RecipeModel r) =>
      r.title != _recipe.title ||
      r.description != _recipe.description ||
      r.imageUrl != _recipe.imageUrl ||
      r.servings != _recipe.servings ||
      r.prepTime != _recipe.prepTime ||
      r.cookTime != _recipe.cookTime ||
      r.totalTime != _recipe.totalTime ||
      r.category != _recipe.category ||
      r.isPublic != _recipe.isPublic ||
      !listEquals(r.ingredients, _recipe.ingredients) ||
      !listEquals(r.instructions, _recipe.instructions);

  // Ask for confirmation, then flip public/private (owner only).
  void _toggleVisibility() {
    final makePublic = !_isPublic;
    // A recipe saved from Discover can never be published: show the block
    // popup, leave the toggle OFF, and change nothing.
    if (makePublic && !recipe.canBePublished) {
      showCannotPublishDialog();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _VisibilityConfirmDialog(
        makePublic: makePublic,
        onConfirm: () {
          Navigator.pop(ctx);
          _applyVisibility(makePublic);
        },
      ),
    );
  }

  void _applyVisibility(bool makePublic) {
    setState(() => _isPublic = makePublic);
    Get.find<HomeController>().updateRecipeVisibility(recipe.id, makePublic);
    CustomSnackbar.show(
      title: makePublic
          ? 'recipe_is_now_public'.tr
          : 'recipe_is_now_private'.tr,
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const heroH = 300.0;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(heroH),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _C.outerPad - 5,
                      6,
                      _C.outerPad - 5,
                      34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          _displayTitle,
                          style: _font(
                            26,
                            FontWeight.w800,
                            _C.textDark,
                            h: 1.12,
                            ls: -0.5,
                          ),
                        ),

                        // Source
                        if (recipe.sourceUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSourceRow(),
                        ],

                        // Visibility pill
                        const SizedBox(height: 12),
                        _buildVisibilityPill(),

                        // Meta row
                        const SizedBox(height: 13),
                        _buildMetaRow(),
                        const SizedBox(height: 20),

                        // AI swap / scale applied banner (with Undo)
                        _aiBanner(),

                        // Quick action tiles
                        _buildActionTiles(),
                        const SizedBox(height: 18),

                        // Cookbooks card
                        _buildCookbooksCard(),
                        const SizedBox(height: _C.cardSpacing),

                        // Add a note card
                        _buildNoteCard(),
                        const SizedBox(height: _C.cardSpacing),

                        // Ingredients card
                        _buildIngredientsCard(),
                        const SizedBox(height: _C.cardSpacing),

                        // Instructions card
                        _buildInstructionsCard(),
                        const SizedBox(height: _C.cardSpacing),

                        // Cook step-by-step
                        _buildCookButton(),
                        const SizedBox(height: _C.cardSpacing),

                        // Nutrition (Plus)
                        _buildNutritionCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating top buttons ────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 18,
            right: 18,
            child: Row(
              children: [
                _floatingBtn('back', () => Get.back()),
                const Spacer(),
                _floatingBtn(
                  'pencil',
                  () => Get.to(() => RecipeEditorScreen(recipe: recipe)),
                ),
                const SizedBox(width: 9),
                _floatingBtn('dots', _showRecipeMenuPopup, active: _menuOpen),
              ],
            ),
          ),

          // ── Plus-only "Ask AI" floating button (design 75) ──────────
          Positioned(
            right: 18,
            bottom: 20,
            child: Obx(() {
              if (!SubscriptionService.instance.isPlusListenable.value) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _askAiHintPill(),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                        Get.to(() => AiAssistantScreen(recipe: recipe)),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.6),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const OnboardingLineIcon(
                            'chat',
                            size: 19,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'ask_ai'.tr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // AI swap / scale applied banner + Undo (design 79). Reactive on the
  // assistant's last change for this recipe.
  Widget _aiBanner() {
    return Obx(() {
      final ctrl = AiAssistantController.to;
      ctrl.swaps.length; // establish reactive dependency on the swap list
      final recipeSwaps = ctrl.swapsFor(recipe.id);
      final scaleChange = ctrl.changeFor(recipe.id); // scale-only now

      // Prefer the scale banner when a scale is active; otherwise the swap
      // banner (whose Undo reverts every swap at once — mockup 79).
      final bool isSwap = scaleChange == null && recipeSwaps.isNotEmpty;
      if (scaleChange == null && recipeSwaps.isEmpty) {
        return const SizedBox.shrink();
      }

      final String summary;
      if (isSwap) {
        if (recipeSwaps.length == 1) {
          final e = recipeSwaps.first;
          summary = '${e.oldName} → ${_shortName(e.newName)}';
        } else {
          summary = '${recipeSwaps.length} ingredients';
        }
      } else {
        summary = scaleChange!.summary;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEFD),
          border: Border.all(color: const Color(0xFFE0D2F7)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
                ),
              ),
              child: Icon(
                isSwap ? Icons.swap_horiz_rounded : Icons.straighten_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: _font(
                    12.5,
                    FontWeight.w600,
                    const Color(0xFF5A4A78),
                    h: 1.4,
                  ),
                  children: [
                    TextSpan(text: isSwap ? 'AI swapped ' : 'AI scaled '),
                    TextSpan(
                      text: summary,
                      style: _font(
                        12.5,
                        FontWeight.w800,
                        const Color(0xFF5A4A78),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (isSwap) {
                  await ctrl.undoAllSwaps(recipe);
                } else {
                  await ctrl.undo();
                }
                if (!mounted) return;
                CustomSnackbar.show(
                  title: 'Undone',
                  message: 'The change was reverted.',
                  type: SnackbarType.info,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Text(
                'undo'.tr,
                style: _font(12.5, FontWeight.w800, const Color(0xFF7A45E0)),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// First part of a replacement name for the banner ("heavy cream + …" →
  /// "heavy cream").
  String _shortName(String n) =>
      n.split(RegExp(r'\s*\+|\s+and\s+')).first.trim();

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHero(double height) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
              ? AppNetworkImage(
                  recipe.imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  placeholder: _imagePlaceholder(),
                  error: _imagePlaceholder(),
                )
              : _imagePlaceholder(),
          // Gradient: dark at top, fades to background at the bottom
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66140F0A),
                  Color(0x00140F0A),
                  Color(0x00140F0A),
                  Color(0xFFFBF4EA),
                ],
                stops: [0.0, 0.32, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF0E6D6),
    child: const Center(
      child: Icon(Icons.restaurant_rounded, size: 60, color: Color(0xFFC7BCAC)),
    ),
  );

  /// Small hint pill above the Ask AI button (design 75) — also opens the chat.
  Widget _askAiHintPill() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Need a swap or help? ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B6156),
              ),
            ),
            TextSpan(
              text: 'Ask AI ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7A45E0),
              ),
            ),
            const TextSpan(text: '✨', style: TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _floatingBtn(String icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? _C.primary : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: OnboardingLineIcon(
            icon,
            size: 20,
            color: active ? Colors.white : _C.textDark,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCE ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSourceRow() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(recipe.sourceUrl);
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OnboardingLineIcon('globe', size: 15, color: _C.textHint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _sourceLabel(recipe.sourceUrl),
              style: _font(13, FontWeight.w600, _C.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          const OnboardingLineIcon('chevR', size: 16, color: Color(0xFFC7BCAC)),
        ],
      ),
    );
  }

  String _sourceLabel(String url) {
    if (url.contains('instagram')) {
      return 'from_source'.trParams({'source': 'instagram.com'});
    }
    if (url.contains('tiktok')) {
      return 'from_source'.trParams({'source': 'tiktok.com'});
    }
    if (url.contains('facebook')) {
      return 'from_source'.trParams({'source': 'facebook.com'});
    }
    if (url.contains('gemini_image')) return 'from_photo_import'.tr;
    if (url.contains('recipe_name')) return 'ai_generated_recipe'.tr;

    return 'from_recipe_ai'.tr;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VISIBILITY PILL  (reflects recipe.isPublic — tap opens editor to change)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVisibilityPill() {
    final isPublic = _isPublic;
    // Recipes saved from Discover can never be published.
    final discovered = recipe.isDiscoveredCopy;
    final fg = isPublic ? _C.green : _C.textMedium;
    final bg = isPublic ? _C.greenBg : _C.surfaceLight;
    final bd = isPublic ? _C.greenBorder : _C.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleVisibility,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnboardingLineIcon(
                  isPublic ? 'globe' : 'lock',
                  size: 14,
                  color: fg,
                ),
                const SizedBox(width: 7),
                Text(
                  isPublic ? 'public'.tr : 'private'.tr,
                  style: _font(12.5, FontWeight.w800, fg),
                ),
                const SizedBox(width: 6),
                Text(
                  discovered ? '· ${'locked'.tr}' : '· ${'tap_to_change'.tr}',
                  style: _font(11, FontWeight.w600, fg.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ),
        // Small info text under the Public toggle for saved-from-Discover
        // recipes (they can be used privately but never published).
        if (discovered) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OnboardingLineIcon('lock', size: 11, color: _C.textHint),
              const SizedBox(width: 5),
              Text(
                RecipePublishPolicy.savedFromDiscoverHint,
                style: _font(10.5, FontWeight.w600, _C.textHint),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // META ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMetaRow() {
    // Pick the first NON-EMPTY time. `??` alone is wrong here: imported recipes
    // often store totalTime as "" (empty, not null) while cook/prep have values,
    // and `?? ` only falls through on null — so the time would never show.
    final time = _firstNonEmpty([
      _displayTotalTime,
      _displayCookTime,
      _displayPrepTime,
    ]);
    final children = <Widget>[];
    if (time != null) {
      children.add(Expanded(child: _metaItem('clock', time)));
    }
    children.add(
      Expanded(
        child: _metaItem(
          'friend',
          'n_servings'.trParams({'count': '$_servings'}),
        ),
      ),
    );
    children.add(Expanded(child: _metaItem('spark', _difficultyLabel())));

    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      row.add(children[i]);
      if (i < children.length - 1) {
        row.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              '·',
              style: _font(14, FontWeight.w700, const Color(0xFFD8CFC0)),
            ),
          ),
        );
      }
    }
    return Row(children: row);
  }

  Widget _metaItem(String icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnboardingLineIcon(icon, size: 16, color: _C.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: _font(11, FontWeight.w700, _C.textBody),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// First value that is non-null AND not blank (empty strings are skipped).
  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Minutes parsed from the recipe's time string(s): handles "20 mins",
  /// "1h 20m", "1 hr 30 min" and a bare "45".
  int _totalMinutes() {
    final t = _firstNonEmpty([
      _displayTotalTime,
      _displayCookTime,
      _displayPrepTime,
    ]);
    if (t == null) return 0;
    final hourMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(t);
    final minMatch = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(t);
    var total = 0;
    if (hourMatch != null) {
      total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 60;
    }
    if (minMatch != null) total += int.tryParse(minMatch.group(1)!) ?? 0;
    if (total == 0) {
      final bare = RegExp(r'\d+').firstMatch(t);
      if (bare != null) total = int.tryParse(bare.group(0)!) ?? 0;
    }
    return total;
  }

  /// A real Easy / Medium / Hard label derived from the recipe's complexity —
  /// the import source never provides one, so it's estimated from the number of
  /// ingredients, number of steps, and total time.
  String _difficultyLabel() {
    final ingredients = _displayIngredients.length;
    final steps = _displayInstructions.length;
    final mins = _totalMinutes();
    var score = 0;
    if (ingredients >= 13) {
      score += 2;
    } else if (ingredients >= 8) {
      score += 1;
    }
    if (steps >= 11) {
      score += 2;
    } else if (steps >= 6) {
      score += 1;
    }
    if (mins >= 90) {
      score += 2;
    } else if (mins >= 45) {
      score += 1;
    }
    if (score >= 4) return 'hard'.tr;
    if (score >= 2) return 'medium'.tr;
    return 'easy'.tr;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION TILES (Cookbook / Meal Plan / Share)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionTiles() {
    return Row(
      children: [
        _actionTile('book', 'cookbook'.tr, _showAddToCookbookSheet),
        const SizedBox(width: 8),
        _actionTile('cal', 'meal_plan'.tr, _showMealPlanPicker),
        const SizedBox(width: 8),
        _actionTile('share', 'share'.tr, _shareRecipe),
      ],
    );
  }

  Widget _actionTile(String icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _C.border),
              ),
              child: OnboardingLineIcon(icon, size: 22, color: _C.primary),
            ),
            const SizedBox(height: 7),
            Text(label, style: _font(11, FontWeight.w600, _C.textMedium)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COOKBOOKS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCookbooksCard() {
    final cookbookCtrl = Get.find<CookbookController>();

    return Obx(() {
      final containing = cookbookCtrl.cookbooks
          .where((cb) => cb.recipeIds.contains(recipe.id))
          .toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_C.cardPad),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'cookbooks'.tr,
              style: _font(18, FontWeight.w800, _C.textDark),
            ),
            const SizedBox(height: 12),
            if (containing.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: containing.map((cb) {
                  return _TranslatedCookbookChip(
                    cb: cb,
                    onTap: () =>
                        Get.to(() => CookbookRecipesScreen(cookbook: cb)),
                  );
                }).toList(),
              )
            else
              GestureDetector(
                onTap: _showAddToCookbookSheet,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'plus',
                      size: 16,
                      color: _C.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'add_to_cookbook'.tr,
                      style: _font(13, FontWeight.w700, _C.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD A NOTE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNoteCard() {
    final hasNote = _note.isNotEmpty;
    return GestureDetector(
      onTap: _showAddNoteSheet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        decoration: _cardDeco(),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.noteBg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: const OnboardingLineIcon(
                'pencil',
                size: 18,
                color: _C.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? 'your_note'.tr : 'add_a_note'.tr,
                    style: _font(14, FontWeight.w700, _C.textDark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hasNote ? _note : 'note_placeholder'.tr,
                    style: _font(
                      12.5,
                      FontWeight.w400,
                      const Color(0xFF9A938A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const OnboardingLineIcon(
              'chevR',
              size: 18,
              color: Color(0xFFC7BCAC),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INGREDIENTS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildIngredientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_C.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ingredients'.tr,
                style: _font(18, FontWeight.w800, _C.textDark),
              ),
              const Spacer(),
              _buildStepper(),
            ],
          ),
          const SizedBox(height: 6),
          // Text(
          //   'Tap to check off · amounts scale with servings',
          //   style: _font(12, FontWeight.w500, const Color(0xFF9A938A)),
          // ),
          const SizedBox(height: 12),
          // Units switcher + ingredient list rebuild reactively when the user
          // toggles Metric/US (globally via SettingsController), so every
          // quantity + unit recalculates instantly.
          Obx(() {
            final system = _settings.unitSystem;
            // Depend on the swap list too, so applying/undoing a swap redraws
            // the inline "SWAPPED" tag on the affected row.
            AiAssistantController.to.swaps.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnitsBanner(),
                const SizedBox(height: 4),
                ..._buildIngredientsList(system),
              ],
            );
          }),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showGrocerySelectionSheet,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OnboardingLineIcon('cart', size: 18, color: _C.primary),
                  const SizedBox(width: 9),
                  Text(
                    'add_to_groceries'.tr,
                    style: _font(14, FontWeight.w700, _C.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Plus-only unit switcher (visual — matches the HTML locked control)
  Widget _buildUnitsBanner() {
    // Metric/Imperial is a Plus feature (PremiumGate → SubscriptionService).
    // Free users see the blurred, locked banner; tapping opens the upgrade flow.
    if (!PremiumGate.unitConversionUnlocked) {
      return GestureDetector(
        onTap: () => showUpgradeDialog(context, feature: 'unit_converter'.tr),
        behavior: HitTestBehavior.opaque,
        child: _buildLockedUnitsBanner(),
      );
    }

    final isUS = _settings.units.value == 'US';
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        color: _C.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.purpleBorder),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon('ruler', size: 16, color: _C.purple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'units'.tr,
              style: _font(12.5, FontWeight.w700, const Color(0xFF5B3E8C)),
            ),
          ),
          Container(
            width: 116,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Stack(
              children: [
                // Sliding purple background
                AnimatedAlign(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  alignment: isUS
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: isUS ? 36 : 75,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _C.purple,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),

                // Labels
                Row(
                  children: [
                    Expanded(child: _unitChip('US', isUS)),

                    Expanded(flex: 2, child: _unitChip('Metric', !isUS)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => _settings.setUnits(label),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 28,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: _font(
              11,
              selected ? FontWeight.w800 : FontWeight.w700,
              selected ? Colors.white : const Color(0xFF9A938A),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // The original locked (Plus paywall) banner — shown when the premium flag is
  // off. Preserved so re-gating is a one-line flag change.
  Widget _buildLockedUnitsBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        color: _C.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.purpleBorder),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon('ruler', size: 16, color: _C.purple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'units'.tr,
              style: _font(12.5, FontWeight.w700, const Color(0xFF5B3E8C)),
            ),
          ),
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Opacity(
              opacity: 0.7,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _C.purple,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'US',
                        style: _font(11, FontWeight.w800, Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        'Metric',
                        style: _font(
                          11,
                          FontWeight.w700,
                          const Color(0xFF9A938A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _plusBadge(),
        ],
      ),
    );
  }

  Widget _plusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.purple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OnboardingLineIcon('crown', size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text('PLUS', style: _font(9, FontWeight.w800, Colors.white)),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsList(UnitSystem system) {
    final multiplier = _servings / _initialServings;
    final ingredientSections = _displayIngredientSections;
    final ingredients = _displayIngredients;
    final hasSections = ingredientSections.any((s) => s.items.isNotEmpty);

    final widgets = <Widget>[];
    if (hasSections) {
      int globalIdx = 0;
      for (final section in ingredientSections) {
        if (section.items.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.items.length; i++) {
          final scaled = UnitConverter.scaleAndConvert(
            section.items[i],
            multiplier,
            system,
          );
          widgets.add(_ingredientRow(scaled, globalIdx, section.items[i]));
          globalIdx++;
        }
      }
      return widgets;
    }

    for (var i = 0; i < ingredients.length; i++) {
      final scaled = UnitConverter.scaleAndConvert(
        ingredients[i],
        multiplier,
        system,
      );
      widgets.add(_ingredientRow(scaled, i, ingredients[i]));
    }
    return widgets;
  }

  Widget _buildStepper() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.borderInner),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            'minus',
            _servings > 1,
            () => setState(() => _servings--),
            _C.textDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_servings',
                  style: _font(14, FontWeight.w800, _C.textDark),
                ),
                const SizedBox(width: 3),
                Text(
                  'serv'.tr,
                  style: _font(10, FontWeight.w600, const Color(0xFF9A938A)),
                ),
              ],
            ),
          ),
          _stepBtn('plus', true, () => setState(() => _servings++), _C.primary),
        ],
      ),
    );
  }

  Widget _stepBtn(String icon, bool enabled, VoidCallback onTap, Color color) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 40,
        height: 36,
        child: Center(
          child: OnboardingLineIcon(
            icon,
            size: 16,
            color: enabled ? color : _C.textHint,
          ),
        ),
      ),
    );
  }

  /// Emoji for the ingredient at flat [index], matched on its ENGLISH original.
  /// [emojiForIngredient] is an English-keyword dictionary, so a translated name
  /// misses and falls back to a generic category emoji. Translation preserves
  /// ingredient order/structure, so we look the English line up by index and
  /// match on that. Falls back to [displayName] when no English original exists
  /// (English mode, or a recipe not loaded via HomeController).
  String _ingredientEmoji(int index, String displayName) {
    final en = _home.englishRecipe(recipe.id);
    if (en != null) {
      final hasSections = en.ingredientSections.any((s) => s.items.isNotEmpty);
      final flat = hasSections
          ? [for (final s in en.ingredientSections) ...s.items]
          : en.ingredients;
      if (index >= 0 && index < flat.length) {
        return _grocery.emojiForIngredient(flat[index]);
      }
    }
    return _grocery.emojiForIngredient(displayName);
  }

  Widget _ingredientRow(String text, int index, [String? rawLine]) {
    // Inline "SWAPPED" tag + per-ingredient Undo when this line came from an AI
    // swap (mockup 79). Falls back to the normal row otherwise.
    final swap = rawLine == null
        ? null
        : AiAssistantController.to.activeSwapForLine(recipe.id, rawLine);
    if (swap != null) return _swappedIngredientRow(text, swap);

    final checked = _checkedIngredients.contains(index);
    final parts = _parseIngredient(text);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Grocery category icon (same emoji the Groceries screen uses),
          // detected from the ingredient name.
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.goldBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _ingredientEmoji(index, parts.$2),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          // Quantity (bold)
          if (parts.$1 != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 54),
              child: Text(
                "${parts.$1!}  ",
                style:
                    _font(
                      14,
                      FontWeight.w800,
                      checked ? _C.textHint : _C.textDark,
                    ).copyWith(
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
              ),
            ),
          ],
          // Name
          Expanded(
            child: Text(
              parts.$2,
              style:
                  _font(
                    14,
                    FontWeight.w500,
                    checked ? _C.textHint : _C.textBody,
                    h: 1.35,
                  ).copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// A swapped ingredient row: purple-tinted card, swap icon, the new line with
  /// a "SWAPPED" badge, the struck-through original ("was …"), and inline Undo.

  Widget _swappedIngredientRow(String text, SwapEntry swap) {
    final parts = _parseIngredient(text);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DAF9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE3FC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 17,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          // Title now gets the FULL remaining width, so it wraps cleanly
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (parts.$1 != null)
                        TextSpan(
                          text: '${parts.$1!} ',
                          style: _font(14, FontWeight.w800, _C.textDark),
                        ),
                      TextSpan(
                        text: parts.$2,
                        style: _font(14, FontWeight.w700, _C.textDark),
                      ),
                    ],
                  ),
                  style: const TextStyle(height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  'was ${swap.oldLine}',
                  style: _font(
                    12,
                    FontWeight.w500,
                    const Color(0xFF9A8FB0),
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
                const SizedBox(height: 5),
                // Bottom row: badge on left, Undo on right — its own dedicated row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE3FC),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'swapped'.tr,
                        style: _font(
                          9,
                          FontWeight.w800,
                          const Color(0xFF7A45E0),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await AiAssistantController.to.undoSwap(recipe, swap);
                        if (!mounted) return;
                        CustomSnackbar.show(
                          title: 'Undone',
                          message: 'Restored ${swap.oldName}.',
                          type: SnackbarType.info,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE3FC),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFFE6DAF9)),
                        ),
                        child: Text(
                          'undo'.tr,
                          style: _font(
                            12,
                            FontWeight.w800,
                            const Color(0xFF7A45E0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String?, String) _parseIngredient(String text) {
    final match = RegExp(
      r'^([\d½¼¾⅓⅔⅛⅜⅝⅞/.\s]+(?:\s*(?:cup|cups|tbsp|tsp|oz|lb|lbs|g|kg|ml|l|piece|pieces|clove|cloves|inch|pinch|bunch|handful|can|cans|packet|packets|slice|slices|medium|large|small)\b)?)\s+(.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final qty = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
    }
    final simple = RegExp(r'^([\d½¼¾⅓⅔⅛/.\s]+)\s+(.*)$').firstMatch(text);
    if (simple != null) {
      final qty = simple.group(1)!.trim();
      final rest = simple.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
    }
    return (null, text);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUCTIONS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_C.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'instructions'.tr,
            style: _font(18, FontWeight.w800, _C.textDark),
          ),
          const SizedBox(height: 6),
          // Steps rebuild reactively on unit change; serving changes rebuild the
          // whole screen via setState. Quantities + timers in the text scale to
          // match the ingredient list.
          Obx(() {
            final multiplier = _servings / _initialServings;
            final system = _settings.unitSystem;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildInstructionsList(multiplier, system),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionsList(double multiplier, UnitSystem system) {
    final instructionSections = _displayInstructionSections;
    final instructions = _displayInstructions;
    final hasSections = instructionSections.any((s) => s.steps.isNotEmpty);

    final widgets = <Widget>[];
    if (hasSections) {
      var stepNum = 1;
      for (final section in instructionSections) {
        if (section.steps.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.steps.length; i++) {
          widgets.add(
            _instructionRow(
              stepNum,
              InstructionScaler.scale(section.steps[i], multiplier, system),
            ),
          );
          stepNum++;
        }
      }
      return widgets;
    }

    for (var i = 0; i < instructions.length; i++) {
      widgets.add(
        _instructionRow(
          i + 1,
          InstructionScaler.scale(instructions[i], multiplier, system),
        ),
      );
    }
    return widgets;
  }

  Widget _instructionRow(int number, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            // padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _C.noteBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: _font(10, FontWeight.w800, _C.primary),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: _font(14, FontWeight.w500, _C.textBodyDark, h: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: _font(14, FontWeight.w800, _C.textDark),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COOK BUTTON (inline)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCookButton() {
    return GestureDetector(
      onTap: () => Get.to(
        () => CookModeScreen(recipe: recipe),
        transition: Transition.downToUp,
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _C.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.7),
              blurRadius: 26,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('play', color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Text(
              'cook_step_by_step'.tr,
              style: _font(16, FontWeight.w700, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUTRITION CARD (Plus — visual/locked)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNutritionCard() {
    // Nutrition is a Plus feature (design 32d). Plus members see the real
    // preview + can open the full flow; free users see the "NUTRITION · Per 1
    // serving" heading with a yellow "Subscribe now" banner and the donut/macros
    // blurred underneath (NutritionLockedCard) — tapping opens the upgrade
    // dialog. Values are estimated from the recipe ingredients by
    // NutritionEstimator, using the live serving count (_servings) so changing
    // the stepper recalculates without reopening (spec step 7). Reacts live to
    // the plan via Obx, so upgrading swaps in the real card immediately.
    // Estimate from the ENGLISH original: the food database is English-keyed, so
    // a translated ingredient line would miss and drop from the breakdown.
    // Display of the (English) ingredient names is translated separately.
    final n = NutritionController.to.calculateNutrition(
      _home.englishRecipe(recipe.id) ?? recipe,
      servingsOverride: _servings,
    );
    if (n.isEmpty) return const SizedBox.shrink();
    return Obx(() {
      final isPlus = SubscriptionService.instance.isPlusListenable.value;
      if (!isPlus) {
        return NutritionLockedCard(
          nutrition: n,
          onTap: () =>
              showUpgradeDialog(context, feature: 'nutrition_calculator'.tr),
        );
      }
      return NutritionPreviewCard(
        nutrition: n,
        servings: n.servings,
        onViewBreakdown: () {
          Get.to(
            () => NutritionScreen(recipeName: _displayTitle, nutrition: n),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        },
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS  (business logic preserved verbatim)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _shareRecipe() async {
    try {
      // -----------------------------------------
      // Wait for preload if still running
      // -----------------------------------------
      if (_cachedShareFile == null || !await _cachedShareFile!.exists()) {
        log('⏳ Waiting for share content...');

        await _prepareShareFile();
      }

      // -----------------------------------------
      // Final safety check
      // -----------------------------------------
      final shareFile = _cachedShareFile;

      if (shareFile == null || !await shareFile.exists()) {
        Get.snackbar('Error', 'Unable to prepare recipe for sharing.');
        return;
      }

      const appLink = 'https://yourapp.page.link/recipe';

      final shareText =
          '''
🍴 $_displayTitle

View the full recipe, ingredients, instructions and more in the app 👇

$appLink
''';

      await Share.shareXFiles(
        [XFile(shareFile.path)],
        text: shareText,
        subject: _displayTitle,
      );
    } catch (e, stackTrace) {
      log('❌ Share recipe error: $e', stackTrace: stackTrace);

      Get.snackbar('Error', 'Unable to share recipe. Please try again.');
    }
  }

  Widget _buildShareRecipeCard([Uint8List? imageBytes]) {
    final time =
        _firstNonEmpty([
          _displayTotalTime,
          _displayCookTime,
          _displayPrepTime,
        ]) ??
        '';

    return Material(
      color: Colors.white,
      child: SizedBox(
        width: 1080,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: _buildRecipeImage(imageBytes),
              ),
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        AppLogo(size: 42),
                        SizedBox(width: 16),
                        Text(
                          'Recipe-AI',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Text(
                      _displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        _shareInfoItem(
                          icon: Icons.people_outline,
                          title: 'Servings',
                          value: _displayServings ?? '-',
                        ),
                        const SizedBox(width: 24),
                        _shareInfoItem(
                          icon: Icons.access_time,
                          title: 'Time',
                          value: time.isEmpty ? '-' : time,
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),
                    const Divider(),
                    const SizedBox(height: 28),
                    const Text(
                      'View the full recipe in RecipeNest',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ingredients, instructions and more inside the app.',
                      style: TextStyle(fontSize: 26, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 28,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black,
                      ),
                      child: const Center(
                        child: Text(
                          'Download the app to view full recipe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Uint8List? imageBytes) {
    log("Image Bytes in Widget: ${imageBytes?.length}");

    if (imageBytes == null) {
      return _shareImagePlaceholder();
    }

    return SizedBox(
      width: 1080,
      height: 600,
      child: Image.memory(
        imageBytes,
        width: 1080,
        height: 600,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }

          return _shareImagePlaceholder();
        },
      ),
    );
  }

  Widget _shareImagePlaceholder() {
    return Container(
      width: 1080,
      height: 600,
      color: const Color(0xFFF0E6D6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        size: 100,
        color: Color(0xFFC7BCAC),
      ),
    );
  }

  // Overflow-safe info item — value 1 line + ellipsis, Expanded so Row ma
  // space properly divide thay
  Widget _shareInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGrocerySelectionSheet() {
    final system = _settings.unitSystem;
    final multiplier = _servings / _initialServings;
    // Display list (owner's language / viewer's translated language) — used
    // ONLY for rendering the checklist. Adding to the grocery store still
    // uses `recipe.ingredients` (the canonical English list) below, exactly
    // as before, so downstream grocery-emoji matching keeps working.
    final displayIngredients = _displayIngredients;
    final displaySections = _displayIngredientSections;
    // Compute the flat count from the display lists (sections or flat) so
    // selectedIndices length matches the rows the user actually sees.
    final hasSectionsForCount = displaySections.any((s) => s.items.isNotEmpty);
    final flatDisplayCount = hasSectionsForCount
        ? displaySections.fold<int>(0, (sum, s) => sum + s.items.length)
        : displayIngredients.length;
    final selectedIndices = List<bool>.generate(flatDisplayCount, (_) => true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801E1B18),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            final checkedCount = selectedIndices.where((c) => c).length;
            final hasSections = displaySections.any((s) => s.items.isNotEmpty);

            final widgets = <Widget>[];

            void toggleIndex(int idx) {
              setStateSheet(() {
                selectedIndices[idx] = !selectedIndices[idx];
              });
            }

            Widget selectionRow(String text, int globalIdx) {
              final isChecked = selectedIndices[globalIdx];
              final parts = _parseIngredient(text);
              return GestureDetector(
                onTap: () => toggleIndex(globalIdx),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _C.rowLine)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isChecked ? _C.primary : Colors.transparent,
                          border: isChecked
                              ? null
                              : Border.all(color: _C.borderInner, width: 2),
                        ),
                        child: isChecked
                            ? const Center(
                                child: OnboardingLineIcon(
                                  'check',
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.goldBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _ingredientEmoji(globalIdx, parts.$2),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (parts.$1 != null) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 54),
                          child: Text(
                            "${parts.$1!}  ",
                            style: _font(
                              14,
                              FontWeight.w800,
                              isChecked ? _C.textDark : _C.textHint,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          parts.$2,
                          style: _font(
                            14,
                            FontWeight.w500,
                            isChecked ? _C.textBody : _C.textHint,
                            h: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (hasSections) {
              int globalIdx = 0;
              for (final section in displaySections) {
                if (section.items.isEmpty) continue;
                if (section.name != null && section.name!.isNotEmpty) {
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Text(
                        section.name!.toUpperCase(),
                        style: _font(
                          11.5,
                          FontWeight.w800,
                          _C.primary,
                          ls: 0.8,
                        ),
                      ),
                    ),
                  );
                }
                for (var i = 0; i < section.items.length; i++) {
                  final scaled = UnitConverter.scaleAndConvert(
                    section.items[i],
                    multiplier,
                    system,
                  );
                  widgets.add(selectionRow(scaled, globalIdx));
                  globalIdx++;
                }
              }
            } else {
              for (var i = 0; i < displayIngredients.length; i++) {
                final scaled = UnitConverter.scaleAndConvert(
                  displayIngredients[i],
                  multiplier,
                  system,
                );
                widgets.add(selectionRow(scaled, i));
              }
            }

            final allChecked = selectedIndices.every((c) => c);

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E0D2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'add_to_groceries_title'.tr,
                              style: _font(
                                20,
                                FontWeight.w800,
                                _C.textDark,
                                ls: -0.4,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4F1EA),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const OnboardingLineIcon(
                                  'x',
                                  size: 17,
                                  color: _C.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'select_items_to_purchase'.tr,
                              style: _font(
                                13.5,
                                FontWeight.w600,
                                _C.textMedium,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setStateSheet(() {
                                  final target = !allChecked;
                                  for (
                                    var i = 0;
                                    i < selectedIndices.length;
                                    i++
                                  ) {
                                    selectedIndices[i] = target;
                                  }
                                });
                              },
                              child: Text(
                                allChecked
                                    ? 'deselect_all'.tr
                                    : 'select_all'.tr,
                                style: _font(13, FontWeight.w700, _C.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: _C.rowLine, height: 1, thickness: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      children: widgets,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      MediaQuery.of(ctx).padding.bottom + 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: _C.rowLine)),
                    ),
                    child: GestureDetector(
                      onTap: checkedCount == 0
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              final groceryController =
                                  Get.find<GroceryStore>();
                              final toAdd = <String>[];
                              // Build the flat canonical (English) list in the
                              // same section/flat order as the display list so
                              // indices stay 1:1 — grocery items are stored in
                              // English regardless of which language was shown.
                              final canonicalFlat = <String>[];
                              final canonSections = recipe.ingredientSections;
                              final hasCanonSections = canonSections.any(
                                (s) => s.items.isNotEmpty,
                              );
                              if (hasCanonSections) {
                                for (final s in canonSections) {
                                  canonicalFlat.addAll(s.items);
                                }
                              } else {
                                canonicalFlat.addAll(recipe.ingredients);
                              }
                              for (
                                var i = 0;
                                i < canonicalFlat.length &&
                                    i < selectedIndices.length;
                                i++
                              ) {
                                if (selectedIndices[i]) {
                                  final scaledIng =
                                      IngredientScaleHelper.scaleIngredient(
                                        canonicalFlat[i],
                                        multiplier,
                                      );
                                  toAdd.add(scaledIng);
                                }
                              }

                              groceryController.addFromRecipe(recipe.id, toAdd);

                              CustomSnackbar.show(
                                title: 'n_ingredients_added'.trParams({
                                  'count': '$checkedCount',
                                }),
                                actionText: 'view'.tr,
                                onAction: () {
                                  Get.offUntil(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HomeScreen(initialIndex: 3),
                                    ),
                                    (route) => route.isFirst,
                                  );
                                },
                              );
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: checkedCount == 0
                              ? const Color(0xFFF4F1EA)
                              : _C.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          checkedCount == 0
                              ? 'select_items_to_add'.tr
                              : checkedCount == 1
                              ? 'add_1_item_to_groceries'.tr
                              : 'add_n_items_to_groceries'.trParams({
                                  'count': '$checkedCount',
                                }),
                          style: _font(
                            15,
                            FontWeight.w700,
                            checkedCount == 0 ? _C.textHint : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD NOTE — bottom sheet (note kept in memory, matching prior behavior)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddNoteSheet() {
    final ctrl = TextEditingController(text: _note);
    final noteFormKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801E1B18),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E0D2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'add_a_note'.tr,
                      style: _font(20, FontWeight.w800, _C.textDark, ls: -0.4),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F1EA),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const OnboardingLineIcon(
                          'x',
                          size: 17,
                          color: _C.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    color: _C.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: StatefulBuilder(
                    builder: (c, setSheet) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: noteFormKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: TextFormField(
                              controller: ctrl,
                              autofocus: true,
                              maxLines: 4,
                              maxLength: 300,
                              keyboardType: TextInputType.multiline,
                              cursorColor: _C.primary,
                              validator: (v) => ValidationHelper.notes(
                                v,
                                max: 500,
                                field: 'Note',
                              ),
                              style: _font(
                                15,
                                FontWeight.w400,
                                _C.textDark,
                                h: 1.5,
                              ),
                              onChanged: (_) => setSheet(() {}),
                              decoration: InputDecoration(
                                hintText: 'note_hint_example'.tr,
                                hintStyle: _font(
                                  15,
                                  FontWeight.w400,
                                  _C.textHint,
                                  h: 1.5,
                                ),
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'saved_to_this_recipe'.tr,
                                style: _font(
                                  12,
                                  FontWeight.w600,
                                  const Color(0xFF9A938A),
                                ),
                              ),
                              Text(
                                '${ctrl.text.characters.length} / 300',
                                style: _font(
                                  12,
                                  FontWeight.w600,
                                  const Color(0xFFB0A899),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    if (!(noteFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final text = ctrl.text.trim();
                    setState(() => _note = text);
                    // Persist to Firestore so the note survives restarts.
                    _home.setNote(_recipe.id, text);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _C.primary.withValues(alpha: 0.7),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'save_note'.tr,
                        style: _font(17, FontWeight.w600, Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECIPE MENU — anchored dropdown popup
  // ═══════════════════════════════════════════════════════════════════════════

  void _showRecipeMenuPopup() {
    final topPad = MediaQuery.of(context).padding.top;
    final top = topPad + 8 + 42 + 10; // below the floating buttons
    setState(() => _menuOpen = true);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: const Color(0x661E1B18),
      transitionDuration: const Duration(milliseconds: 130),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Stack(
          children: [
            // Pointer arrow
            Positioned(
              top: top,
              right: 20,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: anim,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 222,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _C.border),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E1B18,
                            ).withValues(alpha: 0.28),
                            blurRadius: 50,
                            offset: const Offset(0, 24),
                            spreadRadius: -16,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuVisibilityRow(),
                          _menuDivider(),
                          _menuRow('share', 'share_recipe_link'.tr, () {
                            Navigator.pop(ctx);
                            _shareRecipe();
                          }),
                          _menuDivider(),
                          _menuRow('file', 'export_pdf'.tr, () {
                            Navigator.pop(ctx);
                            if (!SubscriptionService.instance.canExportPDF()) {
                              showUpgradeDialog(
                                context,
                                feature: 'export_pdf'.tr,
                              );
                            } else {
                              ExportPdfSheet.open(_recipe, note: _note);
                            }
                          }, plus: true),
                          _menuDivider(),
                          _menuRow('print', 'print_recipe'.tr, () {
                            Navigator.pop(ctx);
                            if (!SubscriptionService.instance
                                .canPrintRecipe()) {
                              showUpgradeDialog(
                                context,
                                feature: 'print_recipe'.tr,
                              );
                            } else {
                              ExportPdfSheet.open(_recipe, note: _note);
                            }
                          }, plus: true),
                          _menuDivider(),
                          _menuRow('trash', 'delete_recipe'.tr, () {
                            Navigator.pop(ctx);
                            _confirmDelete();
                          }, destructive: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  Widget _menuVisibilityRow() {
    return StatefulBuilder(
      builder: (ctx, setRow) {
        final isPublic = _isPublic;
        return InkWell(
          onTap: () {
            Get.back(); // close the menu, then confirm
            _toggleVisibility();
          },
          child: Container(
            color: isPublic ? _C.greenBg : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                OnboardingLineIcon(
                  isPublic ? 'globe' : 'lock',
                  size: 18,
                  color: isPublic ? _C.green : _C.textBody,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPublic ? 'public_recipe'.tr : 'private_recipe'.tr,
                    style: _font(15, FontWeight.w700, _C.textDark),
                  ),
                ),
                // Functional on/off switch
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 23,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isPublic ? _C.green : const Color(0xFFE7DECE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    alignment: isPublic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: _C.rowLine,
  );

  Widget _menuRow(
    String icon,
    String label,
    VoidCallback onTap, {
    bool plus = false,
    bool destructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            OnboardingLineIcon(
              icon,
              size: 18,
              color: destructive ? _C.primaryDark : _C.textBody,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _font(
                  15,
                  FontWeight.w600,
                  destructive ? _C.primaryDark : _C.textDark,
                ),
              ),
            ),
            if (plus && !SubscriptionService.instance.isPlus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE6FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'crown',
                      size: 10,
                      color: Color(0xFF7A45E0),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'PLUS',
                      style: _font(9, FontWeight.w800, const Color(0xFF7A45E0)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHEETS  (business logic preserved verbatim)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddToCookbookSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CookbookPickerSheet(
        cookbookController: Get.find<CookbookController>(),
        recipeId: recipe.id,
        recipeImageUrl: recipe.imageUrl,
      ),
    );
  }

  void _showMealPlanPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MealPlanPickerSheet(
        mealPlanController: Get.find<MealPlanController>(),
        recipe: recipe,
        displayTitle: _displayTitle,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: _C.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const OnboardingLineIcon(
                    'trash',
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'delete_this_recipe'.tr,
                  style: _font(18, FontWeight.w800, _C.textDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'delete_recipe_confirm'.trParams({'title': _displayTitle}),
                  textAlign: TextAlign.center,
                  style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: _C.border),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'cancel'.tr,
                              style: _font(15, FontWeight.w700, _C.textDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx); // close the confirm dialog
                          final deleted = await Get.find<HomeController>()
                              .deleteRecipe(recipe);
                          // On success, close the detail (and any recipe routes)
                          // back to Home — never leave a deleted recipe's detail
                          // in the stack.
                          if (deleted) {
                            Get.until((route) => route.isFirst);
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'delete'.tr,
                              style: _font(15, FontWeight.w700, Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEW: Translated Cookbook Chip (handles translation of cookbook names)
// ─────────────────────────────────────────────────────────────────────────────

class _TranslatedCookbookChip extends StatefulWidget {
  final CookbookModel cb;
  final VoidCallback onTap;

  const _TranslatedCookbookChip({required this.cb, required this.onTap});

  @override
  State<_TranslatedCookbookChip> createState() =>
      _TranslatedCookbookChipState();
}

class _TranslatedCookbookChipState extends State<_TranslatedCookbookChip> {
  String _translatedName = '';
  StreamSubscription<int>? _langSub;
  int _translationId = 0;

  @override
  void initState() {
    super.initState();
    _loadTranslation();
    _langSub = LanguageService.languageVersion.listen((_) {
      _loadTranslation();
    });
  }

  @override
  void didUpdateWidget(covariant _TranslatedCookbookChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cb.id != widget.cb.id ||
        oldWidget.cb.name != widget.cb.name) {
      _loadTranslation();
    }
  }

  @override
  void dispose() {
    _langSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTranslation() async {
    final currentId = ++_translationId;
    final name = widget.cb.name;
    try {
      final translated = await AiTranslationService.translateCookbookName(name);
      if (mounted && currentId == _translationId) {
        setState(() => _translatedName = translated);
      }
    } catch (e) {
      if (mounted && currentId == _translationId) {
        setState(() => _translatedName = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _translatedName.isNotEmpty
        ? _translatedName
        : widget.cb.name;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEE6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingLineIcon('book', size: 15, color: _C.primary),
            const SizedBox(width: 6),
            Text(displayName, style: _font(13, FontWeight.w700, _C.textBody)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MEAL PLAN PICKER SHEET (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class _MealPlanPickerSheet extends StatefulWidget {
  final MealPlanController mealPlanController;
  final RecipeModel recipe;

  /// The title to SHOW in this sheet (owner's original language, or the
  /// viewer's translated language) — the meal plan item itself is still
  /// saved with `recipe.title` (canonical English) below, unchanged.
  final String? displayTitle;

  const _MealPlanPickerSheet({
    required this.mealPlanController,
    required this.recipe,
    this.displayTitle,
  });

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);

  // Internal/database key — NEVER translate this.
  String _selectedMealType = 'Dinner';

  bool _isAdding = false;

  // Internal meal type keys.
  static const List<String> _mealTypeKeys = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Translated meal type names for UI.
  List<String> get _mealTypes => [
    'breakfast'.tr,
    'lunch'.tr,
    'dinner'.tr,
    'snack'.tr,
  ];

  static const Map<String, Color> _mealColors = {
    'Breakfast': Color(0xFFF59E0B),
    'Lunch': Color(0xFF10B981),
    'Dinner': Color(0xFF6366F1),
    'Snack': Color(0xFFEF4444),
  };

  static const Map<String, IconData> _mealIcons = {
    'Breakfast': Icons.wb_sunny_outlined,
    'Lunch': Icons.lunch_dining_outlined,
    'Dinner': Icons.dinner_dining_outlined,
    'Snack': Icons.cookie_outlined,
  };

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _title => widget.displayTitle ?? widget.recipe.title;

  // Get translated meal type from internal English key.
  String _translatedMealType(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return 'breakfast'.tr;
      case 'Lunch':
        return 'lunch'.tr;
      case 'Dinner':
        return 'dinner'.tr;
      case 'Snack':
        return 'snack'.tr;
      default:
        return mealType;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Calendar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _calendar(Color color) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final month = _visibleMonth;

    final firstOfMonth = DateTime(month.year, month.month, 1);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Monday-first.
    final leading = firstOfMonth.weekday - 1;

    // Do not allow going to a month completely before current month.
    final canGoPrev =
        month.year > today.year ||
        (month.year == today.year && month.month > today.month);

    final cells = <Widget>[];

    // Empty cells before first day.
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Days.
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);

      cells.add(
        _dayCell(
          date,
          d,
          isPast: date.isBefore(today),
          isSelected: _sameDay(date, _selectedDay),
          isToday: _sameDay(date, today),
          color: color,
        ),
      );
    }

    return Column(
      children: [
        // Month header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _navArrow(
                Icons.chevron_left,
                canGoPrev
                    ? () {
                        setState(() {
                          _visibleMonth = DateTime(month.year, month.month - 1);
                        });
                      }
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthNames[month.month - 1]} ${month.year}',
                    style: _font(15.5, FontWeight.w800, _C.textDark),
                  ),
                ),
              ),
              _navArrow(Icons.chevron_right, () {
                setState(() {
                  _visibleMonth = DateTime(month.year, month.month + 1);
                });
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Weekday header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: _font(11, FontWeight.w700, _C.textHint),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 4),

        // Day grid.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.05,
            children: cells,
          ),
        ),
      ],
    );
  }

  Widget _dayCell(
    DateTime date,
    int day, {
    required bool isPast,
    required bool isSelected,
    required bool isToday,
    required Color color,
  }) {
    return GestureDetector(
      onTap: isPast
          ? null
          : () {
              setState(() {
                _selectedDay = date;
              });
            },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: (isToday && !isSelected)
                ? Border.all(color: color, width: 1.4)
                : null,
          ),
          child: Text(
            '$day',
            style: _font(
              14,
              (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
              isSelected
                  ? Colors.white
                  : isPast
                  ? _C.textHint.withValues(alpha: 0.4)
                  : _C.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _C.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? _C.textDark : _C.textHint.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Confirm
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    setState(() {
      _isAdding = true;
    });

    try {
      await widget.mealPlanController.addMealPlanItem(
        date: _selectedDay,

        // IMPORTANT:
        // Save English/canonical value to database.
        mealType: _selectedMealType,

        recipeId: widget.recipe.id,

        // Keep canonical English recipe title in meal plan.
        recipeTitle: widget.recipe.title,

        recipeImageUrl: widget.recipe.imageUrl,
      );

      widget.mealPlanController.selectDate(_selectedDay);

      if (mounted) {
        Get.back();
      }

      CustomSnackbar.show(
        title: 'added_to_meal'.trParams({
          'meal': _translatedMealType(_selectedMealType),
        }),
        message: 'recipe_added_to_meal_plan'.trParams({'title': _title}),
        type: SnackbarType.success,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────────
                // Drag handle
                // ─────────────────────────────────────────
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                // ─────────────────────────────────────────
                // Header
                // ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'add_to_meal_plan'.tr,
                              style: _font(18, FontWeight.w800, _C.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _title,
                              style: _font(12, FontWeight.w500, _C.textMedium),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const OnboardingLineIcon(
                          'x',
                          size: 20,
                          color: _C.textMedium,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─────────────────────────────────────────
                // Date title
                // ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Text(
                    'select_date'.tr.toUpperCase(),
                    style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
                  ),
                ),

                // Calendar
                _calendar(_C.primary),

                const SizedBox(height: 20),

                // ─────────────────────────────────────────
                // Meal type title
                // ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Text(
                    'meal_type'.tr.toUpperCase(),
                    style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
                  ),
                ),

                // ─────────────────────────────────────────
                // Meal type tabs
                // ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: List.generate(_mealTypeKeys.length, (index) {
                      // English/database key.
                      final key = _mealTypeKeys[index];

                      // Translated/UI value.
                      final displayName = _mealTypes[index];

                      final selected = _selectedMealType == key;

                      final color = _mealColors[key]!;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // IMPORTANT:
                              // Store English key internally.
                              _selectedMealType = key;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? color
                                  : color.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              // Translated value.
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _font(
                                12.5,
                                selected ? FontWeight.w800 : FontWeight.w700,
                                selected ? Colors.white : color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // ─────────────────────────────────────────
                // Add button
                // ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _isAdding ? null : _confirm,
                    child: Container(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      decoration: BoxDecoration(
                        color: _C.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                      ),
                      child: Center(
                        child: _isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _mealIcons[_selectedMealType] ??
                                        Icons.restaurant,
                                    size: 18,
                                    color: Colors.white,
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    'add_to_meal'.trParams({
                                      'meal': _translatedMealType(
                                        _selectedMealType,
                                      ),
                                    }),
                                    style: _font(
                                      15,
                                      FontWeight.w700,
                                      Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COOKBOOK PICKER SHEET (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class CookbookPickerSheet extends StatefulWidget {
  final CookbookController cookbookController;
  final String recipeId;
  final String? recipeImageUrl;

  const CookbookPickerSheet({
    super.key,
    required this.cookbookController,
    required this.recipeId,
    required this.recipeImageUrl,
  });

  @override
  State<CookbookPickerSheet> createState() => _CookbookPickerSheetState();
}

class _CookbookPickerSheetState extends State<CookbookPickerSheet> {
  late final Set<String> _initial;
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = widget.cookbookController.cookbooks
        .where((c) => c.recipeIds.contains(widget.recipeId))
        .map((c) => c.id)
        .toSet();
    _selected.addAll(_initial);
  }

  Future<void> _apply() async {
    if (_saving) return;
    setState(() => _saving = true);
    final toAdd = _selected.difference(_initial);
    final toRemove = _initial.difference(_selected);
    for (final id in toAdd) {
      await widget.cookbookController.addRecipeToCookbook(
        id,
        widget.recipeId,
        widget.recipeImageUrl,
        showToast: false,
      );
    }
    for (final id in toRemove) {
      await widget.cookbookController.removeRecipeFromCookbook(
        id,
        widget.recipeId,
        showToast: false,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, _selected.length);
    if (toAdd.isNotEmpty) {
      CustomSnackbar.show(
        title: 'saved'.tr,
        message: toAdd.length == 1
            ? 'added_to_1_cookbook'.tr
            : 'added_to_n_cookbooks'.trParams({'count': '${toAdd.length}'}),
        type: SnackbarType.success,
      );
    } else if (toRemove.isNotEmpty) {
      CustomSnackbar.show(
        title: 'updated'.tr,
        message: 'cookbook_selection_updated'.tr,
        type: SnackbarType.success,
      );
    }
  }

  Widget _thumb(CookbookModel cb) {
    final home = Get.find<HomeController>();
    final imgs = <String>[];
    for (final id in cb.recipeIds) {
      final url = home.recipes.firstWhereOrNull((e) => e.id == id)?.imageUrl;
      if (url != null && url.isNotEmpty) imgs.add(url);
      if (imgs.length == 4) break;
    }
    Widget cell(int i) => i < imgs.length
        ? RecipeImage(imageUrl: imgs[i])
        : Container(color: const Color(0xFFE7DECE));
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5D7),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(0)),
                const SizedBox(width: 1),
                Expanded(child: cell(1)),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(2)),
                const SizedBox(width: 1),
                Expanded(child: cell(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Text(
                    'add_to_cookbook'.tr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2A211B),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F1EA),
                        shape: BoxShape.circle,
                      ),
                      child: const OnboardingLineIcon(
                        'x',
                        size: 19,
                        color: Color(0xFF8A7E70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: Obx(() {
                final cbs = widget.cookbookController.cookbooks;
                if (cbs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 16),
                    child: Text(
                      'no_cookbooks_yet_create'.tr,
                      style: _font(13.5, FontWeight.w500, _C.textMedium),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: cbs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) {
                    final cb = cbs[i];
                    final selected = _selected.contains(cb.id);
                    final count = cb.recipeIds.length;
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected
                            ? _selected.remove(cb.id)
                            : _selected.add(cb.id);
                      }),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFFF3EF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            _thumb(cb),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ Translated name
                                  _TranslatedCookbookName(cb: cb),
                                  const SizedBox(height: 1),
                                  Text(
                                    count == 1
                                        ? 'n_recipe'.trParams({
                                            'count': '$count',
                                          })
                                        : 'n_recipes'.trParams({
                                            'count': '$count',
                                          }),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF9A938A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                color: selected
                                    ? const Color(0xFFF2623E)
                                    : Colors.transparent,
                                border: selected
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE2D8C7),
                                        width: 2,
                                      ),
                              ),
                              child: selected
                                  ? const OnboardingLineIcon(
                                      'check',
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            GestureDetector(
              onTap: () {
                showNewCookbookSheet(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 42,
                      height: 42,
                      child: CustomPaint(
                        painter: _DashedRRectPainter(
                          color: Color(0xFFD8CFBE),
                          radius: 12,
                          strokeWidth: 1.5,
                        ),
                        child: Center(
                          child: OnboardingLineIcon(
                            'plus',
                            size: 22,
                            color: Color(0xFFF2623E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Text(
                      'new_cookbook'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF2623E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _apply,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2623E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF2623E).withValues(alpha: 0.4),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'done'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle border (for the "New cookbook" tile in design 36).
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUBLIC DELETE DIALOG (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

void showDeleteRecipeDialog(
  RecipeModel recipe,
  HomeController controller, {
  String? displayTitle,
}) {
  final title = displayTitle ?? recipe.title;
  Get.dialog(
    Dialog(
      backgroundColor: _C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const OnboardingLineIcon(
                'trash',
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'delete_this_recipe'.tr,
              style: _font(18, FontWeight.w800, _C.textDark),
            ),
            const SizedBox(height: 10),
            Text(
              'delete_recipe_confirm_short'.trParams({'title': title}),
              textAlign: TextAlign.center,
              style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: _C.border),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'cancel'.tr,
                          style: _font(15, FontWeight.w700, _C.textDark),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back(); // close the confirm dialog
                      final deleted = await controller.deleteRecipe(recipe);
                      if (deleted) {
                        Get.until((route) => route.isFirst);
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'delete'.tr,
                          style: _font(15, FontWeight.w700, Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// VISIBILITY CONFIRM DIALOG (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class _VisibilityConfirmDialog extends StatelessWidget {
  final bool makePublic;
  final VoidCallback onConfirm;

  const _VisibilityConfirmDialog({
    required this.makePublic,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final accent = makePublic ? _C.green : _C.primary;
    final title = makePublic
        ? 'make_recipe_public_q'.tr
        : 'make_recipe_private_q'.tr;
    final body = makePublic ? 'make_public_desc'.tr : 'make_private_desc'.tr;
    final action = makePublic ? 'make_public'.tr : 'make_private'.tr;

    return Dialog(
      backgroundColor: _C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: OnboardingLineIcon(
                  makePublic ? 'globe' : 'lock',
                  color: accent,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: _font(18, FontWeight.w800, _C.textDark)),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: _C.border),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: _font(15, FontWeight.w700, _C.textDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                      ),
                      child: Text(
                        action,
                        style: _font(15, FontWeight.w700, Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
//  Translated Cookbook Name (for picker sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _TranslatedCookbookName extends StatefulWidget {
  final CookbookModel cb;

  const _TranslatedCookbookName({required this.cb});

  @override
  State<_TranslatedCookbookName> createState() =>
      _TranslatedCookbookNameState();
}

class _TranslatedCookbookNameState extends State<_TranslatedCookbookName> {
  String _translatedName = '';
  StreamSubscription<int>? _langSub;
  int _translationId = 0;

  @override
  void initState() {
    super.initState();
    _loadTranslation();
    _langSub = LanguageService.languageVersion.listen((_) {
      _loadTranslation();
    });
  }

  @override
  void didUpdateWidget(covariant _TranslatedCookbookName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cb.id != widget.cb.id ||
        oldWidget.cb.name != widget.cb.name) {
      _loadTranslation();
    }
  }

  @override
  void dispose() {
    _langSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTranslation() async {
    final currentId = ++_translationId;
    final name = widget.cb.name;
    try {
      final translated = await AiTranslationService.translateCookbookName(name);
      if (mounted && currentId == _translationId) {
        setState(() => _translatedName = translated);
      }
    } catch (e) {
      if (mounted && currentId == _translationId) {
        setState(() => _translatedName = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _translatedName.isNotEmpty
        ? _translatedName
        : widget.cb.name;

    return Text(
      displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2A211B),
      ),
    );
  }
}
