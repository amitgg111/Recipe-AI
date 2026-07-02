import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class EditCookbookSheet extends StatefulWidget {
  final String initialName;
  final ValueChanged<String>? onSave;

  const EditCookbookSheet({
    super.key,
    this.initialName = 'Weeknight Dinners',
    this.onSave,
  });

  static Future<String?> show(
    BuildContext context, {
    String initialName = 'Weeknight Dinners',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCookbookSheet(initialName: initialName),
    );
  }

  @override
  State<EditCookbookSheet> createState() => _EditCookbookSheetState();
}

class _EditCookbookSheetState extends State<EditCookbookSheet> {
  late TextEditingController _controller;
  static const int _maxChars = 40;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rename cookbook',
                  style: AppTextStyles.listTitle,
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.tabBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textBodyDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Text field
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: _maxChars,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        hintText: 'Cookbook name',
                        hintStyle: AppTextStyles.inputHint,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _controller.clear(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 14),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBorder,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.textBodyDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Character count
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length} / $_maxChars',
                style: AppTextStyles.smallLabel.copyWith(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Save button
            PrimaryButton(
              label: 'Save changes',
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () {
                      widget.onSave?.call(_controller.text.trim());
                      Navigator.of(context).pop(_controller.text.trim());
                    },
            ),
            SizedBox(
              height: AppSpacing.xxl +
                  MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
