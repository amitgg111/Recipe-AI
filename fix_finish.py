import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    content = f.read()

# Fix _FinishView constructor
content = content.replace(
"""class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final int stepCount;
  final int rating;""",
"""class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final String displayTitle;
  final int stepCount;
  final int rating;"""
)

content = content.replace(
"""  const _FinishView({
    required this.recipe,
    required this.stepCount,""",
"""  const _FinishView({
    required this.recipe,
    required this.displayTitle,
    required this.stepCount,"""
)

# Use widget.displayTitle in _FinishViewState
content = content.replace("_displayTitle", "widget.displayTitle")

# Fix _buildFinishScreen to pass _displayTitle
content = content.replace(
"""  Widget _buildFinishScreen(BuildContext context) {
    return _FinishView(
      recipe: widget.recipe,""",
"""  Widget _buildFinishScreen(BuildContext context) {
    return _FinishView(
      recipe: widget.recipe,
      displayTitle: _displayTitle,""" # this uses _displayTitle from _CookModeScreenState
)

# The issue is that I replaced "_displayTitle" globally in the last step which means it affects _CookModeScreenState as well.
# I need to revert that or just do a smarter replace.
