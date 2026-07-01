import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/screens/auth/sign_up_screen.dart';

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

  Future<void> _onAppleContinue() async {
    CustomSnackbar.show(
      title: 'Coming Soon',
      message: 'Apple sign-in will be available soon',
      type: SnackbarType.info,
    );
  }

  void _onOtherOptions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
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
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Centered "Recipe AI" logo (app name + icon)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const AppLogoMark(size: 19),
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
              ),

              const SizedBox(height: 14),

              // Back button + progress line (like the reference)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A211B)
                                .withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 8,
                        color: const Color(0xFFEAEAEA),
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
                'Create an account',
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
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log in',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF2623E),
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _onLogIn,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Continue with Google button
              _OutlinedAuthButton(
                label: 'Continue with Google',
                onTap: _isLoading ? null : _onGoogleContinue,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6B6359),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 13),

              // Continue with Apple button
              _OutlinedAuthButton(
                label: 'Continue with Apple',
                onTap: _onAppleContinue,
                leading: const Icon(
                  Icons.apple,
                  size: 20,
                  color: Color(0xFF2A211B),
                ),
              ),

              const SizedBox(height: 13),

              // Other options button
              _OutlinedAuthButton(
                label: 'Other options',
                onTap: _onOtherOptions,
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
                    const TextSpan(
                      text:
                          'Your data is 100% secure. By continuing you agree to our ',
                    ),
                    TextSpan(
                      text: 'Terms',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
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
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAE0CF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
