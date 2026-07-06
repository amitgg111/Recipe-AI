import 'package:flutter/material.dart';
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
