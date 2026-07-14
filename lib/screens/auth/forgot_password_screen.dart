import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/utils/validators.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _emailError; // inline validation error under the field

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

  // Live email validation (suppress "required" until the field has content).
  void _onEmailChanged(String v) {
    setState(() => _emailError = v.isEmpty ? null : Validators.email(v));
  }

  Future<void> _onSendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Surface the failure via the screen's existing inline error display,
      // since the built-in TextFormField error area is intentionally collapsed.
      setState(() => _emailError = Validators.email(_emailController.text));
      return;
    }
    if (_isLoading) return; // prevent duplicate requests / double taps
    FocusScope.of(context).unfocus(); // dismiss the keyboard on submit

    final emailErr = Validators.email(_emailController.text);
    if (emailErr != null) {
      setState(() => _emailError = emailErr);
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });
    try {
      final email = _emailController.text.trim();
      // Server-side existence check — works even when Firebase email
      // enumeration protection is enabled (the client-only APIs hide this).
      // If the function is unavailable it returns true and we fall through to
      // the normal reset-email flow.
      final registered = await AuthService.isEmailRegistered(email);
      if (!registered) {
        if (mounted) {
          setState(() => _emailError = 'no_account_found_email'.tr);
        }
        return;
      }
      await AuthService.forgotPassword(email);
      if (!mounted) return;
      CustomSnackbar.show(
        title: 'email_sent'.tr,
        message: 'check_inbox_reset_link'.tr,
        type: SnackbarType.success,
      );
    } on FirebaseAuthException catch (e) {
      // No account for this email (or malformed) -> show it INLINE under the
      // field so the user immediately sees why nothing was sent.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        if (mounted) setState(() => _emailError = AuthErrorMapper.message(e));
      } else {
        CustomSnackbar.show(
          title: 'could_not_send_email'.tr,
          message: AuthErrorMapper.message(e),
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        title: 'could_not_send_email'.tr,
        message: AuthErrorMapper.message(e),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBackToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button row (height 44)
                    SizedBox(
                      height: 44,
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

                    // Icon badge (margin-top 8, margin-bottom 20)
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE3DB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const OnboardingLineIcon(
                        'lock',
                        size: 28,
                        color: Color(0xFFF2623E),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title (left-aligned)
                    Text(
                      'forgot_password'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A211B),
                        letterSpacing: -0.44,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle (left-aligned)
                    Text(
                      'forgot_password_subtitle'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8A7E70),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email label
                    Text(
                      'email'.tr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9A938A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Email field (focused style per design)
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: _emailError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFF2623E),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_emailError != null
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFF2623E))
                                      .withValues(alpha: 0.1),
                              blurRadius: 0,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onChanged: _onEmailChanged,
                          onFieldSubmitted: (_) => _onSendResetLink(),
                          validator: (v) => ValidationHelper.email(v),
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: 'enter_the_email'.tr,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 10),
                              child: OnboardingLineIcon(
                                'mail',
                                size: 20,
                                color: Color(0xFFF2623E),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
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
                            // Built-in error area collapsed: the message is shown
                            // via the existing custom _emailError display below.
                            errorStyle: const TextStyle(height: 0, fontSize: 0),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Inline validation error, shown only when present.
                    if (_emailError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _emailError!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Send reset link button
                    GestureDetector(
                      onTap: _isLoading ? null : _onSendResetLink,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFFF2623E).withValues(alpha: 0.7)
                              : const Color(0xFFF2623E),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF2623E,
                              ).withValues(alpha: 0.6),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
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
                                  const OnboardingLineIcon(
                                    'mail',
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    'send_reset_link'.tr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom: "Remembered it? Back to log in"
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8A7E70),
                          ),
                          children: [
                            TextSpan(text: '${'remembered_it'.tr} '),
                            TextSpan(
                              text: 'back_to_log_in'.tr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF2623E),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _onBackToLogin,
                            ),
                          ],
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
}
