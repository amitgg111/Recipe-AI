import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/Service/notification_service.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/screens/onboarding/how_did_you_hear_screen.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/onboarding/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _push = NotificationService.instance;
  final OnboardingController _onb = Get.find<OnboardingController>();

  // Guards against duplicate permission requests / double navigation.
  bool _processing = false;

  // The OS permission is requested only when the user explicitly taps "Allow"
  // (or the positive CTA) — never automatically — so both buttons drive a
  // distinct, working action.

  /// Complete the notifications step: optionally request the OS permission,
  /// persist the choice for Firebase sync, then advance. Never blocks the flow.
  Future<void> _handleChoice({required bool optIn}) async {
    if (_processing) return;
    setState(() => _processing = true);
    bool granted = _push.hasPermission;
    try {
      if (optIn) {
        final result = await _push.requestPermissionOnboarding();
        granted = result.granted;
      }
    } catch (_) {
      // Any failure still records intent and lets the user move on.
      granted = _push.hasPermission;
    } finally {
      _onb.setNotificationChoice(optIn: optIn, granted: granted);
      if (mounted) setState(() => _processing = false);
    }
    if (mounted) _goNext();
  }

  void _goNext() {
    Get.to(() => const HowDidYouHearScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Logo + Progress row
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
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                ],
              ),
              const SizedBox(height: 12),
              // Progress dots (step 6 of 8, index 5)
              const ProgressIndicatorDots(totalSteps: 8, currentStep: 5),
              // Title
              const SizedBox(height: 18),
              Text(
                'Get the right recipe at the right time',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.18,
                  letterSpacing: -0.50,
                ),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "We'll send you a recipe idea at the time that works for you.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
              ),
              // Center content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Notification dialog card
                    SizedBox(
                      width: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2A211B,
                              ).withValues(alpha: 0.45),
                              blurRadius: 50,
                              offset: const Offset(0, 26),
                              spreadRadius: -26,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top section
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                24,
                                22,
                                18,
                              ),
                              child: Column(
                                children: [
                                  // Bell icon
                                  Container(
                                    width: 58,
                                    height: 58,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.redBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Center(
                                      child: OnboardingLineIcon(
                                        'bell',
                                        color: AppColors.primary,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  // Permission text
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                        height: 1.35,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Allow '),
                                        TextSpan(
                                          text: 'Recipe AI',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                            height: 1.35,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' to send you notifications?',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Allow button
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: _processing
                                    ? null
                                    : () => _handleChoice(optIn: true),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Center(
                                    child: _processing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Text(
                                            'Allow',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            // Don't allow button
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: _processing
                                    ? null
                                    : () => _handleChoice(optIn: false),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Center(
                                    child: Text(
                                      "Don't allow",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Below card text
                    const SizedBox(height: 18),
                    Text(
                      'Turn off notifications anytime',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLighter,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom: Help me stay on track button
              PrimaryButton(label: 'Help me stay on track', onPressed: _goNext),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsBody extends StatefulWidget {
  /// Invoked when the user opts in (in-card "Allow"). The parent requests the
  /// OS permission, persists the choice, and advances the flow.
  final Future<void> Function()? onAllow;

  /// Invoked when the user declines (in-card "Don't allow"). The parent skips
  /// the OS request, persists the choice, and advances the flow.
  final Future<void> Function()? onDeny;

  /// Whether a permission request is currently in flight — locks both buttons
  /// and shows a spinner in place of "Allow".
  final bool busy;

  const NotificationsBody({
    super.key,
    this.onAllow,
    this.onDeny,
    this.busy = false,
  });

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  // Sub-title under the card. Reflects the real permission state for a user who
  // navigates back to this step after already choosing.
  String _statusText = 'Turn off notifications anytime';

  @override
  void initState() {
    super.initState();
    // Do NOT auto-prompt here — the OS permission is requested only when the
    // user explicitly taps "Allow" (or the positive CTA). We just reflect the
    // current state so a returning user sees the truth.
    _resolveStatus();
  }

  void _resolveStatus() {
    final push = NotificationService.instance;
    if (!push.isConfigured) return;
    final onb = Get.find<OnboardingController>();
    // Only show a resolved status once the user has completed the step before.
    if (onb.notificationsOptIn.value == null) return;
    final text = push.hasPermission
        ? 'Notifications are on'
        : 'You can turn these on later in Settings';
    if (mounted && text != _statusText) {
      setState(() => _statusText = text);
    }
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
            'Get the right recipe at the right time',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.18,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "We'll send you a recipe idea at the time that works for you.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          // Center content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Notification dialog card
                SizedBox(
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2A211B,
                          ).withValues(alpha: 0.45),
                          blurRadius: 50,
                          offset: const Offset(0, 26),
                          spreadRadius: -26,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                          child: Column(
                            children: [
                              // Bell icon
                              Container(
                                width: 58,
                                height: 58,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.redBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: OnboardingLineIcon(
                                    'bell',
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                              ),
                              // Permission text
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    height: 1.35,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Allow '),
                                    TextSpan(
                                      text: 'Recipe AI',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' to send you notifications?',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Allow button
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: widget.busy
                                ? null
                                : () => widget.onAllow?.call(),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Center(
                                child: widget.busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Text(
                                        'Allow',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        // Don't allow button
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: widget.busy
                                ? null
                                : () => widget.onDeny?.call(),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Center(
                                child: Text(
                                  "Don't allow",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Below card text
                const SizedBox(height: 18),
                Text(
                  _statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLighter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




///b4de6817-d749-42f5-ae39-0331f8aa5a9c