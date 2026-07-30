import re

with open('lib/View/Home/cook_mode_screen.dart', 'r') as f:
    content = f.read()

# 1. Imports
content = content.replace(
    "import 'package:recipe_ai/widgets/onboarding_line_icon.dart';",
    "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:recipe_ai/Service/auth_service.dart';\nimport 'package:recipe_ai/Service/recipe_localizer.dart';\nimport 'package:recipe_ai/widgets/onboarding_line_icon.dart';"
)

# 2. State vars
state_search = """  final Map<int, _StepTimer> _timers = {};
  Timer? _ticker;"""
state_replace = """  final Map<int, _StepTimer> _timers = {};
  Timer? _ticker;

  LocalizedRecipe? _localized;
  bool _localizing = true;

  String get _displayTitle => _localized?.title ?? widget.recipe.title;
  List<String> get _displayInstructions => _localized?.instructions ?? widget.recipe.instructions;
  List<InstructionSection> get _displayInstructionSections => _localized?.instructionSections ?? widget.recipe.instructionSections;"""
content = content.replace(state_search, state_replace)

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
content = content.replace(init_search, init_replace)

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
content = content.replace(parse_search, parse_replace)

# 5. Body
content = content.replace(
    "      body: _isFinished\n          ? _buildFinishScreen(context)\n          : Stack(",
    "      body: _localizing\n          ? const Center(child: CircularProgressIndicator(color: _C.primary))\n          : _isFinished\n          ? _buildFinishScreen(context)\n          : Stack("
)

# 6. widget.recipe.title replacements
content = content.replace("widget.recipe.title", "_displayTitle")
content = content.replace("recipe.title", "_displayTitle")

with open('lib/View/Home/cook_mode_screen.dart', 'w') as f:
    f.write(content)

