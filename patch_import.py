import re

with open('lib/View/Home/import_complete_screen.dart', 'r') as f:
    text = f.read()

# Make it stateful
stateless_search = """class ImportCompleteScreen extends StatelessWidget {
  final RecipeModel recipe;
  final String? recipeId;

  const ImportCompleteScreen({super.key, required this.recipe, this.recipeId});

  @override
  Widget build(BuildContext context) {"""

stateless_replace = """import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/Service/auth_service.dart';

class ImportCompleteScreen extends StatefulWidget {
  final RecipeModel recipe;
  final String? recipeId;

  const ImportCompleteScreen({super.key, required this.recipe, this.recipeId});

  @override
  State<ImportCompleteScreen> createState() => _ImportCompleteScreenState();
}

class _ImportCompleteScreenState extends State<ImportCompleteScreen> {
  LocalizedRecipe? _localized;
  bool _localizing = true;

  @override
  void initState() {
    super.initState();
    _loadLocalizedText();
  }

  Future<void> _loadLocalizedText() async {
    try {
      Map<String, dynamic>? data = widget.recipe.rawData;
      if (data.isEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipe.id)
            .get();
        data = doc.data();
      }
      if (data == null || data.isEmpty) {
        if (mounted) setState(() => _localizing = false);
        return;
      }
      final localized = await RecipeLocalizer.resolve(
        data,
        currentUid: AuthService.currentUser?.uid,
      );
      if (mounted) {
        setState(() {
          _localized = localized;
          _localizing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _localizing = false);
    }
  }

  String get _displayTitle => _localized?.title ?? widget.recipe.title;
  List<String> get _displayIngredients => _localized?.ingredients ?? widget.recipe.ingredients;
  List<String> get _displayInstructions => _localized?.instructions ?? widget.recipe.instructions;

  @override
  Widget build(BuildContext context) {
    if (_localizing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final recipe = widget.recipe;"""
text = text.replace(stateless_search, stateless_replace)

# Replace TrText(recipe.title, ...) with Text(_displayTitle, ...)
text = text.replace("TrText(\n                            recipe.title,", "Text(\n                            _displayTitle,")

# Replace ingredients list in _ingredientsCard
# Wait, I can just replace recipe.ingredients with _displayIngredients globally
text = text.replace("recipe.ingredients", "_displayIngredients")
text = text.replace("recipe.instructions", "_displayInstructions")

# For NutritionScreen call
text = text.replace("recipeName: recipe.title", "recipeName: _displayTitle")

# Inside _saveButton and _editButton, context is passed, so we might need to replace recipe.title with _displayTitle
text = text.replace("recipe.title", "_displayTitle")

with open('lib/View/Home/import_complete_screen.dart', 'w') as f:
    f.write(text)
