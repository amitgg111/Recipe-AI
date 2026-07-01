import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final DiscoverController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DiscoverController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar + search + categories ──
          Container(
            color: AppColors.background,
            padding: EdgeInsets.only(top: top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const AppLogoMark(size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recipe',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        ' AI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSearchBar(
                    hintText: 'Search recipes, chefs...',
                    onChanged: (v) => controller.searchQuery.value = v,
                  ),
                ),
                const SizedBox(height: 14),

                // Category chips
                Obx(() {
                  final selected = controller.selectedCategory.value;
                  return SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: controller.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = controller.categories[i];
                        final isSelected = selected == cat;
                        return GestureDetector(
                          onTap: () => controller.selectCategory(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.surfaceBorderLight,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textBody,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ── Feed ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final items = controller.filteredRecipes;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No recipes found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different category or search',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.fetchDiscoverRecipes(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (_, i) => _RecipeCard(recipe: items[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recipe Card
// ═══════════════════════════════════════════════════════════════════════════════

class _RecipeCard extends StatelessWidget {
  final DiscoverRecipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User row
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceBorderLight,
                backgroundImage: recipe.userAvatar != null && recipe.userAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(recipe.userAvatar!)
                    : null,
                child: recipe.userAvatar == null || recipe.userAvatar!.isEmpty
                    ? Text(
                        recipe.userName.isNotEmpty ? recipe.userName[0].toUpperCase() : 'C',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Name
              Expanded(
                child: Text(
                  recipe.userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Category badge
              if (recipe.category != null && recipe.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recipe.category!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Image with title overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Recipe image
              AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: recipe.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.shimmerBase,
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 40, color: AppColors.shimmerHighlight),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.shimmerBase,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.shimmerHighlight),
                    ),
                  ),
                ),
              ),

              // Bottom gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Title on image
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  recipe.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Play button (visual indicator)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bookmark_border_rounded, size: 20, color: AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
