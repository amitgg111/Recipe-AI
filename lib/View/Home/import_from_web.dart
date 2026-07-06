import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:recipe_ai/Controllers/import_web_controller.dart';
import 'package:recipe_ai/Model/recipe_section_model.dart';

class ImportFromWebScreen extends StatelessWidget {
  const ImportFromWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImportWebController>();

    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildAddressBar(controller, context),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: controller.webViewController),
                  Obx(
                    () => controller.isLoading.value
                        ? const _PageLoadingOverlay()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            _buildImportBar(controller, context),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressBar(
    ImportWebController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: const Border(bottom: BorderSide(color: Color(0xFFE4E2DC))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const OnboardingLineIcon('x', size: 25, color: Colors.black87),
            onPressed: () {
              controller.loadLandingPage();
              Get.back();
            },
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: TextField(
                  controller: controller.searchController,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search or enter website',
                    filled: false,
                    isDense: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                    hintStyle: TextStyle(
                      color: Color(0xFF817C75),
                      fontSize: 18,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textPrimary(context),
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      controller.performSearch(query.trim());
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: const Icon(Icons.refresh, size: 25),
            onPressed: () {
              if (controller.stage.value == ImportStage.landing) {
                final query = controller.searchController.text.trim();
                if (query.isNotEmpty) {
                  controller.performSearch(query);
                } else {
                  controller.webViewController.reload();
                }
              } else {
                controller.webViewController.reload();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportBar(ImportWebController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surface(context).withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Handle
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary(context),
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            const SizedBox(height: 18),

            if (controller.showImportBar)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.isImporting.value
                      ? null
                      : () async {
                          final recipe = await controller.scrapeCurrentPage();

                          if (recipe != null && context.mounted) {
                            _openRecipeBottomSheet(context, recipe, controller);
                          }
                        },
                  icon: controller.isImporting.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: CustomText(
                    controller.isImporting.value
                        ? "Importing..."
                        : "Import Recipe",

                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  OnboardingLineIcon(
                    'book',
                    size: 34,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  const CustomText(
                    "Open a recipe to import",
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 4),
                  const CustomText(
                    "Browse any recipe website and import instantly",
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navButton(
                  iconWidget: const OnboardingLineIcon(
                    'back',
                    size: 22,
                    color: Color(0xFF4A4A4A),
                  ),
                  onTap: () {
                    controller.webViewController.canGoBack().then((can) {
                      if (can) {
                        controller.webViewController.goBack();
                      } else {
                        controller.loadLandingPage();
                      }
                    });
                  },
                ),

                const SizedBox(width: 20),

                _navButton(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    controller.webViewController.reload();
                  },
                ),

                const SizedBox(width: 20),

                _navButton(
                  iconWidget: const OnboardingLineIcon(
                    'chevR',
                    size: 22,
                    color: Color(0xFF4A4A4A),
                  ),
                  onTap: () {
                    controller.webViewController.canGoForward().then((can) {
                      if (can) {
                        controller.webViewController.goForward();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({
    IconData? icon,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          width: 52,
          child:
              iconWidget ??
              Icon(icon, size: 22, color: const Color(0xFF4A4A4A)),
        ),
      ),
    );
  }

  void _openRecipeBottomSheet(
    BuildContext context,
    ScrapedRecipeData recipe,
    ImportWebController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _RecipePreviewSheet(recipe: recipe, controller: controller);
      },
    );
  }
}

// ===========================================================================
// Screen 4 + 5/6: Recipe preview bottom sheet, Save button, and the
// "How did we do?" feedback overlay shown right after saving.
// ===========================================================================
class _RecipePreviewSheet extends StatefulWidget {
  final ScrapedRecipeData recipe;
  final ImportWebController controller;

  const _RecipePreviewSheet({required this.recipe, required this.controller});

  @override
  State<_RecipePreviewSheet> createState() => _RecipePreviewSheetState();
}

class _RecipePreviewSheetState extends State<_RecipePreviewSheet> {
  bool _saved = false;
  bool _isSaving = false;
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final success = await widget.controller.saveRecipe(widget.recipe);

    if (!mounted) return;

    setState(() {
      _isSaving = false;

      if (success) {
        _saved = true;
      }
    });
  }

  List<Widget> _buildIngredientSections(List<IngredientSection> sections) {
    final widgets = <Widget>[];
    log('Sections count: ${widget.recipe.ingredientSections.length}');
    for (final section in sections) {
      log('Section: ${section.name} | Items: ${section.items.length}');

      if (section.name != null && section.name!.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: CustomText(
              section.name!,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        );
      }
      for (final ing in section.items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 10),
                  child: CustomText(
                    '•',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: CustomText(
                    ing,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildInstructionSections(List<InstructionSection> sections) {
    final widgets = <Widget>[];
    int stepNum = 1;
    for (final section in sections) {
      if (section.name != null && section.name!.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: CustomText(
              section.name!,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        );
      }
      for (final step in section.steps) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomText(
                    '$stepNum',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    step,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        stepNum++;
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            _buildSheetContent(context, scrollController),

            if (_isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),

            if (_saved)
              Positioned.fill(
                child: _SavedFeedbackOverlay(
                  onClose: () => Navigator.of(context).pop(),
                  onDone: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final recipe = widget.recipe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText(
                'Recipe Ai',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),

              IconButton(
                icon: const OnboardingLineIcon('x', color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFFF4EFC9),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Obx(
              () => CustomText(
                '${widget.controller.freeRecipesLeft.value}/${ImportWebController.freeRecipesTotal} recipes left. '
                'Try Plus for free',
                fontSize: 14,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: recipe.imageUrl != null
                        ? Image.network(
                            recipe.imageUrl!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,

                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;

                              return Container(
                                width: 110,
                                height: 110,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              );
                            },

                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 110,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          recipe.title,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                        ),
                        if (recipe.description != null) ...[
                          const SizedBox(height: 8),
                          CustomText(
                            recipe.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Hook up real editing later.
                          },
                          icon: const OnboardingLineIcon(
                            'pencil',
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          label: const CustomText('Edit recipe'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _RecipeOverview(recipe: recipe),
              const SizedBox(height: 20),
              const CustomText(
                'INGREDIENTS',
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 24,
              ),
              const SizedBox(height: 12),
              if (recipe.ingredientSections.isEmpty ||
                  recipe.ingredients.isEmpty)
                const CustomText('No ingredients found on this page.')
              else
                ..._buildIngredientSections(recipe.ingredientSections),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 16),
              const CustomText(
                'INSTRUCTIONS',
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 24,
              ),
              const SizedBox(height: 12),
              if (recipe.instructionSections.isEmpty ||
                  recipe.instructions.isEmpty)
                const CustomText('No instructions found on this page.')
              else
                ..._buildInstructionSections(recipe.instructionSections),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_saved || _isSaving) ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const CustomText(
                      'Save',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 16),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              CustomText('Report mistake', color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeOverview extends StatelessWidget {
  final ScrapedRecipeData recipe;

  const _RecipeOverview({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final items = <({IconData? icon, Widget? iconWidget, String label})>[
      if (recipe.totalTime != null)
        (
          icon: null,
          iconWidget: const OnboardingLineIcon(
            'clock',
            size: 16,
            color: AppTheme.primary,
          ),
          label: 'Total ${recipe.totalTime}',
        ),
      if (recipe.prepTime != null)
        (
          icon: null,
          iconWidget: const OnboardingLineIcon(
            'timerR',
            size: 16,
            color: AppTheme.primary,
          ),
          label: 'Prep ${recipe.prepTime}',
        ),
      if (recipe.cookTime != null)
        (
          icon: null,
          iconWidget: const OnboardingLineIcon(
            'flame',
            size: 16,
            color: AppTheme.primary,
          ),
          label: 'Cook ${recipe.cookTime}',
        ),
      if (recipe.servings != null)
        (
          icon: null,
          iconWidget: const OnboardingLineIcon(
            'friend',
            size: 16,
            color: AppTheme.primary,
          ),
          label: recipe.servings!,
        ),
      if (recipe.category != null)
        (
          icon: Icons.category_outlined,
          iconWidget: null,
          label: recipe.category!,
        ),
      if (recipe.cuisine != null)
        (
          icon: null,
          iconWidget: const OnboardingLineIcon(
            'globe',
            size: 16,
            color: AppTheme.primary,
          ),
          label: recipe.cuisine!,
        ),
    ];

    if (items.isEmpty && recipe.keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.map(
          (item) => _OverviewChip(
            icon: item.icon,
            iconWidget: item.iconWidget,
            label: item.label,
          ),
        ),
        ...recipe.keywords
            .take(4)
            .map(
              (keyword) =>
                  _OverviewChip(icon: Icons.sell_outlined, label: keyword),
            ),
      ],
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;

  const _OverviewChip({this.icon, this.iconWidget, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: CustomText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "How did we do?" emoji feedback overlay shown right after Save.
class _SavedFeedbackOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onDone;

  const _SavedFeedbackOverlay({required this.onClose, required this.onDone});

  static const List<String> _emojis = ['😠', '🙁', '😐', '🙂', '😁'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Spacer(),
                  IconButton(
                    icon: const OnboardingLineIcon('x', color: Colors.black87),
                    onPressed: onClose,
                  ),
                ],
              ),
              const OnboardingLineIcon(
                'checkCircle',
                color: AppTheme.primary,
                size: 80,
              ),
              const SizedBox(height: 12),
              const CustomText(
                'Recipe saved',
                fontSize: 16,
                color: Colors.black54,
              ),
              const SizedBox(height: 6),
              CustomText(
                'How did we do?',
                fontSize: 20,
                color: AppTheme.surface(context),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _emojis
                    .map((e) => CustomText(e, fontSize: 30))
                    .toList(),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: CustomText('Done', color: AppTheme.surface(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageLoadingOverlay extends StatelessWidget {
  const _PageLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8DDD2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              CustomText('Loading recipe page', fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ),
    );
  }
}
