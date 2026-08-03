import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Generate a recipe from just its name (AI). App-styled to match the rest of
/// the app: brand hero, styled input, gradient CTA and tappable suggestions.
class GenerateRecipeScreen extends StatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  State<GenerateRecipeScreen> createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  final TextEditingController recipeController = TextEditingController();
  final FocusNode _focus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  static const _suggestions = [
    'Paneer Butter Masala',
    'Pizza Margherita',
    'Chocolate Cake',
    'Chicken Biryani',
    'Pasta Alfredo',
  ];

  @override
  void dispose() {
    recipeController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final recipeName = recipeController.text.trim();
    if (recipeName.isEmpty) {
      CustomSnackbar.show(
        title: 'recipe_name_required'.tr,
        message: 'enter_dish_name_to_generate'.tr,
        type: SnackbarType.warning,
      );
      return;
    }
    _focus.unfocus();
    setState(() => _busy = true);
    final ok = await RecipeImportService.importRecipeFromName(recipeName);
    if (!mounted) return;
    setState(() => _busy = false);
    // Clear the field once the recipe was generated & the review screen shown,
    // so returning here starts fresh.
    if (ok) recipeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    const AppLogo(size: 78),
                    const SizedBox(height: 20),
                    Text(
                      'generate_recipe_by_name'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'generate_recipe_description'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _inputField(),
                    // Validation message shown OUTSIDE the field (below it).
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: recipeController,
                      builder: (context, value, _) {
                        final err = ValidationHelper.title(
                          value.text,
                          field: 'Recipe name',
                          min: 2,
                          max: 100,
                        );
                        if (value.text.isEmpty || err == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            err,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _generateButton(),
                    const SizedBox(height: 28),
                    _suggestionsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFEFEDE6)),
              ),
              child: const OnboardingLineIcon(
                'back',
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'generate_recipe'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const OnboardingLineIcon(
              'search',
              size: 22,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: recipeController,
                focusNode: _focus,
                keyboardType: TextInputType.text,
                inputFormatters: [...ValidationHelper.noLeadingSpace],
                validator: (v) => ValidationHelper.title(
                  v,
                  field: 'Recipe name',
                  min: 2,
                  max: 100,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _generateRecipe(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'recipe_name_hint'.tr,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  // Collapse the built-in error inside the box; shown below.
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateButton() {
    return GestureDetector(
      onTap: _busy ? null : _generateRecipe,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8763), AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Center(
          child: _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const OnboardingLineIcon(
                      'sparkF2',
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'generate_recipe'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _suggestionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                'try_one_of_these'.tr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in _suggestions) _chip(s)],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return GestureDetector(
      onTap: () {
        recipeController.text = text;
        recipeController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.unselectedBorder),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textBodyDark,
          ),
        ),
      ),
    );
  }
}
