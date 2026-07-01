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
import 'package:recipe_ai/screens/auth/forgot_password_screen.dart';
import 'package:recipe_ai/widgets/segmented_control.dart';

/// Combined Log in / Sign up screen.
///
/// The segmented control switches the body between the login and signup forms
/// with a smooth animated transition — there is NO navigation between them.
/// [initialTab] selects which tab opens first (0 = Log in, 1 = Sign up).
class LoginScreen extends StatefulWidget {
  final int initialTab;
  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Active tab (0 = login, 1 = signup) and transition direction.
  late int _tab;
  int _direction = 1;

  // Login form state.
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();

  // Signup form state.
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupNameFocus = FocusNode();
  final _signupEmailFocus = FocusNode();
  final _signupPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    for (final f in [
      _loginEmailFocus,
      _loginPasswordFocus,
      _signupNameFocus,
      _signupEmailFocus,
      _signupPasswordFocus,
    ]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _signupNameFocus.dispose();
    _signupEmailFocus.dispose();
    _signupPasswordFocus.dispose();
    super.dispose();
  }

  // Switch tabs (no navigation) with a directional animated transition.
  void _setTab(int index) {
    if (index == _tab) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _direction = index > _tab ? 1 : -1;
      _tab = index;
    });
  }

  // ── Business logic (unchanged from the original two screens) ──────────────

  Future<void> _onLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CustomSnackbar.show(
        title: 'Missing fields',
        message: 'Please fill in all required fields',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(email: email, password: password);
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

  Future<void> _onCreateAccount() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text.trim();

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

  void _onForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

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

                    // Back button at the top (fixed)
                    SizedBox(
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Centered app-name logo (fixed)
                    const Center(child: _AppLogo()),

                    const SizedBox(height: 22),

                    // Title + subtitle (animated per tab)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: _slideFade,
                      layoutBuilder: _topLeftLayout,
                      child: KeyedSubtree(
                        key: ValueKey('title$_tab'),
                        child: _buildTitleBlock(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Segmented tabs (fixed — switches content, no navigation)
                    SegmentedControl(
                      segments: const ['Log in', 'Sign up'],
                      selectedIndex: _tab,
                      onChanged: _setTab,
                    ),

                    const SizedBox(height: 18),

                    // Form body (animated per tab)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: _slideFade,
                      layoutBuilder: _topLeftLayout,
                      child: KeyedSubtree(
                        key: ValueKey('form$_tab'),
                        child:
                            _tab == 0 ? _buildLoginForm() : _buildSignupForm(),
                      ),
                    ),

                    const Spacer(),

                    const SizedBox(height: 12),

                    // Bottom switch link (fixed position, text per tab)
                    Center(child: _buildBottomLink()),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Directional slide + fade used by both switchers.
  Widget _slideFade(Widget child, Animation<double> animation) {
    final offset = Tween<Offset>(
      begin: Offset(0.12 * _direction, 0),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  Widget _topLeftLayout(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }

  Widget _buildTitleBlock() {
    final isLogin = _tab == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isLogin ? 'Log in' : 'Create account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2A211B),
            letterSpacing: -0.44,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isLogin
              ? "Welcome back — let's get cooking."
              : 'Save & plan recipes in seconds.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8A7E70),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel('Email'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginEmailController,
          focusNode: _loginEmailFocus,
          hint: 'avery@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildLabel('Password'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginPasswordController,
          focusNode: _loginPasswordFocus,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          suffixIcon: _eyeToggle(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _onForgotPassword,
            child: Text(
              'Forgot password?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryActionButton(
          label: 'Log in',
          isLoading: _isLoading,
          onTap: _isLoading ? null : _onLogin,
        ),
        const SizedBox(height: 18),
        const _OrDivider(),
        const SizedBox(height: 18),
        _buildSocialRow(),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel('Name'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupNameController,
          focusNode: _signupNameFocus,
          hint: 'Avery Rhodes',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 11),
        _buildLabel('Email'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupEmailController,
          focusNode: _signupEmailFocus,
          hint: 'avery@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 11),
        _buildLabel('Password'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupPasswordController,
          focusNode: _signupPasswordFocus,
          hint: 'Create a password',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          suffixIcon: _eyeToggle(),
        ),
        const SizedBox(height: 16),
        _PrimaryActionButton(
          label: 'Create account',
          isLoading: _isLoading,
          onTap: _isLoading ? null : _onCreateAccount,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFA8A092),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                TextSpan(
                  text: 'Terms',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A7E70),
                    height: 1.5,
                  ),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
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
        ),
        const SizedBox(height: 14),
        const _OrDivider(),
        const SizedBox(height: 14),
        _buildSocialRow(),
      ],
    );
  }

  Widget _buildBottomLink() {
    final isLogin = _tab == 0;
    return Text.rich(
      TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF8A7E70),
        ),
        children: [
          TextSpan(
            text: isLogin ? 'New here? ' : 'Already have an account? ',
          ),
          TextSpan(
            text: isLogin ? 'Create an account' : 'Log in',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF2623E),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _setTab(isLogin ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            onTap: _onGoogleSignIn,
            leading: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEE9),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'G',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6B6359),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialButton(label: 'Apple', onTap: _onAppleSignIn),
        ),
      ],
    );
  }

  Widget _eyeToggle() {
    return GestureDetector(
      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
      child: Icon(
        _obscurePassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 20,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF9A938A),
      ),
    );
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
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 17,
          ),
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
    );
  }
}

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
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.primary,
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
          child: Divider(color: Color(0xFFE7DECE), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA89F90),
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFE7DECE), thickness: 1),
        ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
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
