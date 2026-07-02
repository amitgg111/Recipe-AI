import 'package:flutter/material.dart';
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
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
  static const gold = Color(0xFFD98A12);
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
  const RecipeDetailScreen({super.key, required this.recipe});

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

  RecipeModel get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    _isPublic = recipe.isPublic;
    // Migration: back-fill `visibility` on legacy docs when opened.
    if (!recipe.visibilityWasStored) {
      Get.find<HomeController>()
          .migrateVisibility(recipe.id, recipe.visibility);
    }
    int parsed = 2;
    if (recipe.servings != null) {
      final m = RegExp(r'\d+').firstMatch(recipe.servings!);
      if (m != null) parsed = int.tryParse(m.group(0)!) ?? 2;
    }
    _initialServings = parsed <= 0 ? 2 : parsed;
    _servings = _initialServings;
  }

  // Ask for confirmation, then flip public/private (owner only).
  void _toggleVisibility() {
    final makePublic = !_isPublic;
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
      title: makePublic ? 'Recipe is now public' : 'Recipe is now private',
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
                      _C.outerPad,
                      6,
                      _C.outerPad,
                      34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recipe.title,
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
                _floatingBtn(
                  Icons.arrow_back_ios_new_rounded,
                  () => Navigator.pop(context),
                ),
                const Spacer(),
                _floatingBtn(
                  Icons.edit_outlined,
                  () => Get.to(() => RecipeEditorScreen(recipe: recipe)),
                ),
                const SizedBox(width: 9),
                _floatingBtn(
                  Icons.more_horiz_rounded,
                  _showRecipeMenuPopup,
                  active: _menuOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              ? Image.network(
                  recipe.imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
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

  Widget _floatingBtn(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
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
        child: Icon(icon, size: 20, color: active ? Colors.white : _C.textDark),
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
          const Icon(Icons.public, size: 15, color: _C.textHint),
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
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFFC7BCAC),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String url) {
    if (url.contains('instagram')) return 'From instagram.com';
    if (url.contains('tiktok')) return 'From tiktok.com';
    if (url.contains('facebook')) return 'From facebook.com';
    if (url.contains('gemini_image')) return 'From photo import';
    if (url.contains('recipe_name')) return 'AI generated recipe';
    if (url.startsWith('http')) {
      try {
        return 'From ${Uri.parse(url).host}';
      } catch (_) {}
    }
    return 'From Recipe AI';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VISIBILITY PILL  (reflects recipe.isPublic — tap opens editor to change)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVisibilityPill() {
    final isPublic = _isPublic;
    final fg = isPublic ? _C.green : _C.textMedium;
    final bg = isPublic ? _C.greenBg : _C.surfaceLight;
    final bd = isPublic ? _C.greenBorder : _C.border;
    return GestureDetector(
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
            Icon(
              isPublic ? Icons.public : Icons.lock_outline_rounded,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 7),
            Text(
              isPublic ? 'Public' : 'Private',
              style: _font(12.5, FontWeight.w800, fg),
            ),
            const SizedBox(width: 6),
            Text(
              '· tap to change',
              style: _font(11, FontWeight.w600, fg.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // META ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMetaRow() {
    final time = recipe.totalTime ?? recipe.cookTime ?? recipe.prepTime ?? '';
    final children = <Widget>[];
    if (time.isNotEmpty) {
      children.add(_metaItem(Icons.access_time_rounded, time));
    }
    children.add(_metaItem(Icons.people_alt_outlined, '$_servings servings'));
    children.add(_metaItem(Icons.auto_awesome_rounded, 'Easy'));

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

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _C.primary),
        const SizedBox(width: 6),
        Text(label, style: _font(13.5, FontWeight.w700, _C.textBody)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION TILES (Cookbook / Meal Plan / Share)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionTiles() {
    return Row(
      children: [
        _actionTile(
          Icons.menu_book_rounded,
          'Cookbook',
          _showAddToCookbookSheet,
        ),
        const SizedBox(width: 8),
        _actionTile(
          Icons.calendar_today_rounded,
          'Meal Plan',
          _showMealPlanPicker,
        ),
        const SizedBox(width: 8),
        _actionTile(Icons.ios_share_rounded, 'Share', _shareRecipe),
      ],
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _C.border),
              ),
              child: Icon(icon, size: 22, color: _C.primary),
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
            Text('Cookbooks', style: _font(18, FontWeight.w800, _C.textDark)),
            const SizedBox(height: 12),
            if (containing.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: containing.map((cb) {
                  return GestureDetector(
                    onTap: () =>
                        Get.to(() => CookbookRecipesScreen(cookbook: cb)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 15,
                            color: _C.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cb.name,
                            style: _font(13, FontWeight.w700, _C.textBody),
                          ),
                        ],
                      ),
                    ),
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
                    const Icon(Icons.add, size: 16, color: _C.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Add to cookbook',
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
              child: const Icon(Icons.edit_outlined, size: 18, color: _C.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? 'Your note' : 'Add a note',
                    style: _font(14, FontWeight.w700, _C.textDark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hasNote ? _note : 'Tweaks, swaps, reminders…',
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
            const Icon(
              Icons.chevron_right_rounded,
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
                'Ingredients',
                style: _font(18, FontWeight.w800, _C.textDark),
              ),
              const Spacer(),
              _buildStepper(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to check off · amounts scale with servings',
            style: _font(12, FontWeight.w500, const Color(0xFF9A938A)),
          ),
          const SizedBox(height: 12),
          _buildUnitsBanner(),
          const SizedBox(height: 4),
          ..._buildIngredientsList(),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _addToGroceries,
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
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 18,
                    color: _C.primary,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Add all to groceries',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        color: _C.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.purpleBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded, size: 16, color: _C.purple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Units',
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
          const Icon(
            Icons.workspace_premium_rounded,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text('PLUS', style: _font(9, FontWeight.w800, Colors.white)),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    final multiplier = _servings / _initialServings;
    final hasSections = recipe.ingredientSections.any(
      (s) => s.items.isNotEmpty,
    );

    final widgets = <Widget>[];
    if (hasSections) {
      int globalIdx = 0;
      for (final section in recipe.ingredientSections) {
        if (section.items.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.items.length; i++) {
          final scaled = IngredientScaleHelper.scaleIngredient(
            section.items[i],
            multiplier,
          );
          widgets.add(_ingredientRow(scaled, globalIdx));
          globalIdx++;
        }
      }
      return widgets;
    }

    for (var i = 0; i < recipe.ingredients.length; i++) {
      final scaled = IngredientScaleHelper.scaleIngredient(
        recipe.ingredients[i],
        multiplier,
      );
      widgets.add(_ingredientRow(scaled, i));
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
            Icons.remove,
            _servings > 1,
            () => setState(() => _servings--),
            _C.textDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                  'serv',
                  style: _font(10, FontWeight.w600, const Color(0xFF9A938A)),
                ),
              ],
            ),
          ),
          _stepBtn(
            Icons.add,
            true,
            () => setState(() => _servings++),
            _C.primary,
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
    IconData icon,
    bool enabled,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 16, color: enabled ? color : _C.textHint),
      ),
    );
  }

  Widget _ingredientRow(String text, int index) {
    final checked = _checkedIngredients.contains(index);
    final parts = _parseIngredient(text);

    return GestureDetector(
      onTap: () => setState(() {
        checked
            ? _checkedIngredients.remove(index)
            : _checkedIngredients.add(index);
      }),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _C.rowLine)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: checked ? _C.primary : Colors.transparent,
                border: checked
                    ? null
                    : Border.all(color: _C.borderInner, width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            // Basket icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _C.goldBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 15,
                color: _C.gold,
              ),
            ),
            const SizedBox(width: 12),
            // Quantity (bold)
            if (parts.$1 != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 54),
                child: Text(
                  parts.$1!,
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
          Text('Instructions', style: _font(18, FontWeight.w800, _C.textDark)),
          const SizedBox(height: 6),
          ..._buildInstructionsList(),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionsList() {
    final hasSections = recipe.instructionSections.any(
      (s) => s.steps.isNotEmpty,
    );

    final widgets = <Widget>[];
    if (hasSections) {
      var stepNum = 1;
      for (final section in recipe.instructionSections) {
        if (section.steps.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.steps.length; i++) {
          widgets.add(_instructionRow(stepNum, section.steps[i]));
          stepNum++;
        }
      }
      return widgets;
    }

    for (var i = 0; i < recipe.instructions.length; i++) {
      widgets.add(_instructionRow(i + 1, recipe.instructions[i]));
    }
    return widgets;
  }

  Widget _instructionRow(int number, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 9, 0, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: _C.noteBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: _font(13, FontWeight.w800, _C.primary),
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
          Text(name, style: _font(14, FontWeight.w800, _C.textDark)),
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
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Text(
              'Cook step-by-step',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_C.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUTRITION',
            style: _font(13, FontWeight.w800, _C.primary, ls: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            'Per 1 serving',
            style: _font(12.5, FontWeight.w500, const Color(0xFF9A938A)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1C9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: _C.purple,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _font(
                        13.5,
                        FontWeight.w500,
                        _C.textBodyDark,
                        h: 1.45,
                      ),
                      children: [
                        const TextSpan(text: 'This is a Plus feature. '),
                        TextSpan(
                          text: 'Subscribe now',
                          style: _font(13.5, FontWeight.w800, _C.purple),
                        ),
                        const TextSpan(
                          text: " to unlock Recipe AI's nutrition calculator!",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(
              opacity: 0.85,
              child: Row(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFF2A24C),
                          Color(0xFFF2A24C),
                          Color(0xFFF08FB0),
                          Color(0xFFF08FB0),
                          Color(0xFF7FD0A8),
                          Color(0xFF7FD0A8),
                        ],
                        stops: [0.0, 0.46, 0.46, 0.72, 0.72, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '430',
                            style: _font(
                              18,
                              FontWeight.w800,
                              const Color(0xFF9A938A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      children: [
                        _nutriBar(const Color(0xFFF08FB0)),
                        const SizedBox(height: 14),
                        _nutriBar(const Color(0xFFF2A24C)),
                        const SizedBox(height: 14),
                        _nutriBar(const Color(0xFF7FD0A8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutriBar(Color dot) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D8C7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 34,
              height: 7,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS  (business logic preserved verbatim)
  // ═══════════════════════════════════════════════════════════════════════════

  void _shareRecipe() {
    final buf = StringBuffer();
    buf.writeln(recipe.title);
    buf.writeln();
    if (recipe.description != null && recipe.description!.isNotEmpty) {
      buf.writeln(recipe.description);
      buf.writeln();
    }
    buf.writeln('INGREDIENTS');
    for (final ing in recipe.ingredients) {
      buf.writeln('• $ing');
    }
    buf.writeln();
    buf.writeln('INSTRUCTIONS');
    for (var i = 0; i < recipe.instructions.length; i++) {
      buf.writeln('${i + 1}. ${recipe.instructions[i]}');
    }
    if (recipe.sourceUrl.isNotEmpty) {
      buf.writeln();
      buf.writeln('Source: ${recipe.sourceUrl}');
    }
    Share.share(buf.toString(), subject: recipe.title);
  }

  void _addToGroceries() {
    final groceryController = Get.find<GroceryStore>();
    final multiplier = _servings / _initialServings;
    final scaled = recipe.ingredients
        .map((i) => IngredientScaleHelper.scaleIngredient(i, multiplier))
        .toList();
    groceryController.addFromRecipe(recipe.id, scaled);
    CustomSnackbar.show(
      title: '${recipe.ingredients.length} ingredients added to groceries',
      actionText: 'View',
      onAction: () {
        HomeScreen.activeIndex = 3;
        Get.offUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => route.isFirst,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD NOTE — bottom sheet (note kept in memory, matching prior behavior)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddNoteSheet() {
    final ctrl = TextEditingController(text: _note);
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
                      'Add a note',
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
                        child: const Icon(
                          Icons.close,
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
                          TextField(
                            controller: ctrl,
                            autofocus: true,
                            maxLines: 4,
                            maxLength: 300,
                            cursorColor: _C.primary,
                            style: _font(
                              15,
                              FontWeight.w400,
                              _C.textDark,
                              h: 1.5,
                            ),
                            onChanged: (_) => setSheet(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  'Used 1.5 cans of coconut milk for extra sauce…',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saved to this recipe',
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
                    setState(() => _note = ctrl.text.trim());
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
                        'Save note',
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
              top: top - 6,
              right: 30,
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: _C.border),
                      top: BorderSide(color: _C.border),
                    ),
                  ),
                ),
              ),
            ),
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
                          _menuRow(
                            Icons.ios_share_rounded,
                            'Share recipe link',
                            () {
                              Navigator.pop(ctx);
                              _shareRecipe();
                            },
                          ),
                          _menuDivider(),
                          _menuRow(
                            Icons.description_outlined,
                            'Export PDF',
                            () => Navigator.pop(ctx),
                            plus: true,
                          ),
                          _menuDivider(),
                          _menuRow(
                            Icons.print_outlined,
                            'Print recipe',
                            () => Navigator.pop(ctx),
                            plus: true,
                          ),
                          _menuDivider(),
                          _menuRow(
                            Icons.delete_outline_rounded,
                            'Delete recipe',
                            () {
                              Navigator.pop(ctx);
                              _confirmDelete();
                            },
                            destructive: true,
                          ),
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
            Navigator.pop(context); // close the menu, then confirm
            _toggleVisibility();
          },
          child: Container(
            color: isPublic ? _C.greenBg : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isPublic ? Icons.public : Icons.lock_outline_rounded,
                  size: 18,
                  color: isPublic ? _C.green : _C.textBody,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPublic ? 'Public recipe' : 'Private recipe',
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
    IconData icon,
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
            Icon(
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
            if (plus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE6FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
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
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Delete this recipe?',
                  style: _font(18, FontWeight.w800, _C.textDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete "${recipe.title}"? This action cannot be undone.',
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
                              'Cancel',
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
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          await Get.find<HomeController>().deleteRecipe(recipe);
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
                              'Delete',
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

// ═══════════════════════════════════════════════════════════════════════════════
// MEAL PLAN PICKER SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _MealPlanPickerSheet extends StatefulWidget {
  final MealPlanController mealPlanController;
  final RecipeModel recipe;

  const _MealPlanPickerSheet({
    required this.mealPlanController,
    required this.recipe,
  });

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  DateTime _selectedDay = DateTime.now();
  String _selectedMealType = 'Dinner';
  bool _isAdding = false;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
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

  List<DateTime> get _days =>
      List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return 'Today';
    }
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  Future<void> _confirm() async {
    setState(() => _isAdding = true);
    try {
      await widget.mealPlanController.addMealPlanItem(
        date: _selectedDay,
        mealType: _selectedMealType,
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
        recipeImageUrl: widget.recipe.imageUrl,
      );
      if (mounted) Navigator.pop(context);
      CustomSnackbar.show(
        title: 'Added to $_selectedMealType',
        message: '${widget.recipe.title} added to meal plan',
        type: SnackbarType.success,
      );
    } catch (_) {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _mealColors[_selectedMealType] ?? _C.primary;
    return Container(
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Meal Plan',
                        style: _font(18, FontWeight.w800, _C.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.recipe.title,
                        style: _font(12, FontWeight.w500, _C.textMedium),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              'SELECT DAY',
              style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (_, i) {
                final day = _days[i];
                final sel = _sameDay(day, _selectedDay);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 56,
                    decoration: BoxDecoration(
                      color: sel ? color : _C.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? color : _C.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayLabel(day),
                          style: _font(
                            11,
                            FontWeight.w600,
                            sel
                                ? Colors.white.withValues(alpha: 0.85)
                                : _C.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: _font(
                            18,
                            FontWeight.w800,
                            sel ? Colors.white : _C.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Text(
              'MEAL TYPE',
              style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _mealTypes.map((type) {
                final sel = _selectedMealType == type;
                final c = _mealColors[type]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMealType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? c.withValues(alpha: 0.12) : _C.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? c : _C.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _mealIcons[type]!,
                            size: 20,
                            color: sel ? c : _C.textHint,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type,
                            style: _font(
                              10,
                              FontWeight.w600,
                              sel ? c : _C.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _isAdding ? null : _confirm,
              child: Container(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                decoration: BoxDecoration(
                  color: color,
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
                              _mealIcons[_selectedMealType] ?? Icons.restaurant,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add to $_selectedMealType',
                              style: _font(15, FontWeight.w700, Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COOKBOOK PICKER SHEET
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
        title: 'Saved',
        message: toAdd.length == 1
            ? 'Added to 1 cookbook'
            : 'Added to ${toAdd.length} cookbooks',
        type: SnackbarType.success,
      );
    } else if (toRemove.isNotEmpty) {
      CustomSnackbar.show(
        title: 'Updated',
        message: 'Cookbook selection updated',
        type: SnackbarType.success,
      );
    }
  }

  // Create a cookbook and auto-select it in the list.
  void _createCookbook() {
    final tc = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('New cookbook',
                      style: _font(20, FontWeight.w800, _C.textDark)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: _C.primary, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: AppDimensions.inputHeight,
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _C.primary, width: 1.5),
                ),
                child: TextField(
                  controller: tc,
                  autofocus: true,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'e.g. Weekend Dinners',
                    hintStyle: AppTextStyles.inputHint,
                    filled: false,
                    isDense: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final name = tc.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  await widget.cookbookController.createCookbook(name);
                  await Future.delayed(const Duration(milliseconds: 800));
                  final nb = widget.cookbookController.cookbooks
                      .firstWhereOrNull((c) => c.name == name);
                  if (nb != null && mounted) {
                    setState(() => _selected.add(nb.id));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Create cookbook', style: AppTextStyles.buttonLabel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add to cookbook',
                      style: _font(18, FontWeight.w800, _C.textDark)),
                  const SizedBox(height: 2),
                  Text('Select one or more',
                      style: _font(12.5, FontWeight.w500, _C.textMedium)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: _C.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Obx(() {
              final cbs = widget.cookbookController.cookbooks;
              if (cbs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No cookbooks yet — create one below.',
                      style: _font(13.5, FontWeight.w500, _C.textMedium)),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: cbs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final cb = cbs[i];
                  final selected = _selected.contains(cb.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selected.remove(cb.id) : _selected.add(cb.id);
                    }),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: RecipeImage(imageUrl: cb.imageUrl),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              cb.name,
                              style: _font(15, FontWeight.w600, _C.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: selected ? _C.primary : Colors.transparent,
                              border: selected
                                  ? null
                                  : Border.all(color: _C.borderInner, width: 2),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 15)
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _createCookbook,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: _C.primary),
                const SizedBox(width: 6),
                Text('New cookbook',
                    style: _font(14, FontWeight.w700, _C.primary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _apply,
            child: Container(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Done'
                            : 'Save to ${_selected.length} cookbook${_selected.length == 1 ? '' : 's'}',
                        style: AppTextStyles.buttonLabel,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUBLIC DELETE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

void showDeleteRecipeDialog(RecipeModel recipe, HomeController controller) {
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
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delete this recipe?',
              style: _font(18, FontWeight.w800, _C.textDark),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to delete "${recipe.title}"?',
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
                          'Cancel',
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
                      Get.back();
                      await controller.deleteRecipe(recipe);
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
                          'Delete',
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
// VISIBILITY CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _VisibilityConfirmDialog extends StatelessWidget {
  final bool makePublic;
  final VoidCallback onConfirm;

  const _VisibilityConfirmDialog(
      {required this.makePublic, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final accent = makePublic ? _C.green : _C.primary;
    final title =
        makePublic ? 'Make this recipe public?' : 'Make this recipe private?';
    final body = makePublic
        ? 'Everyone will be able to discover and view it.'
        : 'Only you will be able to access it.';
    final action = makePublic ? 'Make Public' : 'Make Private';

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
              child: Icon(makePublic ? Icons.public : Icons.lock_outline_rounded,
                  color: accent, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: _font(18, FontWeight.w800, _C.textDark)),
            const SizedBox(height: 10),
            Text(body,
                textAlign: TextAlign.center,
                style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: _C.border),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusButton),
                      ),
                      child:
                          Text('Cancel', style: _font(15, FontWeight.w700, _C.textDark)),
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
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusButton),
                      ),
                      child: Text(action,
                          style: _font(15, FontWeight.w700, Colors.white)),
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
