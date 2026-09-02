// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
// import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';
// import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
// import 'package:recipe_ai/View/Home/discover_screen.dart';
// import 'package:recipe_ai/View/Home/groceries_screen.dart';
// import 'package:recipe_ai/View/Home/meal_plan_screen.dart';
// import 'package:recipe_ai/View/Home/settings_screen.dart';
// import 'package:recipe_ai/theme/app_colors.dart';
// import 'package:recipe_ai/widgets/app_bottom_nav.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({
//     super.key,
//     this.initialIndex = 0,
//     this.showRecipesTab = false,
//   });

//   final int initialIndex;

//   /// true only when opening Cookbook from ImportCompleteScreen.
//   final bool showRecipesTab;

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late int _activeIndex = widget.initialIndex;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (Get.isRegistered<ShareIntentService>()) {
//         Get.find<ShareIntentService>().consumePendingInitialShare();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pages = [
//       CookbooksScreen(showRecipesTab: widget.showRecipesTab),
//       const DiscoverScreen(),
//       const MealPlanScreen(),
//       const GroceriesScreen(),
//       const SettingsScreen(),
//     ];

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: IndexedStack(index: _activeIndex, children: pages),
//       bottomNavigationBar: AppBottomNav(
//         currentIndex: _activeIndex,
//         onTap: (index) {
//           // The Meal Plan tab (2) always opens on the current week/month,
//           // regardless of which month the user last browsed before leaving.
//           if (index == 2) Get.find<MealPlanController>().goToToday();
//           setState(() => _activeIndex = index);
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';

import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/discover_screen.dart';
import 'package:recipe_ai/View/Home/groceries_screen.dart';
import 'package:recipe_ai/View/Home/meal_plan_screen.dart';
import 'package:recipe_ai/View/Home/settings_screen.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';

import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';

import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.showRecipesTab = false,
  });

  final int initialIndex;

  /// true only when opening Cookbook from ImportCompleteScreen.
  final bool showRecipesTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _activeIndex = widget.initialIndex;

  bool _premiumNavigationStarted = false;

  @override
  void initState() {
    super.initState();

    AnalyticsService.instance.trackScreen('HomeScreen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ShareIntentService>()) {
        Get.find<ShareIntentService>().consumePendingInitialShare();
      }

      _checkNewSignupPremium();
    });
  }

  /// Opens UpgradePlusScreen only after a successful NEW signup.
  ///
  /// Flow:
  /// Signup → HomeScreen → wait 2 seconds → UpgradePlusScreen
  Future<void> _checkNewSignupPremium() async {
    if (_premiumNavigationStarted) return;

    final storage = GetStorage();

    final shouldShowPremium = storage.read('show_signup_premium') == true;

    // Normal login / Google / Apple login.
    // Do nothing.
    if (!shouldShowPremium) return;

    _premiumNavigationStarted = true;

    // Consume the flag immediately so the premium screen
    // does not open again if HomeScreen rebuilds.
    await storage.remove('show_signup_premium');

    // HomeScreen must be visible for 2 seconds first.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // User may have signed out during the delay.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // If the user already has Plus, don't show upgrade screen.
    if (SubscriptionService.instance.isPlus) return;

    // Make sure we are still on a valid HomeScreen route.
    if (Get.currentRoute.isEmpty) return;

    Get.to(
      () => const UpgradePlusScreen(),
      transition: Transition.noTransition,
    );
  }

  @override
  void dispose() {
    _premiumNavigationStarted = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CookbooksScreen(showRecipesTab: widget.showRecipesTab),
      const DiscoverScreen(),
      const MealPlanScreen(),
      const GroceriesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _activeIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _activeIndex,
        onTap: (index) {
          AnalyticsService.instance.trackButtonTap(
            'bottom_nav_tab',
            screenName: 'HomeScreen',
            extra: {'tab_index': index},
          );
          // The Meal Plan tab (2) always opens on the current
          // week/month, regardless of which month the user
          // last browsed before leaving.
          if (index == 2) {
            Get.find<MealPlanController>().goToToday();
          }

          setState(() => _activeIndex = index);
        },
      ),
    );
  }
}
