import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/Widget/custom_text.dart';

class CookbookRecipesScreen extends StatelessWidget {
  final CookbookModel cookbook;

  const CookbookRecipesScreen({super.key, required this.cookbook});

  void _confirmRemove(
    BuildContext context,
    CookbookController cookbookController,
    String recipeId,
    String recipeTitle,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText('Remove Recipe', fontWeight: FontWeight.w700),
        content: CustomText('Remove "$recipeTitle" from ${cookbook.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const CustomText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cookbookController.removeRecipeFromCookbook(
                cookbook.id,
                recipeId,
              );
              Navigator.of(ctx).pop();
            },
            child: const CustomText(
              'Remove',
              color: Color(0xFFD94F3D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final cookbookController = Get.find<CookbookController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: CustomText(
          cookbook.name,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      body: Obx(() {
        final latestCookbook = cookbookController.cookbooks.firstWhereOrNull(
          (e) => e.id == cookbook.id,
        );

        if (latestCookbook == null) {
          return const SizedBox();
        }

        final recipes = homeController.recipes
            .where((recipe) => latestCookbook.recipeIds.contains(recipe.id))
            .toList();

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDE8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_outlined,
                    size: 34,
                    color: Color(0xFFBBB8B2),
                  ),
                ),
                const SizedBox(height: 16),
                const CustomText(
                  'No recipes yet',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                const SizedBox(height: 6),
                const CustomText(
                  'Add recipes from the recipe detail screen',
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (_, index) {
            final recipe = recipes[index];

            return GestureDetector(
              onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
              onLongPress: () => _confirmRemove(
                context,
                cookbookController,
                recipe.id,
                recipe.title,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: RecipeImage(
                              imageUrl: recipe.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // Long-press hint icon
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _confirmRemove(
                                context,
                                cookbookController,
                                recipe.id,
                                recipe.title,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface(
                                    context,
                                  ).withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: CustomText(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: CustomText(
                        '${recipe.ingredients.length} ingredients',
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
