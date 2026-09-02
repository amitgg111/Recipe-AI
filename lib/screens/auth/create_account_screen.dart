import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/screens/auth/sign_up_screen.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _onGoogleContinue() async {
    if (_isGoogleLoading || _isAppleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final userCred = await AuthService.signInWithGoogle();

      if (userCred == null) {
        return;
      }

      await _routeAfterAuth();
    } catch (e) {
      if (!mounted) return;

      CustomSnackbar.show(
        title: 'google_sign_in_failed'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _onAppleContinue() async {
    if (_isGoogleLoading || _isAppleLoading) return;
    setState(() => _isAppleLoading = true);

    try {
      final result = await AuthService.signInWithApple();

      if (result.cancelled) {
        return;
      }

      if (result.success) {
        await _routeAfterAuth();
      } else {
        if (!mounted) return;

        CustomSnackbar.show(
          title: 'sign_in_failed'.tr,
          message: result.errorMessage ?? 'could_not_sign_in_with_apple'.tr,
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;

      CustomSnackbar.show(
        title: 'sign_in_failed'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  void _onOtherOptions() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  void _onLogIn() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _routeAfterAuth() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
    } catch (_) {
      Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Centered "Recipe AI" logo (app name + icon)
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(size: 28),
                    SizedBox(width: 8),
                    AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Back button + progress line (like the reference)
              Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        color: const Color(0xFFEDE3D0),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0,
                          child: Container(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Title
              Text(
                'create_an_account'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2A211B),
                  letterSpacing: -0.54,
                ),
              ),

              const SizedBox(height: 9),

              // Subtitle with tappable "Log in"
              Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A7E70),
                  ),
                  children: [
                    TextSpan(text: '${'already_have_account'.tr} '),
                    TextSpan(
                      text: 'login'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF2623E),
                      ),

                      // recognizer: TapGestureRecognizer()..onTap = _onLogIn,
                      recognizer: (_isGoogleLoading || _isAppleLoading)
                          ? null
                          : (TapGestureRecognizer()..onTap = _onLogIn),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Continue with Google button
              _OutlinedAuthButton(
                label: 'continue_with_google'.tr,
                onTap: (_isGoogleLoading || _isAppleLoading)
                    ? null
                    : _onGoogleContinue,
                isLoading: _isGoogleLoading,
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    'assets/welcome/google.svg', // તમારું SVG path
                    width: 24,
                    height: 24,
                  ),
                ),
              ),

              const SizedBox(height: 13),

              // Continue with Apple button
              if (!Platform.isAndroid) ...[
                const SizedBox(height: 13),

                _OutlinedAuthButton(
                  label: 'continue_with_apple'.tr,
                  onTap: (_isGoogleLoading || _isAppleLoading)
                      ? null
                      : _onAppleContinue,
                  isLoading: _isAppleLoading,
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      'assets/welcome/apple.svg', // તમારું SVG path
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 13),

              // Other options button
              _OutlinedAuthButton(
                label: 'other_options'.tr,
                onTap: _onOtherOptions,
                isLoading: false,
              ),

              const Expanded(child: SizedBox()),

              // Bottom disclaimer
              Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA8A092),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: '${'your_data_secure'.tr} '),
                    TextSpan(
                      text: 'terms'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => LegalLinkLauncher.open(
                          RemoteConfigService.instance.termsOfServiceUrl,
                        ),
                    ),
                    TextSpan(text: ' ${'and'.tr} '),
                    TextSpan(
                      text: 'privacy_policy'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => LegalLinkLauncher.open(
                          RemoteConfigService.instance.privacyPolicyUrl,
                        ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool isLoading;

  const _OutlinedAuthButton({
    required this.label,
    required this.onTap,
    this.leading,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? const Color(0xFFEAE0CF).withValues(alpha: 0.6)
                : const Color(0xFFEAE0CF),
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 11),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A211B),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
