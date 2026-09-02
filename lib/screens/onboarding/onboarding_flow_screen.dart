import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recipe_ai/screens/auth/create_account_screen.dart';
import 'package:recipe_ai/screens/onboarding/cuisine_preference.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

import '../../widgets/primary_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

import '../../Controllers/onboarding_controller.dart';
import '../../Service/notification_service.dart';
import '../../Service/analytics_service.dart';

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
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('OnboardingFlowScreen');
  }

  /// Number of steps handled by this unified flow (1–12). The progress track
  /// fills across these steps and completes (100%) on the final step (12).
  static const int _flowPages = 13;

  /// The progress track spans the unified flow, so it is full on step 12.
  static const int _totalSteps = _flowPages;

  /// Page index of the notifications step ("Step 07" in the UI).
  static const int _notificationsPage = 6;

  /// Page index of the "preparing" step ("Step 12" in the UI) — the final step.
  static const int _settingUpPage = 12;

  /// How long the "preparing" step waits before revealing its Continue button.
  static const Duration _settingUpDelay = Duration(seconds: 3);

  int _page = 0;

  /// Whether the current step's selection is valid. Drives the Continue button
  /// enabled state in real time. Only the button rebuilds when this changes.
  final ValueNotifier<bool> _canContinue = ValueNotifier<bool>(true);

  final OnboardingController _onb = Get.find<OnboardingController>();
  final NotificationService _push = NotificationService.instance;

  /// True while the notifications-permission request is in flight — prevents
  /// duplicate prompts and double navigation, and drives the loading state.
  bool _notifBusy = false;

  /// The "preparing" step reveals its Continue button only after a short beat
  /// so the setup animation can play. False until that delay elapses.
  Timer? _settingUpTimer;
  bool _settingUpReady = false;

  @override
  void dispose() {
    _settingUpTimer?.cancel();
    _canContinue.dispose();
    super.dispose();
  }

  /// Called by selectable bodies whenever their selection validity changes.
  void _onValidityChanged(bool isValid) {
    _canContinue.value = isValid;
  }

  void _onContinue() {
    if (!_canContinue.value) return; // guard: no proceeding while invalid
    _advance();
  }

  /// Move to the next step (or hand off to the Plus intro after the last one).
  void _advance() {
    if (_page < _flowPages - 1) {
      setState(() {
        _page++;
      });
      // Each step opens with its default selection, so it starts valid.
      // _canContinue.value = true;
      _canContinue.value = _page != _settingUpPage;
      _syncSettingUpGate();
      _syncSettingUpGate();
    } else {
      // Step 12 done → onboarding is COMPLETE (all preference steps collected).
      // Persist the flag HERE (not at splash), so a user who abandons
      // onboarding part-way sees it again next launch instead of skipping
      // straight to sign-in.
      GetStorage().write('hasSeenOnboarding', true);
      // Continue to the existing Plus intro (steps 13–15).

      Get.to(
        // () => const PlusIntroScreen(),
        () => const CreateAccountScreen(),
        transition: Transition.noTransition,
      );
    }
  }

  /// On the "preparing" step, hold the Continue button back for [_settingUpDelay]
  /// so the setup animation can play, then reveal it. Restarts cleanly whenever
  /// the user navigates onto (or back to) that step, and resets on every other.
  void _syncSettingUpGate() {
    _settingUpTimer?.cancel();

    if (_page == _settingUpPage) {
      _settingUpReady = false;
      _canContinue.value = false;

      _settingUpTimer = Timer(_settingUpDelay, () {
        if (!mounted) return;

        setState(() {
          _settingUpReady = true;
        });

        _canContinue.value = true;
      });
    } else {
      _settingUpReady = false;
    }
  }

  /// Complete the notifications step: optionally request the OS permission,
  /// persist the choice (synced to Firebase on auth), then advance. Re-entrant
  /// safe, so a double-tap can't fire two prompts or two navigations, and it
  /// never leaves the user stuck — even on error the choice is recorded and the
  /// flow moves on.
  Future<void> _completeNotifications({required bool optIn}) async {
    if (_notifBusy) return;
    setState(() => _notifBusy = true);
    bool granted = _push.hasPermission;
    try {
      if (optIn) {
        final result = await _push.requestPermissionOnboarding();
        granted = result.granted;
      }
    } catch (_) {
      granted = _push.hasPermission;
    } finally {
      _onb.setNotificationChoice(optIn: optIn, granted: granted);
      if (mounted) setState(() => _notifBusy = false);
    }
    if (mounted) _advance();
  }

  void _onBack() {
    if (_page == 0) return;
    setState(() {
      _page--;
    });
    _canContinue.value = true;
    _syncSettingUpGate();
  }

  // ---- Per-page content ----------------------------------------------------

  Widget _bodyFor(int page) {
    switch (page) {
      case 0:
        return const WelcomeScreen();
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
        return NotificationsBody(
          busy: _notifBusy,
          onAllow: () => _completeNotifications(optIn: true),
          onDeny: () => _completeNotifications(optIn: false),
        );
      case 7:
        return HowDidYouHearBody(onValidityChanged: _onValidityChanged);
      case 8:
        return RecipeSourcesBody(onValidityChanged: _onValidityChanged);
      case 9:
        return CuisinesBody(onValidityChanged: _onValidityChanged);
      case 10:
        return const AwesomeImportBody();
      case 11:
        return const AgeBody();
      case 12:
        return SettingUpBody(ready: _settingUpReady);
      default:
        return const SizedBox.shrink();
    }
  }

  String _ctaLabelFor(int page) {
    switch (page) {
      case 0:
        return "Get Started — it's free";
      case 6:
        return 'help_me_stay_on_track'.tr;
      case 9:
        return 'show_me_how'.tr;
      default:
        return 'continue_'.tr;
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // final footer = _footerFor(_page);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _page == 0
            ? const Color(0xFF1B1310)
            : AppColors.background,
        statusBarIconBrightness: _page == 0
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: _page == 0 ? Brightness.dark : Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: _page == 0
          ? const Color(0xFF1B1310)
          : AppColors.background,
      body: SafeArea(
        top: false,
        // bottom: false,
        child: Column(
          children: [
            // Fixed top: app name, then back button + animated progress
            // track. Hidden entirely on the Welcome page (page 0) — the
            // indicator only appears from screen 2 onward.
            if (_page > 0) ...[
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: _AppNameLogo(),
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 20),
              child: ValueListenableBuilder<bool>(
                valueListenable: _canContinue,
                builder: (context, canContinue, _) {
                  final isNotifPage = _page == _notificationsPage;
                  final busy = isNotifPage && _notifBusy;

                  final hideForSetup =
                      _page == _settingUpPage && !_settingUpReady;

                  final VoidCallback? onPressed =
                      !canContinue || busy || hideForSetup
                      ? null
                      : (isNotifPage
                            ? () => _completeNotifications(optIn: true)
                            : _onContinue);

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: hideForSetup ? 0.0 : (canContinue ? 1.0 : 0.45),
                    child: PrimaryButton(
                      label: _ctaLabelFor(_page),
                      height: 54,
                      isLoading: busy,
                      onPressed: onPressed,
                      enableSheen: _page == 0,
                    ),
                  );
                },
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppLogo(size: 30),
        SizedBox(width: 9),
        AppWordmark(fontSize: 20, fontWeight: FontWeight.w800),
      ],
    );
  }
}
