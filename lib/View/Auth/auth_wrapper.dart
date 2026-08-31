import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
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
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _scheduledUserId;

  void _schedulePremiumGate(User user) {
    final storage = GetStorage();

    // Fresh signup is handled by HomeScreen.
    // Do NOT schedule another premium navigation here.
    if (storage.read('show_signup_premium') == true) {
      return;
    }

    if (SubscriptionService.instance.isPlus) return;
    if (_scheduledUserId == user.uid) return;

    _scheduledUserId = user.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      if (SubscriptionService.instance.isPlus) return;

      Get.to(
        () => const UpgradePlusScreen(),
        transition: Transition.noTransition,
      );
    });
  }

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

        _schedulePremiumGate(snapshot.data!);
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
