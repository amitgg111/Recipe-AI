import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';

class RecipeEditorScreen extends StatelessWidget {
  final RecipeModel? recipe;

  const RecipeEditorScreen({super.key, this.recipe});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      RecipeEditorController(recipe: recipe),
      tag: recipe?.id ?? 'new_recipe',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, controller),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image ──────────────────────────────────────────
                    _ImageSection(controller: controller),
                    const SizedBox(height: 24),

                    // ── Title ─────────────────────────────────────────
                    _label('LABEL'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: controller.titleController,
                      hint: 'Recipe name',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 20),

                    // ── Details row ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniField(
                            label: 'SERVINGS',
                            controller: controller.servingsController,
                            hint: '4',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniField(
                            label: 'PREP TIME',
                            controller: controller.prepTimeController,
                            hint: '15 min',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniField(
                            label: 'COOK TIME',
                            controller: controller.cookTimeController,
                            hint: '25 min',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Ingredients ───────────────────────────────────
                    _IngredientsEditor(controller: controller, recipe: recipe),
                    const SizedBox(height: 28),

                    // ── Instructions ──────────────────────────────────
                    _InstructionsEditor(controller: controller, recipe: recipe),
                    const SizedBox(height: 28),

                    // ── Visibility toggle ────────────────────────────
                    _VisibilityToggle(controller: controller),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, RecipeEditorController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(Icons.close, size: 18, color: AppColors.textDark),
            ),
          ),
          const Spacer(),
          Text(
            'Edit recipe',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          // Save pill
          Obx(() {
            return GestureDetector(
              onTap: controller.isSaving.value ? null : controller.saveRecipe,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  static Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textHint,
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: fontSize - 1,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  static Widget _buildMiniField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorderLight),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _ImageSection extends StatelessWidget {
  final RecipeEditorController controller;

  const _ImageSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImage = controller.imageFile.value != null ||
          controller.imagePath.value.isNotEmpty;

      Widget imageWidget;
      if (controller.imageFile.value != null) {
        imageWidget =
            Image.file(controller.imageFile.value!, fit: BoxFit.cover);
      } else if (controller.imagePath.value.isNotEmpty) {
        final p = controller.imagePath.value;
        imageWidget = p.startsWith('http')
            ? Image.network(p, fit: BoxFit.cover)
            : Image.file(File(p), fit: BoxFit.cover);
      } else {
        imageWidget = Container(
          color: const Color(0xFFF0E6D6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 36, color: AppColors.textHint),
                const SizedBox(height: 8),
                Text(
                  'Add photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: controller.pickImage,
        child: Container(
          height: 190,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorderLight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,
              if (hasImage) Container(color: Colors.black.withValues(alpha: 0.2)),
              if (hasImage)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Change photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: 6-dot drag handle
// ═══════════════════════════════════════════════════════════════════════════════

class _DragDots extends StatelessWidget {
  const _DragDots();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int r = 0; r < 3; r++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 3, height: 3, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.35), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(width: 3, height: 3, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.35), shape: BoxShape.circle)),
              ],
            ),
            if (r < 2) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: Section header (orange dot + bold name)
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String name;
  const _SectionHeader({required this.name});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.surfaceBorderLight, width: 1)),
              ),
              child: Text(name, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: Add button (+ Add ingredient / + Add step)
// ═══════════════════════════════════════════════════════════════════════════════

class _AddItemButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddItemButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary,
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: Add group button (centered, bordered pill)
// ═══════════════════════════════════════════════════════════════════════════════

class _AddGroupButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGroupButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceBorderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Add group', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INGREDIENTS EDITOR — section-grouped, pixel-perfect
// ═══════════════════════════════════════════════════════════════════════════════

class _IngredientsEditor extends StatelessWidget {
  final RecipeEditorController controller;
  final RecipeModel? recipe;

  const _IngredientsEditor({required this.controller, this.recipe});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.ingredientSections;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingredients', style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark,
            )),
            const SizedBox(height: 14),

            for (int si = 0; si < sections.length; si++) ...[
              _buildSection(si, sections[si]),
            ],

            const SizedBox(height: 14),
            _AddGroupButton(onTap: () => _showAddGroupSheet()),
          ],
        ),
      );
    });
  }

  Widget _buildSection(int sectionIdx, dynamic section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.name != null && section.name!.isNotEmpty)
          _SectionHeader(name: section.name!),

        for (int i = 0; i < section.items.length; i++)
          _ingredientCard(sectionIdx, i, section.items[i]),

        _AddItemButton(label: 'Add ingredient', onTap: () => _showAddItemSheet(sectionIdx)),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _ingredientCard(int sectionIdx, int itemIdx, String text) {
    final parts = _parseQty(text);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: Row(
        children: [
          const _DragDots(),
          const SizedBox(width: 10),
          // Quantity
          if (parts.$1.isNotEmpty) ...[
            SizedBox(
              width: 52,
              child: Text(parts.$1, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
              )),
            ),
          ],
          // Name
          Expanded(
            child: Text(
              parts.$2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textBody, height: 1.35,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),
          // Delete (trash icon)
          GestureDetector(
            onTap: () => controller.removeIngredientFromSection(sectionIdx, itemIdx),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(int sectionIdx) {
    final textCtrl = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'Add ingredient',
        hint: 'e.g. 2 cups flour',
        textController: textCtrl,
        onConfirm: () => controller.addIngredientToSection(sectionIdx, textCtrl.text),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAddGroupSheet() {
    final textCtrl = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'Add group',
        hint: 'e.g. For the sauce',
        textController: textCtrl,
        buttonLabel: 'Add group',
        onConfirm: () {
          final name = textCtrl.text.trim();
          if (name.isNotEmpty) controller.addIngredientGroup(name);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static (String, String) _parseQty(String text) {
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
    return ('', text);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSTRUCTIONS EDITOR — section-grouped, pixel-perfect
// ═══════════════════════════════════════════════════════════════════════════════

class _InstructionsEditor extends StatelessWidget {
  final RecipeEditorController controller;
  final RecipeModel? recipe;

  const _InstructionsEditor({required this.controller, this.recipe});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.instructionSections;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructions', style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark,
            )),
            const SizedBox(height: 14),

            for (int si = 0; si < sections.length; si++) ...[
              _buildSection(si, sections[si], sections),
            ],

            const SizedBox(height: 14),
            _AddGroupButton(onTap: () => _showAddGroupSheet()),
          ],
        ),
      );
    });
  }

  Widget _buildSection(int sectionIdx, dynamic section, List sections) {
    int stepNum = 1;
    for (int i = 0; i < sectionIdx; i++) {
      stepNum += (sections[i].steps as List).length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.name != null && section.name!.isNotEmpty)
          _SectionHeader(name: section.name!),

        for (int i = 0; i < section.steps.length; i++)
          _stepCard(sectionIdx, i, stepNum + i, section.steps[i]),

        _AddItemButton(label: 'Add step', onTap: () => _showAddStepSheet(sectionIdx)),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _stepCard(int sectionIdx, int stepIdx, int stepNumber, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: const _DragDots(),
          ),
          const SizedBox(width: 8),
          // Step number circle
          Container(
            width: 26, height: 26,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$stepNumber', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ),
          ),
          const SizedBox(width: 10),
          // Instruction text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textBody, height: 1.45,
              )),
            ),
          ),
          // Delete
          GestureDetector(
            onTap: () => controller.removeInstructionFromSection(sectionIdx, stepIdx),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStepSheet(int sectionIdx) {
    final textCtrl = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'Add step',
        hint: 'Describe this cooking step...',
        textController: textCtrl,
        maxLines: 4,
        onConfirm: () => controller.addInstructionToSection(sectionIdx, textCtrl.text),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAddGroupSheet() {
    final textCtrl = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'Add group',
        hint: 'e.g. For the dough',
        textController: textCtrl,
        buttonLabel: 'Add group',
        onConfirm: () {
          final name = textCtrl.text.trim();
          if (name.isNotEmpty) controller.addInstructionGroup(name);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════════
// VISIBILITY TOGGLE — Public / Private
// ═══════════════════════════════════════════════════════════════════════════════

class _VisibilityToggle extends StatelessWidget {
  final RecipeEditorController controller;
  const _VisibilityToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPublic = controller.isPublic.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPublic
                    ? AppColors.greenBgLight
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: isPublic ? AppColors.green : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPublic ? 'Public recipe' : 'Private recipe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPublic
                        ? 'Visible to everyone on Discover'
                        : 'Only visible to you',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => controller.isPublic.value = !isPublic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isPublic ? AppColors.green : AppColors.surfaceBorderLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: isPublic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// SHARED BOTTOM SHEET for add/edit
// ═══════════════════════════════════════════════════════════════════════════════

class _EditorBottomSheet extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController textController;
  final int maxLines;
  final String buttonLabel;
  final VoidCallback onConfirm;

  const _EditorBottomSheet({
    required this.title,
    required this.hint,
    required this.textController,
    this.maxLines = 1,
    this.buttonLabel = 'Add',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text field
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: TextField(
                controller: textController,
                maxLines: maxLines,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Confirm button
            GestureDetector(
              onTap: () {
                onConfirm();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusButton),
                ),
                child: Center(
                  child: Text(
                    buttonLabel,
                    style: AppTextStyles.buttonLabel,
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
