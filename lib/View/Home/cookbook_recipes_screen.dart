import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
// hide AnimatedBuilder: cookbooks_screen defines its own class of that name,
// which would otherwise clash with Flutter's AnimatedBuilder used below.
import 'package:recipe_ai/View/Home/cookbooks_screen.dart' hide AnimatedBuilder;
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/screens/import/import_picker_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

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
          final latestCookbook = cookbookController.cookbooks.firstWhereOrNull(
            (e) => e.id == cookbook.id,
          );

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
                onBack: () => Get.back(),
                onMenuTap: () =>
                    _showMenu(context, latestCookbook, cookbookController),
              ),
              const SizedBox(height: 4),
              // ── Title + subtitle ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  latestCookbook.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (recipes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    '${recipes.length == 1 ? 'n_recipe_lc'.trParams({'count': '${recipes.length}'}) : 'n_recipes_lc'.trParams({'count': '${recipes.length}'})} · ${'updated_today'.tr}',
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'no_recipes_yet'.tr,
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

  // ── Popup menu (Edit / Delete) — custom anchored card (HTML #21) ──────────
  void _showMenu(
    BuildContext context,
    CookbookModel cb,
    CookbookController ctrl,
  ) {
    final topOffset = MediaQuery.of(context).padding.top + 54;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: const Color(0x521E1B18), // rgba(30,27,24,.32)
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, child) {
        return Stack(
          children: [
            // Menu card
            Positioned(
              top: topOffset,
              right: 22,
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEFE6D6)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E1B18,
                            ).withValues(alpha: 0.45),
                            blurRadius: 50,
                            offset: const Offset(0, 24),
                            spreadRadius: -16,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuRow(
                            icon: Icons.edit_outlined,
                            iconColor: const Color(0xFF5A5147),
                            iconWidget: const OnboardingLineIcon(
                              'pencil',
                              size: 20,
                              color: Color(0xFF5A5147),
                            ),
                            label: 'edit'.tr,
                            labelColor: const Color(0xFF2A211B),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showRenameSheet(context, cb, ctrl);
                            },
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: const Color(0xFFF4ECDF),
                          ),
                          _menuRow(
                            icon: Icons.delete_outline,
                            iconColor: const Color(0xFFE0481F),
                            iconWidget: const OnboardingLineIcon(
                              'trash',
                              size: 20,
                              color: Color(0xFFE0481F),
                            ),
                            label: 'delete'.tr,
                            labelColor: const Color(0xFFE0481F),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showDeleteDialog(context, cb, ctrl);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _menuRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required VoidCallback onTap,
    Widget? iconWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rename bottom sheet (screen 22) ──────────────────────────────────────
  void _showRenameSheet(
    BuildContext context,
    CookbookModel cb,
    CookbookController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _RenameCookbookSheet(cb: cb, ctrl: ctrl),
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
                  child: const OnboardingLineIcon(
                    'trash',
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'delete_this_cookbook'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'delete_cookbook_message'.tr,
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
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Center(
                            child: Text(
                              'cancel'.tr,
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
                          Get.back();
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
                              'delete'.tr,
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
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE3D2)),
              ),
              child: const OnboardingLineIcon(
                'back',
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Centered title
          Expanded(
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Menu button
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE3D2)),
              ),
              child: const OnboardingLineIcon(
                'dots',
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

class _EmptyState extends StatefulWidget {
  final VoidCallback onAddRecipe;

  const _EmptyState({required this.onAddRecipe});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  // Two independent seamless bobs (ping-pong) matching the HTML @keyframes: the
  // book group `bob` (−13px / 4.4s) and the sparkle badge `floaty` (−7px / 3.6s).
  late final AnimationController _bookBob;
  late final AnimationController _badgeFloat;
  late final Animation<double> _bookBobAnim;
  late final Animation<double> _badgeFloatAnim;

  @override
  void initState() {
    super.initState();
    _bookBob = AnimationController(
      duration: const Duration(milliseconds: 2200), // half of 4.4s
      vsync: this,
    )..repeat(reverse: true);
    _bookBobAnim = Tween<double>(
      begin: 0,
      end: -13,
    ).animate(CurvedAnimation(parent: _bookBob, curve: Curves.easeInOut));
    _badgeFloat = AnimationController(
      duration: const Duration(milliseconds: 1800), // half of 3.6s
      vsync: this,
    )..repeat(reverse: true);
    _badgeFloatAnim = Tween<double>(
      begin: 0,
      end: -7,
    ).animate(CurvedAnimation(parent: _badgeFloat, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bookBob.dispose();
    _badgeFloat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Two-book empty illustration (HTML screen 20)
            SizedBox(
              width: 158,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Soft orange radial glow behind everything
                  Positioned(
                    top: -6,
                    left: (158 - 300) / 2,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.14),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.66],
                        ),
                      ),
                    ),
                  ),
                  // The two book pages, gently bobbing together
                  Positioned(
                    bottom: 0,
                    left: (158 - 148) / 2,
                    child: AnimatedBuilder(
                      animation: _bookBobAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _bookBobAnim.value),
                        child: child,
                      ),
                      child: SizedBox(
                        width: 148,
                        height: 104,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Left page (−7°, pivots at bottom-right)
                            Positioned(
                              left: 0,
                              top: 8,
                              child: Transform.rotate(
                                angle: -7 * math.pi / 180,
                                alignment: Alignment.bottomRight,
                                child: _bookCard(
                                  radius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  lineWidths: const [38, 30, 34],
                                ),
                              ),
                            ),
                            // Right page (+7°, pivots at bottom-left)
                            Positioned(
                              right: 0,
                              top: 8,
                              child: Transform.rotate(
                                angle: 7 * math.pi / 180,
                                alignment: Alignment.bottomLeft,
                                child: _bookCard(
                                  radius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  lineWidths: const [34, 38, 26],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating sparkle badge (gradient 160°)
                  Positioned(
                    top: -6,
                    left: (158 - 46) / 2,
                    child: AnimatedBuilder(
                      animation: _badgeFloatAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _badgeFloatAnim.value),
                        child: child,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(-0.342, -0.940),
                            end: Alignment(0.342, 0.940),
                            colors: [Color(0xFFFF8763), Color(0xFFF2623E)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.primaryShadow,
                              blurRadius: 26,
                              offset: Offset(0, 14),
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: const OnboardingLineIcon(
                          'sparkF2',
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'this_cookbook_is_empty'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'cookbook_empty_add_first'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Add a recipe button
            GestureDetector(
              onTap: () {
                Get.to(() => const ImportPickerScreen());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusButton + 10,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'plus',
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('add_a_recipe'.tr, style: AppTextStyles.buttonLabel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A single tilted "book page" card with faint text lines (72×92).
  Widget _bookCard({
    required BorderRadius radius,
    required List<double> lineWidths,
  }) {
    return Container(
      width: 72,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFF0E7D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: -18,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lineWidths.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            Container(
              width: lineWidths[i],
              height: 6,
              decoration: BoxDecoration(
                color: i == 0
                    ? const Color(0xFFEEE7DA)
                    : const Color(0xFFF1ECE0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
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
          child: AppSearchBar(hintText: 'search_recipes'.tr),
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
            separatorBuilder: (_, __) => const SizedBox(height: 13),
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
class _RecipeListTile extends StatefulWidget {
  final RecipeModel recipe;

  const _RecipeListTile({required this.recipe});

  @override
  State<_RecipeListTile> createState() => _RecipeListTileState();
}

class _RecipeListTileState extends State<_RecipeListTile> {
  LocalizedRecipe? _localizedRecipe;
  bool _isLocalizing = false;

  @override
  void initState() {
    super.initState();
    _loadLocalizedRecipe();
  }

  Future<void> _loadLocalizedRecipe() async {
    if (_isLocalizing) return;

    _isLocalizing = true;

    try {
      final localized = await RecipeLocalizer.resolve(
        widget.recipe.rawData,
        currentUid: FirebaseAuth.instance.currentUser?.uid,
      );

      if (!mounted) return;

      setState(() {
        _localizedRecipe = localized;
      });
    } catch (e) {
      debugPrint(
        'CookbookRecipesScreen: Failed to localize recipe '
        '${widget.recipe.id}: $e',
      );
    } finally {
      _isLocalizing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    // LocalizedRecipe available હોય તો localized title,
    // નહિતર initial render માટે original title.
    final title = _localizedRecipe?.title.isNotEmpty == true
        ? _localizedRecipe!.title
        : recipe.title;

    return GestureDetector(
      onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0E7D6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A211B).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -20,
            ),
          ],
        ),
        child: Row(
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 74,
                height: 74,
                child: _buildImage(recipe),
              ),
            ),

            const SizedBox(width: 14),

            // Title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const OnboardingLineIcon(
                        'clock',
                        size: 15,
                        color: Color(0xFFA89F90),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        recipe.totalTime ?? recipe.cookTime ?? '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A7E70),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron
            const OnboardingLineIcon(
              'chevR',
              size: 15,
              color: Color(0xFFC7BCAC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(RecipeModel recipe) {
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      return AppNetworkImage(
        recipe.imageUrl!,
        width: 74,
        height: 74,
        fit: BoxFit.cover,
        cacheWidth: 222,
        placeholder: _placeholder(),
        error: _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 74,
      height: 74,
      color: const Color(0xFFEDE5D7),
      child: Icon(
        Icons.restaurant_rounded,
        size: 26,
        color: AppColors.textLight.withValues(alpha: 0.4),
      ),
    );
  }
}

/// Bottom-sheet body for renaming a cookbook.
///
/// Owns its own [TextEditingController] and disposes it in [State.dispose], so
/// the controller's lifetime is tied exactly to this element. Flutter unhooks
/// the [TextField] before `dispose` runs, so the field can never touch a
/// disposed controller during the sheet's exit animation / autofill teardown
/// (the cause of the "TextEditingController was used after being disposed"
/// crash from the old `whenComplete(controller.dispose)` pattern).
class _RenameCookbookSheet extends StatefulWidget {
  final CookbookModel cb;
  final CookbookController ctrl;

  const _RenameCookbookSheet({required this.cb, required this.ctrl});

  @override
  State<_RenameCookbookSheet> createState() => _RenameCookbookSheetState();
}

class _RenameCookbookSheetState extends State<_RenameCookbookSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cb.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.ctrl.updateCookbook(widget.cb.id, name);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header row
            Row(
              children: [
                Text(
                  'rename_cookbook'.tr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A211B),
                    letterSpacing: -0.42,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F1EA),
                      shape: BoxShape.circle,
                    ),
                    child: const OnboardingLineIcon(
                      'x',
                      color: Color(0xFF8A7E70),
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Text field
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7F0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF2623E), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2623E).withValues(alpha: 0.12),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                cursorColor: const Color(0xFFF2623E),

                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A211B),
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'cookbook_name'.tr,
                  hintStyle: AppTextStyles.inputHint,
                  filled: false,
                  isCollapsed: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,

                  suffixIcon: _nameController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _nameController.clear();
                            setState(() {});
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFE8DC),
                              shape: BoxShape.circle,
                            ),
                            child: const OnboardingLineIcon(
                              'x',
                              size: 15,
                              color: Color(0xFFA89F90),
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  '${_nameController.text.length} / 40',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB0A899),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2623E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF2623E).withValues(alpha: 0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'save_changes'.tr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
