import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';

class CookbookRecipesScreen extends StatelessWidget {
  final CookbookModel cookbook;

  const CookbookRecipesScreen({super.key, required this.cookbook});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final cookbookController = Get.find<CookbookController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final latestCookbook = cookbookController.cookbooks
              .firstWhereOrNull((e) => e.id == cookbook.id);

          if (latestCookbook == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
            return const SizedBox();
          }

          final recipes = homeController.recipes
              .where((r) => latestCookbook.recipeIds.contains(r.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────────────────────────
              _TopBar(
                title: latestCookbook.name,
                onBack: () => Navigator.pop(context),
                onMenuTap: () => _showMenu(
                  context,
                  latestCookbook,
                  cookbookController,
                ),
              ),
              const SizedBox(height: 4),
              // ── Title + subtitle ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  latestCookbook.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (recipes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    '${recipes.length} ${recipes.length == 1 ? 'recipe' : 'recipes'} · updated today',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 2),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'No recipes yet',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],

              // ── Content ──────────────────────────────────────────────
              Expanded(
                child: recipes.isEmpty
                    ? _EmptyState(
                        onAddRecipe: () =>
                            ImportRecipeBottomSheet.show(context),
                      )
                    : _RecipeList(recipes: recipes),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Popup menu (Edit / Delete) ───────────────────────────────────────────
  void _showMenu(
    BuildContext context,
    CookbookModel cb,
    CookbookController ctrl,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          overlay.size.width - 60,
          MediaQuery.of(context).padding.top + 44,
          40,
          40,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: AppColors.textDark),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showRenameSheet(context, cb, ctrl);
      } else if (value == 'delete') {
        _showDeleteDialog(context, cb, ctrl);
      }
    });
  }

  // ── Rename bottom sheet (screen 22) ──────────────────────────────────────
  void _showRenameSheet(
    BuildContext context,
    CookbookModel cb,
    CookbookController ctrl,
  ) {
    final nameController = TextEditingController(text: cb.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Text(
                          'Rename cookbook',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Text field
                    Container(
                      height: AppDimensions.inputHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                        border:
                            Border.all(color: AppColors.primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: nameController,
                        autofocus: true,
                        style: AppTextStyles.inputText,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cookbook name',
                          hintStyle: AppTextStyles.inputHint,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: nameController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    nameController.clear();
                                    setSheetState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.cancel,
                                      size: 20,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${nameController.text.length} / 40',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    GestureDetector(
                      onTap: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        ctrl.updateCookbook(cb.id, name);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusButton,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryShadow,
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save changes',
                            style: AppTextStyles.buttonLabel,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete confirmation dialog (screen 23) ───────────────────────────────
  void _showDeleteDialog(
    BuildContext context,
    CookbookModel cb,
    CookbookController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trash icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Delete this cookbook?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete this cookbook? Note that this will not delete any of the individual recipes themselves.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          ctrl.deleteCookbook(cb.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Delete',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar: back + title + more menu
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Menu button
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (screen 20)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddRecipe;

  const _EmptyState({required this.onAddRecipe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Plate + utensils illustration
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dashed inner circle
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Plate lines
                        Icon(
                          Icons.restaurant_rounded,
                          size: 36,
                          color: AppColors.iconLight,
                        ),
                      ],
                    ),
                  ),
                  // Orange plus button
                  Positioned(
                    top: 20,
                    right: 80,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Fork left
                  Positioned(
                    left: 50,
                    top: 30,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        Icons.restaurant_outlined,
                        size: 28,
                        color: AppColors.textHint.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  // Knife right
                  Positioned(
                    right: 50,
                    bottom: 30,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Icon(
                        Icons.flatware_rounded,
                        size: 28,
                        color: AppColors.textHint.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'This cookbook is empty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first recipe and it\'ll show up here,\nready to cook.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Add a recipe button
            GestureDetector(
              onTap: onAddRecipe,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusButton,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Add a recipe', style: AppTextStyles.buttonLabel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe list with search (screen 19)
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeList extends StatelessWidget {
  final List<RecipeModel> recipes;

  const _RecipeList({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AppSearchBar(hintText: 'Search recipes'),
        ),
        const SizedBox(height: 12),
        // Recipe list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              4,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _RecipeListTile(recipe: recipe);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe list tile (matching the image row design)
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeListTile extends StatelessWidget {
  final RecipeModel recipe;

  const _RecipeListTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _buildImage(),
              ),
            ),
            const SizedBox(width: 14),
            // Title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.totalTime ?? recipe.cookTime ?? '—',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      return Image.network(
        recipe.imageUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, loading) {
          if (loading == null) return child;
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFF5EDE0),
      child: Icon(
        Icons.restaurant_rounded,
        size: 24,
        color: AppColors.textLight.withValues(alpha: 0.4),
      ),
    );
  }
}
