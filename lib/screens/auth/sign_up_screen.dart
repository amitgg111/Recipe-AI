import 'package:flutter/material.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';

/// Sign Up is now the "Sign up" tab of the combined [LoginScreen]. This thin
/// wrapper preserves all existing navigation targets that open the sign-up
/// screen — they now open the combined screen with the Sign up tab active.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialTab: 1);
  }
}
