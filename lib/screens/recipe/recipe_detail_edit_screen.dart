import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/recipe/set_step_timer_sheet.dart';

class RecipeDetailEditScreen extends StatefulWidget {
  const RecipeDetailEditScreen({super.key});

  @override
  State<RecipeDetailEditScreen> createState() => _RecipeDetailEditScreenState();
}

class _RecipeDetailEditScreenState extends State<RecipeDetailEditScreen> {
  final _titleController = TextEditingController(
    text: 'Coconut Chickpea Curry',
  );
  final _servingsController = TextEditingController(text: '2');
  final _timeController = TextEditingController(text: '35 min');

  final List<_EditIngredientGroup> _ingredientGroups = [
    _EditIngredientGroup(
      name: 'Curry Base',
      items: [
        _EditIngredient(amount: '1 can', name: 'coconut milk (400ml)'),
        _EditIngredient(amount: '1 can', name: 'chickpeas, drained'),
        _EditIngredient(amount: '2 tbsp', name: 'curry paste'),
        _EditIngredient(amount: '1 tbsp', name: 'olive oil'),
      ],
    ),
    _EditIngredientGroup(
      name: 'Vegetables',
      items: [
        _EditIngredient(amount: '1 cup', name: 'baby spinach'),
        _EditIngredient(amount: '1', name: 'red bell pepper, diced'),
        _EditIngredient(amount: '½', name: 'onion, diced'),
      ],
    ),
  ];

  final List<_EditInstruction> _instructions = [
    _EditInstruction(
      'Heat olive oil in a large pan over medium heat. Add diced onion and cook until translucent.',
    ),
    _EditInstruction('Add curry paste and stir for 1 minute until fragrant.'),
    _EditInstruction(
      'Pour in coconut milk and bring to a simmer. Add chickpeas and bell pepper.',
    ),
    _EditInstruction('Cook for 15 minutes, stirring occasionally.'),
    _EditInstruction('Stir in baby spinach and cook until wilted.'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _servingsController.dispose();
    _timeController.dispose();
    for (final g in _ingredientGroups) {
      g.nameController.dispose();
      for (final i in g.items) {
        i.amountController.dispose();
        i.nameController.dispose();
      }
    }
    for (final ins in _instructions) {
      ins.textController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoAndBasics(),
                  const SizedBox(height: 24),
                  _buildIngredientsSection(),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(),
                  const SizedBox(height: 32),
                  _buildDeleteButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text('edit_recipe'.tr, style: AppTextStyles.navLabel),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'save'.tr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAndBasics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with change button
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: const Color(0xFFD4C4A8),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'change_photo'.tr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
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
          const SizedBox(height: 16),
          // Title field
          _buildEditLabel('title'.tr),
          const SizedBox(height: 6),
          _buildFocusedInput(controller: _titleController),
          const SizedBox(height: 14),
          // Servings and Total time side by side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditLabel('servings'.tr),
                    const SizedBox(height: 6),
                    _buildSimpleInput(controller: _servingsController),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditLabel('total_time'.tr),
                    const SizedBox(height: 6),
                    _buildSimpleInput(controller: _timeController),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditLabel(String text) {
    return Text(text, style: AppTextStyles.inputLabel);
  }

  Widget _buildFocusedInput({required TextEditingController controller}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.inputText,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          filled: false,
          isDense: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSimpleInput({required TextEditingController controller}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.unselectedBorder),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.inputText,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          filled: false,
          isDense: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ingredients'.tr, style: AppTextStyles.cardTitle),
        const SizedBox(height: 14),
        ..._ingredientGroups.asMap().entries.map((entry) {
          return _buildEditIngredientGroup(entry.key, entry.value);
        }),
        const SizedBox(height: 12),
        _buildDashedAddButton('add_group'.tr, onTap: () {}),
      ],
    );
  }

  Widget _buildEditIngredientGroup(int groupIndex, _EditIngredientGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.unselectedBorder),
                  ),
                  child: TextField(
                    controller: group.nameController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      filled: false,
                      isDense: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items
          ...group.items.asMap().entries.map((entry) {
            return _buildEditIngredientItem(entry.value);
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.add, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'add_ingredient'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditIngredientItem(_EditIngredient item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, size: 18, color: Color(0xFFCFC5B6)),
          const SizedBox(width: 6),
          SizedBox(
            width: 56,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.unselectedBorder),
              ),
              child: TextField(
                controller: item.amountController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  filled: false,
                  isDense: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.unselectedBorder),
              ),
              child: TextField(
                controller: item.nameController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  filled: false,
                  isDense: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('instructions'.tr, style: AppTextStyles.cardTitle),
        const SizedBox(height: 14),
        ..._instructions.asMap().entries.map((entry) {
          return _buildEditInstructionItem(entry.key, entry.value);
        }),
        const SizedBox(height: 12),
        _buildDashedAddButton('add_step'.tr, onTap: () {}),
      ],
    );
  }

  Widget _buildEditInstructionItem(int index, _EditInstruction instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFE6D6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.drag_handle, size: 18, color: Color(0xFFCFC5B6)),
          const SizedBox(width: 6),
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE3DB),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.unselectedBorder),
                  ),
                  child: TextField(
                    controller: instruction.textController,
                    maxLines: null,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      filled: false,
                      isDense: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () =>
                      SetStepTimerSheet.show(context, stepNumber: index + 1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'add_timer'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedAddButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primary.withValues(alpha: 0.4),
            radius: 12,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EF),
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
            const SizedBox(width: 8),
            Text(
              'delete_recipe'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // No-op; using container border instead for simplicity
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditIngredientGroup {
  String name;
  List<_EditIngredient> items;
  // One controller per field, created once and disposed with the screen — so
  // typed edits survive rebuilds and controllers don't leak on each build.
  final TextEditingController nameController;
  _EditIngredientGroup({required this.name, required this.items})
    : nameController = TextEditingController(text: name);
}

class _EditIngredient {
  String amount;
  String name;
  final TextEditingController amountController;
  final TextEditingController nameController;
  _EditIngredient({required this.amount, required this.name})
    : amountController = TextEditingController(text: amount),
      nameController = TextEditingController(text: name);
}

class _EditInstruction {
  String text;
  final TextEditingController textController;
  _EditInstruction(this.text)
    : textController = TextEditingController(text: text);
}
