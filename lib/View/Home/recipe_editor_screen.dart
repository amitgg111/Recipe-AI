import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants — matched to the HTML "Recipe detail (edit)" design
// ─────────────────────────────────────────────────────────────────────────────
class _E {
  static const bg = AppColors.background;
  static const card = Colors.white;
  static const border = Color(0xFFEFE6D6);
  static const fieldBg = Color(0xFFFBF7F0);
  static const fieldBorder = Color(0xFFE7DECE);
  static const primary = AppColors.primary;
  static const textDark = Color(0xFF2A211B);
  static const label = Color(0xFF9A938A);
  static const grip = Color(0xFFCFC5B6);
  static const trash = Color(0xFFD08B7E);
  static const rowLine = Color(0xFFF0ECE4);
  static const redText = Color(0xFFE0481F);
}

TextStyle _f(double s, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: s,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

BoxDecoration _cardDeco() => BoxDecoration(
  color: _E.card,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: _E.border),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF2A211B).withValues(alpha: 0.16),
      blurRadius: 26,
      offset: const Offset(0, 12),
      spreadRadius: -22,
    ),
  ],
);

class RecipeEditorScreen extends StatefulWidget {
  final RecipeModel? recipe;

  const RecipeEditorScreen({super.key, this.recipe});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      RecipeEditorController(recipe: widget.recipe),
      tag: widget.recipe?.id ?? 'new_recipe',
    );
    final isEdit = widget.recipe != null;

    return Scaffold(
      backgroundColor: _E.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, controller, isEdit),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoBasicsCard(controller: controller),
                      const SizedBox(height: 16),
                      _IngredientsEditor(controller: controller),
                      const SizedBox(height: 14),
                      _InstructionsEditor(controller: controller),
                      const SizedBox(height: 16),
                      if (isEdit) _DeleteButton(recipe: widget.recipe!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar (X · Edit recipe · Save) ──────────────────────────────────────
  Widget _buildTopBar(
    BuildContext context,
    RecipeEditorController controller,
    bool isEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _E.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFEFEDE6)),
                ),
                child: const OnboardingLineIcon(
                  'x',
                  size: 19,
                  color: _E.textDark,
                ),
              ),
            ),
            Text(
              isEdit ? 'edit_recipe'.tr : 'new_recipe'.tr,
              style: _f(17, FontWeight.w800, _E.textDark),
            ),
            Obx(() {
              return GestureDetector(
                onTap: controller.isSaving.value
                    ? null
                    : () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        controller.saveRecipe();
                      },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _E.primary,
                    borderRadius: BorderRadius.circular(13),
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
                          'save'.tr,
                          style: _f(14, FontWeight.w700, Colors.white),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHOTO + BASICS CARD (image, title, servings, total time)
// ═══════════════════════════════════════════════════════════════════════════════

class _PhotoBasicsCard extends StatelessWidget {
  final RecipeEditorController controller;
  const _PhotoBasicsCard({required this.controller});

  @override
  Widget build(BuildContext context) {  
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + change photo (a photo is required to save).
          FormField<String>(
            validator: (_) {
              final hasImage =
                  controller.imageFile.value != null ||
                  controller.imagePath.value.isNotEmpty;
              return hasImage ? null : 'add_recipe_photo'.tr;
            },
            builder: (state) => Obx(() {
              final hasImage =
                  controller.imageFile.value != null ||
                  controller.imagePath.value.isNotEmpty;
              Widget img;
              if (controller.imageFile.value != null) {
                img = Image.file(
                  controller.imageFile.value!,
                  fit: BoxFit.cover,
                );
              } else if (controller.imagePath.value.isNotEmpty) {
                final p = controller.imagePath.value;
                img = p.startsWith('http')
                    ? AppNetworkImage(p, fit: BoxFit.cover)
                    : Image.file(File(p), fit: BoxFit.cover);
              } else {
                img = Container(
                  color: const Color(0xFFF0E6D6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'add_photo'.tr,
                          style: _f(13, FontWeight.w600, AppColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final showError = state.hasError && !hasImage;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          img,
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: controller.pickImage,
                              behavior: HitTestBehavior.opaque,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: showError
                                      ? Border.all(
                                          color: _E.redText,
                                          width: 1.5,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: GestureDetector(
                              onTap: controller.pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const OnboardingLineIcon(
                                      'camera',
                                      size: 15,
                                      color: _E.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'change_photo'.tr,
                                      style: _f(
                                        13,
                                        FontWeight.w700,
                                        _E.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showError) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        state.errorText ?? '',
                        style: _f(11.5, FontWeight.w500, _E.redText),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          // Title
          _fieldLabel('title'.tr),
          const SizedBox(height: 7),
          _FocusField(
            controller: controller.titleController,
            hint: 'recipe_name'.tr,
            height: 48,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            focused: true,
            keyboardType: TextInputType.text,
            validator: (v) =>
                ValidationHelper.title(v, field: 'recipe_title'.tr, min: 2),
          ),
          const SizedBox(height: 14),
          // Servings + total time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('servings'.tr),
                    const SizedBox(height: 7),
                    // Servings can be set only while CREATING a recipe. Editing
                    // an existing one keeps it locked (scaling happens on the
                    // detail screen instead), so it's only validated on create.
                    _FocusField(
                      controller: controller.servingsController,
                      hint: '2',
                      height: 46,
                      enabled: !controller.isEdit,
                      keyboardType: const TextInputType.numberWithOptions(),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: controller.isEdit
                          ? null
                          : (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'required'.tr;
                              if ((int.tryParse(t) ?? 0) <= 0) {
                                return 'enter_servings'.tr;
                              }
                              return null;
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('total_time'.tr),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numbers-only value.
                        Expanded(
                          flex: 2,
                          child: _FocusField(
                            controller: controller.totalTimeController,
                            hint: '35',
                            height: 46,
                            keyboardType:
                                const TextInputType.numberWithOptions(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'required'.tr;
                              if ((int.tryParse(t) ?? 0) <= 0) {
                                return 'enter_time'.tr;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        // minutes / hour unit picker.
                        Expanded(
                          flex: 3,
                          child: _TimeUnitDropdown(controller: controller),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String t) =>
      Text(t.toUpperCase(), style: _f(12, FontWeight.w700, _E.label, ls: 0.5));
}

// A field styled like the HTML inputs (optionally showing the focused ring).
class _FocusField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final bool focused;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FocusField({
    required this.controller,
    required this.hint,
    this.height = 46,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.focused = false,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in a FormField so the validation message renders OUTSIDE (below)
    // the fixed-height box instead of being squeezed inside it. The FormField
    // still participates in the enclosing Form, so Save's .validate() keeps
    // blocking on errors exactly as before — only the error's position moves.
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      autovalidateMode: validator == null
          ? AutovalidateMode.disabled
          : AutovalidateMode.onUserInteraction,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: _E.fieldBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: hasError
                      ? _E.redText
                      : (focused ? _E.primary : _E.fieldBorder),
                  width: (focused || hasError) ? 1.5 : 1,
                ),
                boxShadow: (focused && !hasError)
                    ? [
                        BoxShadow(
                          color: _E.primary.withValues(alpha: 0.1),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: _f(fontSize, fontWeight, _E.textDark),
                cursorColor: _E.primary,
                onChanged: state.didChange,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: _f(fontSize, FontWeight.w400, AppColors.textHint),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  state.errorText ?? '',
                  style: _f(11.5, FontWeight.w500, _E.redText),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Minutes / hour picker paired with the total-time number field.
class _TimeUnitDropdown extends StatelessWidget {
  final RecipeEditorController controller;
  const _TimeUnitDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _E.fieldBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _E.fieldBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.totalTimeUnit.value,
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: _E.card,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _E.label,
            ),
            style: _f(14, FontWeight.w700, _E.textDark),
            items: [
              DropdownMenuItem(value: 'minutes', child: Text('minutes'.tr)),
              DropdownMenuItem(value: 'hours', child: Text('hour'.tr)),
            ],
            onChanged: (v) {
              if (v != null) controller.totalTimeUnit.value = v;
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: 6-dot drag handle
// ═══════════════════════════════════════════════════════════════════════════════

class _DragDots extends StatelessWidget {
  const _DragDots();
  @override
  Widget build(BuildContext context) {
    return const OnboardingLineIcon('grip', size: 18, color: _E.grip);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: Section header (orange dot + name field)
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String name;
  const _SectionHeader({required this.name});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 7),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _E.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: _E.fieldBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _E.fieldBorder),
              ),
              child: Text(name, style: _f(13, FontWeight.w800, _E.textDark)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: "+ Add ingredient / step" text button
// ═══════════════════════════════════════════════════════════════════════════════

class _AddItemButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddItemButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 22, top: 2, bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingLineIcon('plus', size: 15, color: _E.primary),
            const SizedBox(width: 6),
            Text(label, style: _f(13, FontWeight.w700, _E.primary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED: "+ Add group" dashed button
// ═══════════════════════════════════════════════════════════════════════════════

class _AddGroupButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGroupButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('plus', size: 16, color: _E.primary),
            const SizedBox(width: 7),
            Text('add_group'.tr, style: _f(13, FontWeight.w700, _E.textDark)),
          ],
        ),
      ),
    );
  }
}

// A rounded rectangle with a dashed border.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8CFBE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// INGREDIENTS EDITOR — section-grouped
// ═══════════════════════════════════════════════════════════════════════════════

class _IngredientsEditor extends StatelessWidget {
  final RecipeEditorController controller;
  const _IngredientsEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.ingredientSections;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ingredients'.tr, style: _f(16, FontWeight.w800, _E.textDark)),
            const SizedBox(height: 10),
            for (int si = 0; si < sections.length; si++)
              _buildSection(context, si, sections[si], sections.length),
            _AddGroupButton(onTap: () => _showAddGroupSheet()),
          ],
        ),
      );
    });
  }

  Widget _buildSection(
    BuildContext context,
    int sectionIdx,
    dynamic section,
    int totalSections,
  ) {
    // Hide the "Add ingredient" button for the empty, unnamed default section
    // once real groups exist — otherwise it shows twice (above + below a group).
    final isUnnamed = section.name == null || (section.name as String).isEmpty;
    final showAdd = !(isUnnamed && section.items.isEmpty && totalSections > 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.name != null && section.name!.isNotEmpty)
          _SectionHeader(name: section.name!),
        // Drag-to-reorder ingredients within this section — grab the grip
        // handle (⋮⋮) and drop the row anywhere in the list.
        if (section.items.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: section.items.length,
            onReorder: (oldIndex, newIndex) => controller
                .reorderIngredientInSection(sectionIdx, oldIndex, newIndex),
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (_, i) => _ingredientRow(
              sectionIdx,
              i,
              section.items[i],
              key: ValueKey('ing_${sectionIdx}_${i}_${section.items[i]}'),
            ),
          ),
        if (showAdd)
          _AddItemButton(
            label: 'add_ingredient'.tr,
            onTap: () => _showAddItemSheet(sectionIdx),
          ),
      ],
    );
  }

  Widget _ingredientRow(int sectionIdx, int itemIdx, String text, {Key? key}) {
    final parts = _parseQty(text);
    final qty = parts.$1;
    final name = parts.$2;
    return GestureDetector(
      key: key,
      onTap: () => _showEditItemSheet(sectionIdx, itemIdx, text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        // No fixed height — the row grows so long ingredients show in full.
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: _E.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _E.fieldBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the grip starts a drag — tapping elsewhere still edits.
              ReorderableDragStartListener(
                index: itemIdx,
                child: const SizedBox(
                  width: 26,
                  child: Center(child: _DragDots()),
                ),
              ),
              _vLine(),
              // Single merged column: quantity + unit (BOLD) followed by the
              // ingredient name, wrapping over up to 3 lines so nothing is cut.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (qty.isNotEmpty)
                            TextSpan(
                              text: '$qty ',
                              style: _f(14, FontWeight.w800, _E.textDark),
                            ),
                          TextSpan(
                            text: name,
                            style: _f(14, FontWeight.w500, _E.textDark),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              _vLine(),
              GestureDetector(
                onTap: () =>
                    controller.removeIngredientFromSection(sectionIdx, itemIdx),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 40,
                  child: Center(
                    child: OnboardingLineIcon(
                      'trash',
                      size: 18,
                      color: _E.trash,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemSheet(int sectionIdx) {
    Get.bottomSheet(
      _IngredientEditorSheet(
        title: 'add_ingredient'.tr,
        buttonLabel: 'add'.tr,
        initial: '',
        onConfirm: (v) => controller.addIngredientToSection(sectionIdx, v),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showEditItemSheet(int sectionIdx, int itemIdx, String current) {
    Get.bottomSheet(
      _IngredientEditorSheet(
        title: 'edit_ingredient'.tr,
        buttonLabel: 'save'.tr,
        initial: current,
        onConfirm: (v) =>
            controller.updateIngredientInSection(sectionIdx, itemIdx, v),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAddGroupSheet() {
    final tc = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'add_group'.tr,
        hint: 'eg_for_the_sauce'.tr,
        textController: tc,
        buttonLabel: 'add_group'.tr,
        onConfirm: () {
          final name = tc.text.trim();
          if (name.isNotEmpty) controller.addIngredientGroup(name);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Non-convertible "count" / container units (recognised in addition to the
  // convertible units from UnitConverter) so the full unit is captured — and
  // therefore shown bold — rather than leaking into the ingredient name.
  static const Set<String> _countUnits = {
    'clove',
    'cloves',
    'piece',
    'pieces',
    'pc',
    'pcs',
    'can',
    'cans',
    'tin',
    'tins',
    'jar',
    'jars',
    'bottle',
    'bottles',
    'pack',
    'packs',
    'packet',
    'packets',
    'box',
    'boxes',
    'bag',
    'bags',
    'bunch',
    'bunches',
    'head',
    'heads',
    'stalk',
    'stalks',
    'stick',
    'sticks',
    'sprig',
    'sprigs',
    'slice',
    'slices',
    'sheet',
    'sheets',
    'leaf',
    'leaves',
    'pinch',
    'pinches',
    'dash',
    'dashes',
    'handful',
    'handfuls',
    'drop',
    'drops',
    'scoop',
    'scoops',
    'inch',
    'inches',
    'small',
    'medium',
    'large',
    'whole',
  };

  static bool _isUnitToken(String token) {
    final t = token.toLowerCase();
    return UnitConverter.isUnitWord(t) || _countUnits.contains(t);
  }

  static final RegExp _numToken = RegExp(r'^[\d½⅓⅔¼¾⅛⅜⅝⅞./-]+$');
  static final RegExp _hasDigit = RegExp(r'[\d½⅓⅔¼¾⅛⅜⅝⅞]');

  /// Split an ingredient into (quantity+unit, name). Recognises spelled-out and
  /// plural units ("teaspoon", "grams", "gallons"…) via UnitConverter so the
  /// whole measure is captured for the bold prefix.
  static (String, String) _parseQty(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return ('', '');
    final tokens = cleaned.split(' ');
    var i = 0;

    // Leading amount (integer / decimal / fraction / "1 1/2" / range "2-3").
    final numberTokens = <String>[];
    while (i < tokens.length &&
        _numToken.hasMatch(tokens[i]) &&
        _hasDigit.hasMatch(tokens[i])) {
      numberTokens.add(tokens[i]);
      i++;
      if (i + 1 < tokens.length &&
          tokens[i].toLowerCase() == 'to' &&
          _numToken.hasMatch(tokens[i + 1]) &&
          _hasDigit.hasMatch(tokens[i + 1])) {
        numberTokens.add(tokens[i]);
        i++;
      }
    }
    if (numberTokens.isEmpty) return ('', cleaned);

    // Optional unit after the number (two-word "fl oz" first).
    var unit = '';
    if (i < tokens.length) {
      final t1 = tokens[i].toLowerCase();
      final t2 = (i + 1 < tokens.length) ? tokens[i + 1].toLowerCase() : '';
      if ((t1 == 'fl' && t2 == 'oz') ||
          (t1 == 'fluid' && (t2 == 'oz' || t2 == 'ounce' || t2 == 'ounces'))) {
        unit = '${tokens[i]} ${tokens[i + 1]}';
        i += 2;
      } else if (_isUnitToken(t1)) {
        unit = tokens[i];
        i++;
      }
    }

    final name = tokens
        .sublist(i)
        .join(' ')
        .replaceAll(RegExp(r'^of\s+', caseSensitive: false), '')
        .trim();
    final qty = [...numberTokens, if (unit.isNotEmpty) unit].join(' ');
    if (name.isEmpty) return ('', cleaned);
    return (qty, name);
  }
}

Widget _vLine() => Container(width: 1, color: _E.rowLine);

// ═══════════════════════════════════════════════════════════════════════════════
// INSTRUCTIONS EDITOR — section-grouped
// ═══════════════════════════════════════════════════════════════════════════════

class _InstructionsEditor extends StatelessWidget {
  final RecipeEditorController controller;
  const _InstructionsEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.instructionSections;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'instructions'.tr,
              style: _f(16, FontWeight.w800, _E.textDark),
            ),
            const SizedBox(height: 10),
            for (int si = 0; si < sections.length; si++)
              _buildSection(si, sections[si], sections),
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
    // Hide the "Add step" button for the empty, unnamed default section once
    // real groups exist — otherwise it shows twice (above + below a group).
    final isUnnamed = section.name == null || (section.name as String).isEmpty;
    final showAdd =
        !(isUnnamed && (section.steps as List).isEmpty && sections.length > 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.name != null && section.name!.isNotEmpty)
          _SectionHeader(name: section.name!),
        // Drag-to-reorder steps within this section (grab the grip ⋮⋮). Step
        // numbers recompute automatically after a move.
        if ((section.steps as List).isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: section.steps.length,
            onReorder: (oldIndex, newIndex) => controller
                .reorderInstructionInSection(sectionIdx, oldIndex, newIndex),
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (_, i) => _stepRow(
              sectionIdx,
              i,
              stepNum + i,
              section.steps[i],
              key: ValueKey('step_${sectionIdx}_${i}_${section.steps[i]}'),
            ),
          ),
        if (showAdd)
          _AddItemButton(
            label: 'add_step'.tr,
            onTap: () => _showAddStepSheet(sectionIdx),
          ),
      ],
    );
  }

  Widget _stepRow(
    int sectionIdx,
    int stepIdx,
    int stepNumber,
    String text, {
    Key? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => _showEditStepSheet(sectionIdx, stepIdx, text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: const BoxConstraints(minHeight: 46),
        decoration: BoxDecoration(
          color: _E.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _E.fieldBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Only the grip starts a drag — tapping elsewhere still edits.
              ReorderableDragStartListener(
                index: stepIdx,
                child: const SizedBox(
                  width: 22,
                  child: Center(child: _DragDots()),
                ),
              ),
              _vLine(),
              SizedBox(
                width: 24,
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: _f(12, FontWeight.w800, _E.primary),
                  ),
                ),
              ),
              _vLine(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: _f(13.5, FontWeight.w500, _E.textDark, h: 1.4),
                    ),
                  ),
                ),
              ),
              _vLine(),
              GestureDetector(
                onTap: () => controller.removeInstructionFromSection(
                  sectionIdx,
                  stepIdx,
                ),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 34,
                  child: OnboardingLineIcon('trash', size: 18, color: _E.trash),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStepSheet(int sectionIdx) {
    final tc = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'add_step'.tr,
        hint: 'describe_cooking_step'.tr,
        textController: tc,
        maxLines: 4,
        buttonLabel: 'add'.tr,
        onConfirm: () =>
            controller.addInstructionToSection(sectionIdx, tc.text),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showEditStepSheet(int sectionIdx, int stepIdx, String current) {
    final tc = TextEditingController(text: current);
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'edit_step'.tr,
        hint: 'describe_cooking_step'.tr,
        textController: tc,
        maxLines: 4,
        buttonLabel: 'save'.tr,
        onConfirm: () =>
            controller.updateInstructionInSection(sectionIdx, stepIdx, tc.text),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAddGroupSheet() {
    final tc = TextEditingController();
    Get.bottomSheet(
      _EditorBottomSheet(
        title: 'add_group'.tr,
        hint: 'eg_for_the_dough'.tr,
        textController: tc,
        buttonLabel: 'add_group'.tr,
        onConfirm: () {
          final name = tc.text.trim();
          if (name.isNotEmpty) controller.addInstructionGroup(name);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE RECIPE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _DeleteButton extends StatelessWidget {
  final RecipeModel recipe;
  const _DeleteButton({required this.recipe});

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
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
                  child: const OnboardingLineIcon(
                    'trashLg',
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'delete_this_recipe'.tr,
                  style: _f(18, FontWeight.w800, _E.textDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'delete_recipe_confirm'.trParams({'title': recipe.title}),
                  textAlign: TextAlign.center,
                  style: _f(
                    13.5,
                    FontWeight.w400,
                    AppColors.textMedium,
                    h: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: _E.border),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                          ),
                          child: Text(
                            'cancel'.tr,
                            style: _f(15, FontWeight.w700, _E.textDark),
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
                          // On success, drop the editor AND the (now-deleted)
                          // detail screen — go straight to Home so Back can't
                          // return to a recipe that no longer exists.
                          if (deleted) {
                            Get.until((route) => route.isFirst);
                          }
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                          ),
                          child: Text(
                            'delete'.tr,
                            style: _f(15, FontWeight.w700, Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EF),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFF0D6CE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('trash', size: 19, color: _E.redText),
            const SizedBox(width: 8),
            Text(
              'delete_recipe'.tr,
              style: _f(15, FontWeight.w700, _E.redText),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
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
    // NOTE: Get.bottomSheet already wraps the sheet in a
    // Padding(bottom: viewInsets.bottom) for the keyboard. Adding that padding
    // again here double-counted the inset and pushed the sheet a full
    // keyboard-height up the screen, leaving a big gap above the keyboard — so
    // the Container is returned directly.
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: _f(18, FontWeight.w800, _E.textDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: _E.bg,
                    shape: BoxShape.circle,
                  ),
                  child: const OnboardingLineIcon(
                    'x',
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _E.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _E.primary, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: textController,
              maxLines: maxLines,
              autofocus: true,
              cursorColor: _E.primary,
              style: _f(15, FontWeight.w500, _E.textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: _f(14, FontWeight.w400, AppColors.textHint),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              onConfirm();
              Get.back();
            },
            child: Container(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              decoration: BoxDecoration(
                color: _E.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
              child: Center(
                child: Text(buttonLabel, style: AppTextStyles.buttonLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient unit system — the selectable units offered in the editor. Every
// token here is one the app's UnitConverter understands, so switching a recipe
// between Metric/Imperial keeps converting cleanly.
// (label shown in the picker, token written into the ingredient string)
// ─────────────────────────────────────────────────────────────────────────────
const List<(String, String)> _kIngredientUnits = [
  ('No unit', ''),
  ('Milliliter', 'ml'),
  ('Centiliter', 'cl'),
  ('Deciliter', 'dl'),
  ('Liter', 'l'),
  ('Teaspoon', 'tsp'),
  ('Tablespoon', 'tbsp'),
  ('Fluid ounce', 'fl oz'),
  ('Cup', 'cup'),
  ('Pint', 'pint'),
  ('Quart', 'quart'),
  ('Gallon', 'gallon'),
  ('Gram', 'g'),
  ('Kilogram', 'kg'),
  ('Ounce', 'oz'),
  ('Pound', 'lb'),
];

// Every spelling/abbreviation the parser recognises → the canonical token above.
const Map<String, String> _kUnitAliases = {
  'ml': 'ml',
  'milliliter': 'ml',
  'milliliters': 'ml',
  'millilitre': 'ml',
  'millilitres': 'ml',
  'cl': 'cl',
  'centiliter': 'cl',
  'centiliters': 'cl',
  'centilitre': 'cl',
  'centilitres': 'cl',
  'dl': 'dl',
  'deciliter': 'dl',
  'deciliters': 'dl',
  'decilitre': 'dl',
  'decilitres': 'dl',
  'l': 'l',
  'liter': 'l',
  'liters': 'l',
  'litre': 'l',
  'litres': 'l',
  'tsp': 'tsp',
  'tsps': 'tsp',
  'teaspoon': 'tsp',
  'teaspoons': 'tsp',
  'tbsp': 'tbsp',
  'tbsps': 'tbsp',
  'tbs': 'tbsp',
  'tablespoon': 'tbsp',
  'tablespoons': 'tbsp',
  'cup': 'cup',
  'cups': 'cup',
  'pint': 'pint',
  'pints': 'pint',
  'pt': 'pint',
  'quart': 'quart',
  'quarts': 'quart',
  'qt': 'quart',
  'gallon': 'gallon',
  'gallons': 'gallon',
  'gal': 'gallon',
  'g': 'g',
  'gram': 'g',
  'grams': 'g',
  'gm': 'g',
  'gms': 'g',
  'kg': 'kg',
  'kilogram': 'kg',
  'kilograms': 'kg',
  'kgs': 'kg',
  'oz': 'oz',
  'ounce': 'oz',
  'ounces': 'oz',
  'lb': 'lb',
  'lbs': 'lb',
  'pound': 'lb',
  'pounds': 'lb',
};

/// Splits a free-form ingredient line ("2½ cups organic flour") into its
/// (quantity, unit-token, name) parts. A leading unit is only pulled out when
/// it's a recognised unit — anything else (e.g. "2 cloves garlic") is left in
/// the name so nothing is ever lost on a round-trip.
(String, String, String) _splitIngredient(String text) {
  final t = text.trim();
  if (t.isEmpty) return ('', '', '');

  String qty = '';
  String rest = t;
  final qtyM = RegExp(r'^([0-9¼½¾⅓⅔⅛⅜⅝⅞][0-9¼½¾⅓⅔⅛⅜⅝⅞.,/\s-]*)').firstMatch(t);
  if (qtyM != null) {
    qty = qtyM.group(1)!.trim();
    rest = t.substring(qtyM.end).trim();
  }

  String unit = '';
  final flozM = RegExp(
    r'^fl\.?\s*oz\.?',
    caseSensitive: false,
  ).firstMatch(rest);
  if (flozM != null) {
    unit = 'fl oz';
    rest = rest.substring(flozM.end).trim();
  } else {
    final wM = RegExp(r'^([A-Za-z]+)\.?').firstMatch(rest);
    if (wM != null) {
      final canon = _kUnitAliases[wM.group(1)!.toLowerCase()];
      if (canon != null) {
        unit = canon;
        rest = rest.substring(wM.end).trim();
      }
    }
  }
  return (qty, unit, rest);
}

/// Recombines the three parts back into a single ingredient line.
String _composeIngredient(String qty, String unit, String name) {
  final parts = <String>[
    if (qty.trim().isNotEmpty) qty.trim(),
    if (unit.trim().isNotEmpty) unit.trim(),
    if (name.trim().isNotEmpty) name.trim(),
  ];
  return parts.join(' ');
}

String _unitLabel(String token) {
  if (token.isEmpty) return 'no_unit'.tr;
  for (final u in _kIngredientUnits) {
    if (u.$2 == token) return '${u.$1} (${u.$2})';
  }
  return token;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient editor sheet: quantity + unit picker + name, so the unit can be
// chosen from a proper list instead of typed free-hand.
// ─────────────────────────────────────────────────────────────────────────────
class _IngredientEditorSheet extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final String initial;
  final void Function(String composed) onConfirm;

  const _IngredientEditorSheet({
    required this.title,
    required this.buttonLabel,
    required this.initial,
    required this.onConfirm,
  });

  @override
  State<_IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends State<_IngredientEditorSheet> {
  late final TextEditingController _qty;
  late final TextEditingController _name;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final parts = _splitIngredient(widget.initial);
    _qty = TextEditingController(text: parts.$1);
    _unit = parts.$2;
    _name = TextEditingController(text: parts.$3);
  }

  @override
  void dispose() {
    _qty.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final composed = _composeIngredient(_qty.text, _unit, _name.text);
    if (composed.isEmpty) return;
    widget.onConfirm(composed);
    Get.back();
  }

  void _openUnitPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E0D2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
              child: Row(
                children: [
                  Text(
                    'select_unit'.tr,
                    style: _f(17, FontWeight.w800, _E.textDark),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: _kIngredientUnits.length,
                itemBuilder: (_, i) {
                  final u = _kIngredientUnits[i];
                  final selected = u.$2 == _unit;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _unit = u.$2);
                      Get.back();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _E.fieldBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _E.primary : _E.fieldBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.$1,
                              style: _f(
                                15,
                                selected ? FontWeight.w700 : FontWeight.w500,
                                _E.textDark,
                              ),
                            ),
                          ),
                          if (u.$2.isNotEmpty)
                            Text(
                              u.$2,
                              style: _f(13, FontWeight.w600, _E.label),
                            ),
                          if (selected) ...[
                            const SizedBox(width: 10),
                            const OnboardingLineIcon(
                              'check',
                              size: 16,
                              color: _E.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.title, style: _f(18, FontWeight.w800, _E.textDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: _E.bg,
                    shape: BoxShape.circle,
                  ),
                  child: const OnboardingLineIcon(
                    'x',
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quantity + Unit row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: _fieldBox(
                  child: TextField(
                    controller: _qty,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    cursorColor: _E.primary,
                    style: _f(15, FontWeight.w600, _E.textDark),
                    decoration: _fieldDeco('qty'.tr),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _openUnitPicker,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _E.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _E.fieldBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _unitLabel(_unit),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _f(
                              15,
                              FontWeight.w600,
                              _unit.isEmpty ? AppColors.textHint : _E.textDark,
                            ),
                          ),
                        ),
                        const OnboardingLineIcon(
                          'chevDown',
                          size: 18,
                          color: _E.label,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Ingredient name.
          _fieldBox(
            child: TextField(
              controller: _name,
              autofocus: true,
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: _E.primary,
              style: _f(15, FontWeight.w500, _E.textDark),
              decoration: _fieldDeco('ingredient_hint'.tr),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              decoration: BoxDecoration(
                color: _E.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
              child: Center(
                child: Text(
                  widget.buttonLabel,
                  style: AppTextStyles.buttonLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: _E.fieldBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _E.fieldBorder, width: 1.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: child,
  );

  InputDecoration _fieldDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: _f(14, FontWeight.w400, AppColors.textHint),
    isDense: true,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(vertical: 14),
  );
}
