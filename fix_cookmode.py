import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'package:recipe_ai/Service/recipe_localizer.dart';", "import 'package:recipe_ai/Service/recipe_localizer.dart';\nimport 'package:recipe_ai/Model/recipe_section_model.dart';")

content = content.replace("widget._displayTitle", "_displayTitle")
content = content.replace("_displayTitle", "_displayTitle") # no-op

content = content.replace("String get _displayTitle => _localized?.title ?? _displayTitle;", "String get _displayTitle => _localized?.title ?? widget.recipe.title;")

# Fix unused field warning
content = content.replace("bool _localizing = true;", "bool _localizing = true;\n  bool get isLocalizing => _localizing;")
content = content.replace("      body: _localizing", "      body: isLocalizing")

with open('lib/View/Home/cook_mode_screen.dart', 'w') as f:
    f.write(content)

