import re

with open('lib/View/Home/public_recipe_view_screen.dart', 'r') as f:
    text = f.read()

# Add recipe_localizer import
text = text.replace("import 'package:share_plus/share_plus.dart';", "import 'package:share_plus/share_plus.dart';\nimport 'package:recipe_ai/Service/recipe_localizer.dart';\nimport 'package:recipe_ai/Service/auth_service.dart';")

# Add _localized to state
state_search = """  int _ratingSum = 0;
  int _ratingCount = 0;
  double get _avgRating => _ratingCount > 0 ? _ratingSum / _ratingCount : 0;

  DiscoverRecipe get recipe => widget.recipe;"""
state_replace = """  int _ratingSum = 0;
  int _ratingCount = 0;
  double get _avgRating => _ratingCount > 0 ? _ratingSum / _ratingCount : 0;

  LocalizedRecipe? _localized;
  bool _localizing = true;
  bool get isLocalizing => _localizing;

  DiscoverRecipe get recipe => widget.recipe;"""
text = text.replace(state_search, state_replace)

# Modify _loadSocial to resolve localized text
load_search = """      final d = doc.data() ?? {};
      if (mounted) {
        setState(() {"""
load_replace = """      final d = doc.data() ?? {};
      final localized = await RecipeLocalizer.resolve(
        d,
        currentUid: AuthService.currentUser?.uid,
      );
      if (mounted) {
        setState(() {
          _localized = localized;
          _localizing = false;"""
text = text.replace(load_search, load_replace)

text = text.replace("      } catch (_) {}", "      } catch (_) {\n      if (mounted) setState(() => _localizing = false);\n    }")

# Replace usages in the UI
text = text.replace("recipe.title", "(_localized?.title ?? recipe.title)")
text = text.replace("recipe.description", "(_localized?.description ?? recipe.description)")
text = text.replace("recipe.category", "(_localized?.category ?? recipe.category)")
text = text.replace("recipe.cuisine", "(_localized?.cuisine ?? recipe.cuisine)")
text = text.replace("recipe.prepTime", "(_localized?.prepTime ?? recipe.prepTime)")
text = text.replace("recipe.cookTime", "(_localized?.cookTime ?? recipe.cookTime)")
text = text.replace("recipe.totalTime", "(_localized?.totalTime ?? recipe.totalTime)")
text = text.replace("recipe.servings", "(_localized?.servings ?? recipe.servings)")
text = text.replace("recipe.ingredients", "(_localized?.ingredients ?? recipe.ingredients)")
text = text.replace("recipe.instructions", "(_localized?.instructions ?? recipe.instructions)")

with open('lib/View/Home/public_recipe_view_screen.dart', 'w') as f:
    f.write(text)
