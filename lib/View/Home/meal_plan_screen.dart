import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Model/meal_plan_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/recipe_localizer.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/widgets/premium_lock_overlay.dart';
import 'package:recipe_ai/Controllers/nutrition_controller.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/nutrition_animations.dart';
import 'package:recipe_ai/screens/meal_plan/auto_fill_goal_sheet.dart';

class _S {
  static const bg = AppColors.background;
  static const card = AppColors.surface;
  static const border = AppColors.surfaceBorderLight;
  static const textDark = AppColors.textDark;
  static const textMed = AppColors.textMedium;
  static const textHint = AppColors.textHint;
  static const primary = AppColors.primary;

  static const cardBorder = Color(0xFFEFE6D6);
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

  static TextStyle f(
    double size,
    FontWeight weight,
    Color color, {
    double? h,
    double? ls,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: h,
      letterSpacing: ls,
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
  final Map<String, LocalizedRecipe> _localizedRecipes = {};
  final Set<String> _localizingRecipeIds = {};
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

  Future<void> _loadLocalizedRecipe(MealPlanItem meal) async {
    final recipeId = meal.recipeId;

    if (recipeId.isEmpty ||
        _localizedRecipes.containsKey(recipeId) ||
        _localizingRecipeIds.contains(recipeId)) {
      return;
    }

    final recipe = _liveRecipe(meal);
    if (recipe == null) return;

    _localizingRecipeIds.add(recipeId);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();

      final data = doc.data();
      if (data == null) return;

      final localized = await RecipeLocalizer.resolve(
        data,
        currentUid: AuthService.currentUser?.uid,
      );

      if (!mounted) return;

      setState(() {
        _localizedRecipes[recipeId] = localized;
      });
    } catch (e) {
      debugPrint('Meal plan localization failed: $e');
    } finally {
      _localizingRecipeIds.remove(recipeId);
    }
  }

  String _displayTitle(MealPlanItem meal) {
    return _localizedRecipes[meal.recipeId]?.title ?? _liveTitle(meal);
  }

  String _displayTotalTime(MealPlanItem meal) {
    return _localizedRecipes[meal.recipeId]?.totalTime ?? _getMealTime(meal);
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
                Flexible(
                  child: Text(
                    'meal_plan'.tr,
                    style: _S.f(22, FontWeight.w800, _S.textDark, ls: -0.44),
                    maxLines: 1,
                  ),
                ),
                const Spacer(),
                // Day / Month toggle
                _buildViewToggle(),
                const SizedBox(width: 5),
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
    return SlidingSegmented.standard(
      labels: ['day'.tr, 'month'.tr],
      selectedIndex: _viewIndex,
      onChanged: (index) {
        setState(() => _viewIndex = index);
        if (index == 1) _ensureMonthFetched(controller.selectedDate.value);
      },
    );
  }

  // ═══════════════════════ 3-DOT MENU ═══════════════════════

  bool _headerMenuOpen = false;

  Widget _buildHeaderMenu() {
    final key = GlobalKey();
    final open = _headerMenuOpen;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        _openHeaderMenu(box.localToGlobal(Offset.zero) & box.size);
      },
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: open ? const Color(0xFFFCE3DB) : _S.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: open ? const Color(0xFFF2623E) : _S.border),
        ),
        child: OnboardingLineIcon(
          'dots',
          size: 20,
          color: open ? const Color(0xFFF2623E) : _S.textDark,
        ),
      ),
    );
  }

  // Anchored popover under the 3-dot button (HTML 49c): caret + 236px card.
  void _openHeaderMenu(Rect anchor) {
    final screenW = MediaQuery.of(context).size.width;
    final cardRight = screenW - anchor.right;

    setState(() => _headerMenuOpen = true);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: const Color(0x521E1B18), // rgba(30,27,24,.32)
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Stack(
          children: [
            Positioned(
              top: anchor.bottom + 12,
              right: cardRight,
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 236,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEFE6D6)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E1B18,
                            ).withValues(alpha: 0.45),
                            blurRadius: 50,
                            offset: const Offset(0, 24),
                            spreadRadius: -16,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerMenuRow(
                            const OnboardingLineIcon(
                              'crown',
                              size: 24,
                              color: Color(0xFF6D3BD4),
                            ),
                            'auto_fill_my_week'.tr,
                            const Color(0xFF2A211B),
                            FontWeight.w600,
                            () {
                              Navigator.pop(ctx);
                              _showAutoFillSheet();
                            },
                          ),
                          _headerMenuDivider(),
                          _headerMenuRow(
                            const OnboardingLineIcon(
                              'share',
                              color: Color(0xFF5A5147),
                              size: 20,
                            ),
                            'share_meal_plan'.tr,
                            const Color(0xFF2A211B),
                            FontWeight.w600,
                            () {
                              Navigator.pop(ctx);
                              _shareMealPlan();
                            },
                          ),
                          _headerMenuDivider(),
                          _headerMenuRow(
                            const OnboardingLineIcon(
                              'trash',
                              color: Color(0xFFE0481F),
                              size: 20,
                            ),
                            'clear_this_week'.tr,
                            const Color(0xFFE0481F),
                            FontWeight.w700,
                            () {
                              Navigator.pop(ctx);
                              _showClearWeekDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _headerMenuOpen = false);
    });
  }

  Widget _headerMenuRow(
    Widget icon,
    String label,
    Color color,
    FontWeight weight,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 13),
            Text(label, style: _S.f(15, weight, color)),
          ],
        ),
      ),
    );
  }

  Widget _headerMenuDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: const Color(0xFFF4ECDF),
  );

  // Share the selected week's plan as text.
  static const _mealEmoji = {
    'Breakfast': '🍳',
    'Lunch': '🥗',
    'Dinner': '🍽',
    'Snack': '🍎',
  };

  String _weekRangeLabel(List<DateTime> days) {
    final f = days.first, l = days.last;
    if (f.month == l.month) {
      return '${f.day}–${l.day} ${_shortMonths[f.month - 1]}';
    }
    return '${f.day} ${_shortMonths[f.month - 1]} – '
        '${l.day} ${_shortMonths[l.month - 1]}';
  }

  String _buildShareText() {
    final days = controller.getDaysOfWeek(controller.selectedWeekStart.value);
    final buf = StringBuffer()
      ..writeln('📅 ${'my_meal_plan'.tr}')
      ..writeln('${_weekRangeLabel(days)} · from Recipe AI');
    for (final day in days) {
      final meals = controller.getMealsForDate(day);
      if (meals.isEmpty) continue;
      buf.writeln();
      buf.writeln('${_dayNames[day.weekday - 1].toUpperCase()} ${day.day}');
      for (final type in MealPlanController.mealTypes) {
        for (final m in meals.where((x) => x.mealType == type)) {
          buf.writeln('${_mealEmoji[type] ?? '•'} ${_liveTitle(m)}');
        }
      }
    }
    buf.writeln();
    buf.write('Shared from Recipe AI · recipe.ai');
    return buf.toString();
  }

  // Share Meal Plan sheet (HTML 49d): formatted preview + destination tiles.
  void _shareMealPlan() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'share_meal_plan'.tr,
                  style: _S.f(19, FontWeight.w800, _S.textDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const OnboardingLineIcon(
                      'x',
                      color: Color(0xFF8A7E70),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7F0),
                  border: Border.all(color: const Color(0xFFEFE6D6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                child: SingleChildScrollView(child: _buildSharePreview()),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _shareDest(
                  'chat',
                  'WhatsApp',
                  bg: const Color(0xFF25D366),
                  fg: Colors.white,
                  onTap: () => _shareVia('whatsapp'),
                ),
                _shareDest(
                  'copy',
                  'copy_text'.tr,
                  onTap: () => _shareVia('copy'),
                ),
                _shareDest('mail', 'email'.tr, onTap: () => _shareVia('email')),
                _shareDest('share', 'more'.tr, onTap: () => _shareVia('more')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePreview() {
    final days = controller.getDaysOfWeek(controller.selectedWeekStart.value);
    final children = <Widget>[
      Text(
        '📅 ${'my_meal_plan'.tr}',
        style: _S.f(14, FontWeight.w800, _S.textDark),
      ),
      const SizedBox(height: 2),
      Text(
        '${_weekRangeLabel(days)} · from Recipe AI',
        style: _S.f(12, FontWeight.w600, _S.textMed),
      ),
      const SizedBox(height: 12),
    ];
    var any = false;
    for (final day in days) {
      final meals = controller.getMealsForDate(day);
      if (meals.isEmpty) continue;
      if (any) children.add(const SizedBox(height: 12));
      any = true;
      children.add(
        Text(
          '${_dayNames[day.weekday - 1].toUpperCase()} ${day.day}',
          style: _S.f(12.5, FontWeight.w800, const Color(0xFFC0860F)),
        ),
      );
      children.add(const SizedBox(height: 5));
      for (final type in MealPlanController.mealTypes) {
        for (final m in meals.where((x) => x.mealType == type)) {
          children.add(
            Text(
              '${_mealEmoji[type] ?? '•'} ${_liveTitle(m)}',
              style: _S.f(13, FontWeight.w500, const Color(0xFF3A352D), h: 1.7),
            ),
          );
        }
      }
    }
    if (!any) {
      children.add(
        Text(
          'no_meals_this_week'.tr,
          style: _S.f(13, FontWeight.w500, _S.textMed),
        ),
      );
    }
    children.add(const SizedBox(height: 14));
    children.add(
      Text(
        'Shared from Recipe AI · recipe.ai',
        style: _S.f(12, FontWeight.w600, _S.textHint),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _shareDest(
    String icon,
    String label, {
    Color? bg,
    Color? fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: bg == null
                    ? Border.all(color: const Color(0xFFEFE6D6))
                    : null,
              ),
              child: OnboardingLineIcon(
                icon,
                color: fg ?? const Color(0xFF5A5147),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: _S.f(11, FontWeight.w600, const Color(0xFF5A5147)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareVia(String mode) async {
    final text = _buildShareText();
    Get.back();
    switch (mode) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: text));
        CustomSnackbar.show(
          title: 'copied'.tr,
          message: 'meal_plan_copied'.tr,
          type: SnackbarType.success,
        );
        return;
      case 'whatsapp':
        final uri = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(text)}',
        );
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          await Share.share(text);
        }
        return;
      case 'email':
        final uri = Uri.parse(
          'mailto:?subject=${Uri.encodeComponent('my_meal_plan'.tr)}'
          '&body=${Uri.encodeComponent(text)}',
        );
        if (!await launchUrl(uri)) {
          await Share.share(text, subject: 'my_meal_plan'.tr);
        }
        return;
      default:
        await Share.share(text, subject: 'my_meal_plan'.tr);
    }
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

  // ── Nutrition (Plus): real "Today's Nutrition" summary or locked teaser ──

  Widget _buildNutritionUpgradeCard() {
    return Obx(() {
      final isPlus = SubscriptionService.instance.isPlusListenable.value;
      // Touch reactive sources so the card recomputes on plan changes.
      final _ = controller.mealPlanItems.length;
      final date = controller.selectedDate.value;

      if (!isPlus) return _buildNutritionLockedCard();

      final day = NutritionController.to.calculateMealNutrition(date);
      if (day.isEmpty) return const SizedBox.shrink();
      return _buildTodaysNutritionCard(day);
    });
  }

  static String _groupInt(num v) {
    final str = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) b.write(',');
      b.write(str[i]);
    }
    return b.toString();
  }

  Widget _buildTodaysNutritionCard(DayNutrition day) {
    final frac = day.macroFractions;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OnboardingLineIcon('crown', size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'TODAY\'S NUTRITION',
                style: _S
                    .f(11, FontWeight.w800, Colors.white)
                    .copyWith(letterSpacing: 0.4),
              ),
              const Spacer(),
              // Calories count smoothly as meals are added.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedCounter(
                    value: day.calories,
                    format: (v) => _groupInt(v),
                    style: _S.f(13, FontWeight.w800, Colors.white),
                  ),
                  Text(
                    ' kcal',
                    style: _S.f(
                      10,
                      FontWeight.w700,
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Macro-split bar grows in from the left on first paint.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: t, child: child),
              ),
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    Expanded(
                      flex: (frac[0] * 1000).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFFF8C6D8)),
                    ),
                    Expanded(
                      flex: (frac[1] * 1000).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFFF8CE9A)),
                    ),
                    Expanded(
                      flex: (frac[2] * 1000).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFFB6E5CE)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              AnimatedCounter(
                value: day.protein,
                format: (v) => 'P ${v.round()}g',
                style: _S.f(11, FontWeight.w700, Colors.white),
              ),
              const SizedBox(width: 14),
              AnimatedCounter(
                value: day.carbs,
                format: (v) => 'C ${v.round()}g',
                style: _S.f(11, FontWeight.w700, Colors.white),
              ),
              const SizedBox(width: 14),
              AnimatedCounter(
                value: day.fat,
                format: (v) => 'F ${v.round()}g',
                style: _S.f(11, FontWeight.w700, Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionLockedCard() {
    return GestureDetector(
      onTap: () =>
          showUpgradeDialog(context, feature: 'nutrition_calculator'.tr),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D2F7)),
          boxShadow: [
            BoxShadow(
              color: _S.purple.withValues(alpha: 0.4),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
                ),
              ),
              child: const OnboardingLineIcon(
                'crown',
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'see_todays_nutrition'.tr,
                    style: _S.f(13.5, FontWeight.w800, _S.textDark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'calories_macros'.tr,
                    style: _S.f(11.5, FontWeight.w600, _S.textMed),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              child: Text(
                'unlock'.tr,
                style: _S.f(11, FontWeight.w800, Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Week strip: < M T W T F S S > with dates below, single row ──

  Widget _buildWeekStrip(List<DateTime> days, DateTime selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = days[i];
                final isSel = controller.isSameDay(day, selected);

                return GestureDetector(
                  onTap: () => controller.selectDate(day),
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: 1,
                    child: Column(
                      children: [
                        Text(
                          _dayLetters[i],
                          style: _S.f(
                            11,
                            isSel ? FontWeight.w800 : FontWeight.w700,
                            isSel ? _S.primary : _S.textHint,
                          ),
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
                              style: _S.f(
                                13,
                                FontWeight.w800,
                                isSel ? Colors.white : _S.textDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _weekArrow(Widget icon, VoidCallback? onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     behavior: HitTestBehavior.opaque,
  //     child: SizedBox(width: 26, height: 52, child: Center(child: icon)),
  //   );
  // }

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
                    const OnboardingLineIcon(
                      'plus',
                      size: 18,
                      color: _S.primary,
                    ),
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
    final selected = meal.id == _optionsMealId;
    _loadLocalizedRecipe(meal);
    return GestureDetector(
      onTap: () => _openRecipe(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFF2623E) : _S.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFFF2623E).withValues(alpha: 0.4)
                  : const Color(0xFF2A211B).withValues(alpha: 0.4),
              blurRadius: selected ? 26 : 20,
              offset: Offset(0, selected ? 12 : 8),
              spreadRadius: selected ? -16 : -18,
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
                    // _liveTitle(meal),
                    _displayTitle(meal),
                    style: _S.f(13.5, FontWeight.w700, _S.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const OnboardingLineIcon(
                        'clock',
                        size: 13,
                        color: _S.textHint,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          // _getMealTime(meal),
                          _displayTotalTime(meal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _S.f(11.5, FontWeight.w600, _S.textMed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showMealOptions(meal),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: OnboardingLineIcon(
                  'dots',
                  size: 22,
                  color: Color(0xFFC7BCAC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live recipe lookup ──────────────────────────────────────────────────
  // MealPlanItem stores a SNAPSHOT of the recipe's title/image at the time it
  // was added to the plan. If the recipe is edited later, that snapshot goes
  // stale. These helpers always pull the CURRENT recipe (by id) from
  // homeController.recipes first, and only fall back to the stored snapshot
  // if the recipe can no longer be found (e.g. it was deleted).

  RecipeModel? _liveRecipe(MealPlanItem meal) {
    return homeController.recipes.firstWhereOrNull(
      (r) => r.id == meal.recipeId,
    );
  }

  String _liveTitle(MealPlanItem meal) {
    final recipe = _liveRecipe(meal);
    if (recipe != null && recipe.title.isNotEmpty) return recipe.title;
    return meal.recipeTitle;
  }

  String? _liveImageUrl(MealPlanItem meal) {
    final recipe = _liveRecipe(meal);
    if (recipe != null) return recipe.imageUrl;
    return meal.recipeImageUrl;
  }

  // Square recipe thumbnail used by day & month meal cards.
  Widget _mealImage(MealPlanItem meal, double size) {
    final imageUrl = _liveImageUrl(meal);
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, __) =>
                    Container(color: const Color(0xFFEDE5D7)),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFEDE5D7),
                  child: Icon(
                    _S.mealIcon(meal.mealType),
                    size: 20,
                    color: _S.mealColor(meal.mealType),
                  ),
                ),
              )
            : Container(
                color: _S.mealColor(meal.mealType).withValues(alpha: 0.1),
                child: Icon(
                  _S.mealIcon(meal.mealType),
                  size: 22,
                  color: _S.mealColor(meal.mealType),
                ),
              ),
      ),
    );
  }

  void _openRecipe(MealPlanItem meal) {
    final recipe = _liveRecipe(meal);
    if (recipe != null) {
      Get.to(() => RecipeDetailScreen(recipe: recipe));
    }
  }

  String _getMealTime(MealPlanItem meal) {
    final recipe = _liveRecipe(meal);
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

  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Column(
        children: [
          // ── Calendar card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _S.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _S.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A211B).withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                  spreadRadius: -22,
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
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _S.cardBorder),
                          ),
                          child: const OnboardingLineIcon(
                            'back',
                            size: 20,
                            color: Color(0xFF5A5147),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_monthNames[viewMonth.month - 1]} ${viewMonth.year}',
                        style: _S.f(15, FontWeight.w800, _S.textDark),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => controller.selectDate(
                          DateTime(selDate.year, selDate.month + 1, 1),
                        ),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _S.cardBorder),
                          ),
                          child: const OnboardingLineIcon(
                            'chevR',
                            size: 20,
                            color: Color(0xFF5A5147),
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
                              style: _S.f(11, FontWeight.w800, _S.textHint),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 2),

                // Calendar grid  (reactive on selectedDate + month meals)
                Obx(() {
                  final selDate = controller.selectedDate.value;
                  final viewMonth = DateTime(selDate.year, selDate.month);
                  final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
                  final daysInMonth = DateTime(
                    viewMonth.year,
                    viewMonth.month + 1,
                    0,
                  ).day;
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
                  Expanded(
                    child: Text(
                      '${_dayNames[selDate.weekday - 1]}, ${selDate.day} ${_monthNames[selDate.month - 1]}',
                      style: _S.f(16, FontWeight.w800, _S.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddMealSheet(selDate, 'Breakfast'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _S.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const OnboardingLineIcon(
                            'plus',
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'add_meal'.tr,
                            style: _S.f(12.5, FontWeight.w700, Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

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
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _S.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _S.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2A211B,
                            ).withValues(alpha: 0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                            spreadRadius: -20,
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: 1.5,
                        child: const OnboardingLineIcon(
                          'cal',
                          size: 24,
                          color: Color(0xFFD7BBA0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'no_meals_for_day'.tr,
                      style: _S.f(16, FontWeight.w800, _S.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'add_recipe_to_meals'.tr,
                      style: _S.f(13.5, FontWeight.w500, _S.textMed, h: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showAddMealSheet(selDate, 'Breakfast'),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _S.primary,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _S.primary.withValues(alpha: 0.6),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const OnboardingLineIcon(
                              'plus',
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'add_a_meal'.tr,
                              style: _S.f(14, FontWeight.w700, Colors.white),
                            ),
                          ],
                        ),
                      ),
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
                    const OnboardingLineIcon(
                      'crown',
                      size: 24,
                      color: Color(0xFF7A4FC0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'auto_fill_my_week'.tr,
                      style: _S.f(
                        13.5,
                        FontWeight.w700,
                        const Color(0xFF7A4FC0),
                      ),
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
              color: const Color(0xFF2A211B).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -18,
            ),
          ],
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
                    _liveTitle(meal),
                    style: _S.f(13.5, FontWeight.w700, _S.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const OnboardingLineIcon(
                        'clock',
                        size: 12,
                        color: _S.textHint,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _getMealTime(meal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _S.f(11.5, FontWeight.w600, _S.textMed),
                        ),
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
                padding: EdgeInsets.all(10),
                child: OnboardingLineIcon(
                  'dots',
                  size: 25,
                  color: Color(0xFFC7BCAC),
                ),
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

  String? _optionsMealId;

  String _mealDayLabel(MealPlanItem meal) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String day = '';
    try {
      day = days[DateTime.parse(meal.date).weekday - 1];
    } catch (_) {}
    final t = meal.mealType;
    final type = t.isEmpty
        ? ''
        : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
    return day.isEmpty ? type : '$day · $type';
  }

  void _addMealToGroceries(MealPlanItem meal) {
    final recipe = _liveRecipe(meal);
    if (recipe == null || recipe.ingredients.isEmpty) {
      CustomSnackbar.show(
        title: 'no_ingredients'.tr,
        message: 'no_ingredients_for'.trParams({'title': _liveTitle(meal)}),
        type: SnackbarType.error,
      );
      return;
    }
    Get.find<GroceryStore>().addFromRecipe(meal.recipeId, recipe.ingredients);
    CustomSnackbar.show(
      title: 'added_to_groceries'.tr,
      message: 'ingredients_from'.trParams({
        'count': '${recipe.ingredients.length}',
        'title': recipe.title,
      }),
      type: SnackbarType.success,
    );
  }

  // Per-meal options popup (HTML 49b): orange-borders the card, two actions.
  void _showMealOptions(MealPlanItem meal) {
    setState(() => _optionsMealId = meal.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
        decoration: const BoxDecoration(
          color: _S.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _mealImage(meal, 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _liveTitle(meal),
                          style: _S.f(15, FontWeight.w800, _S.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _mealDayLabel(meal),
                          style: _S.f(12, FontWeight.w600, _S.textMed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _mealOptionRow(
              iconName: 'cart',
              iconColor: const Color(0xFF5A5147),
              label: 'add_to_groceries'.tr,
              labelColor: _S.textDark,
              labelWeight: FontWeight.w600,
              onTap: () {
                Get.back();
                _addMealToGroceries(meal);
              },
            ),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 12,
              endIndent: 12,
              color: Color(0xFFF4ECDF),
            ),
            _mealOptionRow(
              iconName: 'trash',
              iconColor: const Color(0xFFE0481F),
              label: 'remove_from_plan'.tr,
              labelColor: const Color(0xFFE0481F),
              labelWeight: FontWeight.w700,
              onTap: () {
                Get.back();
                final title = _liveTitle(meal);
                controller.deleteMealPlanItem(meal.id);
                CustomSnackbar.show(
                  title: 'removed'.tr,
                  message: 'removed_from_plan'.trParams({'title': title}),
                  type: SnackbarType.info,
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _optionsMealId = null);
    });
  }

  Widget _mealOptionRow({
    required String iconName,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required FontWeight labelWeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            OnboardingLineIcon(iconName, color: iconColor, size: 20),
            const SizedBox(width: 13),
            Text(label, style: _S.f(15, labelWeight, labelColor)),
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
              child: const OnboardingLineIcon(
                'trashLg',
                size: 28,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'clear_this_week_q'.tr,
              style: _S.f(18, FontWeight.w800, _S.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'clear_week_confirm'.tr,
              style: _S.f(13, FontWeight.w500, _S.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _S.border),
                      ),
                      child: Center(
                        child: Text(
                          'cancel'.tr,
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
                      Get.back();
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
                          'clear'.tr,
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
    // AI Auto-fill is a Plus feature — free users get the upgrade prompt.
    if (!SubscriptionService.instance.canUseMealPlanner()) {
      showUpgradeDialog(context, feature: 'ai_meal_plan_autofill'.tr);
      return;
    }
    AutoFillGoalSheet.open(context);
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
                  color: isSel
                      ? _S.primary
                      : isToday
                      ? _S.primary.withOpacity(0.1)
                      : _S.card,
                  // Today (when not the selected day) gets an orange outline ring.
                  border: (isToday && !isSel)
                      ? Border.all(color: _S.primary, width: 1.5)
                      : null,
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

  // HTML 51 chip tints: unselected (bg, text). Selected = solid mealColor + white.
  static const _chipTint = {
    'Breakfast': (Color(0xFFFCF3DE), Color(0xFF7A5B12)),
    'Lunch': (Color(0xFFEAF6F0), Color(0xFF1F5E42)),
    'Dinner': (Color(0xFFE9F0FC), Color(0xFF2D6FE0)),
    'Snack': (Color(0xFFFCEAE3), Color(0xFF9B3417)),
  };

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E0D2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'add_to_day_meal'.trParams({
                          'day': widget.dayName,
                          'meal': _selectedType,
                        }),
                        style: _S.f(19, FontWeight.w800, _S.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const OnboardingLineIcon(
                          'x',
                          color: Color(0xFF8A7E70),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MealPlanController.mealTypes
                          .map(_typeChip)
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppSearchBar(
                  hintText: 'search_your_recipes'.tr,
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final dayMeals = widget.controller.getMealsForDate(widget.date);
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
                    'no_recipes_found'.tr,
                    style: _S.f(14, FontWeight.w500, _S.textHint),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: recipes.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF4ECDF)),
                itemBuilder: (_, i) {
                  final recipe = recipes[i];
                  final existing = dayMeals.firstWhereOrNull(
                    (m) =>
                        m.recipeId == recipe.id && m.mealType == _selectedType,
                  );
                  return _recipeRow(recipe, existing);
                },
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              18 + MediaQuery.of(context).padding.bottom,
            ),
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _S.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _S.primary.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Text(
                  'add_to_plan'.tr,
                  style: _S.f(16, FontWeight.w700, Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type) {
    final sel = type == _selectedType;
    final tint = _chipTint[type]!;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? _S.mealColor(type) : tint.$1,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            type,
            style: _S.f(
              12.5,
              sel ? FontWeight.w800 : FontWeight.w700,
              sel ? Colors.white : tint.$2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _recipeRow(RecipeModel recipe, MealPlanItem? existing) {
    final added = existing != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 50,
              height: 50,
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
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
                    recipe.totalTime!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    recipe.totalTime!,
                    style: _S.f(12, FontWeight.w600, _S.textMed),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (existing != null) {
                widget.controller.deleteMealPlanItem(existing.id);
              } else {
                widget.controller.addMealPlanItem(
                  date: widget.date,
                  mealType: _selectedType,
                  recipeId: recipe.id,
                  recipeTitle: recipe.title,
                  recipeImageUrl: recipe.imageUrl,
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: added ? _S.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: added
                    ? null
                    : Border.all(color: _S.primary, width: 1.5),
              ),
              child: OnboardingLineIcon(
                added ? 'check' : 'plus',
                size: 18,
                color: added ? Colors.white : _S.primary,
              ),
            ),
          ),
        ],
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
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashRectPainter old) =>
      old.color != color || old.radius != radius;
}
