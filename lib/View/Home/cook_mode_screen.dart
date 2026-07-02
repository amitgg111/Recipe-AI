import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COOK MODE – unified step-by-step cooking screen
// ═══════════════════════════════════════════════════════════════════════════════

class CookModeScreen extends StatefulWidget {
  final RecipeModel recipe;

  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen>
    with TickerProviderStateMixin {
  late final List<_CookStep> _steps;
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isFinished = false;
  int _selectedRating = 0;

  // Timer state
  Timer? _timer;
  int _timerSecondsRemaining = 0;
  int _timerTotalSeconds = 0;
  bool _timerRunning = false;
  bool _timerPaused = false;
  bool _timerDone = false;
  int? _timerStepIndex;

  // Keep screen on
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _steps = _parseSteps();
    _pageController = PageController();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<_CookStep> _parseSteps() {
    final steps = <_CookStep>[];
    final hasSections =
        widget.recipe.instructionSections.any((s) => s.steps.isNotEmpty);

    if (hasSections) {
      for (final section in widget.recipe.instructionSections) {
        for (final step in section.steps) {
          final duration = _extractDuration(step);
          steps.add(_CookStep(
            text: step,
            sectionName: section.name,
            timerSeconds: duration,
          ));
        }
      }
    } else {
      for (final step in widget.recipe.instructions) {
        final duration = _extractDuration(step);
        steps.add(_CookStep(text: step, timerSeconds: duration));
      }
    }
    return steps;
  }

  int? _extractDuration(String text) {
    final lower = text.toLowerCase();

    // "X hours" pattern
    final hourMatch = RegExp(r'(\d+)\s*hours?').firstMatch(lower);
    // "X minutes" or "X mins" pattern
    final minMatch = RegExp(r'(\d+)\s*(?:minutes?|mins?)').firstMatch(lower);
    // "X seconds" or "X secs" pattern
    final secMatch = RegExp(r'(\d+)\s*(?:seconds?|secs?)').firstMatch(lower);

    int total = 0;
    bool found = false;

    if (hourMatch != null) {
      total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 3600;
      found = true;
    }
    if (minMatch != null) {
      total += (int.tryParse(minMatch.group(1)!) ?? 0) * 60;
      found = true;
    }
    if (secMatch != null) {
      total += int.tryParse(secMatch.group(1)!) ?? 0;
      found = true;
    }

    // Keywords that imply timer
    if (!found) {
      final timerKeywords = [
        'simmer',
        'boil',
        'bake',
        'roast',
        'cook for',
        'fry for',
        'sauté for',
        'rest for',
        'let it sit',
        'marinate',
      ];
      for (final kw in timerKeywords) {
        if (lower.contains(kw) && minMatch == null && hourMatch == null) {
          return 600; // Default 10 min
        }
      }
    }

    return found && total > 0 ? total : null;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Timer controls ────────────────────────────────────────────────────────

  void _startTimer(int stepIndex) {
    final step = _steps[stepIndex];
    if (step.timerSeconds == null) return;

    setState(() {
      _timerStepIndex = stepIndex;
      _timerTotalSeconds = step.timerSeconds!;
      _timerSecondsRemaining = step.timerSeconds!;
      _timerRunning = true;
      _timerPaused = false;
      _timerDone = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSecondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _timerSecondsRemaining = 0;
          _timerRunning = false;
          _timerDone = true;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _timerSecondsRemaining--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerPaused = true;
      _timerRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _timerPaused = false;
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSecondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _timerSecondsRemaining = 0;
          _timerRunning = false;
          _timerDone = true;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _timerSecondsRemaining--);
      }
    });
  }

  void _dismissTimer() {
    _timer?.cancel();
    setState(() {
      _timerStepIndex = null;
      _timerRunning = false;
      _timerPaused = false;
      _timerDone = false;
    });
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _steps.length) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentPage < _steps.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _prevStep() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinishScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            _buildTopBar(),
            const SizedBox(height: 6),
            _buildProgressBar(),

            // ── Mini timer bar (when on different step) ──────────────
            if (_timerStepIndex != null &&
                _timerStepIndex != _currentPage &&
                !_timerDone &&
                (_timerRunning || _timerPaused))
              _buildMiniTimerBar(),

            // ── Page content ─────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildStepPage(i),
              ),
            ),

            // ── Bottom navigation ────────────────────────────────────
            _buildBottomNav(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => _showExitDialog(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(Icons.close, size: 18, color: AppColors.textDark),
            ),
          ),
          const Spacer(),
          // Step counter
          Text(
            'STEP ${_currentPage + 1} OF ${_steps.length}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMedium,
            ),
          ),
          const Spacer(),
          // Settings / more
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorderLight),
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // PROGRESS BAR
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentPage + 1) / _steps.length,
          minHeight: 4,
          backgroundColor: AppColors.surfaceBorder,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // MINI TIMER BAR (shown when navigating away from timer step)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildMiniTimerBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.timer, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          // Timer info
          Text(
            _formatTime(_timerSecondsRemaining),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timerPaused ? 'Paused' : 'Running',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          const Spacer(),
          // Go to timer step
          GestureDetector(
            onTap: () => _goToPage(_timerStepIndex!),
            child: Text(
              'View',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dismiss
          GestureDetector(
            onTap: _dismissTimer,
            child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STEP PAGE (single step content)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildStepPage(int index) {
    final step = _steps[index];
    final isTimerStep = _timerStepIndex == index;
    final showCircleTimer =
        isTimerStep && (_timerRunning || _timerPaused) && !_timerDone;
    final showTimerDone = isTimerStep && _timerDone;
    final showStartTimer = step.timerSeconds != null && !isTimerStep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // ── Timer circle or Done ───────────────────────────────────
          if (showCircleTimer) _buildCircleTimer(),
          if (showTimerDone) _buildTimerDoneWidget(),

          if (showCircleTimer || showTimerDone) const SizedBox(height: 28),

          // ── Instruction text ───────────────────────────────────────
          Text(
            step.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.55,
            ),
          ),

          if (!showCircleTimer && !showTimerDone) const Spacer(flex: 1),

          // ── Start timer button (not started yet) ───────────────────
          if (showStartTimer) ...[
            const SizedBox(height: 28),
            _buildStartTimerButton(index),
          ],

          // ── Pause/Resume button ────────────────────────────────────
          if (showCircleTimer) ...[
            const SizedBox(height: 20),
            _buildPauseResumeButton(),
          ],

          // ── Timer done: Edit / Continue ────────────────────────────
          if (showTimerDone) ...[
            const SizedBox(height: 20),
            _buildTimerDoneButtons(),
          ],

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // CIRCLE TIMER (Screen 18/19)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildCircleTimer() {
    final progress = _timerTotalSeconds > 0
        ? 1.0 - (_timerSecondsRemaining / _timerTotalSeconds)
        : 0.0;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              color: AppColors.surfaceBorder,
            ),
          ),
          // Progress ring
          SizedBox(
            width: 180,
            height: 180,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(-math.pi / 2),
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          // Time text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_timerSecondsRemaining),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'of ${_formatTime(_timerTotalSeconds)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TIMER DONE (Screen 22)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildTimerDoneWidget() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.green.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.green, width: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Done!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 4),
          Icon(Icons.check_circle, size: 28, color: AppColors.green),
        ],
      ),
    );
  }

  Widget _buildTimerDoneButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // Reset timer to allow re-run
            setState(() {
              _timerDone = false;
              _timerStepIndex = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: AppColors.textDark),
                const SizedBox(width: 6),
                Text(
                  'Edit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {
            _dismissTimer();
            _nextStep();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // START TIMER BUTTON (Screen 17)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildStartTimerButton(int stepIndex) {
    final step = _steps[stepIndex];
    return GestureDetector(
      onTap: () => _startTimer(stepIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Start timer: ${_formatTime(step.timerSeconds!)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // PAUSE / RESUME BUTTON (Screen 18/19)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildPauseResumeButton() {
    if (_timerPaused) {
      return GestureDetector(
        onTap: _resumeTimer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  size: 20, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Resume',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _pauseTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Pause',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          // Step preview text
          if (_currentPage < _steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _steps[_currentPage + 1].text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHint,
                  height: 1.4,
                ),
              ),
            ),

          // Navigation row
          Row(
            children: [
              // Previous
              GestureDetector(
                onTap: _currentPage > 0 ? _prevStep : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorderLight),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _currentPage > 0
                        ? AppColors.textDark
                        : AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Step dots
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_steps.length, (i) {
                        final isActive = i == _currentPage;
                        final isPast = i < _currentPage;
                        return Container(
                          width: isActive ? 10 : 7,
                          height: isActive ? 10 : 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppColors.primary
                                : isPast
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : AppColors.surfaceBorder,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Next step button
              GestureDetector(
                onTap: _nextStep,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage < _steps.length - 1
                            ? 'Next step'
                            : 'Finish',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // EXIT DIALOG
  // ═════════════════════════════════════════════════════════════════════════════

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Leave Cook Mode?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your progress will not be saved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surfaceBorder),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton),
                        ),
                        child: Center(
                          child: Text(
                            'Stay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton),
                        ),
                        child: Center(
                          child: Text(
                            'Leave',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // Screen 25: FINISH / BON APPÉTIT SCREEN
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildFinishScreen() {
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top bar
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'STEP ${_steps.length} OF ${_steps.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(flex: 2),

              // Bon appétit title
              Text(
                'Bon appétit! 🎉',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),

              // Recipe image circle
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF0E6D6),
                            child: const Icon(Icons.restaurant_rounded,
                                size: 40, color: AppColors.iconLight),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0E6D6),
                          child: const Icon(Icons.restaurant_rounded,
                              size: 40, color: AppColors.iconLight),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              // Subtitle
              Text(
                'You just made',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recipe.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              // Rate this recipe
              Text(
                'Rate this recipe',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 36,
                        color: i < _selectedRating
                            ? AppColors.starOrange
                            : AppColors.surfaceBorder,
                      ),
                    ),
                  );
                }),
              ),

              const Spacer(flex: 3),

              // Save & finish button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusButton),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('Save & finish', style: AppTextStyles.buttonLabel),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Share your dish button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusButton),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 18, color: AppColors.textDark),
                      const SizedBox(width: 8),
                      Text(
                        'Share your dish',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step data model
// ─────────────────────────────────────────────────────────────────────────────

class _CookStep {
  final String text;
  final String? sectionName;
  final int? timerSeconds;

  const _CookStep({
    required this.text,
    this.sectionName,
    this.timerSeconds,
  });
}
