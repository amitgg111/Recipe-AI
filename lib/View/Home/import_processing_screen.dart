import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';

class ImportProcessingScreen extends StatefulWidget {
  final List<String> steps;

  const ImportProcessingScreen({
    super.key,
    this.steps = const [
      'Reading your recipe…',
      'Extracting ingredients…',
      'Building instructions…',
      'Saving your recipe…',
    ],
  });

  @override
  State<ImportProcessingScreen> createState() => ImportProcessingScreenState();
}

class ImportProcessingScreenState extends State<ImportProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _activeStepIndex = 0;

  final List<_StepStatus> _stepStatuses = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < widget.steps.length; i++) {
      _stepStatuses.add(
        i == 0 ? _StepStatus.inProgress : _StepStatus.pending,
      );
    }

    _advanceSteps();
  }

  void _advanceSteps() {
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      if (_activeStepIndex < widget.steps.length - 1) {
        setState(() {
          _stepStatuses[_activeStepIndex] = _StepStatus.completed;
          _activeStepIndex++;
          _stepStatuses[_activeStepIndex] = _StepStatus.inProgress;
        });
        _advanceSteps();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Pulsing logo circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        // Logo
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const AppLogoMark(size: 38),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Reading your recipe...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Our AI is pulling out every detail so you don\'t have to.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Step list
                ...List.generate(widget.steps.length, (index) {
                  return _buildStepRow(widget.steps[index], index);
                }),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String label, int index) {
    final status = _stepStatuses[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Status icon
          SizedBox(
            width: 24,
            height: 24,
            child: _buildStatusIcon(status),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: status == _StepStatus.completed
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: status == _StepStatus.pending
                  ? AppColors.textHint
                  : status == _StepStatus.completed
                      ? AppColors.textDark
                      : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(_StepStatus status) {
    switch (status) {
      case _StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case _StepStatus.inProgress:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        );
      case _StepStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: 2,
            ),
          ),
        );
    }
  }
}

enum _StepStatus { pending, inProgress, completed }

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
