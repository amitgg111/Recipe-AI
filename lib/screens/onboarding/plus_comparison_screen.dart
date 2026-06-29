import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/onboarding/trial_chooser_screen.dart';

class PlusComparisonScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onClose;

  const PlusComparisonScreen({
    super.key,
    this.onContinue,
    this.onClose,
  });

  @override
  State<PlusComparisonScreen> createState() => _PlusComparisonScreenState();
}

class _PlusComparisonScreenState extends State<PlusComparisonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheenController;
  late final Animation<double> _sheenAnimation;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(period: const Duration(milliseconds: 3000));
    _sheenAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _sheenController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  static const _features = [
    ('Recipe imports', '5 / week', 'Unlimited'),
    ('Recipe nutrition calculator', '—', '✓'),
    ('Create shopping lists in seconds', '—', '✓'),
    ('AI-powered cooking assistant', '—', '✓'),
    ('Convert measurements', '—', '✓'),
    ('Step-by-step cooking mode', '—', '✓'),
    ('Print / export recipes', '—', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 34),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            text: 'Recipe AI ',
                            style: AppTextStyles.listTitle,
                            children: [
                              TextSpan(
                                text: 'Plus',
                                style: AppTextStyles.listTitle.copyWith(color: AppColors.purple),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose ?? () => Get.to(() => const TrialChooserScreen()),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.close, size: 18,
                          color: AppColors.textMedium),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: const Color(0xFF7A45E0)),
                          const SizedBox(width: 5),
                          Text(
                            'MEMBER RESULTS',
                            style: AppTextStyles.tinyLabel.copyWith(
                              color: const Color(0xFF7A45E0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
                        children: [
                          TextSpan(
                            text: '93% of members',
                            style: AppTextStyles.screenTitle.copyWith(
                              fontSize: 26,
                              color: AppColors.purple,
                            ),
                          ),
                          const TextSpan(
                            text: ' reported improved cooking habits',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Comparison table
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 0, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('What you get',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSubtle)),
                                ),
                                SizedBox(
                                  width: 64,
                                  child: Center(
                                    child: Text('Free',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLighter)),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _sheenAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 114,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF9466F2), Color(0xFF7A45E0)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text('PLUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          // Feature rows
                          ...List.generate(_features.length, (i) {
                            final feature = _features[i];
                            final isCheck = feature.$3 == '✓';
                            return Column(
                              children: [
                                SizedBox(
                                  height: 62,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            feature.$1,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 64,
                                          child: Center(
                                            child: Text(
                                              feature.$2,
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textLighter),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 114,
                                          child: Center(
                                            child: isCheck
                                                ? const Icon(Icons.check, color: AppColors.purple, size: 18)
                                                : Text(
                                                    feature.$3,
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.purple),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i < _features.length - 1)
                                  Divider(height: 1, indent: 16, color: AppColors.divider),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton.purple(
                      label: 'Start my free week',
                      onPressed: widget.onContinue ?? () => Get.to(() => const TrialChooserScreen()),
                      enableBob: true,
                      enableSheen: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '7 days free · cancel anytime',
                      style: AppTextStyles.trialPrice,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
