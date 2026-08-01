import 'package:flutter/material.dart';
import 'package:recipe_ai/View/Auth/forget_password_screen.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/Widget/custom_text.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeCtrl.reverse().then((_) {
      setState(() => isLogin = !isLogin);
      _fadeCtrl.forward();
    });
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && name.isEmpty)) {
      CustomSnackbar.show(
        title: 'missing_fields'.tr,
        message: 'please_fill_required_fields'.tr,
        type: SnackbarType.error,
      );

      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await AuthService.signIn(email: email, password: password);
      } else {
        await AuthService.signUp(name: name, email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      CustomSnackbar.show(
        title: 'error'.tr,
        message: e.message ?? 'authentication_error'.tr,
        type: SnackbarType.error,
      );
    } catch (e) {
      CustomSnackbar.show(
        title: 'error'.tr,
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => isLoading = true);
    try {
      final userCred = await AuthService.signInWithGoogle();
      if (userCred == null) {
        CustomSnackbar.show(
          title: 'cancelled'.tr,
          message: 'google_sign_in_cancelled'.tr,
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        title: 'error'.tr,
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // ── Keyboard-safe: SingleChildScrollView + resizeToAvoidBottomInset ──────
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF7F3EE),
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding bottom ensures content clears the keyboard
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            // Minimum height = full screen height, so content centers when
            // keyboard is hidden but scrolls gracefully when it appears
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── Top illustration area ──────────────────────────
                  _HeaderSection(
                    isLogin: isLogin,
                    primary: primary,
                    isDark: isDark,
                  ),

                  // ── Form card ──────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Title ──────────────────────────────
                              CustomText(
                                isLogin
                                    ? 'welcome_back'.tr
                                    : 'create_account'.tr,

                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                              const SizedBox(height: 4),
                              CustomText(
                                isLogin
                                    ? 'sign_in_recipe_collection'.tr
                                    : 'start_saving_favourite_recipes'.tr,
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),

                              const SizedBox(height: 28),

                              // ── Name field (register only) ─────────
                              if (!isLogin) ...[
                                _AuthField(
                                  controller: nameController,
                                  hint: 'full_name'.tr,
                                  icon: Icons.person_outline_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 14),
                              ],

                              // ── Email ──────────────────────────────
                              _AuthField(
                                controller: emailController,
                                hint: 'email_address'.tr,
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),

                              // ── Password ───────────────────────────
                              _AuthField(
                                controller: passwordController,
                                hint: 'password'.tr,
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                isDark: isDark,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),

                              // ── Forgot password ────────────────────
                              if (isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        Get.to(() => ForgotPasswordScreen()),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 0,
                                      ),
                                    ),
                                    child: CustomText(
                                      'forgot_password'.tr,

                                      color: primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // ── Primary CTA ────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : CustomText(
                                          isLogin
                                              ? 'sign_in'.tr
                                              : 'create_account'.tr,

                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Divider ────────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: CustomText(
                                      'or'.tr,

                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ── Google sign-in ─────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : _googleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google G icon built from coloured letters
                                      const _GoogleIcon(),
                                      const SizedBox(width: 10),
                                      CustomText(
                                        'continue_with_google'.tr,

                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Toggle login / register ────────────
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText(
                                      isLogin
                                          ? 'dont_have_account'.tr
                                          : 'already_have_account'.tr,

                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),

                                    TextButton(
                                      onPressed: isLoading ? null : _toggleMode,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(left: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: CustomText(
                                        isLogin ? 'sign_up'.tr : 'sign_in'.tr,
                                        color: primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header illustration (food emoji strip + tagline)
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final bool isLogin;
  final Color primary;
  final bool isDark;

  const _HeaderSection({
    required this.isLogin,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // ── Background colour band ─────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.15),
                    primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // ── Decorative floating emoji row ──────────────────────────
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: const [
                  _EmojiChip('🍝'),
                  _EmojiChip('🥘'),
                  _EmojiChip('🍜'),
                  _EmojiChip('🫕'),
                  _EmojiChip('🥗'),
                  _EmojiChip('🍛'),
                  _EmojiChip('🧆'),
                  _EmojiChip('🥙'),
                ],
              ),
            ),
          ),

          // ── App icon + name ────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      'app_name'.tr,

                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                    ),
                    CustomText(
                      'your_personal_cookbook'.tr,

                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating emoji chip in the header strip
// ─────────────────────────────────────────────────────────────────────────────

class _EmojiChip extends StatelessWidget {
  final String emoji;
  const _EmojiChip(this.emoji);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomText(emoji, fontSize: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled text field
// ─────────────────────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final bool isDark;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF4F4F4);

    return TextField(
      controller: controller,
      obscureText: obscure,
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" logo using coloured Text spans
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFFBBC05)),
          ),
          TextSpan(
            text: 'g',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'l',
            style: TextStyle(color: Color(0xFF34A853)),
          ),
          TextSpan(
            text: 'e',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
        ],
      ),
    );
  }
}
