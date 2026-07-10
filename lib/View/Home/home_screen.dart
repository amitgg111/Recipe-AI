import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/discover_screen.dart';
import 'package:recipe_ai/View/Home/groceries_screen.dart';
import 'package:recipe_ai/View/Home/meal_plan_screen.dart';
import 'package:recipe_ai/View/Home/settings_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  /// Tab to open on first build (0 = Cookbooks). Deep-link callers pass this
  /// instead of a shared static field, so the selected tab never leaks across
  /// sessions (e.g. logging out while on Settings, then logging back in).
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _activeIndex = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    // Home is now on-screen — process any recipe shared into the app while it
    // was closed. Deferred to here (after the first frame) so the import's
    // processing screen is pushed on top of home and isn't wiped out by the
    // splash → home redirect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ShareIntentService>()) {
        Get.find<ShareIntentService>().consumePendingInitialShare();
      }
    });
  }

  final List<Widget> _pages = [
    const CookbooksScreen(),
    const DiscoverScreen(),
    const MealPlanScreen(),
    GroceriesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _activeIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _activeIndex,
        onTap: (index) => setState(() => _activeIndex = index),
      ),
    );
  }
}
