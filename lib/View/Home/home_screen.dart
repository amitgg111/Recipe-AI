import 'package:flutter/material.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/View/Home/discover_screen.dart';
import 'package:recipe_ai/View/Home/groceries_screen.dart';
import 'package:recipe_ai/View/Home/meal_plan_screen.dart';
import 'package:recipe_ai/View/Home/profile_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static int activeIndex = 0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _pages = [
    const CookbooksScreen(),
    const DiscoverScreen(),
    const MealPlanScreen(),
    GroceriesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: HomeScreen.activeIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: HomeScreen.activeIndex,
        onTap: (index) => setState(() => HomeScreen.activeIndex = index),
      ),
    );
  }
}
