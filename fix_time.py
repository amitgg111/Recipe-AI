import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    text = f.read()

# Add displayTimeText to _CookModeScreenState
state_search = "  String get _displayTitle => _localized?.title ?? widget.recipe.title;"
state_replace = """  String get _displayTitle => _localized?.title ?? widget.recipe.title;
  String get _displayTimeText {
    final t = _localized?.totalTime ?? _localized?.cookTime ?? _localized?.prepTime ?? 
              widget.recipe.totalTime ?? widget.recipe.cookTime ?? widget.recipe.prepTime ?? '';
    return t.isEmpty ? '' : ' · ${t.toUpperCase()}';
  }"""
text = text.replace(state_search, state_replace)

# Pass it to _FinishView
build_search = """      return _FinishView(
        recipe: widget.recipe,
        displayTitle: _displayTitle,
        stepCount: _steps.length,"""
build_replace = """      return _FinishView(
        recipe: widget.recipe,
        displayTitle: _displayTitle,
        displayTimeText: _displayTimeText,
        stepCount: _steps.length,"""
text = text.replace(build_search, build_replace)

build2_search = """    return _FinishView(
      recipe: widget.recipe,
      displayTitle: _displayTitle,
      stepCount: _steps.length,"""
build2_replace = """    return _FinishView(
      recipe: widget.recipe,
      displayTitle: _displayTitle,
      displayTimeText: _displayTimeText,
      stepCount: _steps.length,"""
text = text.replace(build2_search, build2_replace)

# Add it to _FinishView
finish_search = """class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final String displayTitle;
  final int stepCount;"""
finish_replace = """class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final String displayTitle;
  final String displayTimeText;
  final int stepCount;"""
text = text.replace(finish_search, finish_replace)

finish2_search = """  const _FinishView({
    required this.recipe,
    required this.displayTitle,
    required this.stepCount,"""
finish2_replace = """  const _FinishView({
    required this.recipe,
    required this.displayTitle,
    required this.displayTimeText,
    required this.stepCount,"""
text = text.replace(finish2_search, finish2_replace)

# Use it in _FinishViewState
time_search = """  String get _timeText {
    final r = widget.recipe;
    final t = r.totalTime ?? r.cookTime ?? r.prepTime ?? '';
    return t.isEmpty ? '' : ' · ${t.toUpperCase()}';
  }"""
time_replace = """  String get _timeText => widget.displayTimeText;"""
text = text.replace(time_search, time_replace)

with open('lib/View/Home/cook_mode_screen.dart', 'w') as f:
    f.write(text)
