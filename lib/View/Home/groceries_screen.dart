import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants (matched to the HTML "Groceries" design)
// ─────────────────────────────────────────────────────────────────────────────
class _G {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const border = Color(0xFFEFE6D6);
  static const chipBorder = Color(0xFFEDE3D2);
  static const rowLine = Color(0xFFF4ECDF);
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textBody = Color(0xFF5A5147);
  static const textMed = Color(0xFF8A7E70);
  static const textHint = Color(0xFFA89F90);
  static const green = Color(0xFF1F7A5E);
  static const progressBg = Color(0xFFEEE3D2);
  static const checkBorder = Color(0xFFE2D8C7);
  static const gold = Color(0xFFD98A12);
  static const goldBg = Color(0xFFFBF1E4);
  static const noteBg = Color(0xFFFCE3DB);
  static const checkedBg = Color(0xFFF6F2EA);
  static const fieldBg = Color(0xFFFBF7F0);
  static const fieldBorder = Color(0xFFE7DECE);

  // Single source of truth lives on the controller (shared with recipe details).
  static String emoji(String aisle) => GroceryStore.aisleEmoji(aisle);

  static TextStyle f(
    double s,
    FontWeight w,
    Color c, {
    double? h,
    double? ls,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: s,
    fontWeight: w,
    color: c,
    height: h,
    letterSpacing: ls,
  );
}

// The categories offered when adding / editing an item (drive aisle grouping).
const _kCategories = [
  'Produce',
  'Meat & Poultry',
  'Seafood',
  'Dairy & Eggs',
  'Pantry / Canned & Jarred',
  'Grains & Pasta',
  'Spices & Seasonings',
  'Frozen',
  'Bakery',
  'Beverages',
  'Snacks & Sweets',
  'Household',
  'Other',
];

/// A set of grocery items sharing the same name (across one or more recipes),
/// used to render a single merged line with a per-recipe breakdown.
class _MergedItem {
  final String name;
  final String aisle;
  final List<GroceryItem> parts;
  const _MergedItem(this.name, this.aisle, this.parts);
}

class GroceriesScreen extends StatelessWidget {
  GroceriesScreen({super.key});

  final GroceryStore store = Get.find<GroceryStore>();
  final HomeController homeController = Get.find<HomeController>();
  final SettingsController settings = Get.find<SettingsController>();

  // true = group by meal/recipe, false = group by category/aisle
  final RxBool _byMeal = true.obs;

  // Which merged "By category" rows are expanded (key = "aisle::name").
  final RxSet<String> _expandedKeys = <String>{}.obs;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _G.bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: top + 6, left: 18, right: 18),
            child: _buildHeader(context),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              final items = store.items;
              if (items.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildToggle(),
                    ),
                    Expanded(
                      child: _byMeal.value
                          ? _buildMealEmpty(context)
                          : _buildEmpty(context),
                    ),
                  ],
                );
              }

              final total = items.length;
              final done = items.where((i) => i.checked).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgress(done, total),
                    const SizedBox(height: 18),
                    _buildToggle(),
                    // Row(
                    //   children: [
                    //     Expanded(child: _buildToggle()),
                    //     const SizedBox(width: 8),
                    //     // US / Metric — converts every grocery to one system.
                    //     _unitToggle(),
                    //   ],
                    // ),
                    const SizedBox(height: 16),
                    if (_byMeal.value)
                      ..._buildByMeal(context, items)
                    else
                      ..._buildByCategory(context, items),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'groceries'.tr,
          style: _G.f(22, FontWeight.w800, _G.textDark, ls: -0.4),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showAddItemSheet(context),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _G.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _G.primary.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OnboardingLineIcon('plus', size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'add_item'.tr,
                  style: _G.f(13, FontWeight.w700, Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _MoreMenuButton(onSelected: (v) => _handleMore(context, v)),
      ],
    );
  }

  Widget _buildProgress(int done, int total) {
    final frac = total == 0 ? 0.0 : done / total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 8,
              color: _G.progressBg,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: frac.clamp(0.0, 1.0),
                child: Container(color: _G.green),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Text('$done / $total', style: _G.f(12, FontWeight.w800, _G.green)),
      ],
    );
  }

  Widget _buildToggle() {
    return Row(
      children: [
        _toggleChip('by_meal'.tr, true),
        const SizedBox(width: 7),
        _toggleChip('by_category'.tr, false),
      ],
    );
  }

  Widget _toggleChip(String label, bool meal) {
    final on = _byMeal.value == meal;
    return GestureDetector(
      onTap: () => _byMeal.value = meal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: on ? _G.primary : _G.card,
          borderRadius: BorderRadius.circular(20),
          border: on ? null : Border.all(color: _G.chipBorder),
        ),
        child: Text(
          label,
          style: _G.f(
            12.5,
            on ? FontWeight.w800 : FontWeight.w700,
            on ? Colors.white : _G.textBody,
          ),
        ),
      ),
    );
  }

  // ── By meal (grouped by recipe) ───────────────────────────────────────────
  List<Widget> _buildByMeal(BuildContext context, List<GroceryItem> items) {
    final multiNames = store.multiMealNames;
    final widgets = <Widget>[];

    // 1) "Used in many meals" — ingredients that appear in more than one recipe,
    // merged into a single line so you buy them once for the week.
    final multiItems = items
        .where(
          (it) =>
              it.recipeId.isNotEmpty &&
              multiNames.contains(it.name.toLowerCase()),
        )
        .toList();
    final mergedMulti = _mergeByName(multiItems);
    if (mergedMulti.isNotEmpty) {
      widgets.add(_infoBanner());
      widgets.add(const SizedBox(height: 16));
      widgets.add(_usedInManyHeader());
      widgets.add(_manyMealsCard(context, mergedMulti));
      widgets.add(const SizedBox(height: 18));
    }

    // 2) Per-recipe groups (excluding the merged "used in many meals" items).
    final order = <String>[];
    final groups = <String, List<GroceryItem>>{};
    final extra = <GroceryItem>[];
    for (final it in items) {
      if (it.recipeId.isEmpty) {
        extra.add(it);
        continue;
      }
      if (multiNames.contains(it.name.toLowerCase())) continue;
      if (!groups.containsKey(it.recipeId)) {
        groups[it.recipeId] = [];
        order.add(it.recipeId);
      }
      groups[it.recipeId]!.add(it);
    }

    for (final key in order) {
      final recipe = _recipeById(key);
      final g = groups[key]!;
      if (recipe == null) {
        extra.addAll(g); // recipe deleted → treat as extra
        continue;
      }
      widgets.add(_recipeHeader(recipe, g.length));
      widgets.add(_itemCard(context, g));
      widgets.add(const SizedBox(height: 18));
    }

    // 3) Extra items added by the user.
    if (extra.isNotEmpty) {
      widgets.add(_extraHeader());
      widgets.add(_itemCard(context, extra));
      widgets.add(const SizedBox(height: 18));
    }
    return widgets;
  }

  /// Group items by (case-insensitive) name, preserving first-seen order.
  List<_MergedItem> _mergeByName(List<GroceryItem> list) {
    final order = <String>[];
    final map = <String, List<GroceryItem>>{};
    for (final it in list) {
      final k = it.name.toLowerCase();
      if (!map.containsKey(k)) {
        map[k] = [];
        order.add(k);
      }
      map[k]!.add(it);
    }
    return [
      for (final k in order)
        _MergedItem(map[k]!.first.name, _resolvedAisle(map[k]!.first), map[k]!),
    ];
  }

  /// The item's stored aisle — but if it's still "Other" (or blank), give it a
  /// second chance with the current keyword map so items that never matched a
  /// category land in the right aisle. A real, non-"Other" aisle (e.g. one the
  /// user picked manually) is always kept as-is.
  String _resolvedAisle(GroceryItem item) {
    if (item.aisle.isNotEmpty && item.aisle != 'Other') return item.aisle;
    return store.detectAisle(item.name);
  }

  /// Merged total for a group, guaranteed to equal the sum of the per-part
  /// values shown in the breakdown. Each part is converted to the active unit
  /// system FIRST, then combined — combining the RAW parts and converting the
  /// result once could drop or mis-add parts whose original units differed
  /// (applySystemQuantity only converts the first unit of a string), which is
  /// what made the merged totals wrong.
  String _mergedQty(Iterable<GroceryItem> parts, String name) {
    return GroceryStore.combineQuantities(
      parts.map(
        (p) => UnitConverter.applySystemQuantity(
          p.quantity,
          name,
          settings.unitSystem,
        ),
      ),
    );
  }

  void _toggleExpanded(String key) {
    if (_expandedKeys.contains(key)) {
      _expandedKeys.remove(key);
    } else {
      _expandedKeys.add(key);
    }
    // Nudge the reactive list so the enclosing Obx rebuilds with the new state.
    store.items.refresh();
  }

  // Light banner explaining the merge behaviour (matches the design).
  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3DCF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingLineIcon('spark', size: 16, color: Color(0xFF7C6BD1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'info_merged_line'.tr,
              style: _G.f(
                12.5,
                FontWeight.w600,
                const Color(0xFF6B5CA5),
                h: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usedInManyHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _G.goldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const OnboardingLineIcon(
              'bookmark',
              size: 17,
              color: _G.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'used_in_many_meals'.tr,
                  style: _G.f(14, FontWeight.w800, _G.textDark),
                ),
                Text(
                  'buy_once_for_week'.tr,
                  style: _G.f(11, FontWeight.w600, _G.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manyMealsCard(BuildContext context, List<_MergedItem> merged) {
    final allChecked = merged.every((m) => m.parts.every((p) => p.checked));
    return Container(
      decoration: BoxDecoration(
        color: allChecked ? _G.checkedBg : _G.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _G.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < merged.length; i++)
            _manyMealsRow(context, merged[i], last: i == merged.length - 1),
        ],
      ),
    );
  }

  Widget _manyMealsRow(
    BuildContext context,
    _MergedItem m, {
    required bool last,
  }) {
    // Distinct key namespace ('meal::') so tapping a merged row here never
    // collides with the identically-named row in the By-category view.
    final key = 'meal::${m.name.toLowerCase()}';
    final expanded = _expandedKeys.contains(key);
    final allChecked = m.parts.every((p) => p.checked);
    final combined = _mergedQty(m.parts, m.name);
    return Container(
      decoration: BoxDecoration(
        border: (last && !expanded)
            ? null
            : const Border(bottom: BorderSide(color: _G.rowLine)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _checkbox(
                allChecked,
                onTap: () => store.setCheckedAll(m.parts, !allChecked),
              ),
              const SizedBox(width: 10),
              Expanded(
                // Tap the "N meals combined" label to reveal the recipe names
                // it comes from — mirrors the By-category expandable row.
                child: GestureDetector(
                  onTap: () => _toggleExpanded(key),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          GroceryStore().trName(m.name),
                          style: _G
                              .f(
                                14,
                                FontWeight.w700,
                                allChecked ? _G.textHint : _G.textDark,
                              )
                              .copyWith(
                                decoration: allChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _mealsBreakdown(m),
                                style: _G.f(11, FontWeight.w600, _G.gold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ${expanded ? 'tap_to_hide'.tr : 'tap_to_view'.tr}',
                              style: _G.f(11, FontWeight.w600, _G.gold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (combined.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    combined,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _G
                        .f(
                          13,
                          FontWeight.w700,
                          allChecked ? const Color(0xFFC7BCAC) : _G.textMed,
                        )
                        .copyWith(
                          decoration: allChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () => _showItemOptions(context, m.parts.first),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(6, 12, 12, 12),
                  child: OnboardingLineIcon(
                    'dots',
                    size: 18,
                    color: Color(0xFFB0A899),
                  ),
                ),
              ),
            ],
          ),
          // Per-recipe breakdown when expanded (one row PER recipe) — shows the
          // meal/recipe names this merged ingredient is used in.
          if (expanded) ..._recipeBreakdown(m),
        ],
      ),
    );
  }

  /// "2 meals · 3 + 2 cloves" when the units match, else "N meals combined".
  String _mealsBreakdown(_MergedItem m) {
    final n = m.parts
        .map((p) => p.recipeId)
        .where((r) => r.isNotEmpty)
        .toSet()
        .length;
    final nums = <String>[];
    String? unit;
    for (final p in m.parts) {
      final match = RegExp(
        r'^\s*([\d./½⅓⅔¼¾⅛⅜⅝⅞\s]+?)\s*(.*)$',
      ).firstMatch(p.quantity.trim());
      if (match == null) return 'meals_combined'.trParams({'n': '$n'});
      final num = match.group(1)!.trim();
      final u = match.group(2)!.trim();
      if (num.isEmpty) return 'meals_combined'.trParams({'n': '$n'});
      unit ??= u;
      if (u.toLowerCase() != unit.toLowerCase()) {
        return 'meals_combined'.trParams({'n': '$n'});
      }
      nums.add(num);
    }
    if (nums.length < 2) return 'meals_combined'.trParams({'n': '$n'});
    final unitStr = (unit == null || unit.isEmpty) ? '' : ' $unit';
    return '${'n_meals'.trParams({'n': '$n'})} · ${nums.join(' + ')}$unitStr';
  }

  Widget _checkbox(bool checked, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
        child: Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: checked ? _G.green : Colors.transparent,
            border: checked
                ? null
                : Border.all(color: _G.checkBorder, width: 2),
          ),
          child: checked
              ? const OnboardingLineIcon('check', size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  RecipeModel? _recipeById(String id) =>
      homeController.recipes.firstWhereOrNull((r) => r.id == id);

  Widget _recipeHeader(RecipeModel recipe, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 34,
              height: 34,
              child: (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: recipe.imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 110,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFEDE5D7)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFFEDE5D7)),
                    )
                  : Container(color: const Color(0xFFEDE5D7)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: _G.f(14, FontWeight.w800, _G.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  count == 1
                      ? 'item_singular'.trParams({'count': '$count'})
                      : 'item_plural'.trParams({'count': '$count'}),
                  style: _G.f(11, FontWeight.w600, _G.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _G.noteBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const OnboardingLineIcon(
              'plus',
              size: 18,
              color: _G.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'extra_items'.tr,
                  style: _G.f(14, FontWeight.w800, _G.textDark),
                ),
                Text(
                  'added_by_you'.tr,
                  style: _G.f(11, FontWeight.w600, _G.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── By category (grouped by aisle) ─────────────────────────────────────────
  List<Widget> _buildByCategory(BuildContext context, List<GroceryItem> items) {
    // Merge same-named items FIRST (across recipes AND aisles) so an ingredient
    // that different recipes filed under slightly different aisles still lands
    // on one line — then bucket each merged line into a single aisle.
    final merged = _mergeByName(items);
    final byAisle = <String, List<_MergedItem>>{};
    for (final m in merged) {
      byAisle.putIfAbsent(m.aisle, () => []).add(m);
    }

    final widgets = <Widget>[];
    for (final aisle in store.sortedAisles) {
      final list = byAisle[aisle] ?? const <_MergedItem>[];
      if (list.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(_G.emoji(aisle), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(aisle, style: _G.f(14, FontWeight.w800, _G.textDark)),
              const SizedBox(width: 6),
              Text(
                '· ${list.length}',
                style: _G.f(12, FontWeight.w600, _G.textHint),
              ),
            ],
          ),
        ),
      );
      widgets.add(_mergedCategoryCard(context, list));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _mergedCategoryCard(BuildContext context, List<_MergedItem> merged) {
    final allChecked = merged.every((m) => m.parts.every((p) => p.checked));
    final rows = <Widget>[];
    for (int i = 0; i < merged.length; i++) {
      final m = merged[i];
      final isLast = i == merged.length - 1;
      final recipeIds = m.parts
          .map((p) => p.recipeId)
          .where((r) => r.isNotEmpty)
          .toSet();
      if (recipeIds.length > 1) {
        rows.add(_mergedMultiRow(context, m, recipeIds.length, last: isLast));
      } else {
        // Single-source item(s) — render as normal rows.
        for (int j = 0; j < m.parts.length; j++) {
          rows.add(
            _itemRow(
              context,
              m.parts[j],
              last: isLast && j == m.parts.length - 1,
            ),
          );
        }
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: allChecked ? _G.checkedBg : _G.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _G.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _mergedMultiRow(
    BuildContext context,
    _MergedItem m,
    int recipeCount, {
    required bool last,
  }) {
    final key = '${m.aisle}::${m.name.toLowerCase()}';
    final expanded = _expandedKeys.contains(key);
    final allChecked = m.parts.every((p) => p.checked);
    final combined = _mergedQty(m.parts, m.name);
    return Container(
      decoration: BoxDecoration(
        border: (last && !expanded)
            ? null
            : const Border(bottom: BorderSide(color: _G.rowLine)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _checkbox(
                allChecked,
                onTap: () => store.setCheckedAll(m.parts, !allChecked),
              ),
              const SizedBox(width: 10),
              // Per-ingredient emoji, matching the single-source rows.
              Text(
                store.emojiForIngredient(m.name),
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleExpanded(key),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                GroceryStore().trName(m.name),
                                style: _G
                                    .f(
                                      14,
                                      FontWeight.w700,
                                      allChecked ? _G.textHint : _G.textDark,
                                    )
                                    .copyWith(
                                      decoration: allChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _G.noteBg,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '+$recipeCount',
                                style: _G.f(10.5, FontWeight.w800, _G.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${'from_n_recipes'.trParams({'count': '$recipeCount'})} · '
                          '${expanded ? 'tap_to_hide'.tr : 'tap_to_view'.tr}',
                          style: _G.f(11, FontWeight.w600, _G.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (combined.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    combined,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _G
                        .f(
                          13,
                          FontWeight.w700,
                          allChecked ? const Color(0xFFC7BCAC) : _G.textMed,
                        )
                        .copyWith(
                          decoration: allChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () => _showItemOptions(context, m.parts.first),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(6, 12, 12, 12),
                  child: OnboardingLineIcon(
                    'dots',
                    size: 18,
                    color: Color(0xFFB0A899),
                  ),
                ),
              ),
            ],
          ),
          // Per-recipe breakdown when expanded (one row PER recipe).
          if (expanded) ..._recipeBreakdown(m),
        ],
      ),
    );
  }

  /// One breakdown row per DISTINCT recipe (an ingredient listed twice in the
  /// same recipe is combined, so a recipe never appears twice).
  List<Widget> _recipeBreakdown(_MergedItem m) {
    final order = <String>[];
    final byRecipe = <String, List<GroceryItem>>{};
    for (final p in m.parts) {
      if (p.recipeId.isEmpty) continue;
      if (!byRecipe.containsKey(p.recipeId)) {
        byRecipe[p.recipeId] = [];
        order.add(p.recipeId);
      }
      byRecipe[p.recipeId]!.add(p);
    }
    return [for (final id in order) _subRecipeRow(id, byRecipe[id]!)];
  }

  Widget _subRecipeRow(String recipeId, List<GroceryItem> parts) {
    final recipe = _recipeById(recipeId);
    final name = recipe?.title ?? 'recipe'.tr;
    final qty = _mergedQty(parts, parts.first.name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(47, 0, 14, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: _G.f(12.5, FontWeight.w500, _G.textMed),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (qty.trim().isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                qty,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _G.f(12.5, FontWeight.w600, _G.textMed),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared item card + rows ────────────────────────────────────────────────
  Widget _itemCard(BuildContext context, List<GroceryItem> group) {
    final allChecked = group.every((i) => i.checked);
    return Container(
      decoration: BoxDecoration(
        color: allChecked ? _G.checkedBg : _G.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _G.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < group.length; i++)
            _itemRow(context, group[i], last: i == group.length - 1),
        ],
      ),
    );
  }

  // Widget _itemRow(
  //   BuildContext context,
  //   GroceryItem item, {
  //   required bool last,
  // }) {
  //   final checked = item.checked;
  //   return Container(
  //     decoration: BoxDecoration(
  //       border: last
  //           ? null
  //           : const Border(bottom: BorderSide(color: _G.rowLine)),
  //     ),
  //     child: Row(
  //       children: [
  //         GestureDetector(
  //           onTap: () => store.toggleItem(item),
  //           behavior: HitTestBehavior.opaque,
  //           child: Padding(
  //             padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
  //             child: Container(
  //               width: 23,
  //               height: 23,
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(7),
  //                 color: checked ? _G.green : Colors.transparent,
  //                 border: checked
  //                     ? null
  //                     : Border.all(color: _G.checkBorder, width: 2),
  //               ),
  //               child: checked
  //                   ? const OnboardingLineIcon(
  //                       'check',
  //                       size: 14,
  //                       color: Colors.white,
  //                     )
  //                   : null,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         // Per-ingredient emoji (By category) so each item reads like the
  //         // recipe ingredient list — a distinct icon per ingredient.
  //         if (item.quantity.trim().isNotEmpty) ...[
  //           const SizedBox(width: 8),
  //           Text(
  //             // Convert the stored quantity to the active unit system on
  //             // display (reactive via the enclosing Obx over store.items).
  //             UnitConverter.applySystemQuantity(
  //               item.quantity,
  //               item.name,
  //               settings.unitSystem,
  //             ),

  //             style: _G
  //                 .f(14, FontWeight.w700, checked ? _G.textHint : _G.textDark)
  //                 .copyWith(
  //                   decoration: checked ? TextDecoration.lineThrough : null,
  //                 ),
  //           ),
  //         ],
  //         Expanded(
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 12),
  //             child: Text(
  //               item.name,
  //               style: _G
  //                   .f(
  //                     13,
  //                     FontWeight.w700,
  //                     checked ? const Color(0xFFC7BCAC) : _G.textMed,
  //                   )
  //                   .copyWith(
  //                     decoration: checked ? TextDecoration.lineThrough : null,
  //                   ),
  //               maxLines: 3,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ),
  //         ),

  //         GestureDetector(
  //           onTap: () => _showItemOptions(context, item),
  //           behavior: HitTestBehavior.opaque,
  //           child: const Padding(
  //             padding: EdgeInsets.fromLTRB(6, 12, 12, 12),
  //             child: OnboardingLineIcon(
  //               'dots',
  //               size: 18,
  //               color: Color(0xFFB0A899),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _itemRow(
    BuildContext context,
    GroceryItem item, {
    required bool last,
  }) {
    final checked = item.checked;

    final quantity = UnitConverter.applySystemQuantity(
      item.quantity,
      item.name,
      settings.unitSystem,
    );

    final quantityStyle = _G
        .f(15, FontWeight.w700, checked ? _G.textHint : _G.textDark)
        .copyWith(decoration: checked ? TextDecoration.lineThrough : null);

    final nameStyle = _G
        .f(15, FontWeight.w700, checked ? const Color(0xFFC7BCAC) : _G.textMed)
        .copyWith(decoration: checked ? TextDecoration.lineThrough : null);

    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: _G.rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => store.toggleItem(item),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
              child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: checked ? _G.green : Colors.transparent,
                  border: checked
                      ? null
                      : Border.all(color: _G.checkBorder, width: 2),
                ),
                child: checked
                    ? const OnboardingLineIcon(
                        'check',
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (quantity.trim().isNotEmpty) ...[
                      TextSpan(text: quantity, style: quantityStyle),

                      // Quantity અને ingredient વચ્ચે margin
                      const WidgetSpan(child: SizedBox(width: 12)),
                    ],

                    TextSpan(
                      text: GroceryStore().trName(item.name),
                      style: nameStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => _showItemOptions(context, item),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(6, 12, 12, 12),
              child: OnboardingLineIcon(
                'dots',
                size: 18,
                color: Color(0xFFB0A899),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── "By meal" empty state — prompt to add recipes to the meal plan ──────────
  Widget _buildMealEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _G.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _G.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A211B).withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: const OnboardingLineIcon(
                'cal',
                size: 28,
                color: _G.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'no_meal_ingredients_yet'.tr,
              style: _G.f(20, FontWeight.w800, _G.textDark, ls: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'meal_ingredients_hint'.tr,
              textAlign: TextAlign.center,
              style: _G.f(14, FontWeight.w500, _G.textMed, h: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Get.offUntil(
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(initialIndex: 2),
                  ),
                  (r) => r.isFirst,
                );
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _G.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'cal',
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'go_to_meal_plan'.tr,
                      style: _G.f(14, FontWeight.w700, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'just_need_a_few'.tr,
              style: _G.f(12, FontWeight.w600, _G.textHint),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showAddItemSheet(context),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _G.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _G.fieldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'plus',
                      size: 17,
                      color: _G.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'add_item_manually'.tr,
                      style: _G.f(13.5, FontWeight.w700, _G.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state (general / By category) ─────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _EmptyGroceryArt(),
            const SizedBox(height: 22),
            Text(
              'your_list_is_empty'.tr,
              style: _G.f(23, FontWeight.w800, _G.textDark, ls: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'empty_list_hint'.tr,
              textAlign: TextAlign.center,
              style: _G.f(14.5, FontWeight.w500, _G.textMed, h: 1.5),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => _showAddItemSheet(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _G.primary,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _G.primary.withValues(alpha: 0.6),
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
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'add_first_ingredient'.tr,
                      style: _G.f(15, FontWeight.w700, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── More menu (dropdown) ────────────────────────────────────────────────────
  void _handleMore(BuildContext context, String v) {
    switch (v) {
      case 'share':
        _showShareSheet(context);
      case 'clearChecked':
        store.clearChecked();
        CustomSnackbar.show(
          title: 'cleared'.tr,
          message: 'checked_items_removed'.tr,
          type: SnackbarType.info,
        );
      case 'clearAll':
        _confirmClearAll(context);
    }
  }

  // Categorised text used for both the preview and the native share.
  String _shareText() {
    final byAisle = store.byAisle;
    final buf = StringBuffer('🛒 ${'my_grocery_list'.tr}\n');
    for (final aisle in store.sortedAisles) {
      final group = byAisle[aisle] ?? [];
      if (group.isEmpty) continue;
      buf.writeln('\n${_G.emoji(aisle)} ${aisle.toUpperCase()}');
      for (final e in group) {
        final tick = e.checked ? '☑' : '☐';
        final qty = e.quantity.trim().isNotEmpty ? ' — ${e.quantity}' : '';
        buf.writeln('$tick ${e.name}$qty');
      }
    }
    buf.writeln('\nShared from Recipe AI');
    return buf.toString();
  }

  void _showShareSheet(BuildContext context) {
    final byAisle = store.byAisle;
    final aisles = store.sortedAisles
        .where((a) => (byAisle[a] ?? []).isNotEmpty)
        .toList();
    final count = store.items.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'share_shopping_list'.tr,
                  style: _G.f(19, FontWeight.w800, _G.textDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F1EA),
                      shape: BoxShape.circle,
                    ),
                    child: const OnboardingLineIcon(
                      'x',
                      size: 17,
                      color: _G.textMed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Preview
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                decoration: BoxDecoration(
                  color: _G.fieldBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _G.border),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛒 ${'my_grocery_list'.tr}',
                        style: _G.f(14, FontWeight.w800, _G.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${count == 1 ? 'item_singular'.trParams({'count': '$count'}) : 'item_plural'.trParams({'count': '$count'})} · from Recipe AI',
                        style: _G.f(12, FontWeight.w600, _G.textMed),
                      ),
                      const SizedBox(height: 12),
                      for (final aisle in aisles) ...[
                        Text(
                          '${_G.emoji(aisle)} ${aisle.toUpperCase()}',
                          style: _G.f(12.5, FontWeight.w800, _G.gold),
                        ),
                        const SizedBox(height: 5),
                        for (final e in byAisle[aisle]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${e.checked ? '☑' : '☐'} ${e.name}'
                              '${e.quantity.trim().isNotEmpty ? ' — ${e.quantity}' : ''}',
                              style: _G.f(
                                13,
                                FontWeight.w500,
                                const Color(0xFF3A352D),
                                h: 1.4,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Shared from Recipe AI · recipe.ai',
                        style: _G.f(12, FontWeight.w600, _G.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Share.share(_shareText(), subject: 'My Grocery List');
              },
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _G.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const OnboardingLineIcon(
                      'share',
                      size: 19,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'share_list'.tr,
                      style: _G.f(16, FontWeight.w700, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        decoration: const BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const OnboardingLineIcon(
                'trash',
                size: 28,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'clear_all_items_q'.tr,
              style: _G.f(18, FontWeight.w800, _G.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'clear_all_confirm'.tr,
              textAlign: TextAlign.center,
              style: _G.f(13, FontWeight.w500, _G.textHint),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _G.border),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: _G.f(14, FontWeight.w700, _G.textDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      store.clearAll();
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'clear_all'.tr,
                        style: _G.f(14, FontWeight.w700, Colors.white),
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

  // ── Item options sheet ──────────────────────────────────────────────────────
  void _showItemOptions(BuildContext context, GroceryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
        decoration: const BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _handle()),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _G.goldBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        store.emojiForIngredient(item.name),
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),

                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          GroceryStore().trName(item.name),
                          style: _G.f(15, FontWeight.w800, _G.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (item.quantity.trim().isNotEmpty) item.quantity,
                            item.aisle,
                          ].join(' · '),
                          style: _G.f(12, FontWeight.w600, _G.textMed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _G.rowLine),
            _optionRow(
              Icons.edit_outlined,
              'edit_item'.tr,
              () {
                Get.back();
                _showEditItemSheet(context, item);
              },
              iconWidget: const OnboardingLineIcon(
                'pencil',
                size: 20,
                color: _G.textBody,
              ),
            ),
            _optionRow(
              item.checked ? Icons.remove_done_rounded : Icons.check_rounded,
              item.checked ? 'mark_as_not_bought'.tr : 'mark_as_bought'.tr,
              () {
                Get.back();
                store.toggleItem(item);
              },
            ),
            _optionRow(Icons.category_outlined, 'change_category'.tr, () {
              Get.back();
              _showCategoryPicker(context, item.aisle, (cat) {
                _replaceItem(item, item.name, item.quantity, cat);
              });
            }),
            _optionRow(
              Icons.delete_outline_rounded,
              'delete_item'.tr,
              () {
                Get.back();
                store.removeItem(item);
                CustomSnackbar.show(
                  title: 'removed'.tr,
                  message: 'item_removed'.trParams({'name': item.name}),
                  type: SnackbarType.info,
                );
              },
              destructive: true,
              iconWidget: const OnboardingLineIcon(
                'trash',
                size: 20,
                color: Color(0xFFE0481F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
    Widget? iconWidget,
  }) {
    final c = destructive ? const Color(0xFFE0481F) : _G.textBody;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            iconWidget ?? Icon(icon, size: 20, color: c),
            const SizedBox(width: 13),
            Text(
              label,
              style: _G.f(
                15,
                destructive ? FontWeight.w700 : FontWeight.w600,
                destructive ? const Color(0xFFE0481F) : _G.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit item sheets ───────────────────────────────────────────────────
  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final category = 'Other'.obs;
    // Mirror the name field into an Rx so the category auto-detect preview
    // rebuilds live as the user types (Obx can't observe a plain controller).
    final nameRx = ''.obs;
    nameCtrl.addListener(() => nameRx.value = nameCtrl.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        title: 'add_an_item'.tr,
        nameCtrl: nameCtrl,
        nameRx: nameRx,
        qtyCtrl: qtyCtrl,
        category: category,
        buttonLabel: 'add_to_list'.tr,
        autoDetect: (name) => store.detectAisle(name),
        onPickCategory: () =>
            _showCategoryPicker(ctx, category.value, (c) => category.value = c),
        onSubmit: () {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          store.items.add(
            GroceryItem(
              name: name,
              quantity: qtyCtrl.text.trim(),
              recipeId: '',
              aisle: category.value == 'Other'
                  ? store.detectAisle(name)
                  : category.value,
            ),
          );
          store.items.refresh();
          Navigator.pop(ctx);
          CustomSnackbar.show(
            title: 'added'.tr,
            message: 'added_to_list'.trParams({'name': name}),
            type: SnackbarType.success,
          );
        },
      ),
    );
  }

  void _showEditItemSheet(BuildContext context, GroceryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity);
    final category = item.aisle.obs;
    final nameRx = item.name.obs;
    nameCtrl.addListener(() => nameRx.value = nameCtrl.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        title: 'edit_item'.tr,
        nameCtrl: nameCtrl,
        nameRx: nameRx,
        qtyCtrl: qtyCtrl,
        category: category,
        buttonLabel: 'save_changes'.tr,
        autoDetect: (name) => store.detectAisle(name),
        onPickCategory: () =>
            _showCategoryPicker(ctx, category.value, (c) => category.value = c),
        onSubmit: () {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          _replaceItem(item, name, qtyCtrl.text.trim(), category.value);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // Edit = replace (model has no in-place update); keeps recipeId + checked.
  void _replaceItem(GroceryItem old, String name, String qty, String aisle) {
    final idx = store.items.indexOf(old);
    if (idx < 0) return;
    store.items[idx] = GroceryItem(
      name: name,
      quantity: qty,
      aisle: aisle,
      recipeId: old.recipeId,
      checked: old.checked,
    );
    store.items.refresh();
  }

  // ── Category picker sheet ────────────────────────────────────────────────────
  void _showCategoryPicker(
    BuildContext context,
    String current,
    ValueChanged<String> onPick,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        decoration: const BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Text(
                    'choose_a_category'.tr,
                    style: _G.f(19, FontWeight.w800, _G.textDark),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F1EA),
                        shape: BoxShape.circle,
                      ),
                      child: const OnboardingLineIcon(
                        'x',
                        size: 12,
                        color: _G.textMed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _kCategories.map((cat) {
                  final sel = cat == current;
                  return GestureDetector(
                    onTap: () {
                      onPick(cat);
                      Navigator.pop(ctx);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _G.noteBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _G.emoji(cat),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat,
                              style: _G.f(15, FontWeight.w600, _G.textDark),
                            ),
                          ),
                          if (sel)
                            const OnboardingLineIcon(
                              'check',
                              size: 20,
                              color: _G.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Container(
    width: 42,
    height: 5,
    decoration: BoxDecoration(
      color: const Color(0xFFE7E0D2),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// More-menu button — anchored dropdown (Share / Clear checked / Clear all)
// ─────────────────────────────────────────────────────────────────────────────
class _MoreMenuButton extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _MoreMenuButton({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();

    return GestureDetector(
      key: key,
      onTap: () {
        final box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;

        final pos = box.localToGlobal(Offset.zero);
        final screenW = MediaQuery.of(context).size.width;

        const menuWidth = 275.0;

        // Right side aligned with the button
        final right = screenW - pos.dx - box.size.width;

        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'more_menu',
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 140),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (ctx, anim, __, ___) {
            return Stack(
              children: [
                Positioned(
                  top: pos.dy + box.size.height + 6,
                  right: right,
                  child: FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      alignment: Alignment.topRight,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: menuWidth,
                          decoration: BoxDecoration(
                            color: _G.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _G.chipBorder),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1E1B18,
                                ).withValues(alpha: 0.30),
                                blurRadius: 30,
                                offset: const Offset(0, 16),
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _menuRow(
                                icon: const OnboardingLineIcon(
                                  'share',
                                  size: 19,
                                  color: _G.textBody,
                                ),
                                label: 'share_list'.tr,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onSelected('share');
                                },
                              ),

                              _menuDivider(),

                              _menuRow(
                                icon: const OnboardingLineIcon(
                                  'checkCircle',
                                  size: 19,
                                  color: _G.textBody,
                                ),
                                label: 'clear_checked_items'.tr,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onSelected('clearChecked');
                                },
                              ),

                              _menuDivider(),

                              _menuRow(
                                icon: const OnboardingLineIcon(
                                  'trash',
                                  size: 19,
                                  color: Color(0xFFE0481F),
                                ),
                                label: 'clear_all'.tr,
                                color: const Color(0xFFE0481F),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onSelected('clearAll');
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
        );
      },
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _G.chipBorder),
        ),
        child: const OnboardingLineIcon('dots', size: 20, color: _G.textDark),
      ),
    );
  }

  Widget _menuRow({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: _G.f(15, FontWeight.w600, color ?? _G.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Divider(height: 1, thickness: 1, color: _G.chipBorder);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit item form sheet (Item + Quantity + Category)
// ─────────────────────────────────────────────────────────────────────────────
class _ItemFormSheet extends StatefulWidget {
  final String title;
  final TextEditingController nameCtrl;
  final RxString nameRx;
  final TextEditingController qtyCtrl;
  final RxString category;
  final String buttonLabel;
  final String Function(String name) autoDetect;
  final VoidCallback onPickCategory;
  final VoidCallback onSubmit;

  const _ItemFormSheet({
    required this.title,
    required this.nameCtrl,
    required this.nameRx,
    required this.qtyCtrl,
    required this.category,
    required this.buttonLabel,
    required this.autoDetect,
    required this.onPickCategory,
    required this.onSubmit,
  });

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    widget.title,
                    style: _G.f(19, FontWeight.w800, _G.textDark),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F1EA),
                        shape: BoxShape.circle,
                      ),
                      child: const OnboardingLineIcon(
                        'x',
                        size: 17,
                        color: _G.textMed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('item'.tr),
              const SizedBox(height: 7),
              _field(
                widget.nameCtrl,
                'eg_paper_towels'.tr,
                focused: true,
                autofocus: true,
                keyboardType: TextInputType.text,
                validator: (v) =>
                    ValidationHelper.required(v, field: 'item'.tr),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('quantity'.tr),
                        const SizedBox(height: 7),
                        _field(widget.qtyCtrl, 'eg_qty'.tr),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('category'.tr),
                        const SizedBox(height: 7),
                        GestureDetector(
                          onTap: widget.onPickCategory,
                          child: Obx(() {
                            final typed = widget.nameRx.value.trim();
                            final cat =
                                widget.category.value == 'Other' &&
                                    typed.isNotEmpty
                                ? widget.autoDetect(typed)
                                : widget.category.value;
                            return Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _G.fieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _G.fieldBorder),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _G.emoji(cat),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: _G.f(
                                        13,
                                        FontWeight.w600,
                                        _G.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const OnboardingLineIcon(
                                    'chevDown',
                                    size: 18,
                                    color: _G.textHint,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  widget.onSubmit();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _G.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.buttonLabel,
                    style: _G.f(16, FontWeight.w700, Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t.toUpperCase(),
    style: _G.f(12, FontWeight.w700, const Color(0xFF9A938A), ls: 0.4),
  );

  Widget _field(
    TextEditingController c,
    String hint, {
    bool focused = false,
    bool autofocus = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: _G.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? _G.primary : _G.fieldBorder,
          width: focused ? 1.5 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _G.primary.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: c,
        autofocus: autofocus,
        cursorColor: _G.primary,
        style: _G.f(16, FontWeight.w600, _G.textDark),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _G.f(15, FontWeight.w400, _G.textHint),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty-groceries illustration — the cart tile with floating produce shapes,
// matched to design "57 · Groceries (empty)" incl. the `floaty` bob animation
// (translateY 0 → -7px → 0, ease-in-out; per-shape durations 4/4.6/5s, staggered
// 0/0.4/0.8s).
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyGroceryArt extends StatefulWidget {
  const _EmptyGroceryArt();

  @override
  State<_EmptyGroceryArt> createState() => _EmptyGroceryArtState();
}

class _EmptyGroceryArtState extends State<_EmptyGroceryArt>
    with TickerProviderStateMixin {
  late final List<AnimationController> _bob;

  static const _durations = [4000, 4600, 5000];
  static const _delays = [0, 400, 800];

  @override
  void initState() {
    super.initState();
    _bob = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      ),
    );
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) _bob[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _bob) {
      c.dispose();
    }
    super.dispose();
  }

  // floaty keyframe: 0% → 0, 50% → -7px, 100% → 0 (cosine ease).
  double _dy(int i) => -3.5 * (1 - math.cos(2 * math.pi * _bob[i].value));

  Widget _float(int i, Widget child) => AnimatedBuilder(
    animation: _bob[i],
    builder: (_, c) => Transform.translate(offset: Offset(0, _dy(i)), child: c),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 148,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: _cartTile()),
          Positioned(top: 6, left: 8, child: _float(0, _tomato())),
          Positioned(top: 20, right: 12, child: _float(1, _lemon())),
          Positioned(top: 88, left: 0, child: _float(2, _chilli())),
        ],
      ),
    );
  }

  Widget _cartTile() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial glow behind the tile.
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x24F2623E), Color(0x00F2623E)],
                stops: [0.0, 0.66],
              ),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFEFE6D6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A211B).withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -18,
                ),
              ],
            ),
            child: const OnboardingLineIcon(
              'cart',
              size: 38,
              color: Color(0xFFF2623E),
            ),
          ),
        ],
      ),
    );
  }

  static const _shapeShadow = BoxShadow(
    color: Color(0x662A211B), // rgba(42,33,27,.4)
    blurRadius: 16,
    offset: Offset(0, 8),
    spreadRadius: -7,
  );

  // 30px red tomato.
  Widget _tomato() => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.36, -0.4),
        colors: [Color(0xFFFF6F52), Color(0xFFE5402A)],
      ),
      boxShadow: [_shapeShadow],
    ),
  );

  // 32×23 yellow lemon (ellipse).
  Widget _lemon() => Container(
    width: 32,
    height: 23,
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.elliptical(16, 11.5)),
      gradient: RadialGradient(
        center: Alignment(-0.36, -0.4),
        colors: [Color(0xFFFFE05A), Color(0xFFEBAE14)],
      ),
      boxShadow: [_shapeShadow],
    ),
  );

  // Green chilli: rounded stem + rotated leaf.
  Widget _chilli() => SizedBox(
    width: 24,
    height: 24,
    child: Stack(
      children: [
        Positioned(
          left: 8.5,
          top: 0,
          child: Container(
            width: 7,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF3E8E4F),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          top: 1,
          left: 1,
          child: Transform.rotate(
            angle: -30 * math.pi / 180,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF54B069),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
