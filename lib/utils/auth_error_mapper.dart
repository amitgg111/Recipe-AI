import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

/// Translates raw auth/Firebase errors into short, friendly, user-facing
/// messages. Centralising this keeps every screen consistent and ensures we
/// never surface a raw exception string (which can leak internals) to users.
///
/// Nothing sensitive is logged or returned — messages are intentionally generic
/// where revealing detail would aid account enumeration or attacks.
class AuthErrorMapper {
  AuthErrorMapper._();

  /// Returns a friendly message for [error]. Accepts a [FirebaseAuthException],
  /// a [SocketException] (offline), or any other object (generic fallback).
  static String message(Object? error) {
    if (error is FirebaseAuthException) {
      return _forCode(error.code, error.message);
    }
    if (error is SocketException) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String _forCode(String code, String? fallback) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      // Modern Firebase (with email-enumeration protection) returns this
      // instead of user-not-found / wrong-password for sign-in failures.
      case 'invalid-credential':
        return 'Your email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'credential-already-in-use':
        return 'This sign-in is already linked to another account.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'That link has expired. Please request a new one.';
      default:
        // Never expose raw internals; fall back to a generic message.
        return fallback == null || fallback.isEmpty
            ? 'Something went wrong. Please try again.'
            : 'Unable to continue. Please try again.';
    }
  }
}
