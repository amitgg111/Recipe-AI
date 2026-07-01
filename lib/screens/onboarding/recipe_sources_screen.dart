import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/screens/onboarding/awesome_import_screen.dart';

class RecipeSourcesScreen extends StatefulWidget {
  static const String routeName = '/onboarding/recipe-sources';

  const RecipeSourcesScreen({super.key});

  @override
  State<RecipeSourcesScreen> createState() => _RecipeSourcesScreenState();
}

class _RecipeSourcesScreenState extends State<RecipeSourcesScreen> {
  final Set<int> _selected = {0};

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
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            children: [
              // Logo + Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recipe AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ProgressIndicatorDots(
                totalSteps: 8,
                currentStep: 7,
              ),
              // Title
              const SizedBox(height: 16),
              Text(
                'Where do you get your\nrecipes from?',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 25,
                  height: 1.18,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all that apply',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 22),
              // Card 1: Social media (pre-selected)
              _SourceCard(
                title: 'Social media',
                isSelected: _selected.contains(0),
                onTap: () => _toggle(0),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _SocialBadge(
                      icon: Icons.camera_alt,
                      color: Color(0xFFC13584),
                      bg: Color(0xFFFCE4EE),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      icon: Icons.music_note,
                      color: Color(0xFF1F1F24),
                      bg: Color(0xFFECECEF),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      icon: Icons.chat_bubble,
                      color: Color(0xFF2D6FE0),
                      bg: Color(0xFFE4ECFB),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      icon: Icons.push_pin,
                      color: Color(0xFFDD3B33),
                      bg: Color(0xFFFCE2E0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              // Card 2: Recipe websites
              _SourceCard(
                title: 'Recipe websites',
                isSelected: _selected.contains(1),
                onTap: () => _toggle(1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _SocialBadge(
                      icon: Icons.public,
                      color: Color(0xFF2F7AB5),
                      bg: Color(0xFFDCEBF4),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      icon: Icons.search,
                      color: Color(0xFF6B6359),
                      bg: Color(0xFFF0EEE9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              // Card 3: Printed / handwritten
              _SourceCard(
                title: 'Printed / handwritten',
                isSelected: _selected.contains(2),
                onTap: () => _toggle(2),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _SocialBadge(
                      icon: Icons.menu_book,
                      color: Color(0xFFE0552F),
                      bg: Color(0xFFFCE3DB),
                    ),
                    SizedBox(width: 6),
                    _SocialBadge(
                      icon: Icons.edit,
                      color: Color(0xFF5E8A2C),
                      bg: Color(0xFFE7F0DC),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Continue button
              PrimaryButton(
                label: 'Continue',
                onPressed: () => Get.to(() => const AwesomeImportScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeSourcesBody extends StatefulWidget {
  /// Reports whether at least one source is selected (drives the Continue
  /// button).
  final ValueChanged<bool>? onValidityChanged;

  const RecipeSourcesBody({super.key, this.onValidityChanged});

  @override
  State<RecipeSourcesBody> createState() => _RecipeSourcesBodyState();
}

class _RecipeSourcesBodyState extends State<RecipeSourcesBody> {
  final Set<int> _selected = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidityChanged?.call(_selected.isNotEmpty);
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    widget.onValidityChanged?.call(_selected.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Title
          Text(
            'Where do you get your\nrecipes from?',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 25,
              height: 1.18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 22),
          // Card 1: Social media (pre-selected)
          _SourceCard(
            title: 'Social media',
            isSelected: _selected.contains(0),
            onTap: () => _toggle(0),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SocialBadge(
                  icon: Icons.camera_alt,
                  color: Color(0xFFC13584),
                  bg: Color(0xFFFCE4EE),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  icon: Icons.music_note,
                  color: Color(0xFF1F1F24),
                  bg: Color(0xFFECECEF),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  icon: Icons.chat_bubble,
                  color: Color(0xFF2D6FE0),
                  bg: Color(0xFFE4ECFB),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  icon: Icons.push_pin,
                  color: Color(0xFFDD3B33),
                  bg: Color(0xFFFCE2E0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          // Card 2: Recipe websites
          _SourceCard(
            title: 'Recipe websites',
            isSelected: _selected.contains(1),
            onTap: () => _toggle(1),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SocialBadge(
                  icon: Icons.public,
                  color: Color(0xFF2F7AB5),
                  bg: Color(0xFFDCEBF4),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  icon: Icons.search,
                  color: Color(0xFF6B6359),
                  bg: Color(0xFFF0EEE9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          // Card 3: Printed / handwritten
          _SourceCard(
            title: 'Printed / handwritten',
            isSelected: _selected.contains(2),
            onTap: () => _toggle(2),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SocialBadge(
                  icon: Icons.menu_book,
                  color: Color(0xFFE0552F),
                  bg: Color(0xFFFCE3DB),
                ),
                SizedBox(width: 6),
                _SocialBadge(
                  icon: Icons.edit,
                  color: Color(0xFF5E8A2C),
                  bg: Color(0xFFE7F0DC),
                ),
              ],
            ),
          ),
        ],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge,
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
      child: Center(
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
