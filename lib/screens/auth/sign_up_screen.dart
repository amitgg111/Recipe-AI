import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Auth/auth_wrapper.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/widgets/segmented_control.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _onCreateAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      CustomSnackbar.show(
        title: 'Missing fields',
        message: 'Please fill in all required fields',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(name: name, email: email, password: password);
      Get.offAll(() => const AuthWrapper());
    } on FirebaseAuthException catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: e.message ?? 'Authentication error',
        type: SnackbarType.error,
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

  Future<void> _onGoogleSignIn() async {
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

  Future<void> _onAppleSignIn() async {
    CustomSnackbar.show(
      title: 'Coming Soon',
      message: 'Apple sign-in will be available soon',
      type: SnackbarType.info,
    );
  }

  void _onLogIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Back button
                    _BackButton(onTap: () => Navigator.of(context).maybePop()),

                    const SizedBox(height: 20),

                    // Small logo centered
                    Center(
                      child: Container(
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
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Center(
                      child: Text(
                        'Create account',
                        style: AppTextStyles.screenTitle,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Center(
                      child: Text(
                        'Save & plan recipes in seconds.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Segmented control
                    SegmentedControl(
                      segments: const ['Log in', 'Sign up'],
                      selectedIndex: 1,
                      onChanged: _onSegmentChanged,
                    ),

                    const SizedBox(height: 24),

                    // Name field
                    _buildLabel('Name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      hint: 'Jenny Rhodes',
                      prefixIcon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 16),

                    // Email field
                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hint: 'sunny@gmail.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hint: 'Create a password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create account button
                    _PrimaryActionButton(
                      label: 'Create account',
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _onCreateAccount,
                    ),

                    const SizedBox(height: 16),

                    // Disclaimer
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.disclaimer,
                          children: [
                            const TextSpan(
                              text: 'By continuing you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms',
                              style: AppTextStyles.disclaimer.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const TextSpan(text: ' & '),
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

                    const SizedBox(height: 24),

                    // Divider with "or"
                    const _OrDivider(),

                    const SizedBox(height: 24),

                    // Social buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            onTap: _onGoogleSignIn,
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EAE0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'G',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            onTap: _onAppleSignIn,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Bottom: "Already have an account? Log in"
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            style:
                                AppTextStyles.bodySmall.copyWith(fontSize: 14),
                            children: [
                              const TextSpan(
                                  text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log in',
                                style: AppTextStyles.link,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _onLogIn,
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.inputLabel);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isFocused ? AppColors.primary : const Color(0xFFEAE0CF),
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
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              prefixIcon,
              size: 20,
              color: isFocused ? AppColors.primary : AppColors.textHint,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (duplicated from login for independence)
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryShadow,
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(label, style: AppTextStyles.buttonLabel),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: AppColors.surfaceBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: AppColors.surfaceBorder, thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  const _SocialButton({
    required this.label,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFEAE0CF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
