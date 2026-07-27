import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/utils/validators.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/screens/onboarding/trial_chooser_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/screens/auth/forgot_password_screen.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

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
  // Terms & Privacy agreement checkbox on the sign-up form — checked (on) by
  // default; the user can uncheck it to disable account creation.
  bool _agreedToTerms = true;

  // Inline validation errors (null = nothing shown under the field).
  String? _loginEmailError;
  String? _loginPasswordError;
  String? _signupNameError;
  String? _signupEmailError;
  String? _signupPasswordError;

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
  void deactivate() {
    // Any navigation that removes this screen from the tree (back, Get.offAll,
    // replace, page transition) clears the fields so nothing typed persists to
    // the next visit.
    _clearAllControllers();
    super.deactivate();
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
      _clearAllControllers();
    });
  }

  /// Reset every auth field and its inline error. Called when the login/sign-up
  /// tab changes and whenever this screen leaves the tree (navigation / page
  /// transition), so no typed data lingers between tabs or across visits.
  void _clearAllControllers() {
    _loginEmailController.clear();
    _loginPasswordController.clear();
    _signupNameController.clear();
    _signupEmailController.clear();
    _signupPasswordController.clear();
    _loginEmailError = null;
    _loginPasswordError = null;
    _signupNameError = null;
    _signupEmailError = null;
    _signupPasswordError = null;
  }

  // ── Validation (rules live in Validators; UI only renders the result) ─────

  // Drives the enabled state of each primary button. Login checks email format
  // + password presence only (never enforce strength rules on existing
  // accounts); sign-up enforces the full strong-password policy.
  bool get _isLoginValid =>
      Validators.email(_loginEmailController.text) == null &&
      Validators.loginPassword(_loginPasswordController.text) == null;

  bool get _isSignupValid =>
      Validators.name(_signupNameController.text) == null &&
      Validators.email(_signupEmailController.text) == null &&
      Validators.password(_signupPasswordController.text) == null;

  // Live field validation while typing. We suppress the "required" message for
  // an empty field (don't nag before the user starts) but surface format /
  // strength errors immediately. Always calls setState so the button's
  // enabled state stays in sync with the current input.
  void _live(
    String value,
    String? Function(String?) validator,
    void Function(String?) setError,
  ) {
    setState(() => setError(value.isEmpty ? null : validator(value)));
  }

  // ── Business logic ────────────────────────────────────────────────────────

  Future<void> _onLogin() async {
    if (_isLoading) return; // prevent duplicate requests / double taps
    FocusScope.of(context).unfocus(); // dismiss the keyboard on submit

    // Validate everything (incl. required) before any Firebase call.
    final emailErr = Validators.email(_loginEmailController.text);
    final passErr = Validators.loginPassword(_loginPasswordController.text);
    if (emailErr != null || passErr != null) {
      setState(() {
        _loginEmailError = emailErr;
        _loginPasswordError = passErr;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      // AuthService trims the email internally; passwords are never logged.
      await AuthService.signIn(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
      );
      await _routeAfterAuth();
    } catch (e) {
      CustomSnackbar.show(
        title: 'login_failed'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCreateAccount() async {
    if (_isLoading) return; // prevent duplicate account creation / double taps
    FocusScope.of(context).unfocus();

    final nameErr = Validators.name(_signupNameController.text);
    final emailErr = Validators.email(_signupEmailController.text);
    final passErr = Validators.password(_signupPasswordController.text);
    if (nameErr != null || emailErr != null || passErr != null) {
      setState(() {
        _signupNameError = nameErr;
        _signupEmailError = emailErr;
        _signupPasswordError = passErr;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        name: _signupNameController.text,
        email: _signupEmailController.text,
        password: _signupPasswordController.text,
      );
      CustomSnackbar.show(
        title: 'welcome_exclaim'.tr,
        message: 'account_created_message'.tr,
        type: SnackbarType.success,
      );
      await _routeAfterAuth();
    } catch (e) {
      CustomSnackbar.show(
        title: 'sign_up_failed'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    if (_isLoading) return; // prevent duplicate login requests
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final userCred = await AuthService.signInWithGoogle();
      if (userCred == null) return; // user cancelled the picker — stay silent
      await _routeAfterAuth();
    } catch (e) {
      CustomSnackbar.show(
        title: 'google_sign_in_failed'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAppleSignIn() async {
    if (_isLoading) return; // prevent duplicate login requests
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithApple();
      if (result.cancelled) return; // user backed out — stay silent
      if (result.success) {
        await _routeAfterAuth();
      } else {
        CustomSnackbar.show(
          title: 'apple_sign_in_failed'.tr,
          message: result.errorMessage ?? 'could_not_sign_in_with_apple'.tr,
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeAfterAuth() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final needsTrialChooser = snap.data()?['trialChooserCompleted'] == false;

      Get.offAll(
        () =>
            needsTrialChooser ? const TrialChooserScreen() : const HomeScreen(),
        transition: Transition.noTransition,
      );
    } catch (_) {
      Get.offAll(() => const HomeScreen(), transition: Transition.noTransition);
    }
  }

  void _onForgotPassword() {
    FocusScope.of(context).unfocus();
    // Clear before navigating away (push over) — deactivate() only fires when
    // this screen is removed, not when another route is pushed on top of it.
    setState(_clearAllControllers);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
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
              minHeight:
                  MediaQuery.of(context).size.height -
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
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEDE3D2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const OnboardingLineIcon(
                              'back',
                              size: 15,
                              color: AppColors.textDark,
                            ),
                          ),
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
                    SlidingSegmented.tabs(
                      labels: ['login'.tr, 'sign_up'.tr],
                      selectedIndex: _tab,
                      onChanged: _setTab,
                      height: 38,
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
                        child: _tab == 0
                            ? _buildLoginForm()
                            : _buildSignupForm(),
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
          isLogin ? 'login'.tr : 'create_account'.tr,
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
              ? 'welcome_back_lets_cook'.tr
              : 'save_plan_recipes_seconds'.tr,
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
        _buildLabel('email'.tr),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginEmailController,
          focusNode: _loginEmailFocus,
          hint: 'enter_the_email'.tr,
          prefixIconName: 'mail',
          keyboardType: TextInputType.emailAddress,
          errorText: _loginEmailError,
          onChanged: (v) =>
              _live(v, Validators.email, (e) => _loginEmailError = e),
          textInputAction: TextInputAction.next,
          onSubmitted: () =>
              FocusScope.of(context).requestFocus(_loginPasswordFocus),
        ),
        const SizedBox(height: 16),
        _buildLabel('password'.tr),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginPasswordController,
          focusNode: _loginPasswordFocus,
          hint: '••••••••',
          prefixIconName: 'lock',
          obscure: _obscurePassword,
          suffixIcon: _eyeToggle(),
          errorText: _loginPasswordError,
          onChanged: (v) => _live(
            v,
            Validators.loginPassword,
            (e) => _loginPasswordError = e,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: () => _onLogin(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _onForgotPassword,
            child: Text(
              'forgot_password'.tr,
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
          label: 'login'.tr,
          isLoading: _isLoading,
          enabled: _isLoginValid,
          onTap: _onLogin,
        ),
        const SizedBox(height: 14),
        const _OrDivider(),
        const SizedBox(height: 14),
        _buildSocialRow(),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel('name'.tr),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupNameController,
          focusNode: _signupNameFocus,
          hint: 'enter_the_name'.tr,
          prefixIconName: 'user',
          keyboardType: TextInputType.name,
          errorText: _signupNameError,
          onChanged: (v) =>
              _live(v, Validators.name, (e) => _signupNameError = e),
          textInputAction: TextInputAction.next,
          onSubmitted: () =>
              FocusScope.of(context).requestFocus(_signupEmailFocus),
        ),
        const SizedBox(height: 11),
        _buildLabel('email'.tr),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupEmailController,
          focusNode: _signupEmailFocus,
          hint: 'enter_the_email'.tr,
          prefixIconName: 'mail',
          keyboardType: TextInputType.emailAddress,
          errorText: _signupEmailError,
          onChanged: (v) =>
              _live(v, Validators.email, (e) => _signupEmailError = e),
          textInputAction: TextInputAction.next,
          onSubmitted: () =>
              FocusScope.of(context).requestFocus(_signupPasswordFocus),
        ),
        const SizedBox(height: 11),
        _buildLabel('password'.tr),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupPasswordController,
          focusNode: _signupPasswordFocus,
          hint: 'create_a_password'.tr,
          prefixIconName: 'lock',
          obscure: _obscurePassword,
          suffixIcon: _eyeToggle(),
          errorText: _signupPasswordError,
          onChanged: (v) =>
              _live(v, Validators.password, (e) => _signupPasswordError = e),
          textInputAction: TextInputAction.done,
          onSubmitted: () => _onCreateAccount(),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Agreement checkbox — checked (on) by default.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _agreedToTerms
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _agreedToTerms
                        ? AppColors.primary
                        : const Color(0xFFCBBFA8),
                    width: 1.5,
                  ),
                ),
                child: _agreedToTerms
                    ? const OnboardingLineIcon(
                        'check',
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFA8A092),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: '${'by_continuing_agree'.tr} '),
                    TextSpan(
                      text: 'terms'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'privacy_policy'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PrimaryActionButton(
          label: 'create_account'.tr,
          isLoading: _isLoading,
          enabled: _isSignupValid && _agreedToTerms,
          onTap: _onCreateAccount,
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
            text: isLogin
                ? '${'new_here'.tr} '
                : '${'already_have_account'.tr} ',
          ),
          TextSpan(
            text: isLogin ? 'create_an_account'.tr : 'login'.tr,
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
            label: 'google'.tr,
            onTap: _isLoading ? null : _onGoogleSignIn,
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
        if (!Platform.isAndroid) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _SocialButton(
              label: 'apple'.tr,
              onTap: _isLoading ? null : _onAppleSignIn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _eyeToggle() {
    return GestureDetector(
      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
      child: const OnboardingLineIcon(
        'eye',
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
    required String prefixIconName,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppDimensions.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFDC2626)
                  : isFocused
                  ? AppColors.primary
                  : const Color(0xFFEAE0CF),
              width: isFocused || hasError ? 1.5 : 1,
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
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.inputHint,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: OnboardingLineIcon(
                  prefixIconName,
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
              filled: false,
              isDense: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
        ),
        // Inline validation error, shown only when present.
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
      ],
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
        const AppLogo(size: 30),
        const SizedBox(width: 8),
        AppWordmark(fontSize: 16, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool enabled;
  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Disabled while loading or while the form is invalid; taps are ignored
    // and the button dims to signal the state.
    final bool disabled = isLoading || !enabled;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.7)
              : enabled
              ? AppColors.primary
              : AppColors.divider,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          // boxShadow: const [
          //   BoxShadow(
          //     color: AppColors.primaryShadow,
          //     blurRadius: 30,
          //     offset: Offset(0, 16),
          //     spreadRadius: -10,
          //   ),
          // ],
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
        const Expanded(child: Divider(color: Color(0xFFE7DECE), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA89F90),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE7DECE), thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  const _SocialButton({required this.label, required this.onTap, this.leading});

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
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
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
