import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_ai/Controllers/meal_planner_controller.dart';
import 'package:recipe_ai/widgets/app_network_image.dart';

/// Shared design tokens + reusable widgets for the "Auto-fill my week" flow.
/// Every dimension/colour here is pulled once so the three screens stay in sync
/// and pixel-consistent (no per-screen magic numbers).
class Mp {
  Mp._();

  // Palette
  static const bg = Color(0xFFFBF4EA);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2A211B);
  static const body = Color(0xFF6B6359);
  static const muted = Color(0xFF9A938A);
  static const border = Color(0xFFEFE6D6);
  static const divider = Color(0xFFF1E9DA);

  static const purple = Color(0xFF8B5CF6);
  static const purpleDark = Color(0xFF7C3AED);
  static const purpleBg = Color(0xFFF3EEFE);
  static const purpleBorder = Color(0xFFE4D9Fb);

  static const orange = Color(0xFFF2623E);
  static const orangeLight = Color(0xFFFF8763);
  static const green = Color(0xFF1F9D63);

  // Source badge palette
  static const cookbookBg = Color(0xFFF3EBDA);
  static const cookbookFg = Color(0xFF9A7B3A);
  static const communityBg = Color(0xFFE4ECFB);
  static const communityFg = Color(0xFF2D6FE0);
  static const aiBg = Color(0xFFEDE6FB);
  static const aiFg = Color(0xFF7C3AED);

  // Meal category dots
  static const breakfast = Color(0xFFC0860F);
  static const lunch = Color(0xFF1F7A5E);
  static const dinner = Color(0xFF2D6FE0);

  static Color slotColor(String slot) {
    switch (slot) {
      case 'Breakfast':
        return breakfast;
      case 'Lunch':
        return lunch;
      case 'Dinner':
        return dinner;
      default:
        return orange;
    }
  }

  static Color goalAccent(MealGoal g) {
    switch (g) {
      case MealGoal.healthy:
        return const Color(0xFF1F9D63);
      case MealGoal.highProtein:
        return const Color(0xFFE0481F);
      case MealGoal.quickEasy:
        return const Color(0xFFD98A12);
      case MealGoal.vegetarian:
        return const Color(0xFF2E9E5B);
    }
  }

  static TextStyle f(
    double size,
    FontWeight w,
    Color c, {
    double? h,
    double? ls,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: w,
    color: c,
    height: h,
    letterSpacing: ls,
  );
}

/// Scale-on-tap wrapper for buttons/cards (1.0 → 0.97 → 1.0).
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Full-width orange-gradient CTA with an optional leading icon.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Mp.orangeLight, Mp.orange],
          ),
          boxShadow: [
            BoxShadow(
              color: Mp.orange.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 9),
            ],
            Text(label, style: Mp.f(16, FontWeight.w800, Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Full-width purple-gradient CTA (used for "Generate my week").
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final List<Color> colors;
  final double height;
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.colors = const [Mp.purple, Mp.purpleDark],
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.42),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 9),
            ],
            Text(label, style: Mp.f(15.5, FontWeight.w800, Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Outlined secondary button (purple text/border on white).
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Mp.purpleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Mp.purpleBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Mp.purpleDark),
              const SizedBox(width: 8),
            ],
            Text(label, style: Mp.f(14.5, FontWeight.w800, Mp.purpleDark)),
          ],
        ),
      ),
    );
  }
}

/// A source badge chip: Cookbook / Community / AI.
class SourceBadge extends StatelessWidget {
  final PlanSource source;
  const SourceBadge(this.source, {super.key});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (source) {
      case PlanSource.cookbook:
        label = 'Cookbook';
        bg = Mp.cookbookBg;
        fg = Mp.cookbookFg;
        break;
      case PlanSource.community:
        label = 'Community';
        bg = Mp.communityBg;
        fg = Mp.communityFg;
        break;
      case PlanSource.ai:
        label = 'AI';
        bg = Mp.aiBg;
        fg = Mp.aiFg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label, style: Mp.f(10.5, FontWeight.w800, fg)),
    );
  }
}

/// One goal option row in the "Plan my week" sheet.
class GoalOptionCard extends StatelessWidget {
  final MealGoal goal;
  final bool selected;
  final VoidCallback onTap;
  const GoalOptionCard({
    super.key,
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Mp.goalAccent(goal);
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Mp.purpleBg : Mp.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Mp.purple : Mp.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(goal.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: Mp.f(15, FontWeight.w800, Mp.ink)),
                  const SizedBox(height: 2),
                  Text(
                    goal.subtitle,
                    style: Mp.f(12.5, FontWeight.w500, Mp.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool on) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? Mp.purple : Colors.transparent,
      border: Border.all(
        color: on ? Mp.purple : const Color(0xFFD8CFC0),
        width: 1.6,
      ),
    ),
    child: on
        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
        : null,
  );
}

/// A single step row on the generating screen.
class GeneratingStepCard extends StatelessWidget {
  final GenStep step;
  const GeneratingStepCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final active = step.state == MpStepState.active;
    final done = step.state == MpStepState.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: active ? const Color(0x33FFFFFF) : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0x88B79CF6) : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          _leading(active, done),
          const SizedBox(width: 13),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: Mp.f(
                14,
                done || active ? FontWeight.w700 : FontWeight.w600,
                (done || active)
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
              ),
              child: Text(step.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leading(bool active, bool done) {
    if (done) {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Mp.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    if (active) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    );
  }
}

/// One meal row inside a day card (thumbnail · name · source badge · swap).
class MealRowTile extends StatelessWidget {
  final PlannedMeal meal;
  final VoidCallback onTap;
  final VoidCallback onSwap;
  const MealRowTile({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Mp.slotColor(meal.slot),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 38,
                height: 38,
                child: (meal.recipe.imageUrl ?? '').startsWith('http')
                    ? AppNetworkImage(meal.recipe.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Mp.bg,
                        child: const Icon(
                          Icons.restaurant_rounded,
                          size: 18,
                          color: Mp.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                meal.recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mp.f(14, FontWeight.w700, Mp.ink),
              ),
            ),
            const SizedBox(width: 8),
            SourceBadge(meal.recipe.source),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onSwap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 18,
                  color: Mp.muted.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded day card grouping that day's meals.
class MealDayCard extends StatelessWidget {
  final String title;
  final List<PlannedMeal> meals;
  final void Function(PlannedMeal) onTapMeal;
  final void Function(PlannedMeal) onSwapMeal;
  const MealDayCard({
    super.key,
    required this.title,
    required this.meals,
    required this.onTapMeal,
    required this.onSwapMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Mp.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Mp.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Mp.f(14.5, FontWeight.w800, Mp.ink)),
          const SizedBox(height: 6),
          for (var i = 0; i < meals.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Mp.divider),
            MealRowTile(
              meal: meals[i],
              onTap: () => onTapMeal(meals[i]),
              onSwap: () => onSwapMeal(meals[i]),
            ),
          ],
        ],
      ),
    );
  }
}
