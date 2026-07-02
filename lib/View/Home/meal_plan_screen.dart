import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Model/meal_plan_model.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:share_plus/share_plus.dart';

class _S {
  static const bg = AppColors.background;
  static const card = AppColors.surface;
  static const border = AppColors.surfaceBorderLight;
  static const textDark = AppColors.textDark;
  static const textMed = AppColors.textMedium;
  static const textHint = AppColors.textHint;
  static const primary = AppColors.primary;

  static const cardBorder = Color(0xFFEFE6D6);
  static const toggleBg = Color(0xFFF1EBDF);
  static const dash = Color(0xFFD8CFBE);
  static const purple = Color(0xFF8B5CF6);
  // Meal-type colours (matched to the HTML)
  static const breakfastColor = Color(0xFFC0860F);
  static const lunchColor = Color(0xFF1F7A5E);
  static const dinnerColor = Color(0xFF2D6FE0);
  static const snackColor = Color(0xFFE0481F);

  static Color mealColor(String type) {
    switch (type) {
      case 'Breakfast':
        return breakfastColor;
      case 'Lunch':
        return lunchColor;
      case 'Dinner':
        return dinnerColor;
      case 'Snack':
        return snackColor;
      default:
        return primary;
    }
  }

  static IconData mealIcon(String type) {
    switch (type) {
      case 'Breakfast':
        return Icons.wb_sunny_outlined;
      case 'Lunch':
        return Icons.lunch_dining_outlined;
      case 'Dinner':
        return Icons.dinner_dining_outlined;
      case 'Snack':
        return Icons.cookie_outlined;
      default:
        return Icons.restaurant;
    }
  }

  static TextStyle f(double size, FontWeight weight, Color color) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final MealPlanController controller = Get.find<MealPlanController>();
  final HomeController homeController = Get.find<HomeController>();
  int _viewIndex = 0; // 0 = Day, 1 = Month
  Worker? _monthWorker;

  @override
  void initState() {
    super.initState();
    // Fetch the visible month's data reactively (not inside build) — only when
    // the month actually changes and only while the month view is showing.
    _monthWorker = ever<DateTime>(controller.selectedDate, (date) {
      if (_viewIndex == 1) _ensureMonthFetched(date);
    });
  }

  @override
  void dispose() {
    _monthWorker?.dispose();
    super.dispose();
  }

  /// Fetches the month's meals once per distinct month (dedupes queries).
  void _ensureMonthFetched(DateTime date) {
    final monthKey = date.year * 100 + date.month;
    if (_lastFetchedMonth == monthKey) return;
    _lastFetchedMonth = monthKey;
    controller.fetchMonthMealPlans(DateTime(date.year, date.month));
  }

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _S.bg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: _S.bg,
            padding: EdgeInsets.only(
              top: top + 12,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              children: [
                Text(
                  'Meal Plan',
                  style: _S.f(18, FontWeight.w800, _S.textDark),
                ),
                const Spacer(),
                // Day / Month toggle
                _buildViewToggle(),
                const SizedBox(width: 10),
                // 3-dot menu
                _buildHeaderMenu(),
              ],
            ),
          ),

          // ── Body ──
          // No full-screen loader: the day/month views populate reactively via
          // their own scoped Obx, so background refreshes never blank the UI.
          Expanded(
            child: _viewIndex == 1 ? _buildMonthView() : _buildDayView(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ DAY / MONTH TOGGLE ═══════════════════════

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _S.toggleBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_toggleTab('Day', 0), _toggleTab('Month', 1)],
      ),
    );
  }

  Widget _toggleTab(String label, int index) {
    final sel = _viewIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _viewIndex = index);
        if (index == 1) _ensureMonthFetched(controller.selectedDate.value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _S.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: _S.f(
            12.5,
            sel ? FontWeight.w700 : FontWeight.w600,
            sel ? _S.textDark : _S.textHint,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════ 3-DOT MENU ═══════════════════════

  Widget _buildHeaderMenu() {
    final key = GlobalKey();
    return GestureDetector(
      key: key,
      onTap: () {
        final box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final pos = box.localToGlobal(Offset.zero);
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            pos.dx - 140,
            pos.dy + box.size.height + 4,
            pos.dx + 20,
            0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: _S.card,
          items: [
            _menuItem(
              Icons.auto_awesome_rounded,
              'Auto-fill my week',
              false,
              () {
                Navigator.pop(context);
                _showAutoFillSheet();
              },
            ),
            _menuItem(Icons.share_outlined, 'Share meal plan', false, () {
              Navigator.pop(context);
              _shareMealPlan();
            }),
            _menuItem(
              Icons.delete_outline_rounded,
              'Clear this week',
              true,
              () {
                Navigator.pop(context);
                _showClearWeekDialog();
              },
            ),
          ],
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _S.border),
        ),
        child: const Icon(Icons.more_horiz, size: 20, color: _S.textDark),
      ),
    );
  }

  // Share the selected week's plan as text.
  void _shareMealPlan() {
    final days = controller.getDaysOfWeek(controller.selectedWeekStart.value);
    final buf = StringBuffer('My meal plan\n');
    for (final day in days) {
      final meals = controller.getMealsForDate(day);
      if (meals.isEmpty) continue;
      buf.writeln('\n${_dayNames[day.weekday - 1]} ${day.day} '
          '${_shortMonths[day.month - 1]}');
      for (final m in meals) {
        buf.writeln('• ${m.mealType}: ${m.recipeTitle}');
      }
    }
    Share.share(buf.toString(), subject: 'My meal plan');
  }

  PopupMenuItem _menuItem(
    IconData icon,
    String label,
    bool red,
    VoidCallback onTap,
  ) {
    final c = red ? _S.snackColor : _S.textDark;
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 12),
          Text(label, style: _S.f(14, FontWeight.w600, c)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DAY VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDayView() {
    return Obx(() {
      final days = controller.getDaysOfWeek(controller.selectedWeekStart.value);
      final sel = controller.selectedDate.value;

      return Column(
        children: [
          // ── Week strip (single row) ──
          _buildWeekStrip(days, sel),
          const SizedBox(height: 14),

          // ── Nutrition upgrade card (Plus) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildNutritionUpgradeCard(),
          ),
          const SizedBox(height: 14),

          // ── Meal sections ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final type in MealPlanController.mealTypes)
                    _buildMealSection(sel, type),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Nutrition upgrade card (Plus, visual) ──

  Widget _buildNutritionUpgradeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _S.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D2F7)),
        boxShadow: [
          BoxShadow(
            color: _S.purple.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -22,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
              ),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("See today's nutrition",
                    style: _S.f(13.5, FontWeight.w800, _S.textDark)),
                const SizedBox(height: 1),
                Text('Calories & macros across all meals',
                    style: _S.f(11.5, FontWeight.w600, _S.textMed),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
              ),
            ),
            child: Text('Unlock', style: _S.f(11, FontWeight.w800, Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Week strip: < M T W T F S S > with dates below, single row ──

  Widget _buildWeekStrip(List<DateTime> days, DateTime selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _weekArrow(Icons.chevron_left, controller.previousWeek),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = days[i];
                final isSel = controller.isSameDay(day, selected);
                return GestureDetector(
                  onTap: () => controller.selectDate(day),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        _dayLetters[i],
                        style: _S.f(11,
                            isSel ? FontWeight.w800 : FontWeight.w700,
                            isSel ? _S.primary : _S.textHint),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSel ? _S.primary : _S.card,
                          border: isSel
                              ? null
                              : Border.all(color: _S.cardBorder),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: _S.primary.withValues(alpha: 0.7),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: _S.f(13, FontWeight.w800,
                                isSel ? Colors.white : _S.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          _weekArrow(Icons.chevron_right, controller.nextWeek),
        ],
      ),
    );
  }

  Widget _weekArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 26,
        height: 52,
        child: Icon(icon, size: 22, color: _S.textHint),
      ),
    );
  }

  // ── Meal section ──

  Widget _buildMealSection(DateTime date, String mealType) {
    final meals = controller.getMealsForDateAndType(date, mealType);
    final color = _S.mealColor(mealType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Section header: colored dot + label
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              mealType.toUpperCase(),
              style: _S.f(13, FontWeight.w800, color),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Meal cards
        for (final meal in meals) _buildMealCard(meal),

        // + Add button (dashed)
        GestureDetector(
          onTap: () => _showAddMealSheet(date, mealType),
          child: CustomPaint(
            painter: const _DashRectPainter(_S.dash, 13),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 18, color: _S.primary),
                    const SizedBox(width: 7),
                    Text(
                      'Add ${mealType.toLowerCase()}',
                      style: _S.f(13, FontWeight.w700, _S.textMed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Meal card (image + title + time + 3-dot) ──

  Widget _buildMealCard(MealPlanItem meal) {
    return GestureDetector(
      onTap: () => _openRecipe(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _S.cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A211B).withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -18,
            ),
          ],
        ),
        child: Row(
          children: [
            _mealImage(meal, 50),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.recipeTitle,
                    style: _S.f(13.5, FontWeight.w700, _S.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: _S.textHint),
                      const SizedBox(width: 5),
                      Text(_getMealTime(meal),
                          style: _S.f(11.5, FontWeight.w600, _S.textMed)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showMealOptions(meal),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.more_horiz, size: 18, color: Color(0xFFC7BCAC)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Square recipe thumbnail used by day & month meal cards.
  Widget _mealImage(MealPlanItem meal, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: size,
        height: size,
        child: meal.recipeImageUrl != null && meal.recipeImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: meal.recipeImageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, __) => Container(color: const Color(0xFFEDE5D7)),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFEDE5D7),
                  child: Icon(_S.mealIcon(meal.mealType),
                      size: 20, color: _S.mealColor(meal.mealType)),
                ),
              )
            : Container(
                color: _S.mealColor(meal.mealType).withValues(alpha: 0.1),
                child: Icon(_S.mealIcon(meal.mealType),
                    size: 22, color: _S.mealColor(meal.mealType)),
              ),
      ),
    );
  }

  void _openRecipe(MealPlanItem meal) {
    final recipe =
        homeController.recipes.firstWhereOrNull((r) => r.id == meal.recipeId);
    if (recipe != null) {
      Get.to(() => RecipeDetailScreen(recipe: recipe));
    }
  }

  String _getMealTime(MealPlanItem meal) {
    final recipe = homeController.recipes.firstWhereOrNull(
      (r) => r.id == meal.recipeId,
    );
    if (recipe != null &&
        recipe.totalTime != null &&
        recipe.totalTime!.isNotEmpty) {
      return recipe.totalTime!;
    }
    return meal.mealType;
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH VIEW
  // ═══════════════════════════════════════════════════════════════

  int? _lastFetchedMonth;

  // The month view is built ONCE per Day/Month toggle. Only the small reactive
  // sub-sections below (month-nav, grid, selected-date header, selected meals)
  // are wrapped in their own scoped Obx, so selecting a day or editing a meal
  // rebuilds only the affected section — never the whole scroll view.
  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Column(
        children: [
          // ── Calendar card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            decoration: BoxDecoration(
              color: _S.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month nav: < June 2026 >  (reactive on selectedDate)
                Obx(() {
                  final selDate = controller.selectedDate.value;
                  final viewMonth = DateTime(selDate.year, selDate.month);
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.selectDate(
                          DateTime(selDate.year, selDate.month - 1, 1),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _S.border),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: _S.textDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_monthNames[viewMonth.month - 1]} ${viewMonth.year}',
                        style: _S.f(16, FontWeight.w700, _S.textDark),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => controller.selectDate(
                          DateTime(selDate.year, selDate.month + 1, 1),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _S.border),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: _S.textDark,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // Day headers: M T W T F S S  (static)
                Row(
                  children: _dayLetters
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: _S.f(12, FontWeight.w600, _S.textHint),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar grid  (reactive on selectedDate + month meals)
                Obx(() {
                  final selDate = controller.selectedDate.value;
                  final viewMonth = DateTime(selDate.year, selDate.month);
                  final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
                  final daysInMonth =
                      DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
                  final startWeekday = firstDay.weekday;

                  // Precompute meal-types per date ONCE (O(N)) instead of
                  // scanning the whole list for each of the 42 cells (O(42·N)).
                  final typesByDate = <String, Set<String>>{};
                  for (final m in controller.monthMealPlanItems) {
                    (typesByDate[m.date] ??= <String>{}).add(m.mealType);
                  }

                  return _buildCalendarGrid(
                    firstDay,
                    daysInMonth,
                    startWeekday,
                    selDate,
                    typesByDate,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Selected date header + Add meal button ──  (reactive)
          Obx(() {
            final selDate = controller.selectedDate.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_dayNames[selDate.weekday - 1]}, ${selDate.day} ${_shortMonths[selDate.month - 1]}',
                    style: _S.f(16, FontWeight.w700, _S.textDark),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddMealSheet(selDate, 'Breakfast'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _S.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Add meal',
                            style: _S.f(13, FontWeight.w700, Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // ── Meal cards for selected date ──  (reactive on selectedDate + meals)
          Obx(() {
            final selDate = controller.selectedDate.value;
            final selectedMeals = controller.getMonthMealsForDate(selDate);
            if (selectedMeals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48,
                      color: _S.textHint.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No meals for this day',
                      style: _S.f(15, FontWeight.w600, _S.textMed),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a recipe to breakfast, lunch, dinner or a snack.',
                      style: _S.f(12, FontWeight.w500, _S.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final meal in selectedMeals) _buildMonthMealCard(meal),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── Auto-fill my week button ──  (static)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => _showAutoFillSheet(),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEFD),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE0D2F7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 18,
                      color: _S.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-fill my week',
                      style: _S.f(13.5, FontWeight.w700, const Color(0xFF7A4FC0)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    DateTime firstDay,
    int daysInMonth,
    int startWeekday,
    DateTime selected,
    Map<String, Set<String>> typesByDate,
  ) {
    final now = DateTime.now();
    final rows = <Widget>[];
    final totalCells = startWeekday - 1 + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    for (int row = 0; row < totalRows; row++) {
      final rowChildren = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        final dayNum = cellIndex - (startWeekday - 1) + 1;

        if (dayNum < 1 || dayNum > daysInMonth) {
          rowChildren.add(const Expanded(child: SizedBox(height: 48)));
          continue;
        }

        final date = DateTime(firstDay.year, firstDay.month, dayNum);
        final dateStr = controller.formatDatePublic(date);
        rowChildren.add(
          _DayCell(
            dayNum: dayNum,
            isSelected: controller.isSameDay(date, selected),
            isToday: controller.isSameDay(date, now),
            mealTypes: typesByDate[dateStr] ?? const <String>{},
            onTap: () => controller.selectDate(date),
          ),
        );
      }
      rows.add(Row(children: rowChildren));
    }

    return Column(children: rows);
  }

  // Meal card for month view — shows meal type label above title
  Widget _buildMonthMealCard(MealPlanItem meal) {
    final color = _S.mealColor(meal.mealType);

    return GestureDetector(
      onTap: () => _showMealOptions(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _S.border),
        ),
        child: Row(
          children: [
            _mealImage(meal, 48),
            const SizedBox(width: 11),

            // Meal type label + title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealType.toUpperCase(),
                    style: _S.f(10, FontWeight.w800, color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.recipeTitle,
                    style: _S.f(14, FontWeight.w700, _S.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: _S.textHint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _getMealTime(meal),
                        style: _S.f(11, FontWeight.w500, _S.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3-dot
            GestureDetector(
              onTap: () => _showMealOptions(meal),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.more_horiz, size: 18, color: _S.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD MEAL SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showAddMealSheet(DateTime date, String initialType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMealSheet(
        date: date,
        dayName: _dayNames[date.weekday - 1],
        initialMealType: initialType,
        controller: controller,
        homeController: homeController,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MEAL OPTIONS POPUP
  // ═══════════════════════════════════════════════════════════════

  void _showMealOptions(MealPlanItem meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            // Recipe info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _S.mealColor(meal.mealType).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child:
                          meal.recipeImageUrl != null &&
                              meal.recipeImageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: meal.recipeImageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 150,
                            )
                          : Container(
                              color: _S
                                  .mealColor(meal.mealType)
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                _S.mealIcon(meal.mealType),
                                color: _S.mealColor(meal.mealType),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.recipeTitle,
                          style: _S.f(15, FontWeight.w700, _S.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          meal.mealType,
                          style: _S.f(12, FontWeight.w500, _S.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _optionTile(Icons.visibility_outlined, 'View recipe', false, () {
              Navigator.pop(context);
              final recipe = homeController.recipes.firstWhereOrNull(
                (r) => r.id == meal.recipeId,
              );
              if (recipe != null) {
                Get.to(() => RecipeDetailScreen(recipe: recipe));
              }
            }),
            _optionTile(
              Icons.shopping_cart_outlined,
              'Add to groceries',
              false,
              () {
                Navigator.pop(context);
                CustomSnackbar.show(
                  title: 'Added',
                  message: 'Ingredients added to groceries',
                  type: SnackbarType.success,
                );
              },
            ),
            _optionTile(
              Icons.delete_outline_rounded,
              'Remove from plan',
              true,
              () {
                Navigator.pop(context);
                controller.deleteMealPlanItem(meal.id);
                CustomSnackbar.show(
                  title: 'Removed',
                  message: '${meal.recipeTitle} removed from plan',
                  type: SnackbarType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String label,
    bool red,
    VoidCallback onTap,
  ) {
    final c = red ? _S.snackColor : _S.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 14),
            Text(label, style: _S.f(15, FontWeight.w600, c)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR WEEK DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showClearWeekDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 28,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Clear this week?',
              style: _S.f(18, FontWeight.w800, _S.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'This will remove all meals from the current week.',
              style: _S.f(13, FontWeight.w500, _S.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _S.border),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: _S.f(14, FontWeight.w700, _S.textDark),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      controller.clearWeek();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Clear',
                          style: _S.f(14, FontWeight.w700, Colors.white),
                        ),
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  // AUTO-FILL SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showAutoFillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AutoFillSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR DAY CELL
// ═══════════════════════════════════════════════════════════════════════════════

/// A single calendar day cell. Extracted into its own widget so the grid stays
/// cheap to rebuild and each cell is a small, self-contained subtree.
class _DayCell extends StatelessWidget {
  final int dayNum;
  final bool isSelected;
  final bool isToday;
  final Set<String> mealTypes;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayNum,
    required this.isSelected,
    required this.isToday,
    required this.mealTypes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = isSelected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Date number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSel ? _S.primary : Colors.transparent,
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: _S.primary.withValues(alpha: 0.7),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: _S.f(
                      13,
                      isSel || isToday ? FontWeight.w800 : FontWeight.w600,
                      isSel
                          ? Colors.white
                          : isToday
                          ? _S.primary
                          : _S.textDark,
                    ),
                  ),
                ),
              ),
              // Meal color dots row
              if (mealTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final type in MealPlanController.mealTypes)
                        if (mealTypes.contains(type))
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _S.mealColor(type),
                              shape: BoxShape.circle,
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD MEAL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _AddMealSheet extends StatefulWidget {
  final DateTime date;
  final String dayName;
  final String initialMealType;
  final MealPlanController controller;
  final HomeController homeController;

  const _AddMealSheet({
    required this.date,
    required this.dayName,
    required this.initialMealType,
    required this.controller,
    required this.homeController,
  });

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  late String _selectedType;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialMealType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: _S.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to ${widget.dayName}, $_selectedType',
                        style: _S.f(18, FontWeight.w800, _S.textDark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: _S.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: Row(
                    children: MealPlanController.mealTypes.map((type) {
                      final sel = type == _selectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _S.mealColor(type)
                                  : _S.mealColor(type).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              type,
                              style: _S.f(
                                12,
                                FontWeight.w700,
                                sel ? Colors.white : _S.mealColor(type),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                AppSearchBar(
                  hintText: 'Search your recipes',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final recipes = widget.homeController.recipes
                  .where(
                    (r) =>
                        _search.isEmpty ||
                        r.title.toLowerCase().contains(_search.toLowerCase()),
                  )
                  .toList();

              if (recipes.isEmpty) {
                return Center(
                  child: Text(
                    'No recipes found',
                    style: _S.f(14, FontWeight.w500, _S.textHint),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: recipes.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _S.border),
                itemBuilder: (_, i) {
                  final recipe = recipes[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child:
                                recipe.imageUrl != null &&
                                    recipe.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: recipe.imageUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 150,
                                  )
                                : Container(
                                    color: AppColors.shimmerBase,
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 20,
                                      color: AppColors.shimmerHighlight,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: _S.f(14, FontWeight.w700, _S.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (recipe.totalTime != null &&
                                  recipe.totalTime!.isNotEmpty)
                                Text(
                                  recipe.totalTime!,
                                  style: _S.f(12, FontWeight.w500, _S.textHint),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.controller.addMealPlanItem(
                              date: widget.date,
                              mealType: _selectedType,
                              recipeId: recipe.id,
                              recipeTitle: recipe.title,
                              recipeImageUrl: recipe.imageUrl,
                            );
                            Navigator.pop(context);
                            CustomSnackbar.show(
                              title: 'Added',
                              message:
                                  '${recipe.title} added to $_selectedType',
                              type: SnackbarType.success,
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _S.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: _S.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTO-FILL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _AutoFillSheet extends StatefulWidget {
  const _AutoFillSheet();

  @override
  State<_AutoFillSheet> createState() => _AutoFillSheetState();
}

class _AutoFillSheetState extends State<_AutoFillSheet> {
  final Set<String> _selectedDiet = {'Vegetarian'};
  bool _usePantry = false;
  final Set<String> _selectedMeals = {'Breakfast', 'Lunch', 'Dinner'};
  int _servings = 4;

  static const _dietOptions = [
    'Vegetarian',
    'High-protein',
    'Quick (sub 30m)',
    'Budget',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: _S.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Auto-fill my week',
                      style: _S.f(18, FontWeight.w800, _S.textDark),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: _S.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DIET & STYLE',
                    style: _S.f(11, FontWeight.w700, _S.textHint),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietOptions.map((opt) {
                      final sel = _selectedDiet.contains(opt);
                      return GestureDetector(
                        onTap: () => setState(
                          () => sel
                              ? _selectedDiet.remove(opt)
                              : _selectedDiet.add(opt),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green
                                : AppColors.greenBgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            opt,
                            style: _S.f(
                              12,
                              FontWeight.w700,
                              sel ? Colors.white : AppColors.green,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => setState(() => _usePantry = !_usePantry),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _usePantry
                                ? AppColors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _usePantry ? AppColors.green : _S.border,
                              width: 1.5,
                            ),
                          ),
                          child: _usePantry
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Use my pantry',
                          style: _S.f(14, FontWeight.w600, _S.textDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'WHICH MEALS',
                    style: _S.f(11, FontWeight.w700, _S.textHint),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MealPlanController.mealTypes.map((type) {
                        final sel = _selectedMeals.contains(type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(
                              () => sel
                                  ? _selectedMeals.remove(type)
                                  : _selectedMeals.add(type),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? _S.mealColor(type)
                                    : _S
                                          .mealColor(type)
                                          .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                type,
                                style: _S.f(
                                  12,
                                  FontWeight.w700,
                                  sel ? Colors.white : _S.mealColor(type),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Servings',
                        style: _S.f(14, FontWeight.w700, _S.textDark),
                      ),
                      const Spacer(),
                      _servingBtn(Icons.remove, () {
                        if (_servings > 1) setState(() => _servings--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_servings',
                          style: _S.f(16, FontWeight.w800, _S.textDark),
                        ),
                      ),
                      _servingBtn(Icons.add, () => setState(() => _servings++)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scales every recipe',
                    style: _S.f(12, FontWeight.w500, _S.textHint),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                  title: 'Coming Soon',
                  message: 'AI meal plan generation coming soon!',
                  type: SnackbarType.info,
                );
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Generate my week',
                    style: _S.f(15, FontWeight.w700, Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servingBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _S.border),
        ),
        child: Icon(icon, size: 18, color: _S.textDark),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dashed rounded-rectangle border painter (for "Add meal" buttons)
// ═══════════════════════════════════════════════════════════════════════════════
class _DashRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashRectPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashRectPainter old) =>
      old.color != color || old.radius != radius;
}
