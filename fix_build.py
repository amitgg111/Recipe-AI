import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""    if (_isFinished) {
      return _FinishView(
        recipe: widget.recipe,
        stepCount: _steps.length,""",
"""    if (_isFinished) {
      return _FinishView(
        recipe: widget.recipe,
        displayTitle: _displayTitle,
        stepCount: _steps.length,"""
)

with open('lib/View/Home/cook_mode_screen.dart', 'w') as f:
    f.write(text)
