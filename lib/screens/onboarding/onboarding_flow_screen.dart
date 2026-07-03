import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../theme/app_dimensions.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../widgets/button_shine_effect.dart';

import '../auth/login_screen.dart';
import 'welcome_screen.dart';
import 'social_proof_screen.dart';
import 'goals_screen.dart';
import 'thats_great_screen.dart';
import 'goals_happen_screen.dart';
import 'when_to_cook_screen.dart';
import 'notifications_screen.dart';
import 'how_did_you_hear_screen.dart';
import 'recipe_sources_screen.dart';
import 'awesome_import_screen.dart';
import 'age_screen.dart';
import 'setting_up_screen.dart';
import 'plus_intro_screen.dart';

/// Single-screen onboarding flow for steps 1–12.
///
/// The SafeArea, top progress bar, back button, background and bottom CTA stay
/// fixed. Only the center content swaps (with an animated transition) as the
/// user advances. Step 12 hands off to the existing [PlusIntroScreen], which
/// keeps its own separate design (steps 13–15).
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  /// Number of steps handled by this unified flow (1–12). The progress track
  /// fills across these steps and completes (100%) on the final step (12).
  static const int _flowPages = 12;

  /// The progress track spans the unified flow, so it is full on step 12.
  static const int _totalSteps = _flowPages;

  int _page = 0;

  /// Whether the current step's selection is valid. Drives the Continue button
  /// enabled state in real time. Only the button rebuilds when this changes.
  final ValueNotifier<bool> _canContinue = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _canContinue.dispose();
    super.dispose();
  }

  /// Called by selectable bodies whenever their selection validity changes.
  void _onValidityChanged(bool isValid) {
    _canContinue.value = isValid;
  }

  void _onContinue() {
    if (!_canContinue.value) return; // guard: no proceeding while invalid
    if (_page < _flowPages - 1) {
      setState(() {
        _page++;
      });
      // Each step opens with its default selection, so it starts valid.
      _canContinue.value = true;
    } else {
      // Step 12 done → continue to the existing Plus intro (steps 13–15).
      Get.to(
        () => const PlusIntroScreen(),
        transition: Transition.noTransition,
      );
    }
  }

  void _onBack() {
    if (_page == 0) return;
    setState(() {
      _page--;
    });
    _canContinue.value = true;
  }

  // ---- Per-page content ----------------------------------------------------

  Widget _bodyFor(int page) {
    switch (page) {
      case 0:
        return const WelcomeBody();
      case 1:
        return const SocialProofBody();
      case 2:
        return GoalsBody(onValidityChanged: _onValidityChanged);
      case 3:
        return const ThatsGreatBody();
      case 4:
        return const GoalsHappenBody();
      case 5:
        return const WhenToCookBody();
      case 6:
        return const NotificationsBody();
      case 7:
        return const HowDidYouHearBody();
      case 8:
        return RecipeSourcesBody(onValidityChanged: _onValidityChanged);
      case 9:
        return const AwesomeImportBody();
      case 10:
        return const AgeBody();
      case 11:
        return const SettingUpBody();
      default:
        return const SizedBox.shrink();
    }
  }

  String _ctaLabelFor(int page) {
    switch (page) {
      case 0:
        return 'Get Started';
      case 6:
        return 'Help me stay on track';
      case 9:
        return 'Show me how';
      default:
        return 'Continue';
    }
  }

  /// Optional widget rendered just below the fixed CTA (kept minimal).
  Widget? _footerFor(int page) {
    if (page == 0) {
      // Welcome: "Already have an account? Log in"
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            GestureDetector(
              onTap: () => Get.to(
                () => const LoginScreen(),
                transition: Transition.noTransition,
              ),
              child: Text(
                'Log in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final footer = _footerFor(_page);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top: app name, then back button + animated progress
            // track. Hidden entirely on the Welcome page (page 0) — the
            // indicator only appears from screen 2 onward.
            if (_page > 0) ...[
              const SizedBox(height: 10),
              const _AppNameLogo(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OnboardingProgressBar(
                  currentStep: _page + 1,
                  totalSteps: _totalSteps,
                  showBackButton: true,
                  onBack: _onBack,
                ),
              ),
              const SizedBox(height: 6),
            ],
            // Content area — swaps instantly between steps (no transition).
            Expanded(
              child: KeyedSubtree(
                key: ValueKey<int>(_page),
                child: _bodyFor(_page),
              ),
            ),
            // Fixed bottom: CTA (+ optional footer).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only the button rebuilds when selection validity changes.
                  ValueListenableBuilder<bool>(
                    valueListenable: _canContinue,
                    builder: (context, canContinue, _) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: canContinue ? 1.0 : 0.45,
                        // Premium white gloss sweep — shown ONLY on the Welcome
                        // screen's "Get Started" button (page 0). Overlays the
                        // button without changing its logic.
                        child: ButtonShineEffect(
                          enabled: _page == 0,
                          sweepDuration: const Duration(milliseconds: 1600),
                          pauseDuration: const Duration(milliseconds: 2500),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusButton,
                          ),
                          child: PrimaryButton(
                            label: _ctaLabelFor(_page),
                            height: 54,
                            onPressed: canContinue ? _onContinue : null,
                          ),
                        ),
                      );
                    },
                  ),
                  if (footer != null) footer,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed "Recipe AI" app-name shown at the top of steps 2–12.
class _AppNameLogo extends StatelessWidget {
  const _AppNameLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const AppLogoMark(size: 20),
        ),
        const SizedBox(width: 9),
        Text(
          'Recipe AI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
