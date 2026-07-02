import 'package:flutter/material.dart';
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
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/segmented_control.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
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
  late Animation<double> _fabPulseAnimation;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _fabPulseAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const AppLogoMark(size: 24),
          ),
          const SizedBox(width: 10),
          Text(
            'Recipe AI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '5/5',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.gold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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
              child: Text('Cookbooks', style: AppTextStyles.screenTitle),
            ),
            const SizedBox(height: 40),
            const EmptyPlateIllustration(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              "Let's get cooking!",
              style: AppTextStyles.screenTitle.copyWith(fontSize: 27),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your cookbook is empty for now. Save your first recipe and it\'ll have a cozy home right here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Add your first recipe',
              leadingIcon: const Icon(Icons.add, color: Colors.white, size: 20),
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
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedControl(
                    segments: const ['Cookbooks', 'Recipes'],
                    selectedIndex: _selectedSegment,
                    onChanged: (i) => setState(() => _selectedSegment = i),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Container(
                    width: AppDimensions.appBarButtonSize,
                    height: AppDimensions.appBarButtonSize,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(color: AppColors.surfaceBorderLight),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: AppColors.textDark,
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
              hintText: _selectedSegment == 0
                  ? 'Search cookbooks'
                  : 'Search recipes',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_selectedSegment == 0)
            _buildCookbooksGrid(controller)
          else
            _buildRecipesGrid(controller),
        ],
      ),
    );
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
      final cookbooks = _sortCookbooks(cookbookController.cookbooks);
      if (cookbooks.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 40,
          ),
          child: Center(
            child: Text(
              'No cookbooks yet',
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
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.72,
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
      final recipes = _sortRecipes(controller.recipes);
      if (recipes.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 40,
          ),
          child: Center(
            child: Text(
              'No recipes yet. Add one to get started!',
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
          AnimatedBuilder(
            animation: _fabPulseAnimation,
            builder: (context, child) {
              return Container(
                width: AppDimensions.fabSize + 20,
                height: AppDimensions.fabSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: _fabPulseAnimation.value,
                    ),
                    width: 2,
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
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort By bottom sheet ──────────────────────────────────────────────────
  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header row
                  Row(
                    children: [
                      Text('Sort by', style: AppTextStyles.screenTitle),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                  _SortOption(
                    label: 'Newest first',
                    isSelected: _sortIndex == 0,
                    onTap: () {
                      setState(() => _sortIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Oldest first',
                    isSelected: _sortIndex == 1,
                    onTap: () {
                      setState(() => _sortIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Name A-Z',
                    isSelected: _sortIndex == 2,
                    onTap: () {
                      setState(() => _sortIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Name Z-A',
                    isSelected: _sortIndex == 3,
                    onTap: () {
                      setState(() => _sortIndex = 3);
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

  // ── Add Menu bottom sheet (Add Recipe / Add Cookbook) ───────────────────────
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text('Add to Recipe AI', style: AppTextStyles.screenTitle),
              const SizedBox(height: 6),
              Text(
                'Import from anywhere',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 24),
              // Add a Recipe
              _AddMenuOption(
                icon: Icons.receipt_long_outlined,
                iconBgColor: AppColors.primary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                title: 'Add a Recipe',
                subtitle: 'Import from anywhere',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportSourcePickerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Add a Cookbook
              _AddMenuOption(
                icon: Icons.menu_book_rounded,
                iconBgColor: const Color(0xFFFCE3DB),
                iconColor: AppColors.primary,
                title: 'Add a Cookbook',
                subtitle: 'Organize your recipes',
                onTap: () {
                  Navigator.pop(context);
                  _showNewCookbookSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── New Cookbook bottom sheet ───────────────────────────────────────────────
  void _showNewCookbookSheet(BuildContext context) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle + close
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
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
                const SizedBox(height: 8),
                // Title
                Text('New cookbook', style: AppTextStyles.screenTitle),
                const SizedBox(height: 20),
                // Name label
                Text('Title', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                // Text field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.primary, width: 1.5),
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
                    decoration: InputDecoration(
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
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '0 / 40',
                  style: AppTextStyles.smallLabel.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 24),
                // Create cookbook button
                GestureDetector(
                  onTap: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final cookbookCtrl = Get.find<CookbookController>();
                    cookbookCtrl.createCookbook(name);
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusButton,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primaryShadow,
                          blurRadius: 30,
                          offset: Offset(0, 16),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Create cookbook',
                          style: AppTextStyles.buttonLabel,
                        ),
                      ],
                    ),
                  ),
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
// Sort option row widget
// ─────────────────────────────────────────────────────────────────────────────

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceBorder,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Menu option tile
// ─────────────────────────────────────────────────────────────────────────────

class _AddMenuOption extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddMenuOption({
    required this.icon,
    required this.iconBgColor,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

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
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add a recipe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Import from social media banner
              GestureDetector(
                onTap: () {
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
                      Text(
                        'Import from social media',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share to Recipe AI from Instagram, TikTok,\nFacebook and more',
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
                          _socialIcon(
                            Icons.camera_alt_rounded,
                            const Color(0xFFE1306C),
                          ),
                          const SizedBox(width: 8),
                          _socialIcon(Icons.music_note_rounded, Colors.black),
                          const SizedBox(width: 8),
                          _socialIcon(
                            Icons.facebook_rounded,
                            const Color(0xFF1877F2),
                          ),
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
                      icon: Icons.photo_camera_outlined,
                      title: 'Import from\nphoto',
                      subtitle: 'Scan a cookbook page',
                      onTap: () {
                        Navigator.pop(context);
                        RecipeImportService.importRecipeFromGallery(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImportSourceCard(
                      icon: Icons.text_fields_rounded,
                      title: 'Import from text',
                      subtitle: 'Enter recipe name',
                      onTap: () {
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
                      icon: Icons.language_rounded,
                      title: 'Import from web',
                      subtitle: 'Paste a link',
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
                      icon: Icons.edit_note_rounded,
                      title: 'Write from\nscratch',
                      subtitle: 'Create manually',
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

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ImportSourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
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
                fontSize: 11.5,
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
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 1),
                child: _buildImageGrid(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cookbook.name,
            style: AppTextStyles.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${cookbook.recipeCount} ${cookbook.recipeCount == 1 ? 'recipe' : 'recipes'}',
            style: AppTextStyles.smallLabel,
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
              const SizedBox(width: 1.5),
              Expanded(child: _gridCell(urls, 1)),
            ],
          ),
        ),
        const SizedBox(height: 1.5),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _gridCell(urls, 2)),
              const SizedBox(width: 1.5),
              Expanded(child: _gridCell(urls, 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gridCell(List<String?> urls, int index) {
    if (index < urls.length && urls[index] != null) {
      return Image.network(
        urls[index]!,
        fit: BoxFit.cover,
        cacheWidth: 300,
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
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.iconLight, size: 24),
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
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: AppColors.textMedium,
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.totalTime ?? recipe.cookTime ?? '—',
                        style: AppTextStyles.smallLabel.copyWith(fontSize: 12),
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
      return Image.network(
        recipe.imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 600,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (_, child, loading) {
          if (loading == null) return child;
          return _imagePlaceholder();
        },
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
    return Image.network(
      imageUrl!,
      width: width ?? 50,
      height: height ?? 50,
      fit: BoxFit.cover,
      cacheWidth: 150,
      errorBuilder: (_, __, ___) =>
          _ImagePlaceholder(width: width ?? 50, height: height ?? 50),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _ImagePlaceholder(
          width: width ?? 50,
          height: height ?? 50,
          showLoader: true,
        );
      },
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
          Text('Add Recipe', style: AppTextStyles.screenTitle),
          const SizedBox(height: 6),
          Text(
            "Choose how you'd like to add a recipe",
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 25),
          _ImportOptionTile(
            icon: Icons.video_library_outlined,
            title: 'Import from Social Media',
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
            title: 'Import from Text',
            subtitle: 'Just Enter The Recipe Name!',
            onTap: () {
              Get.to(() => const GenerateRecipeScreen());
            },
          ),
          _ImportOptionTile(
            icon: Icons.language,
            title: 'Import from Website',
            subtitle: 'Paste recipe URL',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportFromWebScreen()),
              );
            },
          ),
          _ImportOptionTile(
            icon: Icons.photo_camera_outlined,
            title: 'Import from Photo',
            subtitle: 'Scan image or screenshot',
            onTap: () {
              RecipeImportService.importRecipeFromGallery(context);
            },
          ),
          _ImportOptionTile(
            icon: Icons.edit_note_outlined,
            title: 'Create from Scratch',
            subtitle: 'Write recipe manually',
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
              Text('Analyzing Recipe', style: AppTextStyles.cardTitle),
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
          Icon(isPublic ? Icons.public : Icons.lock_outline_rounded,
              size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
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
