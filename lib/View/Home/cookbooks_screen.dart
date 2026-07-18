import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/View/Home/cookbook_recipes_screen.dart';
import 'package:recipe_ai/View/Home/import_from_social_screen.dart';
import 'package:recipe_ai/View/Home/import_from_text_screen.dart';
import 'package:recipe_ai/View/Home/import_from_web.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/widgets/premium_lock_overlay.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/screens/import/add_menu_sheet.dart';
import 'package:recipe_ai/screens/import/add_cookbook_sheet.dart';
import 'package:recipe_ai/screens/import/import_picker_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/empty_plate_illustration.dart';

class CookbooksScreen extends StatefulWidget {
  const CookbooksScreen({super.key});

  @override
  State<CookbooksScreen> createState() => _CookbooksScreenState();
}

class _CookbooksScreenState extends State<CookbooksScreen>
    with TickerProviderStateMixin {
  int _selectedSegment = 0;
  int _sortIndex = 0;
  late AnimationController _fabPulseController;

  // ── Search ──────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final hasCookbooks = controller.cookbooks.isNotEmpty;
                    final hasRecipes = controller.recipes.isNotEmpty;
                    final isEmpty = !hasCookbooks && !hasRecipes;

                    if (isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildPopulatedState(controller);
                  }),
                ),
              ],
            ),
            _buildFAB(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          const AppLogo(size: 36),
          const SizedBox(width: 10),
          const AppWordmark(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          const Spacer(),
          Obx(() {
            final sub = SubscriptionService.instance;
            final plus = sub.isPlusListenable.value;
            final remaining = sub.freeCreditsListenable.value.clamp(
              0,
              SubscriptionService.kInitialFreeCredits,
            );
            return GestureDetector(
              onTap: () => Get.to(() => const UpgradePlusScreen()),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: plus ? AppColors.purpleBg : AppColors.goldBg,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingLineIcon(
                      plus ? 'crown' : 'sparkF',
                      size: 14,
                      color: plus ? AppColors.purpleDark : AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      plus
                          ? 'PLUS'
                          : '$remaining/${SubscriptionService.kInitialFreeCredits}',
                      style: AppTextStyles.chipLabel.copyWith(
                        color: plus ? AppColors.purpleDark : AppColors.gold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'cookbooks'.tr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const EmptyPlateIllustration(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'lets_get_cooking'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'cookbook_empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'add_your_first_recipe'.tr,
              width: 230,
              leadingIcon: const OnboardingLineIcon(
                'plus',
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => _showAddMenu(context),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState(HomeController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.bottomNavHeight + AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: SlidingSegmented.tabs(
                    labels: ['cookbooks'.tr, 'recipes'.tr],
                    selectedIndex: _selectedSegment,
                    onChanged: (i) => setState(() => _selectedSegment = i),
                    height: 36,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: AppDimensions.appBarButtonSize,
                    height: AppDimensions.appBarButtonSize,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.surfaceBorderLight),
                    ),
                    child: const OnboardingLineIcon(
                      'sort',
                      size: 18,
                      color: Color(0xFF9A938A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppSearchBar(
              controller: _searchController,
              hintText: _selectedSegment == 0
                  ? 'search_cookbooks'.tr
                  : 'search_recipes'.tr,
              height: 50,
              borderRadius: 14,
              borderColor: const Color(0xFFEDE3D2),
              showShadow: false,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFA89F90),
              ),
              prefixIcon: const OnboardingLineIcon(
                'search',
                size: 20,
                color: Color(0xFFA89F90),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedSegment == 0)
            _buildCookbooksGrid(controller)
          else
            _buildRecipesGrid(controller),
        ],
      ),
    );
  }

  List<CookbookModel> _filterCookbooks(List<CookbookModel> cookbooks) {
    if (_searchQuery.isEmpty) return cookbooks;
    final query = _searchQuery.toLowerCase();
    return cookbooks
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  List<CookbookModel> _sortCookbooks(List<CookbookModel> cookbooks) {
    final sorted = List<CookbookModel>.from(cookbooks);
    switch (_sortIndex) {
      case 0: // Newest first (already from Firestore in desc order)
        return sorted;
      case 1: // Oldest first
        return sorted.reversed.toList();
      case 2: // Name A-Z
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return sorted;
      case 3: // Name Z-A
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        return sorted;
      default:
        return sorted;
    }
  }

  Widget _buildCookbooksGrid(HomeController controller) {
    return Obx(() {
      final cookbookController = Get.find<CookbookController>();
      final cookbooks = _sortCookbooks(
        _filterCookbooks(cookbookController.cookbooks),
      );
      if (cookbooks.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 40,
          ),
          child: Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'no_cookbooks_yet'.tr
                  : 'no_cookbooks_match'.trParams({'query': _searchQuery}),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            // Slightly taller cells so the label + count line below the square
            // cover never overflows, even for taller scripts (Devanagari) or
            // longer translations.
            childAspectRatio: 0.70,
          ),
          itemCount: cookbooks.length,
          itemBuilder: (context, index) {
            final cookbook = cookbooks[index];
            return _CookbookCard(
              cookbook: cookbook,
              recipes: controller.recipes,
              onTap: () {
                Get.to(() => CookbookRecipesScreen(cookbook: cookbook));
              },
            );
          },
        ),
      );
    });
  }

  List<RecipeModel> _filterRecipes(List<RecipeModel> recipes) {
    if (_searchQuery.isEmpty) return recipes;
    final query = _searchQuery.toLowerCase();
    return recipes.where((r) => r.title.toLowerCase().contains(query)).toList();
  }

  List<RecipeModel> _sortRecipes(List<RecipeModel> recipes) {
    final sorted = List<RecipeModel>.from(recipes);
    switch (_sortIndex) {
      case 0: // Newest first (already from Firestore in desc order)
        return sorted;
      case 1: // Oldest first
        return sorted.reversed.toList();
      case 2: // Name A-Z
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        return sorted;
      case 3: // Name Z-A
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        return sorted;
      default:
        return sorted;
    }
  }

  Widget _buildRecipesGrid(HomeController controller) {
    return Obx(() {
      final recipes = _sortRecipes(_filterRecipes(controller.recipes));
      if (recipes.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 40,
          ),
          child: Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'no_recipes_yet_add_one'.tr
                  : 'no_recipes_match'.trParams({'query': _searchQuery}),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            return _RecipeCard(recipe: recipes[index]);
          },
        ),
      );
    });
  }

  Widget _buildFAB() {
    return Positioned(
      right: AppSpacing.xl,
      bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // HTML `@keyframes ringpulse` (2.4s ease-out infinite): a solid
          // FAB-coloured circle behind the button that expands scale .75→1.9
          // and fades opacity .55→0 (gone by 70% of the cycle). It starts
          // smaller than the FAB, so each loop restart stays hidden behind it.
          AnimatedBuilder(
            animation: _fabPulseController,
            builder: (context, child) {
              final t = Curves.easeOut.transform(_fabPulseController.value);
              final scale = 0.75 + (1.9 - 0.75) * t;
              final opacity = t < 0.7 ? 0.55 * (1 - t / 0.7) : 0.0;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: AppDimensions.fabSize,
                    height: AppDimensions.fabSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => _showAddMenu(context),
            child: Container(
              width: AppDimensions.fabSize,
              height: AppDimensions.fabSize,
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryShadow,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const OnboardingLineIcon(
                'plus',
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort By bottom sheet ──────────────────────────────────────────────────
  void _showSortSheet(BuildContext context) {
    final options = [
      ('newest_first'.tr, 'clock'),
      ('oldest_first'.tr, 'clock'),
      ('name_a_z'.tr, 'A'),
      ('name_z_a'.tr, 'Z'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle (HTML: 42x5, #E7E0D2). No close button.
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E0D2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 14),
                    child: Text(
                      'sort_by'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A211B),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  for (var i = 0; i < options.length; i++)
                    _sortRow(
                      leading: options[i].$2,
                      label: options[i].$1,
                      isSelected: _sortIndex == i,
                      onTap: () {
                        setState(() => _sortIndex = i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // A single HTML-style sort row: a leading rounded icon box (a clock for the
  // time sorts, or a letter for the name sorts) + the label, with a trailing
  // orange check and a highlighted background on the selected row.
  Widget _sortRow({
    required String leading, // 'clock' or a single letter (e.g. 'A')
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final fg = isSelected ? const Color(0xFFF2623E) : const Color(0xFF8A7E70);
    final Widget leadingChild = leading == 'clock'
        ? OnboardingLineIcon('clock', color: fg, size: 20)
        : Text(
            leading,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFCE3DB)
                    : const Color(0xFFF4F1EA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: leadingChild,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: const Color(0xFF2A211B),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2623E),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const OnboardingLineIcon(
                  'check',
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Add Menu bottom sheet (Add Recipe / Add Cookbook) ───────────────────────
  void _showAddMenu(BuildContext context) {
    // The design-accurate "Add to Recipe AI" sheet (screen 24). Navigation is
    // wired here; the sheet owns the layout/icons.
    AddMenuSheet.show(
      context,
      onAddRecipe: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportPickerScreen()),
        );
      },
      onAddCookbook: () => showNewCookbookSheet(context),
    );
  }

  // ── New Cookbook bottom sheet ───────────────────────────────────────────────
  void showNewCookbookSheet(BuildContext context) async {
    // Design-accurate "New cookbook" sheet (screen 27). It returns the typed
    // title; we create the cookbook here.
    final name = await AddCookbookSheet.show(context);
    if (name != null && name.trim().isNotEmpty) {
      Get.find<CookbookController>().createCookbook(name.trim());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort option row widget
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Add Menu option tile
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Import Source Picker Screen (full screen — matching image 26)
// ─────────────────────────────────────────────────────────────────────────────

class ImportSourcePickerScreen extends StatelessWidget {
  const ImportSourcePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Top bar: back + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const OnboardingLineIcon(
                      'back',
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'add_a_recipe'.tr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ImportQuotaBanner(),
              const SizedBox(height: 20),

              // Import from social media banner
              GestureDetector(
                onTap: () {
                  if (!SubscriptionService.instance.canUseRecipeImport()) {
                    showUpgradeDialog(context, feature: 'Social imports');
                    return;
                  }
                  ImportFromSocialScreen.showPicker(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const OnboardingLineIcon(
                              'share',
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'import_from_social_media'.tr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'import_from_social_desc'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Social icons row
                      Row(
                        children: [
                          _socialIcon('camera', const Color(0xFFC13584)),
                          const SizedBox(width: 8),
                          _socialIcon('music', const Color(0xFF1F1F24)),
                          const SizedBox(width: 8),
                          _socialIcon('chat', const Color(0xFF2D6FE0)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Grid of import options (2x2)
              Row(
                children: [
                  Expanded(
                    child: _ImportSourceCard(
                      iconName: 'camera',
                      iconBg: const Color(0xFFE4ECFB),
                      iconColor: const Color(0xFF2D6FE0),
                      title: 'import_from_photo'.tr,
                      subtitle: 'scan_a_cookbook_page'.tr,
                      onTap: () {
                        if (!SubscriptionService.instance
                            .canUseRecipeImport()) {
                          showUpgradeDialog(context, feature: 'Photo import');
                          return;
                        }
                        Navigator.pop(context);
                        RecipeImportService.importRecipeFromGallery(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImportSourceCard(
                      iconName: 'file',
                      iconBg: const Color(0xFFFDEBD2),
                      iconColor: const Color(0xFFD98A12),
                      title: 'import_from_text'.tr,
                      subtitle: 'enter_recipe_name'.tr,
                      onTap: () {
                        if (!SubscriptionService.instance
                            .canUseRecipeImport()) {
                          showUpgradeDialog(context, feature: 'Text import');
                          return;
                        }
                        Navigator.pop(context);
                        Get.to(() => const GenerateRecipeScreen());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ImportSourceCard(
                      iconName: 'globe',
                      iconBg: const Color(0xFFEDE7FE),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'import_from_web'.tr,
                      subtitle: 'paste_a_link'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImportFromWebScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImportSourceCard(
                      iconName: 'pencil',
                      iconBg: const Color(0xFFDBF0E7),
                      iconColor: const Color(0xFF1F7A5E),
                      title: 'write_from_scratch'.tr,
                      subtitle: 'create_manually'.tr,
                      onTap: () {
                        Navigator.pop(context);
                        Get.to(() => const RecipeEditorScreen());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(String iconName, Color color) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: OnboardingLineIcon(iconName, size: 20, color: color),
    );
  }
}

/// Free-tier import quota strip on the "Add a recipe" screen. Reacts live to the
/// count; hidden entirely for Plus users (they have unlimited imports).
class _ImportQuotaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sub = SubscriptionService.instance;
      if (sub.isPlusListenable.value) return const SizedBox.shrink();
      final remaining = sub.freeCreditsListenable.value;
      final exhausted = remaining <= 0;
      const max = 5;
      final accent = exhausted ? AppColors.purpleDark : AppColors.primary;
      return GestureDetector(
        onTap: exhausted ? () => showUpgradeDialog(context) : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: exhausted ? AppColors.purpleBgLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: exhausted
                  ? AppColors.purpleBorder
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  exhausted ? Icons.lock_rounded : Icons.auto_awesome_rounded,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recipe_imports'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exhausted
                          ? 'imports_remaining_upgrade'.tr
                          : 'n_of_m_remaining'.trParams({
                              'remaining': '$remaining',
                              'max': '$max',
                            }),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: exhausted
                            ? AppColors.purpleDark
                            : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : remaining / max,
                        minHeight: 6,
                        backgroundColor: accent.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (exhausted)
                const PlusBadge()
              else
                Text(
                  '$remaining/$max',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _ImportSourceCard extends StatelessWidget {
  final String iconName;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportSourceCard({
    required this.iconName,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 175,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: OnboardingLineIcon(iconName, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.smallLabel.copyWith(
                color: AppColors.textMedium,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cookbook card with 2x2 image grid
// ─────────────────────────────────────────────────────────────────────────────

class _CookbookCard extends StatelessWidget {
  final CookbookModel cookbook;
  final List<RecipeModel> recipes;
  final VoidCallback onTap;

  const _CookbookCard({
    required this.cookbook,
    required this.recipes,
    required this.onTap,
  });

  List<String?> get _imageUrls {
    final images = <String?>[];
    for (final id in cookbook.recipeIds) {
      final recipe = recipes.firstWhereOrNull((r) => r.id == id);
      if (recipe != null &&
          recipe.imageUrl != null &&
          recipe.imageUrl!.isNotEmpty) {
        images.add(recipe.imageUrl);
      }
      if (images.length >= 4) break;
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flexible so the square image yields a couple of pixels when the
          // labels below are taller (e.g. Devanagari text) — prevents the
          // fixed grid cell from overflowing.
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5D7),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg - 1,
                  ),
                  child: _buildImageGrid(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            cookbook.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            cookbook.recipeCount == 1
                ? 'n_recipe_lc'.trParams({'count': '${cookbook.recipeCount}'})
                : 'n_recipes_lc'.trParams({'count': '${cookbook.recipeCount}'}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9A938A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final urls = _imageUrls;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _gridCell(urls, 0)),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(urls, 1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _gridCell(urls, 2)),
              const SizedBox(width: 2),
              Expanded(child: _gridCell(urls, 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gridCell(List<String?> urls, int index) {
    if (index < urls.length && urls[index] != null) {
      return AppNetworkImage(
        urls[index]!,
        fit: BoxFit.cover,
        cacheWidth: 300,
        placeholder: _placeholder(),
        error: _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE7DECE),
      child: const Center(
        // Design's exact image-placeholder glyph (rect + mountain + sun),
        // matching the HTML cookbook cover cell — not Material's image_outlined.
        child: OnboardingLineIcon('image', size: 20, color: Color(0xFFCFC5B4)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe card
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLg - 1),
                    ),
                    child: _buildImage(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Get.find<HomeController>().toggleFavorite(
                        recipe.id,
                        !recipe.isFavorite,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: OnboardingLineIcon(
                          recipe.isFavorite ? 'heart' : 'heartO',
                          size: 18,
                          color: AppColors.pinterest,
                        ),
                      ),
                    ),
                  ),
                  // Privacy badge (🔒 Private / 🌍 Public)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _PrivacyBadge(isPublic: recipe.isPublic),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppTextStyles.chipLabel.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const OnboardingLineIcon(
                        'clock',
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          recipe.totalTime ?? recipe.cookTime ?? '—',
                          style: AppTextStyles.smallLabel.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      return AppNetworkImage(
        recipe.imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 600,
        placeholder: _imagePlaceholder(),
        error: _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5EDE0),
      child: Icon(
        Icons.restaurant_rounded,
        size: 36,
        color: AppColors.textLight.withValues(alpha: 0.4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeImage (shared widget)
// ─────────────────────────────────────────────────────────────────────────────

class RecipeImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;

  const RecipeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _ImagePlaceholder(width: width ?? 50, height: height ?? 50);
    }
    return AppNetworkImage(
      imageUrl!,
      width: width ?? 50,
      height: height ?? 50,
      fit: BoxFit.cover,
      cacheWidth: 150,
      placeholder: _ImagePlaceholder(
        width: width ?? 50,
        height: height ?? 50,
        showLoader: true,
      ),
      error: _ImagePlaceholder(width: width ?? 50, height: height ?? 50),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final bool showLoader;

  const _ImagePlaceholder({
    required this.width,
    required this.height,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.restaurant_menu,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import recipe bottom sheet (kept for backward compat)
// ─────────────────────────────────────────────────────────────────────────────

class ImportRecipeBottomSheet extends StatelessWidget {
  const ImportRecipeBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportRecipeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Text('add_recipe'.tr, style: AppTextStyles.screenTitle),
          const SizedBox(height: 6),
          Text('choose_how_add_recipe'.tr, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 25),
          _ImportOptionTile(
            icon: Icons.video_library_outlined,
            title: 'import_from_social_media'.tr,
            subtitle: 'Instagram, Facebook, TikTok',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportFromSocialScreen(),
                ),
              );
            },
          ),
          _ImportOptionTile(
            icon: Icons.language,
            title: 'import_from_text'.tr,
            subtitle: 'just_enter_recipe_name'.tr,
            onTap: () {
              Get.to(() => const GenerateRecipeScreen());
            },
          ),
          _ImportOptionTile(
            icon: Icons.language,
            title: 'import_from_website'.tr,
            subtitle: 'paste_recipe_url'.tr,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportFromWebScreen()),
              );
            },
          ),
          _ImportOptionTile(
            icon: Icons.photo_camera_outlined,
            title: 'import_from_photo'.tr,
            subtitle: 'scan_image_or_screenshot'.tr,
            onTap: () {
              RecipeImportService.importRecipeFromGallery(context);
            },
          ),
          _ImportOptionTile(
            icon: Icons.edit_note_outlined,
            title: 'create_from_scratch'.tr,
            subtitle: 'write_recipe_manually'.tr,
            onTap: () {
              Get.to(() => const RecipeEditorScreen());
            },
          ),
        ],
      ),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.smallLabel),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo import loading overlay
// ─────────────────────────────────────────────────────────────────────────────

class PhotoImportLoadingOverlay extends StatefulWidget {
  const PhotoImportLoadingOverlay({
    super.key,
    this.steps = const [
      'Reading your image…',
      'Identifying ingredients…',
      'Building instructions…',
      'Saving your recipe…',
    ],
  });

  final List<String> steps;

  @override
  State<PhotoImportLoadingOverlay> createState() =>
      _PhotoImportLoadingOverlayState();
}

class _PhotoImportLoadingOverlayState extends State<PhotoImportLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final List<String> _steps;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _steps = widget.steps;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _tickStep();
  }

  void _tickStep() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
      _tickStep();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('analyzing_recipe'.tr, style: AppTextStyles.cardTitle),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0x22FF6B35),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVACY BADGE — 🔒 Private / 🌍 Public (used on My Recipes cards)
// ═══════════════════════════════════════════════════════════════════════════════

class _PrivacyBadge extends StatelessWidget {
  final bool isPublic;
  const _PrivacyBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    final fg = isPublic ? const Color(0xFF1F7A5E) : const Color(0xFF5A5147);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingLineIcon(isPublic ? 'globe' : 'lock', size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'public'.tr : 'private'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
