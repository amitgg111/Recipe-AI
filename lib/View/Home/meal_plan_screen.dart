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

class _S {
  static const bg = AppColors.background;
  static const card = AppColors.surface;
  static const border = AppColors.surfaceBorderLight;
  static const textDark = AppColors.textDark;
  static const textMed = AppColors.textMedium;
  static const textHint = AppColors.textHint;
  static const primary = AppColors.primary;

  static const breakfastColor = Color(0xFFF59E0B);
  static const lunchColor = Color(0xFF10B981);
  static const dinnerColor = Color(0xFF6366F1);
  static const snackColor = Color(0xFFEF4444);

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
        fontSize: size, fontWeight: weight, color: color);
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

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
            padding: EdgeInsets.only(top: top + 12, left: 20, right: 20, bottom: 12),
            child: Row(
              children: [
                Text('Meal Plan',
                    style: _S.f(24, FontWeight.w800, _S.textDark)),
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _S.primary));
              }
              if (_viewIndex == 1) return _buildMonthView();
              return _buildDayView();
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ DAY / MONTH TOGGLE ═══════════════════════

  Widget _buildViewToggle() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.tabBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleTab('Day', 0),
          _toggleTab('Month', 1),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, int index) {
    final sel = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: sel ? _S.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: sel
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: _S.f(13, sel ? FontWeight.w700 : FontWeight.w500,
                  sel ? _S.textDark : _S.textHint)),
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
              pos.dx - 140, pos.dy + box.size.height + 4, pos.dx + 20, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: _S.card,
          items: [
            _menuItem(Icons.auto_awesome_rounded, 'Auto-fill my week', false, () {
              Navigator.pop(context);
              _showAutoFillSheet();
            }),
            _menuItem(Icons.share_outlined, 'Share meal plan', false, () {
              Navigator.pop(context);
            }),
            _menuItem(Icons.delete_outline_rounded, 'Clear this week', true, () {
              Navigator.pop(context);
              _showClearWeekDialog();
            }),
          ],
        );
      },
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _S.border),
        ),
        child: const Icon(Icons.more_horiz, size: 18, color: _S.textDark),
      ),
    );
  }

  PopupMenuItem _menuItem(IconData icon, String label, bool red, VoidCallback onTap) {
    final c = red ? _S.snackColor : _S.textDark;
    return PopupMenuItem(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 12),
        Text(label, style: _S.f(14, FontWeight.w600, c)),
      ]),
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
          const SizedBox(height: 12),

          // ── Add to groceries button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => CustomSnackbar.show(
                  title: 'Groceries',
                  message: 'Week added to grocery list',
                  type: SnackbarType.success),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _S.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 18, color: _S.primary),
                    const SizedBox(width: 8),
                    Text('Add this week to groceries',
                        style: _S.f(14, FontWeight.w700, _S.primary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

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

  // ── Week strip: < M T W T F S S > with dates below, single row ──

  Widget _buildWeekStrip(List<DateTime> days, DateTime selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Left arrow
          GestureDetector(
            onTap: controller.previousWeek,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.chevron_left, size: 22, color: _S.textHint),
            ),
          ),

          // 7 day columns
          ...List.generate(7, (i) {
            final day = days[i];
            final isSel = controller.isSameDay(day, selected);
            final isToday = controller.isToday(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectDate(day),
                child: Column(
                  children: [
                    // Day letter
                    Text(
                      _dayLetters[i],
                      style: _S.f(12, FontWeight.w600, _S.textHint),
                    ),
                    const SizedBox(height: 6),
                    // Date number (circled if selected/today)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel
                            ? _S.primary
                            : isToday
                                ? _S.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                        border: isToday && !isSel
                            ? Border.all(color: _S.primary, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: _S.f(
                            14,
                            FontWeight.w700,
                            isSel
                                ? Colors.white
                                : isToday
                                    ? _S.primary
                                    : _S.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Right arrow
          GestureDetector(
            onTap: controller.nextWeek,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.chevron_right, size: 22, color: _S.textHint),
            ),
          ),
        ],
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
        const SizedBox(height: 14),
        // Section header: colored dot + label
        Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(mealType.toUpperCase(),
              style: _S.f(12, FontWeight.w800, color)),
        ]),
        const SizedBox(height: 10),

        // Meal cards
        for (final meal in meals) _buildMealCard(meal),

        // + Add button (full width, prominent)
        GestureDetector(
          onTap: () => _showAddMealSheet(date, mealType),
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: _S.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _S.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: _S.primary),
                const SizedBox(width: 6),
                Text('Add ${mealType.toLowerCase()}',
                    style: _S.f(14, FontWeight.w600, _S.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Meal card (image + title + time + 3-dot) ──

  Widget _buildMealCard(MealPlanItem meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: _S.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _S.border),
      ),
      child: Row(
        children: [
          // Round recipe image
          ClipOval(
            child: SizedBox(
              width: 46, height: 46,
              child: meal.recipeImageUrl != null && meal.recipeImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.recipeImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.restaurant, size: 20,
                            color: AppColors.shimmerHighlight),
                      ),
                    )
                  : Container(
                      color: _S.mealColor(meal.mealType).withValues(alpha: 0.1),
                      child: Icon(_S.mealIcon(meal.mealType),
                          size: 22, color: _S.mealColor(meal.mealType)),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.recipeTitle,
                    style: _S.f(14, FontWeight.w700, _S.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 13,
                      color: _S.textHint),
                  const SizedBox(width: 4),
                  Text(_getMealTime(meal),
                      style: _S.f(12, FontWeight.w500, _S.textHint)),
                ]),
              ],
            ),
          ),

          // 3-dot menu
          GestureDetector(
            onTap: () => _showMealOptions(meal),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.more_horiz, size: 18, color: _S.textHint),
            ),
          ),
        ],
      ),
    );
  }

  String _getMealTime(MealPlanItem meal) {
    final recipe = homeController.recipes
        .firstWhereOrNull((r) => r.id == meal.recipeId);
    if (recipe != null && recipe.totalTime != null && recipe.totalTime!.isNotEmpty) {
      return recipe.totalTime!;
    }
    return meal.mealType;
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH VIEW
  // ═══════════════════════════════════════════════════════════════

  int? _lastFetchedMonth;

  Widget _buildMonthView() {
    return Obx(() {
      final selDate = controller.selectedDate.value;
      final viewMonth = DateTime(selDate.year, selDate.month);
      final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
      final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
      final startWeekday = firstDay.weekday;

      final monthKey = viewMonth.year * 100 + viewMonth.month;
      if (_lastFetchedMonth != monthKey) {
        _lastFetchedMonth = monthKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.fetchMonthMealPlans(viewMonth);
        });
      }

      final selectedMeals = controller.getMonthMealsForDate(selDate);

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
                  // Month nav: < June 2026 >
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final prev = DateTime(selDate.year, selDate.month - 1, 1);
                          controller.selectDate(prev);
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _S.border),
                          ),
                          child: const Icon(Icons.chevron_left, size: 20, color: _S.textDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_monthNames[viewMonth.month - 1]} ${viewMonth.year}',
                        style: _S.f(16, FontWeight.w700, _S.textDark),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final next = DateTime(selDate.year, selDate.month + 1, 1);
                          controller.selectDate(next);
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _S.border),
                          ),
                          child: const Icon(Icons.chevron_right, size: 20, color: _S.textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Day headers: M T W T F S S
                  Row(
                    children: _dayLetters
                        .map((d) => Expanded(
                            child: Center(
                                child: Text(d,
                                    style: _S.f(12, FontWeight.w600, _S.textHint)))))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar grid with meal color dots
                  _buildCalendarGrid(firstDay, daysInMonth, startWeekday, selDate),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Selected date header + Add meal button ──
            Padding(
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _S.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Add meal', style: _S.f(13, FontWeight.w700, Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Meal cards for selected date ──
            if (selectedMeals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu_rounded,
                        size: 48, color: _S.textHint.withValues(alpha: 0.3)),
                    const SizedBox(height: 10),
                    Text('No meals for this day',
                        style: _S.f(15, FontWeight.w600, _S.textMed)),
                    const SizedBox(height: 4),
                    Text('Add a recipe to breakfast, lunch, dinner or a snack.',
                        style: _S.f(12, FontWeight.w500, _S.textHint),
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final meal in selectedMeals)
                      _buildMonthMealCard(meal),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ── Auto-fill my week button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _showAutoFillSheet(),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.purpleBgLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 18,
                          color: AppColors.purple),
                      const SizedBox(width: 8),
                      Text('Auto-fill my week',
                          style: _S.f(14, FontWeight.w700, AppColors.purple)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCalendarGrid(DateTime firstDay, int daysInMonth,
      int startWeekday, DateTime selected) {
    final now = DateTime.now();
    final rows = <Widget>[];
    int dayCounter = 1;
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
        final isSel = controller.isSameDay(date, selected);
        final isToday = controller.isSameDay(date, now);
        final mealTypesForDate = controller.getMealTypesForDate(date);

        rowChildren.add(Expanded(
          child: GestureDetector(
            onTap: () => controller.selectDate(date),
            child: SizedBox(
              height: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Date number
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel
                          ? _S.primary
                          : isToday
                              ? _S.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: _S.f(
                          13,
                          isToday || isSel ? FontWeight.w700 : FontWeight.w500,
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
                  if (mealTypesForDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final type in MealPlanController.mealTypes)
                            if (mealTypesForDate.contains(type))
                              Container(
                                width: 5, height: 5,
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
        ));
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
            // Round recipe image
            ClipOval(
              child: SizedBox(
                width: 46, height: 46,
                child: meal.recipeImageUrl != null && meal.recipeImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.recipeImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.shimmerBase,
                          child: const Icon(Icons.restaurant, size: 20,
                              color: AppColors.shimmerHighlight),
                        ),
                      )
                    : Container(
                        color: color.withValues(alpha: 0.1),
                        child: Icon(_S.mealIcon(meal.mealType),
                            size: 22, color: color),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Meal type label + title + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.mealType.toUpperCase(),
                      style: _S.f(10, FontWeight.w800, color)),
                  const SizedBox(height: 2),
                  Text(meal.recipeTitle,
                      style: _S.f(14, FontWeight.w700, _S.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 12, color: _S.textHint),
                    const SizedBox(width: 3),
                    Text(_getMealTime(meal),
                        style: _S.f(11, FontWeight.w500, _S.textHint)),
                  ]),
                ],
              ),
            ),

            // 3-dot
            GestureDetector(
              onTap: () => _showMealOptions(meal),
              child: Padding(
                padding: const EdgeInsets.all(8),
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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            // Recipe info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _S.mealColor(meal.mealType).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50, height: 50,
                    child: meal.recipeImageUrl != null &&
                            meal.recipeImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: meal.recipeImageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: _S.mealColor(meal.mealType)
                                .withValues(alpha: 0.15),
                            child: Icon(_S.mealIcon(meal.mealType),
                                color: _S.mealColor(meal.mealType))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.recipeTitle,
                          style: _S.f(15, FontWeight.w700, _S.textDark),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(meal.mealType,
                          style: _S.f(12, FontWeight.w500, _S.textHint)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _optionTile(Icons.visibility_outlined, 'View recipe', false, () {
              Navigator.pop(context);
              final recipe = homeController.recipes
                  .firstWhereOrNull((r) => r.id == meal.recipeId);
              if (recipe != null) {
                Get.to(() => RecipeDetailScreen(recipe: recipe));
              }
            }),
            _optionTile(
                Icons.shopping_cart_outlined, 'Add to groceries', false, () {
              Navigator.pop(context);
              CustomSnackbar.show(
                  title: 'Added',
                  message: 'Ingredients added to groceries',
                  type: SnackbarType.success);
            }),
            _optionTile(
                Icons.delete_outline_rounded, 'Remove from plan', true, () {
              Navigator.pop(context);
              controller.deleteMealPlanItem(meal.id);
              CustomSnackbar.show(
                  title: 'Removed',
                  message: '${meal.recipeTitle} removed from plan',
                  type: SnackbarType.info);
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
      IconData icon, String label, bool red, VoidCallback onTap) {
    final c = red ? _S.snackColor : _S.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: c),
          const SizedBox(width: 14),
          Text(label, style: _S.f(15, FontWeight.w600, c)),
        ]),
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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 28, color: AppColors.red),
            ),
            const SizedBox(height: 16),
            Text('Clear this week?',
                style: _S.f(18, FontWeight.w800, _S.textDark)),
            const SizedBox(height: 6),
            Text('This will remove all meals from the current week.',
                style: _S.f(13, FontWeight.w500, _S.textHint),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _S.border)),
                    child: Center(
                        child: Text('Cancel',
                            style: _S.f(14, FontWeight.w700, _S.textDark))),
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
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text('Clear',
                            style: _S.f(14, FontWeight.w700, Colors.white))),
                  ),
                ),
              ),
            ]),
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
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Text(
                        'Add to ${widget.dayName}, $_selectedType',
                        style: _S.f(18, FontWeight.w800, _S.textDark))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                        color: _S.primary, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ]),
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
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel
                                ? _S.mealColor(type)
                                : _S.mealColor(type).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(type,
                              style: _S.f(12, FontWeight.w700,
                                  sel ? Colors.white : _S.mealColor(type))),
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
            ]),
          ),
          Expanded(
            child: Obx(() {
              final recipes = widget.homeController.recipes
                  .where((r) =>
                      _search.isEmpty ||
                      r.title
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                  .toList();

              if (recipes.isEmpty) {
                return Center(
                    child: Text('No recipes found',
                        style: _S.f(14, FontWeight.w500, _S.textHint)));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: recipes.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: _S.border),
                itemBuilder: (_, i) {
                  final recipe = recipes[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44, height: 44,
                          child: recipe.imageUrl != null &&
                                  recipe.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: recipe.imageUrl!,
                                  fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.shimmerBase,
                                  child: const Icon(Icons.restaurant,
                                      size: 20,
                                      color: AppColors.shimmerHighlight)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recipe.title,
                                style:
                                    _S.f(14, FontWeight.w700, _S.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (recipe.totalTime != null &&
                                recipe.totalTime!.isNotEmpty)
                              Text(recipe.totalTime!,
                                  style: _S.f(
                                      12, FontWeight.w500, _S.textHint)),
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
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _S.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add,
                              size: 18, color: _S.primary),
                        ),
                      ),
                    ]),
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
    'Vegetarian', 'High-protein', 'Quick (sub 30m)', 'Budget'
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
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20)))),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Auto-fill my week',
                      style: _S.f(18, FontWeight.w800, _S.textDark)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                          color: _S.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ]),
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
                  Text('DIET & STYLE',
                      style: _S.f(11, FontWeight.w700, _S.textHint)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _dietOptions.map((opt) {
                      final sel = _selectedDiet.contains(opt);
                      return GestureDetector(
                        onTap: () => setState(() => sel
                            ? _selectedDiet.remove(opt)
                            : _selectedDiet.add(opt)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green
                                : AppColors.greenBgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(opt,
                              style: _S.f(12, FontWeight.w700,
                                  sel ? Colors.white : AppColors.green)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => setState(() => _usePantry = !_usePantry),
                    child: Row(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _usePantry
                              ? AppColors.green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _usePantry
                                  ? AppColors.green
                                  : _S.border,
                              width: 1.5),
                        ),
                        child: _usePantry
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text('Use my pantry',
                          style: _S.f(14, FontWeight.w600, _S.textDark)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('WHICH MEALS',
                      style: _S.f(11, FontWeight.w700, _S.textHint)),
                  const SizedBox(height: 10),
                  Row(
                    children: MealPlanController.mealTypes.map((type) {
                      final sel = _selectedMeals.contains(type);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => sel
                              ? _selectedMeals.remove(type)
                              : _selectedMeals.add(type)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _S.mealColor(type)
                                  : _S.mealColor(type)
                                      .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(type,
                                style: _S.f(
                                    12,
                                    FontWeight.w700,
                                    sel
                                        ? Colors.white
                                        : _S.mealColor(type))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Text('Servings',
                        style: _S.f(14, FontWeight.w700, _S.textDark)),
                    const Spacer(),
                    _servingBtn(Icons.remove, () {
                      if (_servings > 1) setState(() => _servings--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_servings',
                          style: _S.f(16, FontWeight.w800, _S.textDark)),
                    ),
                    _servingBtn(Icons.add, () => setState(() => _servings++)),
                  ]),
                  const SizedBox(height: 4),
                  Text('Scales every recipe',
                      style: _S.f(12, FontWeight.w500, _S.textHint)),
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
                    type: SnackbarType.info);
              },
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text('Generate my week',
                        style: _S.f(15, FontWeight.w700, Colors.white))),
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
        width: 34, height: 34,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _S.border)),
        child: Icon(icon, size: 18, color: _S.textDark),
      ),
    );
  }
}
