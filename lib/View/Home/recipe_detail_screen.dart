import 'package:flutter/material.dart';
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
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const border = Color(0xFFEDE3D2);
  static const borderLight = Color(0xFFF4ECDF);
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textMedium = Color(0xFF8A7E70);
  static const textHint = Color(0xFFA89F90);
  static const textBody = Color(0xFF6B6359);
  static const green = Color(0xFF1F7A5E);
  static const greenBg = Color(0xFFEAF6F0);

  static const double outerPad = 16.0;
  static const double cardPad = 16.0;
  static const double cardRadius = 18.0;
  static const double cardSpacing = 14.0;
  static const double sectionSpacing = 20.0;
  static const double imageRadius = 28.0;
  static const double btnSize = 40.0;
}

TextStyle _font(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
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
  final GlobalKey _menuKey = GlobalKey();
  final Set<int> _checkedIngredients = {};

  RecipeModel get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    int parsed = 2;
    if (recipe.servings != null) {
      final m = RegExp(r'\d+').firstMatch(recipe.servings!);
      if (m != null) parsed = int.tryParse(m.group(0)!) ?? 2;
    }
    _initialServings = parsed <= 0 ? 2 : parsed;
    _servings = _initialServings;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final imageH = screenH * 0.38;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ──────────────────────────────────────
                _buildHeroImage(imageH),

                // ── Body content ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _C.outerPad, 16, _C.outerPad, 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(recipe.title, style: _font(22, FontWeight.w800, _C.textDark)),
                      const SizedBox(height: 6),

                      // Source
                      if (recipe.sourceUrl.isNotEmpty) ...[
                        _buildSourceRow(),
                        const SizedBox(height: 10),
                      ],

                      // Tags
                      _buildTags(),
                      const SizedBox(height: 14),

                      // Meta row
                      _buildMetaRow(),
                      const SizedBox(height: 16),

                      // Action buttons (Save, MealPlan, Share, Like)
                      _buildActionButtons(),
                      const SizedBox(height: _C.cardSpacing),

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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating top buttons ────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: _C.outerPad,
            right: _C.outerPad,
            child: Row(
              children: [
                _floatingBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                const Spacer(),
                _floatingBtn(Icons.edit_outlined, () => Get.to(() => RecipeEditorScreen(recipe: recipe))),
                const SizedBox(width: 10),
                _floatingBtn(Icons.more_horiz_rounded, _showRecipeMenuPopup, key: _menuKey),
              ],
            ),
          ),

          // ── Sticky bottom CTA ───────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                _C.outerPad, 12, _C.outerPad,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: _C.bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Get.to(
                  () => CookModeScreen(recipe: recipe),
                  transition: Transition.downToUp,
                ),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text('Cook step-by-step', style: _font(16, FontWeight.w700, Colors.white)),
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // HERO IMAGE (full-width, rounded bottom corners)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildHeroImage(double height) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(_C.imageRadius),
        bottomRight: Radius.circular(_C.imageRadius),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
            ? Image.network(recipe.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder())
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF0E6D6),
        child: const Center(child: Icon(Icons.restaurant_rounded, size: 60, color: Color(0xFFC7BCAC))),
      );

  // ── Floating circular button ─────────────────────────────────────────────

  Widget _floatingBtn(IconData icon, VoidCallback onTap, {Color? iconColor, GlobalKey? key}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: key,
        width: _C.btnSize,
        height: _C.btnSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? _C.textDark),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SOURCE ROW
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildSourceRow() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(recipe.sourceUrl);
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.language, color: Colors.white, size: 10),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _sourceLabel(recipe.sourceUrl),
              style: _font(12, FontWeight.w500, _C.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String url) {
    if (url.contains('instagram')) return 'from instagram.com';
    if (url.contains('tiktok')) return 'from tiktok.com';
    if (url.contains('facebook')) return 'from facebook.com';
    if (url.contains('gemini_image')) return 'from photo import';
    if (url.contains('recipe_name')) return 'AI generated recipe';
    if (url.startsWith('http')) {
      try { return 'from ${Uri.parse(url).host}'; } catch (_) {}
    }
    return 'from Recipe AI';
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // TAGS
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildTags() {
    return Row(
      children: [
        // Public
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.greenBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 13, color: _C.green),
              const SizedBox(width: 5),
              Text('Public', style: _font(11, FontWeight.w700, _C.green)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // AI-generated
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: _C.primary),
              const SizedBox(width: 5),
              Text('AI-generated', style: _font(11, FontWeight.w700, _C.primary)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // META ROW (time, servings, difficulty)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildMetaRow() {
    final time = recipe.totalTime ?? recipe.cookTime ?? recipe.prepTime ?? '';
    return Row(
      children: [
        if (time.isNotEmpty) ...[
          _metaItem(Icons.access_time_rounded, time),
          const SizedBox(width: 16),
        ],
        _metaItem(Icons.restaurant_outlined, '$_servings servings'),
        const SizedBox(width: 16),
        _metaItem(Icons.local_fire_department_outlined, 'Easy'),
      ],
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _C.textMedium),
        const SizedBox(width: 5),
        Text(label, style: _font(13, FontWeight.w600, _C.textMedium)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS (Save, Meal Plan, Share)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Row(
      children: [
        _actionBtn(Icons.bookmark_border_rounded, 'Cookbooks', _showAddToCookbookSheet),
        const SizedBox(width: 10),
        _actionBtn(Icons.calendar_today_outlined, 'Meal Plan', _showMealPlanPicker),
        const SizedBox(width: 10),
        _actionBtn(Icons.share_outlined, 'Share', _shareRecipe),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: _C.textMedium),
              const SizedBox(height: 4),
              Text(label, style: _font(10, FontWeight.w600, _C.textMedium)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // COOKBOOKS CARD
  // ═══════════════════════════════════════════════════════════════════════════════

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
            Text('Cookbooks', style: _font(17, FontWeight.w700, _C.textDark)),
            const SizedBox(height: 12),
            if (containing.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: containing.map((cb) {
                  return GestureDetector(
                    onTap: () => Get.to(() => CookbookRecipesScreen(cookbook: cb)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: SizedBox(
                              width: 22, height: 22,
                              child: RecipeImage(imageUrl: cb.imageUrl),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(cb.name, style: _font(13, FontWeight.w600, _C.textDark)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: _C.textHint),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              GestureDetector(
                onTap: _showAddToCookbookSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: _C.primary),
                    const SizedBox(width: 4),
                    Text('Add to cookbook', style: _font(13, FontWeight.w600, _C.primary)),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADD A NOTE CARD
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildNoteCard() {
    return GestureDetector(
      onTap: _showAddNoteDialog,
      child: Container(
        padding: const EdgeInsets.all(_C.cardPad),
        decoration: _cardDeco(),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 18, color: Color(0xFFD4A853)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a note',
                    style: _font(14, FontWeight.w700, _C.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _note.isEmpty ? 'Notes, swaps, reminders...' : _note,
                    style: _font(12, FontWeight.w400, _C.textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: _C.textHint),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // INGREDIENTS CARD
  // ═══════════════════════════════════════════════════════════════════════════════

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
              Text('Ingredients', style: _font(17, FontWeight.w700, _C.textDark)),
              const Spacer(),
              _buildStepper(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to check off · amounts scale with servings',
            style: _font(11, FontWeight.w400, _C.textHint),
          ),
          const SizedBox(height: 14),

          ..._buildIngredientsList(),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: _addToGroceries,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 18, color: _C.primary),
                  const SizedBox(width: 8),
                  Text('Add all to groceries', style: _font(14, FontWeight.w700, _C.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    final multiplier = _servings / _initialServings;
    final hasSections = recipe.ingredientSections.any((s) => s.items.isNotEmpty);

    if (hasSections) {
      final widgets = <Widget>[];
      int globalIdx = 0;
      for (final section in recipe.ingredientSections) {
        if (section.items.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.items.length; i++) {
          final scaled = IngredientScaleHelper.scaleIngredient(section.items[i], multiplier);
          widgets.add(_ingredientRow(scaled, globalIdx));
          if (i < section.items.length - 1) {
            widgets.add(Divider(height: 1, color: _C.borderLight));
          }
          globalIdx++;
        }
      }
      return widgets;
    }

    final widgets = <Widget>[];
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final scaled = IngredientScaleHelper.scaleIngredient(recipe.ingredients[i], multiplier);
      widgets.add(_ingredientRow(scaled, i));
      if (i < recipe.ingredients.length - 1) {
        widgets.add(Divider(height: 1, color: _C.borderLight));
      }
    }
    return widgets;
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, _servings > 1, () => setState(() => _servings--)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_servings', style: _font(16, FontWeight.w800, _C.textDark)),
          ),
          _stepBtn(Icons.add, true, () => setState(() => _servings++)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: enabled ? _C.primary.withValues(alpha: 0.1) : const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: enabled ? _C.primary : _C.textHint),
      ),
    );
  }

  Widget _ingredientRow(String text, int index) {
    final checked = _checkedIngredients.contains(index);
    final parts = _parseIngredient(text);

    return GestureDetector(
      onTap: () => setState(() {
        checked ? _checkedIngredients.remove(index) : _checkedIngredients.add(index);
      }),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: checked ? _C.primary : Colors.transparent,
                border: checked ? null : Border.all(color: _C.border, width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            // Bag icon
            Icon(Icons.shopping_bag_outlined, size: 18, color: _C.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            // Quantity (bold)
            if (parts.$1 != null)
              Text(
                parts.$1!,
                style: _font(14, FontWeight.w800, checked ? _C.textHint : _C.textDark).copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            if (parts.$1 != null) const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(
                parts.$2,
                style: _font(14, FontWeight.w500, checked ? _C.textHint : _C.textBody, h: 1.4).copyWith(
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
        caseSensitive: false)
        .firstMatch(text);
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // INSTRUCTIONS CARD
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_C.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructions', style: _font(17, FontWeight.w700, _C.textDark)),
          const SizedBox(height: 14),
          ..._buildInstructionsList(),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionsList() {
    final hasSections = recipe.instructionSections.any((s) => s.steps.isNotEmpty);

    if (hasSections) {
      final widgets = <Widget>[];
      var stepNum = 1;
      for (final section in recipe.instructionSections) {
        if (section.steps.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(_sectionHeader(section.name!));
        }
        for (var i = 0; i < section.steps.length; i++) {
          widgets.add(_instructionRow(stepNum, section.steps[i]));
          if (i < section.steps.length - 1) {
            widgets.add(Divider(height: 1, color: _C.borderLight));
          }
          stepNum++;
        }
      }
      return widgets;
    }

    final widgets = <Widget>[];
    for (var i = 0; i < recipe.instructions.length; i++) {
      widgets.add(_instructionRow(i + 1, recipe.instructions[i]));
      if (i < recipe.instructions.length - 1) {
        widgets.add(Divider(height: 1, color: _C.borderLight));
      }
    }
    return widgets;
  }

  Widget _instructionRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: _font(12, FontWeight.w700, Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: _font(14, FontWeight.w500, _C.textBody, h: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION HEADER (bullet + name)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(name, style: _font(14, FontWeight.w700, _C.textDark)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // CARD DECORATION
  // ═══════════════════════════════════════════════════════════════════════════════

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(_C.cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADD NOTE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════════

  void _showAddNoteDialog() {
    final ctrl = TextEditingController(text: _note);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: _C.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Add a note', style: _font(18, FontWeight.w800, _C.textDark)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 16, color: _C.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLines: 5,
                    style: _font(14, FontWeight.w400, _C.textDark),
                    decoration: InputDecoration(
                      hintText: 'I used 1 can of coconut milk for extra creaminess...',
                      hintStyle: _font(13, FontWeight.w400, _C.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() => _note = ctrl.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    ),
                    child: Center(
                      child: Text('Save note', style: AppTextStyles.buttonLabel),
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // RECIPE MENU POPUP
  // ═══════════════════════════════════════════════════════════════════════════════

  void _showRecipeMenuPopup() {
    final renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 140,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _C.card,
      elevation: 8,
      items: [
        _dropdownItem('share', Icons.share_outlined, 'Share ingredients'),
        _dropdownItem('pdf', Icons.picture_as_pdf_outlined, 'Export PDF'),
        _dropdownItem('plan', Icons.calendar_today_outlined, 'Plan recipe'),
        _dropdownItem('delete', Icons.delete_outline_rounded, 'Delete recipe', isDestructive: true),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'share': _shareRecipe();
        case 'plan': _showMealPlanPicker();
        case 'delete': _confirmDelete();
      }
    });
  }

  PopupMenuEntry<String> _dropdownItem(String value, IconData icon, String title, {bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.red : _C.textMedium),
          const SizedBox(width: 12),
          Text(title, style: _font(14, FontWeight.w600, isDestructive ? Colors.red : _C.textDark)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SHEETS
  // ═══════════════════════════════════════════════════════════════════════════════

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 20),
                Text('Delete this recipe?', style: _font(18, FontWeight.w800, _C.textDark)),
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
                            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                          ),
                          child: Center(child: Text('Cancel', style: _font(15, FontWeight.w700, _C.textDark))),
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
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
                          child: Center(child: Text('Delete', style: _font(15, FontWeight.w700, Colors.white))),
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

  const _MealPlanPickerSheet({required this.mealPlanController, required this.recipe});

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  DateTime _selectedDay = DateTime.now();
  String _selectedMealType = 'Dinner';
  bool _isAdding = false;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  static const Map<String, Color> _mealColors = {
    'Breakfast': Color(0xFFF59E0B), 'Lunch': Color(0xFF10B981),
    'Dinner': Color(0xFF6366F1), 'Snack': Color(0xFFEF4444),
  };
  static const Map<String, IconData> _mealIcons = {
    'Breakfast': Icons.wb_sunny_outlined, 'Lunch': Icons.lunch_dining_outlined,
    'Dinner': Icons.dinner_dining_outlined, 'Snack': Icons.cookie_outlined,
  };

  List<DateTime> get _days => List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) return 'Today';
    return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
  }
  bool _sameDay(DateTime a, DateTime b) => a.day == b.day && a.month == b.month && a.year == b.year;

  Future<void> _confirm() async {
    setState(() => _isAdding = true);
    try {
      await widget.mealPlanController.addMealPlanItem(
        date: _selectedDay, mealType: _selectedMealType,
        recipeId: widget.recipe.id, recipeTitle: widget.recipe.title,
        recipeImageUrl: widget.recipe.imageUrl,
      );
      if (mounted) Navigator.pop(context);
      CustomSnackbar.show(
        title: 'Added to $_selectedMealType',
        message: '${widget.recipe.title} added to meal plan',
        type: SnackbarType.success,
      );
    } catch (_) { setState(() => _isAdding = false); }
  }

  @override
  Widget build(BuildContext context) {
    final color = _mealColors[_selectedMealType] ?? _C.primary;
    return Container(
      decoration: const BoxDecoration(color: _C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 4), width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add to Meal Plan', style: _font(18, FontWeight.w800, _C.textDark)),
                const SizedBox(height: 2),
                Text(widget.recipe.title, style: _font(12, FontWeight.w500, _C.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.only(left: 20, bottom: 8), child: Text('SELECT DAY', style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8))),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (_, i) {
                final day = _days[i]; final sel = _sameDay(day, _selectedDay);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), width: 56,
                    decoration: BoxDecoration(color: sel ? color : _C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? color : _C.border)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_dayLabel(day), style: _font(11, FontWeight.w600, sel ? Colors.white.withValues(alpha: 0.85) : _C.textHint)),
                      const SizedBox(height: 4),
                      Text('${day.day}', style: _font(18, FontWeight.w800, sel ? Colors.white : _C.textDark)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.only(left: 20, bottom: 10), child: Text('MEAL TYPE', style: _font(11, FontWeight.w700, _C.textHint, ls: 0.8))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: _mealTypes.map((type) {
              final sel = _selectedMealType == type; final c = _mealColors[type]!;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _selectedMealType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: sel ? c.withValues(alpha: 0.12) : _C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? c : _C.border, width: sel ? 1.5 : 1)),
                  child: Column(children: [
                    Icon(_mealIcons[type]!, size: 20, color: sel ? c : _C.textHint),
                    const SizedBox(height: 4),
                    Text(type, style: _font(10, FontWeight.w600, sel ? c : _C.textHint)),
                  ]),
                ),
              ));
            }).toList()),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _isAdding ? null : _confirm,
              child: Container(
                width: double.infinity, height: AppDimensions.buttonHeight,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
                child: Center(child: _isAdding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_mealIcons[_selectedMealType] ?? Icons.restaurant, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Add to $_selectedMealType', style: _font(15, FontWeight.w700, Colors.white)),
                      ])),
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

class CookbookPickerSheet extends StatelessWidget {
  final CookbookController cookbookController;
  final String recipeId;
  final String? recipeImageUrl;

  const CookbookPickerSheet({super.key, required this.cookbookController, required this.recipeId, required this.recipeImageUrl});

  void _createAndAdd(BuildContext context) {
    final tc = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(color: _C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('New cookbook', style: _font(20, FontWeight.w800, _C.textDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: _C.primary, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              height: AppDimensions.inputHeight,
              decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(11), border: Border.all(color: _C.primary, width: 1.5)),
              child: TextField(controller: tc, autofocus: true, style: AppTextStyles.inputText, decoration: InputDecoration(hintText: 'e.g. Weekend Dinners', hintStyle: AppTextStyles.inputHint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final name = tc.text.trim(); if (name.isEmpty) return;
                Navigator.pop(ctx); Navigator.pop(context);
                await cookbookController.createCookbook(name);
                await Future.delayed(const Duration(milliseconds: 800));
                final nb = cookbookController.cookbooks.firstWhereOrNull((c) => c.name == name);
                if (nb != null) cookbookController.addRecipeToCookbook(nb.id, recipeId, recipeImageUrl);
              },
              child: Container(
                width: double.infinity, height: AppDimensions.buttonHeight,
                decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add, color: Colors.white, size: 20), const SizedBox(width: 8),
                  Text('Create cookbook', style: AppTextStyles.buttonLabel),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 14),
        Row(children: [
          Text('Add to cookbook', style: _font(18, FontWeight.w800, _C.textDark)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: Icon(Icons.close, size: 16, color: _C.textDark)),
          ),
        ]),
        const SizedBox(height: 18),
        Obx(() {
          final cbs = cookbookController.cookbooks;
          return ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: cbs.length, separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final cb = cbs[i]; final added = cb.recipeIds.contains(recipeId);
              return GestureDetector(
                onTap: added ? null : () { cookbookController.addRecipeToCookbook(cb.id, recipeId, recipeImageUrl); Navigator.pop(context); },
                behavior: HitTestBehavior.opaque,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 40, height: 40, child: RecipeImage(imageUrl: cb.imageUrl))),
                  const SizedBox(width: 14),
                  Expanded(child: Text(cb.name, style: _font(15, FontWeight.w600, _C.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: added ? _C.primary : Colors.transparent, border: added ? null : Border.all(color: _C.border, width: 1.5)),
                    child: added ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                ])),
              );
            },
          );
        }),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _createAndAdd(context),
          child: Row(children: [
            Icon(Icons.add, size: 18, color: _C.primary), const SizedBox(width: 6),
            Text('new cookbook', style: _font(14, FontWeight.w600, _C.primary)),
          ]),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: AppDimensions.buttonHeight,
            decoration: BoxDecoration(color: _C.primary, borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
            child: Center(child: Text('Close', style: AppTextStyles.buttonLabel)),
          ),
        ),
      ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28)),
          const SizedBox(height: 20),
          Text('Delete this recipe?', style: _font(18, FontWeight.w800, _C.textDark)),
          const SizedBox(height: 10),
          Text('Are you sure you want to delete "${recipe.title}"?', textAlign: TextAlign.center, style: _font(13.5, FontWeight.w400, _C.textMedium, h: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(height: 48, decoration: BoxDecoration(border: Border.all(color: _C.border), borderRadius: BorderRadius.circular(AppDimensions.radiusButton)), child: Center(child: Text('Cancel', style: _font(15, FontWeight.w700, _C.textDark)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () async { Get.back(); await controller.deleteRecipe(recipe); },
              child: Container(height: 48, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(AppDimensions.radiusButton)), child: Center(child: Text('Delete', style: _font(15, FontWeight.w700, Colors.white)))),
            )),
          ]),
        ]),
      ),
    ),
  );
}
