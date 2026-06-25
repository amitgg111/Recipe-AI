import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Model/meal_plan_model.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';

import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanController controller = Get.find<MealPlanController>();
  final HomeController homeController = Get.find<HomeController>();

  // ─── Meal type color map ───────────────────────────────────────────────────
  static const Map<String, Color> _mealColors = {
    'Breakfast': Color(0xFFF59E0B),
    'Lunch': Color(0xFF10B981),
    'Dinner': Color(0xFF6366F1),
    'Snack': Color(0xFFEF4444),
  };

  Color _mealColor(String mealType) =>
      _mealColors[mealType] ?? AppTheme.primary;

  // ─── Helpers ───────────────────────────────────────────────────────────────
  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.day == d2.day && d1.month == d2.month && d1.year == d2.year;

  String _formatDayTitle(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final isToday = _isSameDay(date, DateTime.now());
    final dayName = weekdays[date.weekday - 1];
    return isToday ? 'Today · $dayName ${date.day}' : '$dayName ${date.day}';
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ─── Recipe Selection Bottom Sheet ────────────────────────────────────────
  void _showRecipeSelectionBottomSheet(
    BuildContext context,
    DateTime date,
    String mealType,
  ) {
    final color = _mealColor(mealType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_mealIcon(mealType), color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Add to $mealType',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          CustomText(
                            'Pick a recipe from your cookbook',
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 4),

              // ── Recipe List ──
              Expanded(
                child: Obx(() {
                  if (homeController.recipes.isEmpty) {
                    return _buildEmptyRecipes();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: homeController.recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = homeController.recipes[index];
                      return _buildRecipeSelectTile(
                        recipe,
                        date,
                        mealType,
                        color,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _mealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_sunny_outlined;
      case 'Lunch':
        return Icons.lunch_dining_outlined;
      case 'Dinner':
        return Icons.dinner_dining_outlined;
      case 'Snack':
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  Widget _buildEmptyRecipes() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const CustomText(
            'No recipes yet',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 6),
          CustomText(
            'Add recipes to your Cookbooks first.',
            color: Colors.grey.shade500,
            fontSize: 14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSelectTile(
    dynamic recipe,
    DateTime date,
    String mealType,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        controller.addMealPlanItem(
          date: date,
          mealType: mealType,
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          recipeImageUrl: recipe.imageUrl,
        );
        Navigator.pop(context);
        Get.snackbar(
          'Added to $mealType',
          '${recipe.title} scheduled successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: color,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
          icon: Icon(_mealIcon(mealType), color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: RecipeImage(
                imageUrl: recipe.imageUrl,
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    recipe.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    recipe.cuisine ?? 'Unknown cuisine',
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: color, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const CustomText(
          'Meal Plan',
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          // "Today" jump button
          Obx(() {
            final isCurrentWeek = _isSameDay(
              controller.selectedWeekStart.value,
              _getMonday(DateTime.now()),
            );
            if (isCurrentWeek) return const SizedBox.shrink();
            return TextButton(
              onPressed: () {
                controller.selectedWeekStart.value = _getMonday(DateTime.now());
              },
              child: Text(
                'Today',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Week Navigator ──
            _buildWeekNavigator(),

            // ── Day Cards ──
            Obx(() {
              if (controller.isLoading.value &&
                  controller.mealPlanItems.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final weekDays = controller.getDaysOfWeek(
                controller.selectedWeekStart.value,
              );
              final items = controller.mealPlanItems.toList();
              return Column(
                children: weekDays
                    .map((date) => _buildDayCard(date, items))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  DateTime _getMonday(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));

  // ─── Week Navigator ────────────────────────────────────────────────────────
  Widget _buildWeekNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Prev
          _navButton(Icons.chevron_left, controller.previousWeek),
          const SizedBox(width: 8),

          // Date label
          Expanded(
            child: Obx(
              () => Center(
                child: Column(
                  children: [
                    CustomText(
                      _weekLabel(controller.selectedWeekStart.value),
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      controller.formatDateRange(
                        controller.selectedWeekStart.value,
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          // Next
          _navButton(Icons.chevron_right, controller.nextWeek),
        ],
      ),
    );
  }

  String _weekLabel(DateTime start) {
    final now = DateTime.now();
    final monday = _getMonday(now);
    final diff = start.difference(monday).inDays;
    if (diff == 0) return 'THIS WEEK';
    if (diff == 7) return 'NEXT WEEK';
    if (diff == -7) return 'LAST WEEK';
    return diff > 0 ? '${diff ~/ 7} WEEKS AHEAD' : '${(-diff) ~/ 7} WEEKS AGO';
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 22, color: Colors.grey.shade700),
      ),
    );
  }

  // ─── Day Card ──────────────────────────────────────────────────────────────
  Widget _buildDayCard(DateTime date, List<MealPlanItem> items) {
    final isToday = _isSameDay(date, DateTime.now());
    final dayTitle = _formatDayTitle(date);
    final dateStr = _formatDate(date);
    final dayItems = items.where((item) => item.date == dateStr).toList();
    final hasMeals = dayItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary.withValues(alpha: 0.04)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withValues(alpha: 0.35)
              : Colors.grey.shade100,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
            child: Row(
              children: [
                // Day dot indicator
                if (isToday)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),

                Expanded(
                  child: CustomText(
                    dayTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isToday ? AppTheme.primary : null,
                  ),
                ),

                // Meal count badge
                if (hasMeals)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      '${dayItems.length} meal${dayItems.length > 1 ? 's' : ''}',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),

                // Add button (popup)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 24,
                    color: isToday ? AppTheme.primary : Colors.grey.shade500,
                  ),
                  tooltip: 'Add meal',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (mealType) =>
                      _showRecipeSelectionBottomSheet(context, date, mealType),
                  itemBuilder: (context) => _mealColors.entries.map((e) {
                    return PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(e.key),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Divider(
            height: 1,
            color: isToday
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
          ),

          // ── Meal items or empty ──
          if (!hasMeals)
            _buildEmptyDay()
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: dayItems.map((item) => _buildMealTile(item)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          CustomText(
            'Tap + to add a recipe',
            color: Colors.grey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildMealTile(MealPlanItem item) {
    final color = _mealColor(item.mealType);

    return GestureDetector(
      onTap: () {
        final recipe = homeController.recipes.firstWhereOrNull(
          (r) => r.id == item.recipeId,
        );
        Get.to(() => RecipeDetailScreen(recipe: recipe!));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            // ── Color strip ──
            Container(
              width: 10,
              height: 86,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),

            // ── Recipe image ──
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: RecipeImage(
                imageUrl: item.recipeImageUrl,
                width: 80,
                height: 86,
              ),
            ),

            // ── Text ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MealType pill
                    CustomText(
                      item.recipeTitle,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        item.mealType,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Delete button ──
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
              tooltip: 'Remove',
              onPressed: () => _confirmDelete(item),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm Delete ────────────────────────────────────────────────────────
  void _confirmDelete(MealPlanItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const CustomText(
              'Remove this meal?',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 6),
            CustomText(
              item.recipeTitle,
              fontSize: 14,
              color: Colors.grey.shade500,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.deleteMealPlanItem(item.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
