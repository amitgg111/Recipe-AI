import 'package:flutter/services.dart';

/// Reusable, UI-agnostic form validators + input formatters.
///
/// Every validator takes a raw (nullable) string and returns `null` when the
/// value is valid, or a short, user-friendly message when it is not — the exact
/// shape `TextFormField.validator` expects. All string validators trim first so
/// leading/trailing (and whitespace-only) input is rejected consistently.
///
/// Keep ALL field rules here so screens never re-implement validation.
class ValidationHelper {
  ValidationHelper._();

  // ── Patterns ────────────────────────────────────────────────────────────────
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _alphaSpace = RegExp(r'^[A-Za-z ]+$');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _username = RegExp(r'^[A-Za-z0-9_.]+$');
  static final RegExp _url = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );
  static final RegExp _amount = RegExp(r'^\d+(\.\d{1,2})?$');
  static final RegExp _time24 = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');

  static String _t(String? v) => (v ?? '').trim();

  // ═══ Text field validators ═══════════════════════════════════════════════════

  /// Name: required, 2–50 chars, letters and spaces only.
  static String? name(
    String? value, {
    String field = 'Name',
    int min = 2,
    int max = 50,
  }) {
    final v = _t(value);
    if (v.isEmpty) return '$field is required';
    if (v.length < min) return '$field must be at least $min characters';
    if (v.length > max) return '$field must be under $max characters';
    if (!_alphaSpace.hasMatch(v)) {
      return '$field can only contain letters and spaces';
    }
    return null;
  }

  /// Email: required, valid address shape.
  static String? email(String? value) {
    final v = _t(value);
    if (v.isEmpty) return 'Email is required';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Strong password: min 8, one upper, one lower, one number, one special.
  /// Returns the first unmet rule so the message updates as the user types.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!_upper.hasMatch(v)) return 'Add an uppercase letter';
    if (!_lower.hasMatch(v)) return 'Add a lowercase letter';
    if (!_digit.hasMatch(v)) return 'Add a number';
    if (!_special.hasMatch(v)) return 'Add a special character';
    return null;
  }

  /// Sign-in password: presence only (never enforce strength on existing
  /// accounts — Firebase is the source of truth).
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  /// Confirm password: present and an exact match of [original].
  static String? confirmPassword(String? value, String? original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please confirm your password';
    if (v != (original ?? '')) return 'Passwords do not match';
    return null;
  }

  /// Phone: digits only (optional leading +), [min]–[max] digits. Defaults suit
  /// a 10-digit local number; pass a range for other countries.
  static String? phone(
    String? value, {
    int min = 10,
    int max = 15,
    bool required = true,
  }) {
    final v = _t(value).replaceAll(RegExp(r'[\s\-()]'), '');
    if (v.isEmpty) return required ? 'Phone number is required' : null;
    if (!RegExp(r'^\+?\d+$').hasMatch(v)) return 'Enter digits only';
    final digits = v.replaceFirst('+', '');
    if (digits.length < min || digits.length > max) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// OTP: required, numeric, exactly [length] digits.
  static String? otp(String? value, {int length = 6}) {
    final v = _t(value);
    if (v.isEmpty) return 'OTP is required';
    if (!_digitsOnly.hasMatch(v)) return 'OTP must be numeric';
    if (v.length != length) return 'OTP must be $length digits';
    return null;
  }

  /// Amount / money: required, non-negative, max two decimals.
  static String? amount(
    String? value, {
    String field = 'Amount',
    bool greaterThanZero = false,
  }) {
    final v = _t(value);
    if (v.isEmpty) return '$field is required';
    if (!_amount.hasMatch(v)) return 'Enter a valid amount (max 2 decimals)';
    final n = double.tryParse(v);
    if (n == null || n < 0) return '$field cannot be negative';
    if (greaterThanZero && n <= 0) return '$field must be greater than zero';
    return null;
  }

  /// Budget / transaction amount: required, strictly greater than zero.
  static String? positiveAmount(String? value, {String field = 'Amount'}) =>
      amount(value, field: field, greaterThanZero: true);

  /// Age: required, whole number within [min]–[max].
  static String? age(String? value, {int min = 1, int max = 120}) {
    final v = _t(value);
    if (v.isEmpty) return 'Age is required';
    final n = int.tryParse(v);
    if (n == null) return 'Age must be a whole number';
    if (n < min || n > max) return 'Enter a valid age';
    return null;
  }

  /// URL: valid http(s) address. When [required] is false, blank is allowed.
  static String? url(String? value, {bool required = true}) {
    final v = _t(value);
    if (v.isEmpty) return required ? 'URL is required' : null;
    if (!_url.hasMatch(v)) return 'Enter a valid http(s) URL';
    return null;
  }

  /// Username: required, no spaces, [min]–[max] chars, letters/numbers/._ only.
  static String? username(String? value, {int min = 3, int max = 20}) {
    final v = _t(value);
    if (v.isEmpty) return 'Username is required';
    if (v.contains(' ')) return 'Username cannot contain spaces';
    if (v.length < min || v.length > max) {
      return 'Username must be $min–$max characters';
    }
    if (!_username.hasMatch(v)) return 'Use letters, numbers, . or _ only';
    return null;
  }

  /// Generic required text.
  static String? required(String? value, {String field = 'This field'}) {
    if (_t(value).isEmpty) return '$field is required';
    return null;
  }

  /// Optional notes/description with a maximum length.
  static String? notes(String? value, {int max = 500, String field = 'Text'}) {
    final v = _t(value);
    if (v.length > max) return '$field must be under $max characters';
    return null;
  }

  /// Title (recipe / cookbook): required, [min]–[max] chars.
  static String? title(
    String? value, {
    String field = 'Title',
    int min = 2,
    int max = 100,
  }) {
    final v = _t(value);
    if (v.isEmpty) return '$field is required';
    if (v.length < min) return '$field must be at least $min characters';
    if (v.length > max) return '$field must be under $max characters';
    return null;
  }

  /// Quantity: positive number. Optional unless [required].
  static String? quantity(String? value, {bool required = false}) {
    final v = _t(value);
    if (v.isEmpty) return required ? 'Quantity is required' : null;
    final n = num.tryParse(v);
    if (n == null || n <= 0) return 'Enter a positive quantity';
    return null;
  }

  /// Time in 24-hour HH:mm format.
  static String? time24(String? value) {
    final v = _t(value);
    if (v.isEmpty) return 'Time is required';
    if (!_time24.hasMatch(v)) return 'Enter a valid time (HH:mm)';
    return null;
  }

  // ═══ Non-text validators (call manually before submit) ═══════════════════════

  /// At least one non-empty entry in a list (ingredients / instructions).
  static String? nonEmptyList(List<dynamic>? items, {String field = 'item'}) {
    final has = (items ?? []).any(
      (e) => e != null && e.toString().trim().isNotEmpty,
    );
    return has ? null : 'Add at least one $field';
  }

  /// Required dropdown / category selection.
  static String? requiredSelection<T>(T? value, {String field = 'Selection'}) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return '$field is required';
    }
    return null;
  }

  /// Mandatory checkbox (e.g. accept terms).
  static String? mustAccept(bool value, {String message = 'Please accept to continue'}) =>
      value ? null : message;

  /// Required image / file selection.
  static String? requiredFile(Object? file, {String field = 'File'}) =>
      file == null ? '$field is required' : null;

  // ═══ Input formatters (for TextField/TextFormField.inputFormatters) ═══════════

  /// Digits only (phone, OTP, age).
  static List<TextInputFormatter> get digitsOnly => [
        FilteringTextInputFormatter.digitsOnly,
      ];

  /// Letters and spaces only (names).
  static List<TextInputFormatter> get lettersAndSpaces => [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
      ];

  /// Decimal number (amount / quantity) — digits and a single dot.
  static List<TextInputFormatter> get decimal => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ];

  /// Block a leading space so input can never start with whitespace.
  static List<TextInputFormatter> get noLeadingSpace => [
        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
      ];

  /// Cap the length.
  static List<TextInputFormatter> maxLen(int n) => [
        LengthLimitingTextInputFormatter(n),
      ];
}
