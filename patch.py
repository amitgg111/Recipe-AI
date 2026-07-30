import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    text = f.read()

# 1. Imports
text = text.replace(
    "import 'package:recipe_ai/widgets/onboarding_line_icon.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:recipe_ai/Service/auth_service.dart';\nimport 'package:recipe_ai/Service/recipe_localizer.dart';\nimport 'package:recipe_ai/widgets/onboarding_line_icon.dart';"
)

# 2. State vars in _CookModeScreenState
state_search = """  final Map<int, _StepTimer> _timers = {};
  Timer? _ticker;"""
state_replace = """  final Map<int, _StepTimer> _timers = {};
  Timer? _ticker;

  LocalizedRecipe? _localized;
  bool _localizing = true;
  bool get isLocalizing => _localizing;

  String get _displayTitle => _localized?.title ?? widget.recipe.title;
  List<String> get _displayInstructions => _localized?.instructions ?? widget.recipe.instructions;
  List<InstructionSection> get _displayInstructionSections => _localized?.instructionSections ?? widget.recipe.instructionSections;"""
text = text.replace(state_search, state_replace)

# 3. initState
init_search = """  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _steps = _parseSteps();
    _pageController = PageController();
  }"""
init_replace = """  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _steps = _parseSteps();
    _pageController = PageController();
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
          _steps.clear();
          _steps.addAll(_parseSteps());
        });
      }
    } catch (e) {
      if (mounted) setState(() => _localizing = false);
    }
  }"""
text = text.replace(init_search, init_replace)

# 4. _parseSteps
parse_search = """  List<_CookStep> _parseSteps() {
    final steps = <_CookStep>[];
    final hasSections = widget.recipe.instructionSections.any(
      (s) => s.steps.isNotEmpty,
    );

    if (hasSections) {
      for (final section in widget.recipe.instructionSections) {
        for (final step in section.steps) {
          steps.add(
            _CookStep(
              text: step,
              label: _labelFor(step, section.name),
              detectedSeconds: _extractDuration(step),
            ),
          );
        }
      }
    } else {
      for (final step in widget.recipe.instructions) {
        steps.add(
          _CookStep(
            text: step,
            label: _labelFor(step, null),
            detectedSeconds: _extractDuration(step),
          ),
        );
      }
    }"""
parse_replace = """  List<_CookStep> _parseSteps() {
    final steps = <_CookStep>[];
    final hasSections = _displayInstructionSections.any(
      (s) => s.steps.isNotEmpty,
    );

    if (hasSections) {
      for (final section in _displayInstructionSections) {
        for (final step in section.steps) {
          steps.add(
            _CookStep(
              text: step,
              label: _labelFor(step, section.name),
              detectedSeconds: _extractDuration(step),
            ),
          );
        }
      }
    } else {
      for (final step in _displayInstructions) {
        steps.add(
          _CookStep(
            text: step,
            label: _labelFor(step, null),
            detectedSeconds: _extractDuration(step),
          ),
        );
      }
    }"""
text = text.replace(parse_search, parse_replace)

# 5. Body loader
text = text.replace(
    "      body: _isFinished\n          ? _buildFinishScreen(context)\n          : Stack(",
    "      body: isLocalizing\n          ? const Center(child: CircularProgressIndicator(color: _C.primary))\n          : _isFinished\n          ? _buildFinishScreen(context)\n          : Stack("
)

# 6. Replace widget.recipe.title inside _CookModeScreenState ONLY
# It's safer to just replace specific lines.
text = text.replace("'recipe': widget.recipe.title,", "'recipe': _displayTitle,")
text = text.replace("text: widget.recipe.title,", "text: _displayTitle,")

# 7. Add displayTitle to _FinishView
text = text.replace(
"""class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final int stepCount;""",
"""class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final String displayTitle;
  final int stepCount;"""
)

text = text.replace(
"""  const _FinishView({
    required this.recipe,
    required this.stepCount,""",
"""  const _FinishView({
    required this.recipe,
    required this.displayTitle,
    required this.stepCount,"""
)

# Replace recipe.title with widget.displayTitle inside _FinishView
# Wait, inside _FinishView it's accessed via _FinishViewState, so it would be widget.displayTitle
text = text.replace("'you_just_cooked'.tr),\n                                  TextSpan(\n                                    text: widget.recipe.title,", "'you_just_cooked'.tr),\n                                  TextSpan(\n                                    text: widget.displayTitle,")
text = text.replace("'recipe': widget.recipe.title", "'recipe': widget.displayTitle")
text = text.replace("subject: widget.recipe.title,", "subject: widget.displayTitle,")

# 8. Pass _displayTitle to _buildFinishScreen
text = text.replace(
"""  Widget _buildFinishScreen(BuildContext context) {
    return _FinishView(
      recipe: widget.recipe,""",
"""  Widget _buildFinishScreen(BuildContext context) {
    return _FinishView(
      recipe: widget.recipe,
      displayTitle: _displayTitle,"""
)

# Add missing import for InstructionSection which is in recipe_localizer.dart (wait, it's in RecipeModel?)
# Actually InstructionSection is in recipe_section_model.dart, let's just make sure.
text = text.replace("import 'package:recipe_ai/Service/recipe_localizer.dart';", "import 'package:recipe_ai/Service/recipe_localizer.dart';\nimport 'package:recipe_ai/Model/recipe_section_model.dart';")

with open('lib/View/Home/cook_mode_screen.dart', 'w') as f:
    f.write(text)
