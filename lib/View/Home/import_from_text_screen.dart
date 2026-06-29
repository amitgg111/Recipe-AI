import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';

class GenerateRecipeScreen extends StatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  State<GenerateRecipeScreen> createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  final TextEditingController recipeController = TextEditingController();

  @override
  void dispose() {
    recipeController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    final recipeName = recipeController.text.trim();

    if (recipeName.isEmpty) {
      Get.snackbar(
        'Recipe Name Required',
        'Please enter a recipe name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await RecipeImportService.importRecipeFromName(recipeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 20),

            const Text(
              'Generate Recipe by Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Enter any recipe name and AI will generate complete recipe details.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            AppSearchBar(
              controller: recipeController,
              hintText: 'e.g. Paneer Butter Masala',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _generateRecipe(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _generateRecipe,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Generate Recipe',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Try recipe names like:\n\n'
                      '• Paneer Butter Masala\n'
                      '• Pizza Margherita\n'
                      '• Chocolate Cake\n'
                      '• Chicken Biryani\n'
                      '• Pasta Alfredo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
