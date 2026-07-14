import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/nutrition_controller.dart';
import 'package:recipe_ai/Service/recipe_pdf_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Bottom sheet shown when a Plus user exports a recipe. Previews the recipe
/// card, then lets them Print or Share the generated PDF (saved to the device
/// via the OS share/save sheet).
class ExportPdfSheet extends StatefulWidget {
  final RecipeModel recipe;

  /// The recipe's in-memory note (session-only) shown in the PDF's Notes card.
  final String? note;

  const ExportPdfSheet({super.key, required this.recipe, this.note});

  /// Opens the sheet for [recipe].
  static void open(RecipeModel recipe, {String? note}) {
    Get.bottomSheet(
      ExportPdfSheet(recipe: recipe, note: note),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<ExportPdfSheet> createState() => _ExportPdfSheetState();
}

class _ExportPdfSheetState extends State<ExportPdfSheet> {
  bool _busy = false;

  RecipeModel get recipe => widget.recipe;

  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final nutrition = NutritionController.to.calculateNutrition(recipe);
      final bytes = await RecipePdfService.build(
        recipe,
        nutrition: nutrition,
        note: widget.note,
      );
      await action(bytes);
    } catch (_) {
      if (mounted) {
        CustomSnackbar.show(
          title: 'pdf_failed'.tr,
          message: 'pdf_failed_msg'.tr,
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() => _run((bytes) async {
        await Printing.sharePdf(
          bytes: bytes,
          filename: RecipePdfService.fileName(recipe),
        );
      });

  Future<void> _print() => _run((bytes) async {
        await Printing.layoutPdf(
          name: RecipePdfService.fileName(recipe),
          onLayout: (_) => bytes,
        );
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            _header(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: _previewCard(),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(
              child: OnboardingLineIcon('file',
                  size: 20, color: AppColors.purpleDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'export_as_pdf'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'plus_feature'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purpleDark,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 19, color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview card (miniature of the exported PDF) ─────────────────────────────

  Widget _previewCard() {
    final time = _firstNonEmpty(
        [recipe.totalTime, recipe.cookTime, recipe.prepTime]);
    final serves = recipe.servingCount;
    final meta = <String>[
      if (time != null) time,
      if (serves > 0) 'serves_n'.trParams({'count': _trimNum(serves)}),
      if (_sourceHost(recipe.sourceUrl) != null) _sourceHost(recipe.sourceUrl)!,
    ].join(' · ');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1B18).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand chip
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: OnboardingLineIcon('chefHat',
                        size: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Recipe AI',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hero image
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: (recipe.imageUrl != null &&
                        recipe.imageUrl!.startsWith('http'))
                    ? AppNetworkImage(recipe.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: OnboardingLineIcon('image',
                              size: 26, color: AppColors.iconLight),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              recipe.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppColors.textDark,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            _previewSection('ingredients_caps'.tr, [0.9, 0.7, 0.8]),
            const SizedBox(height: 12),
            _previewSection('instructions_caps'.tr, [0.95, 0.6]),
          ],
        ),
      ),
    );
  }

  Widget _previewSection(String title, List<double> lineWidths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        for (final w in lineWidths) ...[
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: w,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _outlineButton(
              icon: 'print',
              label: 'print'.tr,
              onTap: _print,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: _primaryButton(
              icon: 'share',
              label: 'share_pdf'.tr,
              onTap: _sharePdf,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingLineIcon('print',
                size: 18, color: AppColors.textBody),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OnboardingLineIcon('share',
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String _trimNum(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  String? _sourceHost(String url) {
    if (url.isEmpty || !url.startsWith('http')) return null;
    if (url.contains('gemini_image') || url.contains('recipe_name')) {
      return null;
    }
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }
}
