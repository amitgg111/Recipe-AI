import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';

class DeleteCookbookDialog extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const DeleteCookbookDialog({
    super.key,
    this.onDelete,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x731E1B18),
      builder: (_) => const DeleteCookbookDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trash icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 30,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Title
            Text(
              'delete_this_cookbook'.tr,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: AppSpacing.md),
            // Description with bold "not"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textBody,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'delete_cookbook_note_prefix'.tr,
                  ),
                  TextSpan(
                    text: 'delete_cookbook_note_not'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'delete_cookbook_note_suffix'.tr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel ?? () => Navigator.of(context).pop(false),
                    child: Container(
                      height: AppDimensions.buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                        border: Border.all(color: AppColors.unselectedBorder),
                      ),
                      child: Center(
                        child: Text(
                          'cancel'.tr,
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: onDelete ?? () => Navigator.of(context).pop(true),
                    child: Container(
                      height: AppDimensions.buttonHeight,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusButton,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.red.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'delete'.tr,
                          style: AppTextStyles.buttonLabel,
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
  }
}
