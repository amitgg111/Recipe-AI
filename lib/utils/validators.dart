import 'package:recipe_ai/utils/validation_helper.dart';

/// Auth-flow validators used by Login / Sign Up / Forgot Password.
///
/// These are thin aliases over [ValidationHelper] so the rules live in exactly
/// one place (no duplication) while the auth screens keep their existing API.
class Validators {
  Validators._();

  static String? email(String? value) => ValidationHelper.email(value);

  static String? password(String? value) => ValidationHelper.password(value);

  static String? loginPassword(String? value) =>
      ValidationHelper.loginPassword(value);

  static String? confirmPassword(String? value, String? original) =>
      ValidationHelper.confirmPassword(value, original);

  /// Sign-up display name: required, at least 2 characters. Intentionally
  /// lenient (allows any character) so it never rejects a valid existing name —
  /// unlike [ValidationHelper.name], which enforces letters-and-spaces for
  /// stricter, non-auth name fields.
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }
}
