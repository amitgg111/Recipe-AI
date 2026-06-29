import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';

class ImportCompleteScreen extends StatelessWidget {
  final RecipeModel recipe;

  const ImportCompleteScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Recipe image header
          if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF0E6D6),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    size: 60,
                    color: AppColors.iconLight,
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                color: const Color(0xFFF0E6D6),
                child: const Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 60,
                    color: AppColors.iconLight,
                  ),
                ),
              ),
            ),

          // Gradient over image bottom
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Top bar: close + "Imported" badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Imported',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content area
          Positioned(
            top: 260,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI notice banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI pulled this from Instagram. Check the details. I like to sure.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recipe title
                  Text(
                    recipe.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Source tag
                  if (recipe.sourceUrl.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sourceLabel(recipe.sourceUrl),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'recipe app',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Meta row: time, servings, flag
                  Row(
                    children: [
                      if (recipe.totalTime != null ||
                          recipe.cookTime != null) ...[
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.totalTime ?? recipe.cookTime ?? '',
                          style: AppTextStyles.smallLabel.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (recipe.servings != null) ...[
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} servings',
                          style: AppTextStyles.smallLabel.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (recipe.cuisine != null) ...[
                        const Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.cuisine!,
                          style: AppTextStyles.smallLabel.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Ingredients ──────────────────────────────────────────
                  _SectionHeader(
                    title: 'Ingredients',
                    trailing: '${recipe.ingredients.length} found',
                  ),
                  const SizedBox(height: 14),
                  ..._buildIngredients(),
                  const SizedBox(height: 28),

                  // ── Instructions ─────────────────────────────────────────
                  _SectionHeader(
                    title: 'Instructions',
                    trailing: '${recipe.instructions.length} steps',
                  ),
                  const SizedBox(height: 14),
                  ..._buildInstructions(),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.surfaceBorderLight),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save to cookbook button
                  GestureDetector(
                    onTap: () => _showCookbookPicker(context),
                    child: Container(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryShadow,
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bookmark_add_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save to cookbook',
                            style: AppTextStyles.buttonLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Edit before saving
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => RecipeDetailScreen(recipe: recipe));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit before saving',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
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

  String _sourceLabel(String sourceUrl) {
    if (sourceUrl.contains('instagram')) return '#Instagram';
    if (sourceUrl.contains('tiktok')) return '#TikTok';
    if (sourceUrl.contains('facebook')) return '#Facebook';
    if (sourceUrl.contains('gemini_image')) return '#Photo import';
    if (sourceUrl.contains('recipe_name')) return '#Generated';
    return '#Imported';
  }

  List<Widget> _buildIngredients() {
    final hasAnySections = recipe.ingredientSections
        .any((s) => s.items.isNotEmpty);

    if (hasAnySections) {
      final widgets = <Widget>[];
      for (final section in recipe.ingredientSections) {
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                '${section.name}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        for (final item in section.items) {
          widgets.add(_IngredientRow(text: item));
        }
      }
      return widgets;
    }

    return recipe.ingredients
        .map((ing) => _IngredientRow(text: ing))
        .toList();
  }

  List<Widget> _buildInstructions() {
    final hasSectionSteps = recipe.instructionSections
        .any((s) => s.steps.isNotEmpty);

    if (hasSectionSteps) {
      final widgets = <Widget>[];
      var stepNum = 1;
      for (final section in recipe.instructionSections) {
        if (section.steps.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                '${section.name}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        for (final step in section.steps) {
          widgets.add(_InstructionRow(number: stepNum, text: step));
          stepNum++;
        }
      }
      return widgets;
    }

    return recipe.instructions.asMap().entries.map((e) {
      return _InstructionRow(number: e.key + 1, text: e.value);
    }).toList();
  }

  void _showCookbookPicker(BuildContext context) {
    final cookbookCtrl = Get.find<CookbookController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CookbookPickerSheet(
        cookbookController: cookbookCtrl,
        recipeId: recipe.id,
        recipeImageUrl: recipe.imageUrl,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header with trailing count
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          child: Text(
            trailing,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient row with bullet
// ─────────────────────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final String text;

  const _IngredientRow({required this.text});

  @override
  Widget build(BuildContext context) {
    // Parse quantity + unit + ingredient
    final parts = _parseIngredient(text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          if (parts.quantity != null) ...[
            Text(
              parts.quantity!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              parts.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textBody,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _IngredientParts _parseIngredient(String text) {
    final match = RegExp(r'^([\d½¼¾⅓⅔⅛/.\s]+)\s*(.*)$').firstMatch(text);
    if (match != null) {
      final qty = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) {
        return _IngredientParts(quantity: qty, name: rest);
      }
    }
    return _IngredientParts(quantity: null, name: text);
  }
}

class _IngredientParts {
  final String? quantity;
  final String name;
  _IngredientParts({required this.quantity, required this.name});
}

// ─────────────────────────────────────────────────────────────────────────────
// Instruction row with step number
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionRow extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Step text
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
