import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/screens/auth/sign_up_screen.dart';
import 'package:recipe_ai/widgets/progress_indicator_dots.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _isLoading = false;

  Future<void> _onGoogleContinue() async {
    setState(() => _isLoading = true);
    try {
      final userCred = await AuthService.signInWithGoogle();
      if (userCred == null) {
        CustomSnackbar.show(
          title: 'Cancelled',
          message: 'Google sign-in was cancelled',
          type: SnackbarType.error,
        );
      } else {
        Get.offAll(() => const AuthWrapper());
      }
    } catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOtherOptions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _onSkip() {
    Navigator.of(context).maybePop();
  }

  void _onLogIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Progress dots
              const ProgressIndicatorDots(totalSteps: 4, currentStep: 3),

              const SizedBox(height: 32),

              // Small logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                'Create an account',
                style: AppTextStyles.screenTitle,
              ),

              const SizedBox(height: 10),

              // Subtitle with tappable "Log in"
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log in',
                      style: AppTextStyles.link.copyWith(fontSize: 14.5),
                      recognizer: TapGestureRecognizer()..onTap = _onLogIn,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Continue with Google button
              _OutlinedAuthButton(
                label: 'Continue with Google',
                onTap: _onGoogleContinue,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Other options button
              _OutlinedAuthButton(
                label: 'Other options',
                onTap: _onOtherOptions,
              ),

              const SizedBox(height: 20),

              // Skip link
              GestureDetector(
                onTap: _onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
              ),

              const Spacer(),

              // Bottom disclaimer
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.disclaimer,
                    children: [
                      const TextSpan(
                        text: 'Your data is 100% secure. By continuing you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms',
                        style: AppTextStyles.disclaimer.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.disclaimer.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
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
  final VoidCallback onTap;
  final Widget? leading;

  const _OutlinedAuthButton({
    required this.label,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: const Color(0xFFEAE0CF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
