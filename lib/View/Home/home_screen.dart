import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/discover_screen.dart';
import 'package:recipe_ai/View/Home/groceries_screen.dart';
import 'package:recipe_ai/View/Home/meal_plan_screen.dart';
import 'package:recipe_ai/View/Home/settings_screen.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ShareIntentService>()) {
        Get.find<ShareIntentService>().consumePendingInitialShare();
      }
    });
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
          // The Meal Plan tab (2) always opens on the current week/month,
          // regardless of which month the user last browsed before leaving.
          if (index == 2) Get.find<MealPlanController>().goToToday();
          setState(() => _activeIndex = index);
        },
      ),
    );
  }
}
