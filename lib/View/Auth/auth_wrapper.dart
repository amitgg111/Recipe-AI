import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/screens/auth/create_account_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// The single source of truth for "is the user signed in?".
///
/// Reacts to [FirebaseAuth.authStateChanges] and shows Home when authenticated,
/// the account entry otherwise.
///
/// It is SEEDED with [FirebaseAuth.currentUser] via `initialData`, so the
/// decision is made synchronously on the very first frame. Right after a
/// successful sign-in `currentUser` is already populated, so Home opens
/// immediately — there is no `waiting` flash, no placeholder screen, and no
/// race. The stream then keeps it in sync for later sign-out / token changes.
///
/// The `waiting` state (a genuine cold resolve with no cached session) renders
/// a PASSIVE loader — never the app's cold-start `SplashScreen`, which runs its
/// own redirect timer and would compete with this stream for navigation.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _AuthLoading();
        }
        if (!snapshot.hasData) {
          print(
            "--------------- if (!snapshot.hasData) {-------------------${!snapshot.hasData}",
          );

          return const CreateAccountScreen();
        }
        print(
          "--------------- if (.   snapshot.hasData) {-------------------${snapshot.hasData}",
        );
        return const HomeScreen();
      },
    );
  }
}

/// Minimal, non-navigating loader shown only while the auth state resolves on a
/// cold start that has no cached session.
class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
