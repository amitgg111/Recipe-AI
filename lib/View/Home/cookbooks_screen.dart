import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';

import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Core/Theme/app_theme_controller.dart';

import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/View/Home/cookbook_recipes_screen.dart';
import 'package:recipe_ai/View/Home/import_from_social_screen.dart';
import 'package:recipe_ai/View/Home/import_from_text_screen.dart';
import 'package:recipe_ai/View/Home/import_from_web.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/Widget/custom_text.dart';

class CookbooksScreen extends StatelessWidget {
  const CookbooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const CustomText(
          "Recipe AI",
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          Obx(
            () => Switch(
              value: themeController.isDark,
              onChanged: (_) {
                themeController.toggleTheme();
              },
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const CustomText(
            //   "Good Morning",
            //   fontSize: 26,
            //   fontWeight: FontWeight.bold,
            // ),

            // const SizedBox(height: 8),

            // CustomText(
            //   "What would you like to cook today?",
            //   color: Colors.grey.shade600,
            // ),
            // const SizedBox(height: 20),
            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CookbookSection(),
                  const SizedBox(height: 28),
                  const CustomText(
                    "Recipes",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 15),
                  if (controller.recipes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: CustomText(
                          "No recipes found. Add one to get started!",
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700
                            ? 3
                            : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.recipes.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                          itemBuilder: (context, index) {
                            return RecipeCard(
                              recipe: controller.recipes[index],
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ImportRecipeBottomSheet.show(context);
        },
        icon: const Icon(Icons.add, color: AppTheme.darkTextPrimary),
        label: const CustomText("Add Recipe", color: AppTheme.darkTextPrimary),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String title;

  const CategoryChip({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Chip(label: CustomText(title)),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeCard({super.key, required this.recipe});

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: RecipeImage(
                  imageUrl: recipe.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: CustomText(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: CustomText(
                "${recipe.ingredients.length} ingredients",
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookbookSection extends StatelessWidget {
  const _CookbookSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Cookbooks",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    "Organize your favorite recipes",
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ],
              ),
            ),

            FilledButton.icon(
              onPressed: () async {
                final cookbookController = Get.find<CookbookController>();
                final textController = TextEditingController();

                await Get.dialog(
                  AlertDialog(
                    title: const Text("Create Cookbook"),
                    content: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "Cookbook Name",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Get.back();

                          if (textController.text.trim().isEmpty) return;

                          await cookbookController.createCookbook(
                            textController.text.trim(),
                          );
                        },
                        child: const Text("Create"),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const CustomText("New", color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Obx(() {
          if (controller.cookbooks.isEmpty) {
            return Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 42, color: Colors.grey),
                  SizedBox(height: 10),
                  CustomText("No cookbooks yet", color: Colors.grey),
                ],
              ),
            );
          }

          return SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.cookbooks.length,
              itemBuilder: (_, index) {
                final cookbook = controller.cookbooks[index];

                return Container(
                  width: 180,
                  margin: EdgeInsets.only(
                    right: index == controller.cookbooks.length - 1 ? 0 : 14,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => CookbookRecipesScreen(cookbook: cookbook));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            cookbook.imageUrl != null &&
                                    cookbook.imageUrl!.isNotEmpty
                                ? Image.network(
                                    cookbook.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),

                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xCC000000),
                                    Color(0x55000000),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface(
                                    context,
                                  ).withValues(alpha: .8),
                                  shape: BoxShape.circle,
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.primary,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showRenameDialog(context, cookbook);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(context, cookbook);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Rename'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    cookbook.name,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    maxLines: 1,
                                  ),

                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.25),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      "${cookbook.recipeCount} Recipes",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecipeImage & placeholder  (shared widget used across all screens)
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
// Import recipe bottom sheet
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
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          const CustomText(
            "Add Recipe",
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 6),
          CustomText(
            "Choose how you'd like to add a recipe",
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 25),
          _ImportOptionTile(
            icon: Icons.video_library_outlined,
            title: "Import from Social Media",
            subtitle: "Instagram, Facebook, TikTok",
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
            title: "Import from Text",
            subtitle: "Just Enter The Recipe Name!",
            onTap: () async {
              Get.to(() => const GenerateRecipeScreen());
            },
          ),
          _ImportOptionTile(
            icon: Icons.language,
            title: "Import from Website",
            subtitle: "Paste recipe URL",
            onTap: () async {
              final importedRecipe = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportFromWebScreen()),
              );
              if (importedRecipe != null) {
                // Save to your list/database
              }
            },
          ),
          _ImportOptionTile(
            icon: Icons.photo_camera_outlined,
            title: "Import from Photo",
            subtitle: "Scan image or screenshot",

            onTap: () {
              RecipeImportService.importRecipeFromGallery(context);
            },
          ),
          _ImportOptionTile(
            icon: Icons.edit_note_outlined,
            title: "Create from Scratch",
            subtitle: "Write recipe manually",
            onTap: () {
              Get.to(() => RecipeEditorScreen());
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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: CustomText(title, fontWeight: FontWeight.w600, fontSize: 16),
      subtitle: CustomText(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

// // ─────────────────────────────────────────────────────────────────────────────
// // Full-screen loading overlay shown while Gemini analyses the recipe image
// // ─────────────────────────────────────────────────────────────────────────────

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

    // Cycle through step labels every 3 s
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
            color: AppTheme.surface(context),
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
              // Pulsing icon
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
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

              const CustomText(
                'Analyzing Recipe',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),

              const SizedBox(height: 10),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: CustomText(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  fontSize: 14,
                  color: AppTheme.lightTextSecondary,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 28),

              // Thin linear progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0x22FF6B35),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showRenameDialog(BuildContext context, CookbookModel cookbook) {
  final controller = Get.find<CookbookController>();

  final textController = TextEditingController(text: cookbook.name);

  Get.dialog(
    AlertDialog(
      title: const Text("Rename Cookbook"),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(hintText: "Cookbook Name"),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            final name = textController.text.trim();

            if (name.isEmpty) return;

            Get.back();

            await controller.updateCookbook(cookbook.id, name);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

void _showDeleteDialog(BuildContext context, CookbookModel cookbook) {
  final controller = Get.find<CookbookController>();

  Get.dialog(
    AlertDialog(
      title: const Text("Delete Cookbook"),
      content: Text('Are you sure you want to delete "${cookbook.name}"?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            Get.back();

            await controller.deleteCookbook(cookbook.id);
          },
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}
