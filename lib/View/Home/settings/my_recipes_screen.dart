import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/widgets/cannot_publish_dialog.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class MyRecipesScreen extends StatefulWidget {
  /// When true, only favourited recipes are shown and the header reads
  /// "Favorite recipes" — used by the Favorites entry in settings.
  final bool favoritesOnly;
  const MyRecipesScreen({super.key, this.favoritesOnly = false});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final HomeController _home = Get.find<HomeController>();
  int _filter = 0; // 0 all, 1 public, 2 private
  String _query = '';

  final Map<String, LocalizedRecipe> _localizedRecipes = {};
  final Set<String> _localizingRecipeIds = {};

  Future<LocalizedRecipe?> _getLocalizedRecipe(RecipeModel recipe) async {
    final cached = _localizedRecipes[recipe.id];
    if (cached != null) return cached;

    if (_localizingRecipeIds.contains(recipe.id)) {
      return null;
    }

    _localizingRecipeIds.add(recipe.id);

    try {
      final localized = await RecipeLocalizer.resolve(
        recipe.rawData,
        currentUid: AuthService.currentUser?.uid,
      );

      if (mounted) {
        setState(() {
          _localizedRecipes[recipe.id] = localized;
        });
      }

      return localized;
    } catch (e) {
      print('Failed to localize recipe ${recipe.id}: $e');
      return null;
    } finally {
      _localizingRecipeIds.remove(recipe.id);
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen(
      widget.favoritesOnly ? "FavoriteRecipesScreen" : "MyRecipesScreen",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          // In favourites mode start from only the favourited recipes.
          final all = widget.favoritesOnly
              ? _home.recipes.where((r) => r.isFavorite).toList()
              : _home.recipes.toList();
          final publicCount = all.where((r) => r.isPublic).length;
          final privateCount = all.length - publicCount;

          var list = all.where((r) {
            if (_filter == 1 && !r.isPublic) return false;
            if (_filter == 2 && r.isPublic) return false;
            if (_query.isNotEmpty &&
                !r.title.toLowerCase().contains(_query.toLowerCase())) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: SettingsUi.header(
                  widget.favoritesOnly
                      ? 'favorite_recipes'.tr
                      : 'my_recipes'.tr,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _searchBar(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    _chip(
                      'filter_all_count'.trParams({'count': '${all.length}'}),
                      0,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'filter_public_count'.trParams({'count': '$publicCount'}),
                      1,
                      // iconName: 'globe',
                      // iconColor: AppColors.green,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'filter_private_count'.trParams({
                        'count': '$privateCount',
                      }),
                      2,
                      // iconName: 'lock',
                      // iconColor: AppColors.textMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: list.isEmpty
                    ? _empty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < list.length; i++)
                                  _recipeRow(list[i], i != list.length - 1),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon(
            'search',
            size: 20,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'search_my_recipes'.tr,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int index, {String? iconName, Color? iconColor}) {
    final active = _filter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = index);

        AnalyticsService.instance.trackEvent(
          "recipe_filter_changed",
          parameters: {
            "filter": index == 0
                ? "all"
                : index == 1
                ? "public"
                : "private",
            "screen": widget.favoritesOnly ? "favorites" : "my_recipes",
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            if (iconName != null && !active) ...[
              OnboardingLineIcon(
                iconName,
                size: 14,
                color: iconColor ?? AppColors.textMedium,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: active ? Colors.white : AppColors.textBodyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recipeRow(RecipeModel recipe, bool showDivider) {
    final localized = _localizedRecipes[recipe.id];

    // Start localization once.
    if (localized == null && !_localizingRecipeIds.contains(recipe.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _getLocalizedRecipe(recipe);
        }
      });
    }

    final title = localized?.title.isNotEmpty == true
        ? localized!.title
        : recipe.title;

    return Column(
      children: [
        InkWell(
          onTap: () {
            AnalyticsService.instance.trackEvent(
              "recipe_opened",
              parameters: {
                "recipe_id": recipe.id,
                "is_public": recipe.isPublic,
                "source": widget.favoritesOnly ? "favorites" : "my_recipes",
              },
            );

            Get.to(() => RecipeDetailScreen(recipe: recipe));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                _thumb(recipe.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_filter == 0) _visibilityBadge(recipe.isPublic),
                GestureDetector(
                  onTap: () => _showOptions(recipe),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: OnboardingLineIcon(
                      'dots',
                      size: 20,
                      color: AppColors.iconLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _thumb(String? url) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.startsWith('http'))
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 150,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.restaurant_rounded, color: Colors.white),
            )
          : const Icon(Icons.restaurant_rounded, color: Colors.white),
    );
  }

  Widget _visibilityBadge(bool isPublic) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.greenBgLight : const Color(0xFFF2EEE6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: OnboardingLineIcon(
        isPublic ? 'globe' : 'lock',
        size: 16,
        color: isPublic ? AppColors.green : AppColors.textMedium,
      ),
    );
  }

  void _showOptions(RecipeModel recipe) {
    final makePublic = !recipe.isPublic;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.of(ctx).padding.bottom,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetItem(
              icon: Icons.open_in_new_rounded,
              label: 'view_recipe'.tr,
              onTap: () {
                Get.back();
                Get.to(() => RecipeDetailScreen(recipe: recipe));
              },
            ),
            _sheetItem(
              iconWidget: OnboardingLineIcon(
                makePublic ? 'globe' : 'lock',
                size: 21,
                color: makePublic ? AppColors.green : AppColors.textDark,
              ),
              label: makePublic ? 'make_public'.tr : 'make_private'.tr,
              color: makePublic ? AppColors.green : AppColors.textDark,
              onTap: () async {
                Get.back();

                if (makePublic && !recipe.canBePublished) {
                  showCannotPublishDialog();
                  return;
                }

                await _home.updateRecipeVisibility(recipe.id, makePublic);

                AnalyticsService.instance.trackEvent(
                  "recipe_visibility_changed",
                  parameters: {
                    "recipe_id": recipe.id,
                    "new_visibility": makePublic ? "public" : "private",
                  },
                );

                CustomSnackbar.show(
                  title: makePublic ? 'now_public'.tr : 'now_private'.tr,
                  message: makePublic
                      ? 'recipe_visible_in_discover'.tr
                      : 'recipe_only_visible_to_you'.tr,
                  type: SnackbarType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    final isSearching = _query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceBorderLight,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: OnboardingLineIcon(
                      'heartO',
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isSearching ? 'no_matches'.tr : 'no_recipes_here_yet'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
