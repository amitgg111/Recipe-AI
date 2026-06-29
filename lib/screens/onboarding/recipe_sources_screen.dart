import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/awesome_import_screen.dart';

class RecipeSourcesScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final int currentStep;
  final int totalSteps;

  const RecipeSourcesScreen({
    super.key,
    this.onContinue,
    this.currentStep = 0,
    this.totalSteps = 7,
  });

  @override
  State<RecipeSourcesScreen> createState() => _RecipeSourcesScreenState();
}

class _RecipeSourcesScreenState extends State<RecipeSourcesScreen> {
  final Set<int> _selected = {};

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Center(
                child: ProgressIndicatorDots(
                  totalSteps: widget.totalSteps,
                  currentStep: widget.currentStep,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Where do you get your\nrecipes from?',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all that apply',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 28),
              _SourceCard(
                title: 'Social media',
                isSelected: _selected.contains(0),
                onTap: () => _toggle(0),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      icon: Icons.camera_alt,
                      color: const Color(0xFFC13584),
                      bg: const Color(0xFFFCE4EE),
                    ),
                    const SizedBox(width: 4),
                    _SocialBadge(
                      icon: Icons.music_note,
                      color: const Color(0xFF1F1F24),
                      bg: const Color(0xFFECECEF),
                    ),
                    const SizedBox(width: 4),
                    _SocialBadge(
                      icon: Icons.chat,
                      color: const Color(0xFF2D6FE0),
                      bg: const Color(0xFFE4ECFB),
                    ),
                    const SizedBox(width: 4),
                    _SocialBadge(
                      icon: Icons.push_pin,
                      color: const Color(0xFFDD3B33),
                      bg: const Color(0xFFFCE2E0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _SourceCard(
                title: 'Recipe websites',
                isSelected: _selected.contains(1),
                onTap: () => _toggle(1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      icon: Icons.language,
                      color: const Color(0xFF2F7AB5),
                      bg: const Color(0xFFDCEBF4),
                    ),
                    const SizedBox(width: 4),
                    _SocialBadge(
                      icon: Icons.search,
                      color: const Color(0xFF6B6359),
                      bg: const Color(0xFFF0EEE9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _SourceCard(
                title: 'Printed / handwritten',
                isSelected: _selected.contains(2),
                onTap: () => _toggle(2),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialBadge(
                      icon: Icons.menu_book,
                      color: const Color(0xFFE0552F),
                      bg: const Color(0xFFFCE3DB),
                    ),
                    const SizedBox(width: 4),
                    _SocialBadge(
                      icon: Icons.edit,
                      color: const Color(0xFF5E8A2C),
                      bg: const Color(0xFFE7F0DC),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: widget.onContinue ?? () => Get.to(() => const AwesomeImportScreen()),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget trailing;

  const _SourceCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF2623E).withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -16,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SocialBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _SocialBadge({
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
