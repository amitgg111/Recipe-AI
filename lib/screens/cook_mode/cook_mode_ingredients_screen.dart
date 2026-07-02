import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeIngredientsScreen extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<CookIngredient>? ingredients;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const CookModeIngredientsScreen({
    super.key,
    this.currentStep = 3,
    this.totalSteps = 8,
    this.ingredients,
    this.onClose,
    this.onNext,
    this.onBack,
  });

  @override
  State<CookModeIngredientsScreen> createState() =>
      _CookModeIngredientsScreenState();
}

class _CookModeIngredientsScreenState extends State<CookModeIngredientsScreen> {
  late List<CookIngredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = widget.ingredients ??
        [
          const CookIngredient(name: '1 can (400ml) coconut milk'),
          const CookIngredient(name: '1 can (400g) chickpeas, drained'),
          const CookIngredient(name: '2 tbsp red curry paste'),
          const CookIngredient(name: '1 tbsp olive oil'),
          const CookIngredient(name: '1 medium onion, diced'),
          const CookIngredient(name: '3 cloves garlic, minced'),
        ];
  }

  void _toggleIngredient(int index) {
    setState(() {
      _ingredients[index] = CookIngredient(
        name: _ingredients[index].name,
        isChecked: !_ingredients[index].isChecked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildProgressBar(),
              const SizedBox(height: 32),
              _buildStepLabel(),
              const SizedBox(height: 20),
              Text(
                'Ingredients for this step',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildIngredientsList(),
              ),
              _buildBottomNav(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onClose ?? () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
            ),
            child: const Icon(Icons.close, size: 20, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.currentStep / widget.totalSteps;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE3D2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel() {
    return Text(
      'STEP ${widget.currentStep} OF ${widget.totalSteps}',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textMedium,
        letterSpacing: 0.04 * 13,
      ),
    );
  }

  Widget _buildIngredientsList() {
    return ListView.separated(
      itemCount: _ingredients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        return _buildIngredientTile(ingredient, index);
      },
    );
  }

  Widget _buildIngredientTile(CookIngredient ingredient, int index) {
    return GestureDetector(
      onTap: () => _toggleIngredient(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ingredient.isChecked
                ? AppColors.green.withValues(alpha: 0.3)
                : const Color(0xFFEFE6D6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ingredient.isChecked
                    ? AppColors.green
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: ingredient.isChecked
                      ? AppColors.green
                      : const Color(0xFFD5CDC1),
                  width: 2,
                ),
              ),
              child: ingredient.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                ingredient.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ingredient.isChecked
                      ? AppColors.textMedium
                      : AppColors.textDark,
                  decoration: ingredient.isChecked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack ?? () => Get.back(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DECE), width: 1),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Next step',
            leadingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            onPressed: widget.onNext,
          ),
        ),
      ],
    );
  }
}

class CookIngredient {
  final String name;
  final bool isChecked;

  const CookIngredient({
    required this.name,
    this.isChecked = false,
  });
}
