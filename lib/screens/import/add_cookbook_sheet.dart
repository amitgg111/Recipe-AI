import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class AddCookbookSheet extends StatefulWidget {
  const AddCookbookSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCookbookSheet(),
    );
  }

  @override
  State<AddCookbookSheet> createState() => _AddCookbookSheetState();
}

class _AddCookbookSheetState extends State<AddCookbookSheet> {
  final _controller = TextEditingController();
  static const int _maxChars = 40;

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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New cookbook',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F1EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Label
                Text(
                  'Title',
                  style: AppTextStyles.inputLabel.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Text field
                Container(
                  height: AppDimensions.inputHeightLg,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxChars,
                    style: AppTextStyles.inputText,
                    cursorColor: AppColors.primary,
                    cursorWidth: 2,
                    cursorHeight: 24,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'e.g. Weeknight Dinners',
                      hintStyle: AppTextStyles.inputHint,
                      filled: false,
                      isDense: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Character count
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_controller.text.length} / $_maxChars',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Create button
                PrimaryButton(
                  label: 'Create cookbook',
                  leadingIcon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, _controller.text.trim());
                        },
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
