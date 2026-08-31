// import 'dart:async';
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:recipe_ai/Service/ai_translation_service.dart';
// import 'package:recipe_ai/Service/auth_service.dart';
// import 'package:recipe_ai/Service/language_service.dart';
// import 'package:recipe_ai/Service/recipe_localizer.dart';
// import 'package:recipe_ai/screens/cookbooks/sort_sheet.dart';
// import 'package:recipe_ai/utils/locale_sort.dart';
// import 'package:recipe_ai/widgets/app_wordmark.dart';
// import 'package:recipe_ai/widgets/app_network_image.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:recipe_ai/Controllers/cookbook_controller.dart';
// import 'package:recipe_ai/Controllers/home_controller.dart';
// import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
// import 'package:recipe_ai/View/Home/cookbook_recipes_screen.dart';
// import 'package:recipe_ai/View/Home/import_from_social_screen.dart';
// import 'package:recipe_ai/View/Home/import_from_text_screen.dart';
// import 'package:recipe_ai/View/Home/import_from_web.dart';
// import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
// import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
// import 'package:recipe_ai/theme/app_colors.dart';
// import 'package:recipe_ai/Service/subscription_service.dart';
// import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
// import 'package:recipe_ai/widgets/app_logo.dart';
// import 'package:recipe_ai/theme/app_text_styles.dart';
// import 'package:recipe_ai/theme/app_spacing.dart';
// import 'package:recipe_ai/theme/app_dimensions.dart';
// import 'package:recipe_ai/widgets/empty_plate_illustration.dart';
// import 'package:recipe_ai/widgets/sliding_segmented.dart';
// import 'package:recipe_ai/widgets/app_search_bar.dart';
// import 'package:recipe_ai/screens/import/add_menu_sheet.dart';
// import 'package:recipe_ai/screens/import/add_cookbook_sheet.dart';
// import 'package:recipe_ai/screens/import/import_picker_screen.dart';
// import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
// import 'package:recipe_ai/widgets/primary_button.dart';

// class CookbooksScreen extends StatefulWidget {
//   final bool showRecipesTab;

//   const CookbooksScreen({super.key, this.showRecipesTab = false});

//   @override
//   State<CookbooksScreen> createState() => _CookbooksScreenState();
// }

// class _CookbooksScreenState extends State<CookbooksScreen>
//     with TickerProviderStateMixin {
//   late int _selectedSegment = widget.showRecipesTab ? 1 : 0;
//   int _sortIndex = 0;
//   late AnimationController _fabPulseController;

//   // ── Search ──────────────────────────────────────────────────────────────
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _fabPulseController = AnimationController(
//       duration: const Duration(milliseconds: 2400),
//       vsync: this,
//     )..repeat();

//     _bindSubscription();
//   }

//   Future<void> _bindSubscription() async {
//     try {
//       final user = AuthService.currentUser;

//       if (user == null) {
//         print('[CookbooksScreen] No logged-in user.');
//         return;
//       }

//       print(
//         '[CookbooksScreen] Binding subscription for UID: '
//         '${user.uid}',
//       );

//       await SubscriptionService.instance.bindUser(user.uid);

//       print(
//         '[CookbooksScreen] Firebase credits: '
//         '${SubscriptionService.instance.freeCredits}',
//       );
//     } catch (e) {
//       print('[CookbooksScreen] Subscription bind error: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _fabPulseController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<HomeController>();

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 _buildTopBar(),
//                 Expanded(
//                   child: Obx(() {
//                     if (controller.isLoading.value) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     final hasCookbooks = controller.cookbooks.isNotEmpty;
//                     final hasRecipes = controller.recipes.isNotEmpty;
//                     final isEmpty = !hasCookbooks && !hasRecipes;

//                     if (isEmpty) {
//                       return _buildEmptyState();
//                     }

//                     return _buildPopulatedState(controller);
//                   }),
//                 ),
//               ],
//             ),
//             _buildFAB(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTopBar() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.xl,
//         AppSpacing.md,
//         AppSpacing.xl,
//         0,
//       ),
//       child: Row(
//         children: [
//           const AppLogo(size: 36),

//           const SizedBox(width: 10),

//           const AppWordmark(
//             fontSize: 20,
//             fontWeight: FontWeight.w800,
//             letterSpacing: -0.3,
//           ),

//           const Spacer(),

//           Obx(() {
//             final sub = SubscriptionService.instance;

//             final plus = sub.isPlusListenable.value;

//             // Show the true remaining count (never negative). Credit amounts
//             // are Remote-Config driven now, so there is no fixed weekly max to
//             // clamp against.
//             final rawCredits = sub.freeCreditsListenable.value;
//             final remaining = rawCredits < 0 ? 0 : rawCredits;

//             print(
//               '[UI] Firebase remaining credits: '
//               '$remaining',
//             );

//             return GestureDetector(
//               onTap: () {
//                 Get.to(() => const UpgradePlusScreen());
//               },
//               behavior: HitTestBehavior.opaque,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 7,
//                 ),
//                 decoration: BoxDecoration(
//                   color: plus ? AppColors.purpleBg : AppColors.goldBg,
//                   borderRadius: BorderRadius.circular(
//                     AppDimensions.radiusRound,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(top: 5.0),
//                       child: OnboardingLineIcon(
//                         plus ? 'crown' : 'sparkF',
//                         size: 19,
//                         color: plus ? AppColors.purpleDark : AppColors.primary,
//                       ),
//                     ),

//                     const SizedBox(width: 5),

//                     Text(
//                       plus ? 'PLUS' : '$remaining Left',
//                       style: AppTextStyles.chipLabel.copyWith(
//                         color: plus ? AppColors.purpleDark : AppColors.gold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//         child: Column(
//           children: [
//             const EmptyPlateIllustration(),
//             const SizedBox(height: AppSpacing.xxl),
//             Text(
//               'lets_get_cooking'.tr,
//               style: GoogleFonts.plusJakartaSans(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 9),
//             Text(
//               'cookbook_empty_subtitle'.tr,
//               textAlign: TextAlign.center,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 fontSize: 13,
//                 color: AppColors.textBody,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xxl),
//             PrimaryButton(
//               label: 'add_your_first_recipe'.tr,
//               width: 230,
//               leadingIcon: const OnboardingLineIcon(
//                 'plus',
//                 color: Colors.white,
//                 size: 24,
//               ),
//               onPressed: () => _showAddMenu(context),
//             ),
//             const SizedBox(height: 100),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPopulatedState(HomeController controller) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.only(
//         bottom: AppDimensions.bottomNavHeight + AppSpacing.xxl,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 18),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: SlidingSegmented.tabs(
//                     labels: ['cookbooks'.tr, 'recipes'.tr],
//                     selectedIndex: _selectedSegment,
//                     onChanged: (i) => setState(() => _selectedSegment = i),
//                     height: 36,
//                   ),
//                 ),
//                 const SizedBox(width: AppSpacing.md),
//                 GestureDetector(
//                   onTap: () => _showSortSheet(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     width: AppDimensions.appBarButtonSize,
//                     height: AppDimensions.appBarButtonSize,
//                     decoration: BoxDecoration(
//                       color: AppColors.surface,
//                       borderRadius: BorderRadius.circular(13),
//                       border: Border.all(color: AppColors.surfaceBorderLight),
//                     ),
//                     child: const OnboardingLineIcon(
//                       'sort',
//                       size: 18,
//                       color: Color(0xFF9A938A),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//             child: AppSearchBar(
//               controller: _searchController,
//               hintText: _selectedSegment == 0
//                   ? 'search_cookbooks'.tr
//                   : 'search_recipes'.tr,
//               height: 50,
//               borderRadius: 14,
//               borderColor: const Color(0xFFEDE3D2),
//               showShadow: false,
//               hintStyle: GoogleFonts.plusJakartaSans(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: const Color(0xFFA89F90),
//               ),
//               prefixIcon: const OnboardingLineIcon(
//                 'search',
//                 size: 20,
//                 color: Color(0xFFA89F90),
//               ),
//               onChanged: (value) {
//                 setState(() => _searchQuery = value.trim());
//               },
//             ),
//           ),
//           const SizedBox(height: AppSpacing.lg),
//           if (_selectedSegment == 0)
//             _buildCookbooksGrid(controller)
//           else
//             _buildRecipesGrid(controller),
//         ],
//       ),
//     );
//   }

//   List<CookbookModel> _filterCookbooks(List<CookbookModel> cookbooks) {
//     if (_searchQuery.isEmpty) return cookbooks;
//     final query = _searchQuery.toLowerCase();
//     return cookbooks
//         .where((c) => c.name.toLowerCase().contains(query))
//         .toList();
//   }

//   /// A pending Firestore serverTimestamp reads as null right after an import —
//   /// treat it as "just now" (newest) so a freshly added item sorts to the TOP
//   /// of "Newest first" (and the bottom of "Oldest first") instead of the wrong
//   /// end while the real timestamp resolves on the server.
//   static int _byNewest(DateTime? a, DateTime? b) =>
//       (b ?? DateTime(9999)).compareTo(a ?? DateTime(9999));

//   static int _byOldest(DateTime? a, DateTime? b) =>
//       (a ?? DateTime(9999)).compareTo(b ?? DateTime(9999));

//   List<CookbookModel> _sortCookbooks(List<CookbookModel> cookbooks) {
//     final sorted = List<CookbookModel>.from(cookbooks);

//     switch (_sortIndex) {
//       case 0: // Newest first
//         sorted.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
//         break;

//       case 1: // Oldest first
//         sorted.sort((a, b) => _byOldest(a.createdAt, b.createdAt));
//         break;

//       case 2: // Name A-Z (language-aware)
//         sorted.sort((a, b) => LocaleSort.compare(a.name, b.name));
//         break;

//       case 3: // Name Z-A (language-aware)
//         sorted.sort((a, b) => LocaleSort.compare(b.name, a.name));
//         break;
//     }

//     return sorted;
//   }

//   Widget _buildCookbooksGrid(HomeController controller) {
//     return Obx(() {
//       final cookbookController = Get.find<CookbookController>();
//       final cookbooks = _sortCookbooks(
//         _filterCookbooks(cookbookController.cookbooks),
//       );

//       if (cookbooks.isEmpty) {
//         return _buildEmptyCookbooksState();
//       }

//       return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//         child: GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             mainAxisSpacing: 16,
//             crossAxisSpacing: 16,
//             // Slightly taller cells so the label + count line below the square
//             // cover never overflows, even for taller scripts (Devanagari) or
//             // longer translations.
//             childAspectRatio: 0.70,
//           ),
//           itemCount: cookbooks.length,
//           itemBuilder: (context, index) {
//             final cookbook = cookbooks[index];
//             print('Cookbooks count: ${cookbooks.length}');
//             return _CookbookCard(
//               key: ValueKey(cookbook.id), // ← આ ઉમેરો

//               cookbook: cookbook,
//               recipes: controller.recipes,
//               onTap: () {
//                 Get.to(() => CookbookRecipesScreen(cookbook: cookbook));
//               },
//             );
//           },
//         ),
//       );
//     });
//   }

//   Widget _buildEmptyCookbooksState() {
//     final isSearching = _searchQuery.trim().isNotEmpty;

//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.xl,
//         vertical: 32,
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 12),

//             Container(
//               width: 150,
//               height: 150,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withValues(alpha: 0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Center(child: Image.asset("assets/welcome/empty.png")),
//             ),
//             const SizedBox(height: 26),

//             // Title
//             Text(
//               isSearching ? 'No Data Found' : 'Your Cookbooks Are Empty',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.plusJakartaSans(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.textDark,
//               ),
//             ),

//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyRecipeState() {
//     final isSearching = _searchQuery.trim().isNotEmpty;

//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.xl,
//         vertical: 32,
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 12),

//             Container(
//               width: 150,
//               height: 150,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withValues(alpha: 0.08),
//                 shape: BoxShape.circle,
//               ),
//               child: Center(child: Image.asset("assets/welcome/empty.png")),
//             ),
//             const SizedBox(height: 26),

//             // Title
//             Text(
//               isSearching ? 'No Data Found' : 'Your Recipe Are Empty',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.plusJakartaSans(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.textDark,
//               ),
//             ),

//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }

//   List<RecipeModel> _filterRecipes(List<RecipeModel> recipes) {
//     if (_searchQuery.isEmpty) return recipes;
//     final query = _searchQuery.toLowerCase();
//     return recipes.where((r) => r.title.toLowerCase().contains(query)).toList();
//   }

//   List<RecipeModel> _sortRecipes(List<RecipeModel> recipes) {
//     final sorted = List<RecipeModel>.from(recipes);

//     switch (_sortIndex) {
//       case 0:
//         // NEWEST FIRST
//         sorted.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
//         break;

//       case 1:
//         // OLDEST FIRST
//         sorted.sort((a, b) => _byOldest(a.createdAt, b.createdAt));
//         break;

//       case 2:
//         // A-Z (language-aware)
//         sorted.sort((a, b) => LocaleSort.compare(a.title, b.title));
//         break;

//       case 3:
//         // Z-A (language-aware)
//         sorted.sort((a, b) => LocaleSort.compare(b.title, a.title));
//         break;
//     }

//     return sorted;
//   }

//   Widget _buildRecipesGrid(HomeController controller) {
//     return Obx(() {
//       final recipes = _sortRecipes(_filterRecipes(controller.recipes));

//       if (recipes.isEmpty) {
//         return _buildEmptyRecipeState();
//       }

//       return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
//         child: GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             mainAxisSpacing: 16,
//             crossAxisSpacing: 14,
//             childAspectRatio: 0.72,
//           ),
//           itemCount: recipes.length,
//           itemBuilder: (context, index) {
//             final recipe = recipes[index];
//             return _RecipeCard(recipe: recipe, key: ValueKey(recipe.id));
//           },
//         ),
//       );
//     });
//   }

//   Widget _buildFAB() {
//     return Positioned(
//       right: AppSpacing.xl,
//       bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // HTML `@keyframes ringpulse` (2.4s ease-out infinite): a solid
//           // FAB-coloured circle behind the button that expands scale .75→1.9
//           // and fades opacity .55→0 (gone by 70% of the cycle). It starts
//           // smaller than the FAB, so each loop restart stays hidden behind it.
//           AnimatedBuilder(
//             animation: _fabPulseController,
//             builder: (context, child) {
//               final t = Curves.easeOut.transform(_fabPulseController.value);
//               final scale = 0.75 + (1.9 - 0.75) * t;
//               final opacity = t < 0.7 ? 0.55 * (1 - t / 0.7) : 0.0;
//               return Opacity(
//                 opacity: opacity,
//                 child: Transform.scale(
//                   scale: scale,
//                   child: Container(
//                     width: AppDimensions.fabSize,
//                     height: AppDimensions.fabSize,
//                     decoration: const BoxDecoration(
//                       color: AppColors.primary,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           GestureDetector(
//             onTap: () {
//               HapticFeedback.mediumImpact();

//               _showAddMenu(context);
//             },
//             child: Container(
//               width: AppDimensions.fabSize,
//               height: AppDimensions.fabSize,
//               padding: const EdgeInsets.all(15),
//               decoration: const BoxDecoration(
//                 color: AppColors.primary,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primaryShadow,
//                     blurRadius: 20,
//                     offset: Offset(0, 8),
//                     spreadRadius: -4,
//                   ),
//                 ],
//               ),
//               child: const OnboardingLineIcon(
//                 'plus',
//                 color: Colors.white,
//                 size: 28,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Sort By bottom sheet ──────────────────────────────────────────────────

//   Future<void> _showSortSheet(BuildContext context) async {
//     final result = await SortSheet.show(context, selectedIndex: _sortIndex);

//     if (!mounted || result == null) return;

//     setState(() {
//       _sortIndex = result;
//     });
//   }

//   // Future<void> _showSortSheet(BuildContext context) async {
//   //   final selectedIndex = await SortSheet.show(context);

//   //   if (!mounted || selectedIndex == null) return;

//   //   setState(() {
//   //     _sortIndex = selectedIndex;
//   //   });
//   // }

//   // A single HTML-style sort row: a leading rounded icon box (a clock for the
//   // time sorts, or a letter for the name sorts) + the label, with a trailing
//   // orange check and a highlighted background on the selected row.

//   // ── Add Menu bottom sheet (Add Recipe / Add Cookbook) ───────────────────────
//   void _showAddMenu(BuildContext context) {
//     // The design-accurate "Add to Recipe AI" sheet (screen 24). Navigation is
//     // wired here; the sheet owns the layout/icons.
//     AddMenuSheet.show(
//       context,
//       onAddRecipe: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const ImportPickerScreen()),
//         );
//       },
//       onAddCookbook: () => showNewCookbookSheet(context),
//     );
//   }

//   // ── New Cookbook bottom sheet ───────────────────────────────────────────────
// }

// void showNewCookbookSheet(BuildContext context) async {
//   // Design-accurate "New cookbook" sheet (screen 27). It returns the typed
//   // title; we create the cookbook here.
//   final name = await AddCookbookSheet.show(context);
//   if (name != null && name.trim().isNotEmpty) {
//     Get.find<CookbookController>().createCookbook(name.trim());
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Cookbook card with 2x2 image grid
// // ─────────────────────────────────────────────────────────────────────────────

// class _CookbookCard extends StatefulWidget {
//   final CookbookModel cookbook;
//   final List<RecipeModel> recipes;
//   final VoidCallback onTap;
//   final Key key;

//   const _CookbookCard({
//     required this.cookbook,
//     required this.recipes,
//     required this.onTap,
//     required this.key,
//   });

//   @override
//   State<_CookbookCard> createState() => _CookbookCardState();
// }

// class _CookbookCardState extends State<_CookbookCard> {
//   String _translatedName = '';
//   StreamSubscription<int>? _langSub;

//   List<String?> get _imageUrls {
//     final images = <String?>[];
//     for (final id in widget.cookbook.recipeIds) {
//       final recipe = widget.recipes.firstWhereOrNull(
//         (recipe) => recipe.id == id,
//       );
//       if (recipe != null &&
//           recipe.imageUrl != null &&
//           recipe.imageUrl!.isNotEmpty) {
//         images.add(recipe.imageUrl);
//       }
//       if (images.length == 4) break;
//     }
//     return images;
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadTranslation();

//     // ── ભાષા બદલાય ત્યારે ફરી translate ──
//     _langSub = LanguageService.languageVersion.listen((_) {
//       _loadTranslation();
//     });
//   }

//   @override
//   void dispose() {
//     _langSub?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadTranslation() async {
//     print('Loading translation for: ${widget.cookbook.name}');
//     final translated = await AiTranslationService.translateCookbookName(
//       widget.cookbook.name,
//     );
//     print('Translated: "$translated" for ${widget.cookbook.name}');
//     if (mounted) {
//       setState(() => _translatedName = translated);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final displayName = _translatedName.isNotEmpty
//         ? _translatedName
//         : widget.cookbook.name;

//     return GestureDetector(
//       onTap: widget.onTap,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           AspectRatio(
//             aspectRatio: 1,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFEDE5D7),
//                 borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
//                 border: Border.all(color: AppColors.surfaceBorder),
//               ),
//               clipBehavior: Clip.antiAlias,
//               child: _buildImageGrid(),
//             ),
//           ),
//           const SizedBox(height: 9),
//           Text(
//             displayName,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: GoogleFonts.plusJakartaSans(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textDark,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             widget.cookbook.recipeCount == 1
//                 ? 'n_recipe_lc'.trParams({
//                     'count': '${widget.cookbook.recipeCount}',
//                   })
//                 : 'n_recipes_lc'.trParams({
//                     'count': '${widget.cookbook.recipeCount}',
//                   }),
//             style: GoogleFonts.plusJakartaSans(
//               fontSize: 13,
//               fontWeight: FontWeight.w400,
//               color: const Color(0xFF9A938A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImageGrid() {
//     final urls = _imageUrls;

//     return Column(
//       children: [
//         Expanded(
//           child: Row(
//             children: [
//               Expanded(child: _gridCell(urls, 0)),

//               const SizedBox(width: 2),

//               Expanded(child: _gridCell(urls, 1)),
//             ],
//           ),
//         ),

//         const SizedBox(height: 2),

//         Expanded(
//           child: Row(
//             children: [
//               Expanded(child: _gridCell(urls, 2)),

//               const SizedBox(width: 2),

//               Expanded(child: _gridCell(urls, 3)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _gridCell(List<String?> urls, int index) {
//     if (index >= urls.length || urls[index] == null || urls[index]!.isEmpty) {
//       return _placeholder();
//     }

//     return AppNetworkImage(
//       urls[index]!,
//       width: double.infinity,
//       height: double.infinity,
//       fit: BoxFit.cover,
//       cacheWidth: 300,
//       placeholder: _placeholder(),
//       error: _placeholder(),
//     );
//   }

//   Widget _placeholder() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: const Color(0xFFE7DECE),

//       child: const Center(
//         child: OnboardingLineIcon('image', size: 20, color: Color(0xFFCFC5B4)),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Recipe card
// // ─────────────────────────────────────────────────────────────────────────────

// class _RecipeCard extends StatefulWidget {
//   final RecipeModel recipe;

//   const _RecipeCard({super.key, required this.recipe});
//   @override
//   State<_RecipeCard> createState() => _RecipeCardState();
// }

// class _RecipeCardState extends State<_RecipeCard> {
//   LocalizedRecipe? _localizedRecipe;
//   bool _isLocalizing = false;
//   StreamSubscription<int>? _langSub;

//   @override
//   void initState() {
//     super.initState();
//     _loadLocalizedRecipe();
//     _langSub = LanguageService.languageVersion.listen((_) {
//       _loadLocalizedRecipe();
//     });
//   }

//   @override
//   void dispose() {
//     _langSub?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadLocalizedRecipe() async {
//     if (_isLocalizing) return;

//     _isLocalizing = true;

//     try {
//       final localized = await RecipeLocalizer.resolve(
//         widget.recipe.rawData,
//         currentUid: AuthService.currentUser?.uid,
//       );

//       if (!mounted) return;

//       setState(() {
//         _localizedRecipe = localized;
//       });
//     } catch (e) {
//       log('Cookbook recipe localization failed: $e');
//     } finally {
//       _isLocalizing = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => RecipeDetailScreen(recipe: widget.recipe),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
//           border: Border.all(color: AppColors.surfaceBorder),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   const ClipRRect(
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(AppDimensions.radiusLg - 1),
//                     ),
//                   ),
//                   _buildImage(),

//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: GestureDetector(
//                       onTap: () {
//                         Get.find<HomeController>().toggleFavorite(
//                           widget.recipe.id,
//                           !widget.recipe.isFavorite,
//                         );
//                       },
//                       behavior: HitTestBehavior.opaque,
//                       child: Container(
//                         width: 28,
//                         height: 28,
//                         padding: const EdgeInsets.all(5),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withValues(alpha: 0.92),
//                           shape: BoxShape.circle,
//                         ),
//                         child: OnboardingLineIcon(
//                           widget.recipe.isFavorite ? 'heart' : 'heartO',
//                           size: 18,
//                           color: AppColors.pinterest,
//                         ),
//                       ),
//                     ),
//                   ),

//                   Positioned(
//                     top: 8,
//                     left: 8,
//                     child: _PrivacyBadge(isPublic: widget.recipe.isPublic),
//                   ),
//                 ],
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _localizedRecipe?.title ?? widget.recipe.title,
//                     style: AppTextStyles.chipLabel.copyWith(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.textDark,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       const OnboardingLineIcon(
//                         'clock',
//                         size: 14,
//                         color: AppColors.textLight,
//                       ),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           _localizedRecipe?.totalTime ??
//                               widget.recipe.totalTime ??
//                               widget.recipe.cookTime ??
//                               '—',
//                           style: AppTextStyles.smallLabel.copyWith(
//                             fontSize: 12,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImage() {
//     final imageUrl = widget.recipe.imageUrl;

//     if (imageUrl == null || imageUrl.isEmpty) {
//       return _imagePlaceholder();
//     }

//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(
//         top: Radius.circular(AppDimensions.radiusLg - 1),
//       ),
//       child: AppNetworkImage(
//         imageUrl,
//         width: double.infinity,
//         height: double.infinity,
//         fit: BoxFit.cover,

//         // Smaller decoded image = faster memory usage
//         // and faster rendering inside a card.
//         cacheWidth: 400,

//         // Show placeholder immediately.
//         placeholder: _imagePlaceholder(),

//         // Don't leave the card blank if image fails.
//         error: _imagePlaceholder(),
//       ),
//     );
//   }

//   Widget _imagePlaceholder() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: const Color(0xFFF5EDE0),
//       alignment: Alignment.center,
//       child: Icon(
//         Icons.restaurant_rounded,
//         size: 36,
//         color: AppColors.textLight.withValues(alpha: 0.4),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // RecipeImage (shared widget)
// // ─────────────────────────────────────────────────────────────────────────────

// class RecipeImage extends StatelessWidget {
//   final String? imageUrl;
//   final double? width;
//   final double? height;

//   const RecipeImage({
//     super.key,
//     required this.imageUrl,
//     this.width,
//     this.height,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return _ImagePlaceholder(width: width ?? 50, height: height ?? 50);
//     }
//     return AppNetworkImage(
//       imageUrl!,
//       width: width ?? 50,
//       height: height ?? 50,
//       fit: BoxFit.cover,
//       cacheWidth: 150,
//       placeholder: _ImagePlaceholder(
//         width: width ?? 50,
//         height: height ?? 50,
//         showLoader: true,
//       ),
//       error: _ImagePlaceholder(width: width ?? 50, height: height ?? 50),
//     );
//   }
// }

// class _ImagePlaceholder extends StatelessWidget {
//   final double width;
//   final double height;
//   final bool showLoader;

//   const _ImagePlaceholder({
//     required this.width,
//     required this.height,
//     this.showLoader = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width,
//       height: height,
//       color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
//       alignment: Alignment.center,
//       child: showLoader
//           ? const SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//           : Icon(
//               Icons.restaurant_menu,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Import recipe bottom sheet (kept for backward compat)
// // ─────────────────────────────────────────────────────────────────────────────

// class ImportRecipeBottomSheet extends StatelessWidget {
//   const ImportRecipeBottomSheet({super.key});

//   static Future<String?> show(BuildContext context) {
//     return showModalBottomSheet<String>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => const ImportRecipeBottomSheet(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
//       decoration: const BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 50,
//             height: 5,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text('add_recipe'.tr, style: AppTextStyles.screenTitle),
//           const SizedBox(height: 6),
//           Text('choose_how_add_recipe'.tr, style: AppTextStyles.bodyMedium),
//           const SizedBox(height: 25),
//           _ImportOptionTile(
//             icon: Icons.video_library_outlined,
//             title: 'import_from_social_media'.tr,
//             subtitle: 'Instagram, Facebook, TikTok',
//             onTap: () {
//               Get.back();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const ImportFromSocialScreen(),
//                 ),
//               );
//             },
//           ),
//           _ImportOptionTile(
//             icon: Icons.language,
//             title: 'import_from_text'.tr,
//             subtitle: 'just_enter_recipe_name'.tr,
//             onTap: () {
//               Get.to(() => const GenerateRecipeScreen());
//             },
//           ),
//           _ImportOptionTile(
//             icon: Icons.language,
//             title: 'import_from_website'.tr,
//             subtitle: 'paste_recipe_url'.tr,
//             onTap: () async {
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ImportFromWebScreen()),
//               );
//             },
//           ),
//           _ImportOptionTile(
//             icon: Icons.photo_camera_outlined,
//             title: 'import_from_photo'.tr,
//             subtitle: 'scan_image_or_screenshot'.tr,
//             onTap: () {
//               RecipeImportService.importRecipeFromGallery(context);
//             },
//           ),
//           _ImportOptionTile(
//             icon: Icons.edit_note_outlined,
//             title: 'create_from_scratch'.tr,
//             subtitle: 'write_recipe_manually'.tr,
//             onTap: () {
//               Get.to(() => const RecipeEditorScreen());
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ImportOptionTile extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   const _ImportOptionTile({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(vertical: 6),
//       leading: Container(
//         width: 52,
//         height: 52,
//         decoration: BoxDecoration(
//           color: AppColors.primary.withValues(alpha: 0.1),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Icon(icon, color: AppColors.primary),
//       ),
//       title: Text(title, style: AppTextStyles.bodyLarge),
//       subtitle: Text(subtitle, style: AppTextStyles.smallLabel),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Photo import loading overlay
// // ─────────────────────────────────────────────────────────────────────────────

// class PhotoImportLoadingOverlay extends StatefulWidget {
//   const PhotoImportLoadingOverlay({
//     super.key,
//     this.steps = const [
//       'Reading your image…',
//       'Identifying ingredients…',
//       'Building instructions…',
//       'Saving your recipe…',
//     ],
//   });

//   final List<String> steps;

//   @override
//   State<PhotoImportLoadingOverlay> createState() =>
//       _PhotoImportLoadingOverlayState();
// }

// class _PhotoImportLoadingOverlayState extends State<PhotoImportLoadingOverlay>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _pulse;
//   late final Animation<double> _scale;
//   late final List<String> _steps;
//   int _stepIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _steps = widget.steps;
//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _scale = Tween<double>(
//       begin: 0.92,
//       end: 1.08,
//     ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
//     _tickStep();
//   }

//   void _tickStep() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
//       _tickStep();
//     });
//   }

//   @override
//   void dispose() {
//     _pulse.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       child: Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(28),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.18),
//                 blurRadius: 32,
//                 offset: const Offset(0, 12),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ScaleTransition(
//                 scale: _scale,
//                 child: Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [AppColors.primary, AppColors.primaryLight],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(22),
//                   ),
//                   child: const Icon(
//                     Icons.auto_awesome,
//                     color: Colors.white,
//                     size: 38,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 28),
//               Text('analyzing_recipe'.tr, style: AppTextStyles.cardTitle),
//               const SizedBox(height: 10),
//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 400),
//                 child: Text(
//                   _steps[_stepIndex],
//                   key: ValueKey(_stepIndex),
//                   style: AppTextStyles.bodyMedium,
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 28),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: const LinearProgressIndicator(
//                   minHeight: 4,
//                   backgroundColor: Color(0x22FF6B35),
//                   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Helpers
// // ─────────────────────────────────────────────────────────────────────────────

// class AnimatedBuilder extends AnimatedWidget {
//   final Widget Function(BuildContext context, Widget? child) builder;
//   final Widget? child;

//   const AnimatedBuilder({
//     super.key,
//     required Animation<double> animation,
//     required this.builder,
//     this.child,
//   }) : super(listenable: animation);

//   @override
//   Widget build(BuildContext context) {
//     return builder(context, child);
//   }
// }

// // ═══════════════════════════════════════════════════════════════════════════════
// // PRIVACY BADGE — 🔒 Private / 🌍 Public (used on My Recipes cards)
// // ═══════════════════════════════════════════════════════════════════════════════

// class _PrivacyBadge extends StatelessWidget {
//   final bool isPublic;
//   const _PrivacyBadge({required this.isPublic});

//   @override
//   Widget build(BuildContext context) {
//     final fg = isPublic ? const Color(0xFF1F7A5E) : const Color(0xFF5A5147);
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.92),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           OnboardingLineIcon(isPublic ? 'globe' : 'lock', size: 12, color: fg),
//           const SizedBox(width: 4),
//           Text(
//             isPublic ? 'public'.tr : 'private'.tr,
//             style: GoogleFonts.plusJakartaSans(
//               fontSize: 10,
//               fontWeight: FontWeight.w800,
//               color: fg,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/language_service.dart';
import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/screens/cookbooks/sort_sheet.dart';
import 'package:recipe_ai/utils/locale_sort.dart';
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
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_spacing.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/empty_plate_illustration.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:recipe_ai/screens/import/add_menu_sheet.dart';
import 'package:recipe_ai/screens/import/add_cookbook_sheet.dart';
import 'package:recipe_ai/screens/import/import_picker_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookbooksScreen extends StatefulWidget {
  final bool showRecipesTab;

  const CookbooksScreen({super.key, this.showRecipesTab = false});

  @override
  State<CookbooksScreen> createState() => _CookbooksScreenState();
}

class _CookbooksScreenState extends State<CookbooksScreen>
    with TickerProviderStateMixin {
  late int _selectedSegment = widget.showRecipesTab ? 1 : 0;
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

    _bindSubscription();
  }

  Future<void> _bindSubscription() async {
    try {
      final user = AuthService.currentUser;

      if (user == null) {
        print('[CookbooksScreen] No logged-in user.');
        return;
      }

      print(
        '[CookbooksScreen] Binding subscription for UID: '
        '${user.uid}',
      );

      await SubscriptionService.instance.bindUser(user.uid);

      print(
        '[CookbooksScreen] Firebase credits: '
        '${SubscriptionService.instance.freeCredits}',
      );
    } catch (e) {
      print('[CookbooksScreen] Subscription bind error: $e');
    }
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

            // Show the true remaining count (never negative). Credit amounts
            // are Remote-Config driven now, so there is no fixed weekly max to
            // clamp against.
            final rawCredits = sub.freeCreditsListenable.value;
            final remaining = rawCredits < 0 ? 0 : rawCredits;

            print(
              '[UI] Firebase remaining credits: '
              '$remaining',
            );

            return GestureDetector(
              onTap: !plus
                  ? () {
                      Get.to(() => const UpgradePlusScreen());
                    }
                  : () {},
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
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: OnboardingLineIcon(
                        plus ? 'crown' : 'sparkF',
                        size: 19,
                        color: plus ? AppColors.purpleDark : AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      plus ? 'PLUS' : '$remaining Left',
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

  /// A pending Firestore serverTimestamp reads as null right after an import —
  /// treat it as "just now" (newest) so a freshly added item sorts to the TOP
  /// of "Newest first" (and the bottom of "Oldest first") instead of the wrong
  /// end while the real timestamp resolves on the server.
  static int _byNewest(DateTime? a, DateTime? b) =>
      (b ?? DateTime(9999)).compareTo(a ?? DateTime(9999));

  static int _byOldest(DateTime? a, DateTime? b) =>
      (a ?? DateTime(9999)).compareTo(b ?? DateTime(9999));

  List<CookbookModel> _sortCookbooks(List<CookbookModel> cookbooks) {
    final sorted = List<CookbookModel>.from(cookbooks);

    switch (_sortIndex) {
      case 0: // Newest first
        sorted.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
        break;

      case 1: // Oldest first
        sorted.sort((a, b) => _byOldest(a.createdAt, b.createdAt));
        break;

      case 2: // Name A-Z (language-aware)
        sorted.sort((a, b) => LocaleSort.compare(a.name, b.name));
        break;

      case 3: // Name Z-A (language-aware)
        sorted.sort((a, b) => LocaleSort.compare(b.name, a.name));
        break;
    }

    return sorted;
  }

  Widget _buildCookbooksGrid(HomeController controller) {
    return Obx(() {
      final cookbookController = Get.find<CookbookController>();
      final cookbooks = _sortCookbooks(
        _filterCookbooks(cookbookController.cookbooks),
      );

      if (cookbooks.isEmpty) {
        return _buildEmptyCookbooksState();
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
            print('Cookbooks count: ${cookbooks.length}');
            return _CookbookCard(
              key: ValueKey(cookbook.id), // ← આ ઉમેરો

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

  Widget _buildEmptyCookbooksState() {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 32,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(child: Image.asset("assets/welcome/empty.png")),
            ),
            const SizedBox(height: 26),

            // Title
            Text(
              isSearching ? 'No Data Found' : 'Your Cookbooks Are Empty',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecipeState() {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 32,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(child: Image.asset("assets/welcome/empty.png")),
            ),
            const SizedBox(height: 26),

            // Title
            Text(
              isSearching ? 'No Data Found' : 'Your Recipe Are Empty',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<RecipeModel> _filterRecipes(List<RecipeModel> recipes) {
    if (_searchQuery.isEmpty) return recipes;
    final query = _searchQuery.toLowerCase();
    return recipes.where((r) => r.title.toLowerCase().contains(query)).toList();
  }

  List<RecipeModel> _sortRecipes(List<RecipeModel> recipes) {
    final sorted = List<RecipeModel>.from(recipes);

    switch (_sortIndex) {
      case 0:
        // NEWEST FIRST
        sorted.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
        break;

      case 1:
        // OLDEST FIRST
        sorted.sort((a, b) => _byOldest(a.createdAt, b.createdAt));
        break;

      case 2:
        // A-Z (language-aware)
        sorted.sort((a, b) => LocaleSort.compare(a.title, b.title));
        break;

      case 3:
        // Z-A (language-aware)
        sorted.sort((a, b) => LocaleSort.compare(b.title, a.title));
        break;
    }

    return sorted;
  }

  Widget _buildRecipesGrid(HomeController controller) {
    return Obx(() {
      final recipes = _sortRecipes(_filterRecipes(controller.recipes));

      if (recipes.isEmpty) {
        return _buildEmptyRecipeState();
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
            final recipe = recipes[index];
            return _RecipeCard(recipe: recipe, key: ValueKey(recipe.id));
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
            onTap: () {
              HapticFeedback.mediumImpact();

              _showAddMenu(context);
            },
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

  Future<void> _showSortSheet(BuildContext context) async {
    final result = await SortSheet.show(context, selectedIndex: _sortIndex);

    if (!mounted || result == null) return;

    setState(() {
      _sortIndex = result;
    });
  }

  // ── Add Menu bottom sheet ──────────────────────────────────────────────
  void _showAddMenu(BuildContext context) {
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
}

void showNewCookbookSheet(BuildContext context) async {
  final name = await AddCookbookSheet.show(context);
  if (name != null && name.trim().isNotEmpty) {
    Get.find<CookbookController>().createCookbook(name.trim());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COOKBOOK CARD  (FIXED: translation reloads on rename)
// ═══════════════════════════════════════════════════════════════════════════════

class _CookbookCard extends StatefulWidget {
  final CookbookModel cookbook;
  final List<RecipeModel> recipes;
  final VoidCallback onTap;
  final Key key;

  const _CookbookCard({
    required this.cookbook,
    required this.recipes,
    required this.onTap,
    required this.key,
  });

  @override
  State<_CookbookCard> createState() => _CookbookCardState();
}

class _CookbookCardState extends State<_CookbookCard> {
  String _translatedName = '';
  StreamSubscription<int>? _langSub;

  // Unique counter for each translation attempt – only the latest one applies.
  int _translationId = 0;

  List<String?> get _imageUrls {
    final images = <String?>[];
    for (final id in widget.cookbook.recipeIds) {
      final recipe = widget.recipes.firstWhereOrNull(
        (recipe) => recipe.id == id,
      );
      if (recipe != null &&
          recipe.imageUrl != null &&
          recipe.imageUrl!.isNotEmpty) {
        images.add(recipe.imageUrl);
      }
      if (images.length == 4) break;
    }
    return images;
  }

  @override
  void initState() {
    super.initState();
    _loadTranslation();

    // ── Language change listener ──
    _langSub = LanguageService.languageVersion.listen((_) {
      _loadTranslation();
    });
  }

  @override
  void dispose() {
    _langSub?.cancel();
    super.dispose();
  }

  // ── React to cookbook changes ──
  @override
  void didUpdateWidget(covariant _CookbookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the cookbook ID or name changed, reload translation.
    if (oldWidget.cookbook.id != widget.cookbook.id ||
        oldWidget.cookbook.name != widget.cookbook.name) {
      _loadTranslation();
    }
  }

  Future<void> _loadTranslation() async {
    // Increment the ID so that stale responses are ignored.
    final currentId = ++_translationId;
    final name = widget.cookbook.name;

    try {
      final translated = await AiTranslationService.translateCookbookName(name);
      // Only apply if this is still the latest request and widget is mounted.
      if (mounted && currentId == _translationId) {
        setState(() => _translatedName = translated);
      }
    } catch (e) {
      // If translation fails, we keep the existing _translatedName or fallback.
      // The fallback in build will show the original name if _translatedName is empty.
      if (mounted && currentId == _translationId) {
        // Optionally set _translatedName to '' to fallback to original.
        setState(() => _translatedName = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _translatedName.isNotEmpty
        ? _translatedName
        : widget.cookbook.name;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5D7),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageGrid(),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.cookbook.recipeCount == 1
                ? 'n_recipe_lc'.trParams({
                    'count': '${widget.cookbook.recipeCount}',
                  })
                : 'n_recipes_lc'.trParams({
                    'count': '${widget.cookbook.recipeCount}',
                  }),
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
    if (index >= urls.length || urls[index] == null || urls[index]!.isEmpty) {
      return _placeholder();
    }

    return AppNetworkImage(
      urls[index]!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      cacheWidth: 300,
      placeholder: _placeholder(),
      error: _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE7DECE),
      child: const Center(
        child: OnboardingLineIcon('image', size: 20, color: Color(0xFFCFC5B4)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RECIPE CARD (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class _RecipeCard extends StatefulWidget {
  final RecipeModel recipe;

  const _RecipeCard({super.key, required this.recipe});
  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  LocalizedRecipe? _localizedRecipe;
  bool _isLocalizing = false;
  StreamSubscription<int>? _langSub;

  @override
  void initState() {
    super.initState();
    _loadLocalizedRecipe();
    _langSub = LanguageService.languageVersion.listen((_) {
      _loadLocalizedRecipe();
    });
  }

  @override
  void dispose() {
    _langSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalizedRecipe() async {
    if (_isLocalizing) return;

    _isLocalizing = true;

    try {
      final localized = await RecipeLocalizer.resolve(
        widget.recipe.rawData,
        currentUid: AuthService.currentUser?.uid,
      );

      if (!mounted) return;

      setState(() {
        _localizedRecipe = localized;
      });
    } catch (e) {
      log('Cookbook recipe localization failed: $e');
    } finally {
      _isLocalizing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: widget.recipe),
          ),
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
                fit: StackFit.expand,
                children: [
                  const ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLg - 1),
                    ),
                  ),
                  _buildImage(),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        Get.find<HomeController>().toggleFavorite(
                          widget.recipe.id,
                          !widget.recipe.isFavorite,
                        );
                      },
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
                          widget.recipe.isFavorite ? 'heart' : 'heartO',
                          size: 18,
                          color: AppColors.pinterest,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: _PrivacyBadge(isPublic: widget.recipe.isPublic),
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
                    _localizedRecipe?.title ?? widget.recipe.title,
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
                          _localizedRecipe?.totalTime ??
                              widget.recipe.totalTime ??
                              widget.recipe.cookTime ??
                              '—',
                          style: AppTextStyles.smallLabel.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    final imageUrl = widget.recipe.imageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _imagePlaceholder();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusLg - 1),
      ),
      child: AppNetworkImage(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 400,
        placeholder: _imagePlaceholder(),
        error: _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5EDE0),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        size: 36,
        color: AppColors.textLight.withValues(alpha: 0.4),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RECIPE IMAGE (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
//  IMPORT BOTTOM SHEET (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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
              Get.back();
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

// ═══════════════════════════════════════════════════════════════════════════════
//  PHOTO IMPORT LOADING OVERLAY (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
//  HELPERS (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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
//  PRIVACY BADGE (unchanged)
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
