import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _onSendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomSnackbar.show(
        title: 'Missing email',
        message: 'Please enter your email address',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(email);
      CustomSnackbar.show(
        title: 'Email sent',
        message: 'Check your inbox for a password reset link',
        type: SnackbarType.success,
      );
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

  void _onBackToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _emailFocus.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Lock icon in orange bg square
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE3DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Center(
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.screenTitle,
                ),
              ),

              const SizedBox(height: 10),

              // Description
              Center(
                child: Text(
                  "Enter the email linked to your account and we'll send you a link to reset your password.",
                  style: AppTextStyles.bodyXSmall.copyWith(
                    color: AppColors.textMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 28),

              // Email field
              Text('Email', style: AppTextStyles.inputLabel),
              const SizedBox(height: 6),
              Container(
                height: AppDimensions.inputHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color:
                        isFocused ? AppColors.primary : const Color(0xFFEAE0CF),
                    width: isFocused ? 1.5 : 1,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'sunny@gmail.com',
                    hintStyle: AppTextStyles.inputHint,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color:
                            isFocused ? AppColors.primary : AppColors.textHint,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Send reset link button
              GestureDetector(
                onTap: _isLoading ? null : _onSendResetLink,
                child: Container(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  decoration: BoxDecoration(
                    color: _isLoading ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusButton),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text('A reset link', style: AppTextStyles.buttonLabel),
                          ],
                        ),
                ),
              ),

              const Spacer(),

              // Bottom: "Remembered it? Back to log in"
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
                      children: [
                        const TextSpan(text: 'Remembered it? '),
                        TextSpan(
                          text: 'Back to log in',
                          style: AppTextStyles.link,
                          recognizer: TapGestureRecognizer()
                            ..onTap = _onBackToLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
