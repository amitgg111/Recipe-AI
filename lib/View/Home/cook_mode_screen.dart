import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/local_notification_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COOK MODE — step-by-step & timer states (matches the HTML design)
// ═══════════════════════════════════════════════════════════════════════════════

/// Design tokens for Cook Mode.
class _C {
  static const bg = Color(0xFFFBF4EA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFF2623E);
  static const primarySoft = Color(0xFFFFF3EF);
  static const track = Color(0xFFEEE3D2);
  static const border = Color(0xFFEFE6D6);
  static const borderInput = Color(0xFFE7DECE);
  static const textDark = Color(0xFF2A211B);
  static const textBody = Color(0xFF3A352D);
  static const textMed = Color(0xFF8A7E70);
  static const textLight = Color(0xFF9A938A);
  static const iconLight = Color(0xFFC7BCAC);
  static const green = Color(0xFF1F7A5E);
  static const pausedRing = Color(0xFFC9BEA9);

  // Chip accent colors, cycled per concurrent timer.
  static const chipColors = [primary, green, Color(0xFF2D6FE0), Color(0xFF8B5CF6)];
}

TextStyle _f(double size, FontWeight w, Color c,
        {double? spacing, double? height}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: spacing,
      height: height,
    );

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

  /// Active timers keyed by their step index. Supports several running at once.
  final Map<int, _StepTimer> _timers = {};
  Timer? _ticker;

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
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Step parsing ────────────────────────────────────────────────────────

  List<_CookStep> _parseSteps() {
    final steps = <_CookStep>[];
    final hasSections =
        widget.recipe.instructionSections.any((s) => s.steps.isNotEmpty);

    if (hasSections) {
      for (final section in widget.recipe.instructionSections) {
        for (final step in section.steps) {
          steps.add(_CookStep(
            text: step,
            label: _labelFor(step, section.name),
            detectedSeconds: _extractDuration(step),
          ));
        }
      }
    } else {
      for (final step in widget.recipe.instructions) {
        steps.add(_CookStep(
          text: step,
          label: _labelFor(step, null),
          detectedSeconds: _extractDuration(step),
        ));
      }
    }
    if (steps.isEmpty) {
      steps.add(_CookStep(
        text: 'No instructions available for this recipe.',
        label: 'Step',
        detectedSeconds: null,
      ));
    }
    return steps;
  }

  /// A short chip label — a cooking verb from the step, else "Timer".
  String _labelFor(String text, String? section) {
    const verbs = [
      'simmer', 'boil', 'bake', 'roast', 'fry', 'sauté', 'saute', 'sear',
      'rest', 'chill', 'marinate', 'steam', 'grill', 'poach', 'proof', 'knead',
    ];
    final lower = text.toLowerCase();
    for (final v in verbs) {
      if (lower.contains(v)) {
        return v[0].toUpperCase() + v.substring(1);
      }
    }
    return 'Timer';
  }

  int? _extractDuration(String text) {
    final lower = text.toLowerCase();
    final hourMatch = RegExp(r'(\d+)\s*hours?').firstMatch(lower);
    final minMatch = RegExp(r'(\d+)\s*(?:minutes?|mins?)').firstMatch(lower);
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
    if (!found) {
      const keywords = [
        'simmer', 'boil', 'bake', 'roast', 'cook for', 'fry for',
        'sauté for', 'rest for', 'let it sit', 'marinate', 'steam',
      ];
      for (final kw in keywords) {
        if (lower.contains(kw)) return 600; // default 10 min
      }
    }
    return found && total > 0 ? total : null;
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Ticker + timer controls ──────────────────────────────────────────────

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _maybeStopTicker() {
    if (!_timers.values.any((t) => t.running)) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    bool changed = false;
    _timers.forEach((index, t) {
      if (t.running && t.remaining > 0) {
        t.remaining--;
        changed = true;
        if (t.remaining == 0) {
          t.running = false;
          t.done = true;
          LocalNotificationService.instance.cancelCookTimerAlert(index);
          HapticFeedback.heavyImpact();
          // Alert like the lock-screen notification when it's a background step.
          if (index != _currentPage) {
            CustomSnackbar.show(
              title: 'Timer done — Step ${index + 1} ⏰',
              message: '${widget.recipe.title} · ${t.label.toLowerCase()} finished',
              type: SnackbarType.success,
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    });
    if (changed && mounted) setState(() {});
    _maybeStopTicker();
  }

  void _startTimer(int index, int seconds) {
    setState(() {
      _timers[index] = _StepTimer(
        total: seconds,
        remaining: seconds,
        running: true,
        label: _steps[index].label,
        color: _C.chipColors[
            _timers.length % _C.chipColors.length],
      );
    });
    _ensureTicker();
    _syncTimerNotification(index);
  }

  void _pause(int index) {
    setState(() => _timers[index]?.running = false);
    _maybeStopTicker();
    _syncTimerNotification(index);
  }

  void _resume(int index) {
    final t = _timers[index];
    if (t == null) return;
    setState(() {
      t.running = true;
      t.done = false;
    });
    _ensureTicker();
    _syncTimerNotification(index);
  }

  void _reset(int index) {
    final t = _timers[index];
    if (t == null) return;
    setState(() {
      t.remaining = t.total;
      t.running = true;
      t.done = false;
    });
    _ensureTicker();
    _syncTimerNotification(index);
  }

  void _addMinute(int index) {
    final t = _timers[index];
    if (t == null) return;
    setState(() {
      t.remaining += 60;
      t.total = math.max(t.total, t.remaining);
      if (t.done) {
        t.done = false;
        t.running = true;
      }
    });
    _ensureTicker();
    _syncTimerNotification(index);
  }

  void _dismiss(int index) {
    setState(() => _timers.remove(index));
    LocalNotificationService.instance.cancelCookTimerAlert(index);
    _maybeStopTicker();
  }

  /// Keep a backing local notification in sync with a running timer so the
  /// "Cook timer alert" still fires if the app is backgrounded. Only scheduled
  /// when the device permission is granted AND the toggle is enabled; otherwise
  /// any pending alert for this slot is cancelled.
  void _syncTimerNotification(int index) {
    final local = LocalNotificationService.instance;
    final t = _timers[index];
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    if (t == null ||
        !t.running ||
        t.remaining <= 0 ||
        settings == null ||
        !settings.canFireCookTimer) {
      local.cancelCookTimerAlert(index);
      return;
    }
    local.scheduleCookTimerAlert(
      slot: index,
      fireAt: DateTime.now().add(Duration(seconds: t.remaining)),
      title: 'Timer done — Step ${index + 1} ⏰',
      body: '${widget.recipe.title} · ${t.label.toLowerCase()} finished',
    );
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _goTo(int page) {
    if (page < 0 || page >= _steps.length) return;
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _next() {
    if (_currentPage < _steps.length - 1) {
      _goTo(_currentPage + 1);
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _prev() {
    if (_currentPage > 0) _goTo(_currentPage - 1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _FinishView(
        recipe: widget.recipe,
        stepCount: _steps.length,
        rating: _selectedRating,
        onRate: (r) => setState(() => _selectedRating = r),
        onClose: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              Text(
                'STEP ${_currentPage + 1} OF ${_steps.length}',
                style: _f(13, FontWeight.w800, _C.textMed, spacing: 0.5),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _stepPage(i),
                ),
              ),
              _bottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header: close + progress bar ──────────────────────────────────────────

  Widget _header() {
    return Row(
      children: [
        _squareBtn(Icons.close_rounded, _confirmExit),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: _C.track),
                  FractionallySizedBox(
                    widthFactor: (_currentPage + 1) / _steps.length,
                    child: Container(color: _C.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _squareBtn(IconData icon, VoidCallback onTap,
      {double size = 40, Color? fg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _C.border),
        ),
        child: Icon(icon, size: 20, color: fg ?? _C.textDark),
      ),
    );
  }

  // ─── One step page ──────────────────────────────────────────────────────────

  Widget _stepPage(int index) {
    final step = _steps[index];
    final timer = _timers[index];
    final duration = step.customSeconds ?? step.detectedSeconds;

    // Chips for timers running/paused on OTHER steps.
    final otherTimers = _timers.entries
        .where((e) => e.key != index && !e.value.done)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    Widget body;
    if (timer != null && timer.done) {
      body = _timerDone(index, timer, step);
    } else if (timer != null) {
      body = _timerActive(index, timer, step);
    } else {
      // No active timer on this step: centered text (+ start/add-timer button).
      body = Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                step.text,
                textAlign: TextAlign.center,
                style: _f(22, FontWeight.w700, _C.textDark,
                    spacing: -0.3, height: 1.4),
              ),
            ),
          ),
          if (duration != null)
            _outlineTimerButton(
              icon: Icons.schedule_rounded,
              label: 'Start timer · ${_fmt(duration)}',
              onTap: () => _startTimer(index, duration),
            )
          else
            _outlineTimerButton(
              icon: Icons.add_alarm_rounded,
              label: 'Add a timer',
              onTap: () => _openSetTimerSheet(index),
            ),
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      children: [
        if (otherTimers.isNotEmpty) ...[
          const SizedBox(height: 14),
          _chipRow(otherTimers),
        ],
        Expanded(child: body),
      ],
    );
  }

  Widget _outlineTimerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(top: 8, bottom: 14),
        decoration: BoxDecoration(
          color: _C.primarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: _C.primary),
            const SizedBox(width: 10),
            Text(label, style: _f(16, FontWeight.w600, _C.primary)),
          ],
        ),
      ),
    );
  }

  // ─── Running / paused timer (ring + controls + step card) ───────────────────

  Widget _timerActive(int index, _StepTimer t, _CookStep step) {
    final paused = !t.running;
    final progress = t.total > 0 ? t.remaining / t.total : 0.0;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: paused ? 0.7 : 1,
                  child: SizedBox(
                    width: 248,
                    height: 248,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!paused)
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                _C.primary.withValues(alpha: 0.18),
                                _C.primary.withValues(alpha: 0),
                              ], stops: const [0.0, 0.7]),
                            ),
                          ),
                        CustomPaint(
                          size: const Size(248, 248),
                          painter: _RingPainter(
                            progress: progress.clamp(0, 1),
                            color: paused ? _C.pausedRing : _C.primary,
                            bg: _C.track,
                            stroke: 13,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!paused) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded,
                                      size: 14, color: _C.primary),
                                  const SizedBox(width: 5),
                                  Text(step.label.toUpperCase(),
                                      style: _f(11, FontWeight.w800, _C.primary,
                                          spacing: 0.8)),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              _fmt(t.remaining),
                              style: _f(paused ? 58 : 54, FontWeight.w800,
                                  _C.textDark, spacing: -1.5, height: 1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              paused ? 'paused' : 'of ${_fmt(t.total)}',
                              style: _f(13, FontWeight.w700, _C.textMed),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _smallCtrlBtn(Icons.restart_alt_rounded,
                        () => _reset(index)),
                    const SizedBox(width: 12),
                    _pillBtn(
                      icon: paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: paused ? 'Resume' : 'Pause',
                      onTap: () => paused ? _resume(index) : _pause(index),
                    ),
                    const SizedBox(width: 12),
                    _plusOneBtn(() => _addMinute(index)),
                  ],
                ),
              ],
            ),
          ),
        ),
        _stepCard(step.text),
      ],
    );
  }

  Widget _smallCtrlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.borderInput),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF5A5147)),
      ),
    );
  }

  Widget _plusOneBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.borderInput),
        ),
        child: Text('+1', style: _f(13, FontWeight.w800, const Color(0xFF5A5147))),
      ),
    );
  }

  Widget _pillBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _C.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 9),
            Text(label, style: _f(15, FontWeight.w600, Colors.white)),
          ],
        ),
      ),
    );
  }

  // ─── Timer done ─────────────────────────────────────────────────────────────

  Widget _timerDone(int index, _StepTimer t, _CookStep step) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 248,
                  height: 248,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(248, 248),
                        painter: _RingPainter(
                          progress: 1,
                          color: _C.green,
                          bg: _C.green,
                          stroke: 13,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                                color: _C.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                                size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text('Done!',
                              style: _f(30, FontWeight.w800, _C.green,
                                  spacing: -0.4)),
                          const SizedBox(height: 4),
                          Text('${step.label} · ${_fmt(t.total)}',
                              style: _f(13, FontWeight.w700, _C.textMed)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _addMinute(index),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.borderInput),
                        ),
                        child: Text('+1 min',
                            style: _f(15, FontWeight.w600,
                                const Color(0xFF5A5147))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _pillBtn(
                      icon: Icons.check_rounded,
                      label: 'Dismiss',
                      color: _C.green,
                      onTap: () => _dismiss(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _stepCard(step.text),
      ],
    );
  }

  Widget _stepCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Text(text, style: _f(15, FontWeight.w600, _C.textBody, height: 1.4)),
    );
  }

  // ─── Mini-timer chips (background timers) ────────────────────────────────────

  Widget _chipRow(List<MapEntry<int, _StepTimer>> timers) {
    if (timers.length == 1) {
      return _timerChip(timers.first.key, timers.first.value, big: true);
    }
    if (timers.length == 2) {
      return Row(
        children: [
          Expanded(child: _timerChip(timers[0].key, timers[0].value)),
          const SizedBox(width: 9),
          Expanded(child: _timerChip(timers[1].key, timers[1].value)),
        ],
      );
    }
    // 3+ concurrent timers: scroll horizontally so nothing overflows.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < timers.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            SizedBox(
              width: 160,
              child: _timerChip(timers[i].key, timers[i].value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timerChip(int index, _StepTimer t, {bool big = false}) {
    final progress = t.total > 0 ? t.remaining / t.total : 0.0;
    final ringSize = big ? 34.0 : 30.0;
    return GestureDetector(
      onTap: () => _goTo(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: big ? 11 : 10, vertical: 9),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF0E7D6)),
          boxShadow: [
            BoxShadow(
              color: _C.textDark.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _RingPainter(
                      progress: progress.clamp(0, 1),
                      color: t.color,
                      bg: t.color == _C.primary
                          ? const Color(0xFFF6D8CC)
                          : _C.track,
                      stroke: 4,
                    ),
                  ),
                  if (big) const Text('🔥', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            SizedBox(width: big ? 11 : 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${t.label} · Step ${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _f(big ? 11 : 10, FontWeight.w700, _C.textMed)),
                  Text(big ? '${_fmt(t.remaining)} left' : _fmt(t.remaining),
                      style: _f(big ? 15 : 14, FontWeight.w800, _C.textDark)),
                ],
              ),
            ),
            if (big)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: _C.iconLight),
          ],
        ),
      ),
    );
  }

  // ─── Bottom nav ──────────────────────────────────────────────────────────────

  Widget _bottomNav() {
    final isLast = _currentPage == _steps.length - 1;
    return Row(
      children: [
        _squareBtn(Icons.arrow_back_rounded, _prev, size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _next,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha: 0.7),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLast ? 'Finish' : 'Next step',
                      style: _f(16, FontWeight.w700, Colors.white)),
                  const SizedBox(width: 9),
                  Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Set-timer sheet ─────────────────────────────────────────────────────────

  void _openSetTimerSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SetTimerSheet(
        stepNumber: index + 1,
        onConfirm: (seconds) {
          Navigator.pop(context);
          setState(() => _steps[index].customSeconds = seconds);
          _startTimer(index, seconds);
        },
      ),
    );
  }

  // ─── Exit confirmation ────────────────────────────────────────────────────────

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Leave Cook Mode?',
                  style: _f(18, FontWeight.w800, _C.textDark)),
              const SizedBox(height: 8),
              Text('Your timers and progress won\'t be saved.',
                  textAlign: TextAlign.center,
                  style: _f(13.5, FontWeight.w500, _C.textMed, height: 1.4)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: _C.border),
                        ),
                        child: Text('Stay',
                            style: _f(14.5, FontWeight.w700, _C.textDark)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _C.primary,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text('Leave',
                            style: _f(14.5, FontWeight.w700, Colors.white)),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// FINISH / BON APPÉTIT
// ═══════════════════════════════════════════════════════════════════════════════

class _FinishView extends StatefulWidget {
  final RecipeModel recipe;
  final int stepCount;
  final int rating;
  final ValueChanged<int> onRate;
  final VoidCallback onClose;

  const _FinishView({
    required this.recipe,
    required this.stepCount,
    required this.rating,
    required this.onRate,
    required this.onClose,
  });

  @override
  State<_FinishView> createState() => _FinishViewState();
}

class _FinishViewState extends State<_FinishView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _timeText {
    final r = widget.recipe;
    final t = r.totalTime ?? r.cookTime ?? r.prepTime ?? '';
    return t.isEmpty ? '' : ' · ${t.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ..._confetti(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 20, color: _C.textDark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _heroDish(recipe),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCE3DB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 14,
                                      color: _C.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.stepCount} STEPS$_timeText',
                                    style: _f(12, FontWeight.w800, _C.primary,
                                        spacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text('Bon appétit! 🎉',
                                style: _f(30, FontWeight.w800, _C.textDark,
                                    spacing: -0.5)),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                style: _f(15, FontWeight.w500, _C.textMed,
                                    height: 1.5),
                                children: [
                                  const TextSpan(text: 'You just cooked '),
                                  TextSpan(
                                      text: recipe.title,
                                      style: _f(15, FontWeight.w800,
                                          _C.textDark)),
                                  const TextSpan(text: '.\nHow did it turn out?'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 22),
                            _ratingCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _finishButtons(recipe),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroDish(RecipeModel recipe) {
    return SizedBox(
      width: 162,
      height: 162,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: [
                BoxShadow(
                  color: _C.textDark.withValues(alpha: 0.4),
                  blurRadius: 44,
                  offset: const Offset(0, 24),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipOval(
              child: (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                  ? Image.network(recipe.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 450,
                      errorBuilder: (_, __, ___) => _dishFallback())
                  : _dishFallback(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _C.green,
                shape: BoxShape.circle,
                border: Border.all(color: _C.bg, width: 4),
              ),
              child: const Icon(Icons.check_rounded, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dishFallback() => Container(
        color: const Color(0xFFF0E6D6),
        child: const Icon(Icons.restaurant_rounded,
            size: 44, color: _C.iconLight),
      );

  Widget _ratingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate this recipe',
              style: _f(13, FontWeight.w700, _C.textLight)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < widget.rating;
              return GestureDetector(
                onTap: () => widget.onRate(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34,
                    color: filled ? const Color(0xFFF2A24C) : const Color(0xFFE2D8C7),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _finishButtons(RecipeModel recipe) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            CustomSnackbar.show(
              title: 'Nice work! 🎉',
              message: 'Enjoy your ${recipe.title}.',
              type: SnackbarType.success,
            );
            widget.onClose();
          },
          child: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withValues(alpha: 0.6),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Text('Save & finish',
                style: _f(16, FontWeight.w600, Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Share.share(
              'I just cooked ${recipe.title}! 🍳 Made with Recipe AI.',
              subject: recipe.title),
          child: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.borderInput),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.ios_share_rounded, size: 18, color: _C.primary),
                const SizedBox(width: 8),
                Text('Share your dish',
                    style: _f(15, FontWeight.w700, _C.textDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _confetti() {
    final specs = [
      [34.0, 90.0, 11.0, const Color(0xFFF2A24C), true],
      [318.0, 130.0, 9.0, const Color(0xFF1F7A5E), false],
      [50.0, 200.0, 8.0, const Color(0xFFF2623E), true],
      [300.0, 170.0, 12.0, const Color(0xFF8B5CF6), true],
    ];
    return [
      for (final s in specs)
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final dy = math.sin(_anim.value * math.pi * 2) * 6;
            return Positioned(
              left: s[0] as double,
              top: (s[1] as double) + dy,
              child: Container(
                width: s[2] as double,
                height: s[2] as double,
                decoration: BoxDecoration(
                  color: s[3] as Color,
                  borderRadius:
                      BorderRadius.circular((s[4] as bool) ? 3 : 50),
                ),
              ),
            );
          },
        ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SET TIMER SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SetTimerSheet extends StatefulWidget {
  final int stepNumber;
  final ValueChanged<int> onConfirm;

  const _SetTimerSheet({required this.stepNumber, required this.onConfirm});

  @override
  State<_SetTimerSheet> createState() => _SetTimerSheetState();
}

class _SetTimerSheetState extends State<_SetTimerSheet> {
  int _min = 15;
  int _sec = 0;

  int get _total => _min * 60 + _sec;
  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          22, 14, 22, 28 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E0D2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step timer', style: _f(20, FontWeight.w800, _C.textDark,
                  spacing: -0.3)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF4F1EA), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: _C.textMed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: _f(13, FontWeight.w500, _C.textLight),
              children: [
                const TextSpan(text: 'Adds a tappable timer to '),
                TextSpan(
                    text: 'Step ${widget.stepNumber}',
                    style: _f(13, FontWeight.w700, const Color(0xFF5A5147))),
                const TextSpan(text: ' while cooking.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // mm : ss steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _numberBox(
                value: _two(_min),
                unit: 'MIN',
                highlight: true,
                onInc: () => setState(() => _min = (_min + 1).clamp(0, 99)),
                onDec: () => setState(() => _min = (_min - 1).clamp(0, 99)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Text(':',
                    style: _f(36, FontWeight.w800, _C.iconLight)),
              ),
              _numberBox(
                value: _two(_sec),
                unit: 'SEC',
                highlight: false,
                onInc: () => setState(() => _sec = (_sec + 5) % 60),
                onDec: () => setState(() => _sec = (_sec + 55) % 60),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Quick pick', style: _f(12, FontWeight.w700, _C.textLight)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in [1, 5, 10, 15, 30])
                _preset(m),
            ],
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _total == 0 ? null : () => widget.onConfirm(_total),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _total == 0
                    ? _C.primary.withValues(alpha: 0.5)
                    : _C.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _total == 0
                    ? null
                    : [
                        BoxShadow(
                          color: _C.primary.withValues(alpha: 0.7),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                          spreadRadius: -10,
                        ),
                      ],
              ),
              child: Text('Add timer · ${_two(_min)}:${_two(_sec)}',
                  style: _f(17, FontWeight.w600, Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberBox({
    required String value,
    required String unit,
    required bool highlight,
    required VoidCallback onInc,
    required VoidCallback onDec,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onInc,
          child: const Icon(Icons.keyboard_arrow_up_rounded,
              size: 26, color: _C.textMed),
        ),
        Container(
          width: 88,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? _C.primarySoft : const Color(0xFFFBF7F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight ? _C.primary : _C.borderInput,
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Text(value,
              style: _f(40, FontWeight.w800, _C.textDark)),
        ),
        GestureDetector(
          onTap: onDec,
          child: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 26, color: _C.textMed),
        ),
        Text(unit, style: _f(11, FontWeight.w700, _C.textLight, spacing: 0.5)),
      ],
    );
  }

  Widget _preset(int m) {
    final active = _min == m && _sec == 0;
    return GestureDetector(
      onTap: () => setState(() {
        _min = m;
        _sec = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _C.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _C.primary : _C.borderInput),
        ),
        child: Text('$m min',
            style: _f(13, active ? FontWeight.w800 : FontWeight.w700,
                active ? Colors.white : const Color(0xFF5A5147))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RING PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress; // 0..1 fraction of ring to draw (from top, clockwise)
  final Color color;
  final Color bg;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bg,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = bg;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.bg != bg ||
      old.stroke != stroke;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _CookStep {
  final String text;
  final String label;
  final int? detectedSeconds;
  int? customSeconds;

  _CookStep({
    required this.text,
    required this.label,
    required this.detectedSeconds,
  }) : customSeconds = null;
}

class _StepTimer {
  int total;
  int remaining;
  bool running;
  bool done = false;
  final String label;
  final Color color;

  _StepTimer({
    required this.total,
    required this.remaining,
    required this.running,
    required this.label,
    required this.color,
  });
}
