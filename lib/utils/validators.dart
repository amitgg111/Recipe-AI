/// Pure, reusable input validators for the authentication flow.
///
/// These are deliberately UI-agnostic: each method takes a raw string and
/// returns `null` when the value is valid, or a short human-readable error
/// message when it is not. Screens call these and render the returned message
/// inline — no widget or context dependencies live here, so the rules can be
/// unit-tested and reused across Login, Sign Up and Forgot Password.
class Validators {
  Validators._();

  // A pragmatic email pattern: one or more non-space/non-@ chars, an @, a
  // domain, a dot and a TLD. Intentionally permissive (real validation is the
  // confirmation email) while still rejecting obviously malformed input.
  static final RegExp _emailRegex =
      RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  // Any character that is not a letter or a digit counts as "special".
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');

  /// Email: required, trimmed, must match a basic address shape.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Strong password (used for account creation): min 8 chars with upper,
  /// lower, number and special character. Returns the FIRST unmet rule so the
  /// message can update live as the user types toward a valid password.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!_uppercase.hasMatch(v)) return 'Add an uppercase letter';
    if (!_lowercase.hasMatch(v)) return 'Add a lowercase letter';
    if (!_digit.hasMatch(v)) return 'Add a number';
    if (!_special.hasMatch(v)) return 'Add a special character';
    return null;
  }

  /// Login password: presence only. We must NOT enforce the strength rules on
  /// sign-in — existing accounts may predate them, and rejecting them here
  /// would lock valid users out. Firebase remains the source of truth.
  static String? loginPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    return null;
  }

  /// Confirm password: must be present and match the original exactly.
  static String? confirmPassword(String? value, String? original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please confirm your password';
    if (v != (original ?? '')) return 'Passwords do not match';
    return null;
  }

  /// Name: required, at least 2 non-space characters (rejects whitespace-only).
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }
}
