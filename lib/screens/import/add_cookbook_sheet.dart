import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/utils/validation_helper.dart';

class AddCookbookSheet extends StatefulWidget {
  const AddCookbookSheet({super.key});

  static Future<String?> show(BuildContext context) {
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
  final _formKey = GlobalKey<FormState>();
  static const int _maxChars = 40;

  // Validation message for the current text (null when valid).
  String? get _titleError => ValidationHelper.title(
    _controller.text,
    field: 'cookbook_name'.tr,
    min: 2,
    max: 40,
  );

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
                    Flexible(
                      child: Text(
                        'new_cookbook'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Get.back(),
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
                  'title'.tr,
                  style: AppTextStyles.inputLabel.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Text field
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Container(
                    height: AppDimensions.inputHeightLg,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _controller,
                      maxLength: _maxChars,
                      keyboardType: TextInputType.text,
                      style: AppTextStyles.inputText,
                      cursorColor: AppColors.primary,
                      cursorWidth: 2,
                      cursorHeight: 24,
                      validator: (v) => ValidationHelper.title(
                        v,
                        field: 'cookbook_name'.tr,
                        min: 2,
                        max: 40,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        // Collapse the built-in error so it never renders inside
                        // this fixed-height box (which clipped the hint and
                        // overlapped the text). The message is shown below.
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                        hintText: 'cookbook_name_hint'.tr,
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
                          vertical: 0, //AppSpacing.lg,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Validation message (left) + character count (right).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child:
                          (_controller.text.isNotEmpty && _titleError != null)
                          ? Text(
                              _titleError!,
                              style: AppTextStyles.smallLabel.copyWith(
                                color: AppColors.red,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_controller.text.length} / $_maxChars',
                      style: AppTextStyles.smallLabel.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Create button
                PrimaryButton(
                  label: 'create_cookbook'.tr,
                  leadingIcon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.pop(context, _controller.text.trim());
                        },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
