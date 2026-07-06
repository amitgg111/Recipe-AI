import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
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

  static const _emoji = {
    'Fresh Produce': '🥬',
    'Dairy, Eggs & Fridge': '🥛',
    'Herbs & Spices': '🌿',
    'Oils & Vinegars': '🫒',
    'Flours & Sugars': '🧁',
    'Pantry': '🥫',
    'Meat & Seafood': '🥩',
    'Grains & Pasta': '🍝',
    'Bakery': '🍞',
    'Frozen': '🧊',
    'Beverages': '🥤',
    'Snacks & Sweets': '🍫',
    'Household': '🧻',
    'Uncategorized': '🛒',
  };
  static String emoji(String aisle) => _emoji[aisle] ?? '🛒';

  static TextStyle f(double s, FontWeight w, Color c, {double? h, double? ls}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);
}

// The categories offered when adding / editing an item (drive aisle grouping).
const _kCategories = [
  'Fresh Produce',
  'Dairy, Eggs & Fridge',
  'Meat & Seafood',
  'Grains & Pasta',
  'Pantry',
  'Herbs & Spices',
  'Oils & Vinegars',
  'Flours & Sugars',
  'Bakery',
  'Frozen',
  'Beverages',
  'Snacks & Sweets',
  'Household',
  'Uncategorized',
];

class GroceriesScreen extends StatelessWidget {
  GroceriesScreen({super.key});

  final GroceryStore store = Get.find<GroceryStore>();
  final HomeController homeController = Get.find<HomeController>();
  final SettingsController settings = Get.find<SettingsController>();

  // true = group by meal/recipe, false = group by category/aisle
  final RxBool _byMeal = true.obs;

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
        Text('Groceries', style: _G.f(22, FontWeight.w800, _G.textDark, ls: -0.4)),
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
                const Icon(Icons.add, size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Text('Add item', style: _G.f(13, FontWeight.w700, Colors.white)),
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
        _toggleChip('By meal', true),
        const SizedBox(width: 7),
        _toggleChip('By category', false),
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
          style: _G.f(12.5, on ? FontWeight.w800 : FontWeight.w700,
              on ? Colors.white : _G.textBody),
        ),
      ),
    );
  }

  // ── By meal (grouped by recipe) ───────────────────────────────────────────
  List<Widget> _buildByMeal(BuildContext context, List<GroceryItem> items) {
    final order = <String>[];
    final groups = <String, List<GroceryItem>>{};
    for (final it in items) {
      final key = it.recipeId;
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(it);
    }

    final widgets = <Widget>[];
    final extra = <GroceryItem>[];

    for (final key in order) {
      final recipe = key.isEmpty ? null : _recipeById(key);
      if (recipe == null) {
        extra.addAll(groups[key]!);
        continue;
      }
      widgets.add(_recipeHeader(recipe, groups[key]!.length));
      widgets.add(_itemCard(context, groups[key]!));
      widgets.add(const SizedBox(height: 18));
    }

    if (extra.isNotEmpty) {
      widgets.add(_extraHeader());
      widgets.add(_itemCard(context, extra));
      widgets.add(const SizedBox(height: 18));
    }
    return widgets;
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
                Text(recipe.title,
                    style: _G.f(14, FontWeight.w800, _G.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$count item${count == 1 ? '' : 's'}',
                    style: _G.f(11, FontWeight.w600, _G.textHint)),
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
                color: _G.noteBg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, size: 18, color: _G.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extra items', style: _G.f(14, FontWeight.w800, _G.textDark)),
                Text('Added by you',
                    style: _G.f(11, FontWeight.w600, _G.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── By category (grouped by aisle) ─────────────────────────────────────────
  List<Widget> _buildByCategory(BuildContext context, List<GroceryItem> items) {
    final byAisle = store.byAisle;
    final aisles = store.sortedAisles;
    final widgets = <Widget>[];
    for (final aisle in aisles) {
      final group = byAisle[aisle] ?? [];
      if (group.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(_G.emoji(aisle), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(aisle, style: _G.f(14, FontWeight.w800, _G.textDark)),
              const SizedBox(width: 6),
              Text('· ${group.length}',
                  style: _G.f(12, FontWeight.w600, _G.textHint)),
            ],
          ),
        ),
      );
      widgets.add(_itemCard(context, group));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
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

  Widget _itemRow(BuildContext context, GroceryItem item, {required bool last}) {
    final checked = item.checked;
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: _G.rowLine)),
      ),
      child: Row(
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
                  border:
                      checked ? null : Border.all(color: _G.checkBorder, width: 2),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                item.name,
                style: _G
                    .f(14, FontWeight.w700, checked ? _G.textHint : _G.textDark)
                    .copyWith(
                        decoration:
                            checked ? TextDecoration.lineThrough : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (item.quantity.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              // Convert the stored quantity to the active unit system on
              // display (reactive via the enclosing Obx over store.items).
              UnitConverter.applySystem(item.quantity, settings.unitSystem),
              style: _G
                  .f(13, FontWeight.w700,
                      checked ? const Color(0xFFC7BCAC) : _G.textMed)
                  .copyWith(
                      decoration: checked ? TextDecoration.lineThrough : null),
            ),
          ],
          GestureDetector(
            onTap: () => _showItemOptions(context, item),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(6, 12, 12, 12),
              child: Icon(Icons.more_horiz, size: 18, color: Color(0xFFB0A899)),
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
              child: const Icon(Icons.calendar_today_rounded,
                  size: 34, color: _G.primary),
            ),
            const SizedBox(height: 20),
            Text('No meal ingredients yet',
                style: _G.f(20, FontWeight.w800, _G.textDark, ls: -0.4)),
            const SizedBox(height: 8),
            Text(
              'Add recipes to your meal plan and their ingredients show up '
              'here, grouped by meal.',
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
                    const Icon(Icons.calendar_today_rounded,
                        size: 17, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Go to meal plan',
                        style: _G.f(14, FontWeight.w700, Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Just need a few things?',
                style: _G.f(12, FontWeight.w600, _G.textHint)),
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
                    const Icon(Icons.add, size: 17, color: _G.primary),
                    const SizedBox(width: 7),
                    Text('Add an item manually',
                        style: _G.f(13.5, FontWeight.w700, _G.textDark)),
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _G.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _G.border),
                boxShadow: [
                  BoxShadow(
                    color: _G.textDark.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 42, color: _G.primary),
            ),
            const SizedBox(height: 22),
            Text('Your list is empty',
                style: _G.f(23, FontWeight.w800, _G.textDark, ls: -0.4)),
            const SizedBox(height: 8),
            Text(
              "Pull ingredients from your meal plan or add items yourself — we'll keep everything tidy for the store.",
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
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Add first ingredient',
                        style: _G.f(15, FontWeight.w700, Colors.white)),
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
            title: 'Cleared',
            message: 'Checked items removed',
            type: SnackbarType.info);
      case 'clearAll':
        _confirmClearAll(context);
    }
  }

  // Categorised text used for both the preview and the native share.
  String _shareText() {
    final byAisle = store.byAisle;
    final buf = StringBuffer('🛒 My Grocery List\n');
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
    final aisles =
        store.sortedAisles.where((a) => (byAisle[a] ?? []).isNotEmpty).toList();
    final count = store.items.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.78),
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
                Text('Share shopping list',
                    style: _G.f(19, FontWeight.w800, _G.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF4F1EA), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 17, color: _G.textMed),
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
                      Text('🛒 My Grocery List',
                          style: _G.f(14, FontWeight.w800, _G.textDark)),
                      const SizedBox(height: 2),
                      Text('$count item${count == 1 ? '' : 's'} · from Recipe AI',
                          style: _G.f(12, FontWeight.w600, _G.textMed)),
                      const SizedBox(height: 12),
                      for (final aisle in aisles) ...[
                        Text('${_G.emoji(aisle)} ${aisle.toUpperCase()}',
                            style: _G.f(12.5, FontWeight.w800, _G.gold)),
                        const SizedBox(height: 5),
                        for (final e in byAisle[aisle]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${e.checked ? '☑' : '☐'} ${e.name}'
                              '${e.quantity.trim().isNotEmpty ? ' — ${e.quantity}' : ''}',
                              style: _G.f(13, FontWeight.w500,
                                  const Color(0xFF3A352D), h: 1.4),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      Text('Shared from Recipe AI · recipe.ai',
                          style: _G.f(12, FontWeight.w600, _G.textHint)),
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
                    const Icon(Icons.ios_share_rounded,
                        size: 19, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Share list',
                        style: _G.f(16, FontWeight.w700, Colors.white)),
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
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 28, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text('Clear all items?', style: _G.f(18, FontWeight.w800, _G.textDark)),
            const SizedBox(height: 6),
            Text('This removes every item from your grocery list.',
                textAlign: TextAlign.center,
                style: _G.f(13, FontWeight.w500, _G.textHint)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _G.border),
                      ),
                      child: Text('Cancel',
                          style: _G.f(14, FontWeight.w700, _G.textDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      store.clearAll();
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Clear all',
                          style: _G.f(14, FontWeight.w700, Colors.white)),
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
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.shopping_basket_outlined,
                        size: 18, color: _G.gold),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: _G.f(15, FontWeight.w800, _G.textDark),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
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
            _optionRow(Icons.edit_outlined, 'Edit item', () {
              Navigator.pop(context);
              _showEditItemSheet(context, item);
            }),
            _optionRow(
              item.checked ? Icons.remove_done_rounded : Icons.check_rounded,
              item.checked ? 'Mark as not bought' : 'Mark as bought',
              () {
                Navigator.pop(context);
                store.toggleItem(item);
              },
            ),
            _optionRow(Icons.category_outlined, 'Change category', () {
              Navigator.pop(context);
              _showCategoryPicker(context, item.aisle, (cat) {
                _replaceItem(item, item.name, item.quantity, cat);
              });
            }),
            _optionRow(Icons.delete_outline_rounded, 'Delete item', () {
              Navigator.pop(context);
              store.removeItem(item);
              CustomSnackbar.show(
                  title: 'Removed',
                  message: '${item.name} removed',
                  type: SnackbarType.info);
            }, destructive: true),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(IconData icon, String label, VoidCallback onTap,
      {bool destructive = false}) {
    final c = destructive ? const Color(0xFFE0481F) : _G.textBody;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 13),
            Text(label,
                style: _G.f(15, destructive ? FontWeight.w700 : FontWeight.w600,
                    destructive ? const Color(0xFFE0481F) : _G.textDark)),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit item sheets ───────────────────────────────────────────────────
  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final category = 'Uncategorized'.obs;
    // Mirror the name field into an Rx so the category auto-detect preview
    // rebuilds live as the user types (Obx can't observe a plain controller).
    final nameRx = ''.obs;
    nameCtrl.addListener(() => nameRx.value = nameCtrl.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemFormSheet(
        title: 'Add an item',
        nameCtrl: nameCtrl,
        nameRx: nameRx,
        qtyCtrl: qtyCtrl,
        category: category,
        buttonLabel: 'Add to list',
        autoDetect: (name) => store.detectAisle(name),
        onPickCategory: () =>
            _showCategoryPicker(ctx, category.value, (c) => category.value = c),
        onSubmit: () {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          store.items.add(GroceryItem(
            name: name,
            quantity: qtyCtrl.text.trim(),
            recipeId: '',
            aisle: category.value == 'Uncategorized'
                ? store.detectAisle(name)
                : category.value,
          ));
          store.items.refresh();
          Navigator.pop(ctx);
          CustomSnackbar.show(
              title: 'Added',
              message: '$name added to your list',
              type: SnackbarType.success);
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
        title: 'Edit item',
        nameCtrl: nameCtrl,
        nameRx: nameRx,
        qtyCtrl: qtyCtrl,
        category: category,
        buttonLabel: 'Save changes',
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
      BuildContext context, String current, ValueChanged<String> onPick) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
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
                  Text('Choose a category',
                      style: _G.f(19, FontWeight.w800, _G.textDark)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF4F1EA), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 17, color: _G.textMed),
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
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: sel ? _G.noteBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(_G.emoji(cat),
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(cat,
                                style: _G.f(15, FontWeight.w600, _G.textDark)),
                          ),
                          if (sel)
                            const Icon(Icons.check_rounded,
                                size: 20, color: _G.primary),
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
            borderRadius: BorderRadius.circular(3)),
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
        showMenu<String>(
          context: context,
          color: _G.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          position: RelativeRect.fromLTRB(pos.dx - 170,
              pos.dy + box.size.height + 6, pos.dx + box.size.width, 0),
          items: [
            _mi('share', Icons.ios_share_rounded, 'Share list'),
            _mi('clearChecked', Icons.check_circle_outline_rounded,
                'Clear checked items'),
            _mi('clearAll', Icons.delete_outline_rounded, 'Clear all',
                destructive: true),
          ],
        ).then((v) {
          if (v != null) onSelected(v);
        });
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _G.chipBorder),
        ),
        child: const Icon(Icons.more_horiz, size: 20, color: _G.textDark),
      ),
    );
  }

  PopupMenuItem<String> _mi(String value, IconData icon, String label,
      {bool destructive = false}) {
    final c = destructive ? const Color(0xFFE0481F) : _G.textBody;
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 19, color: c),
          const SizedBox(width: 12),
          Text(label,
              style: _G.f(15, FontWeight.w600,
                  destructive ? const Color(0xFFE0481F) : _G.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit item form sheet (Item + Quantity + Category)
// ─────────────────────────────────────────────────────────────────────────────
class _ItemFormSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: _G.card,
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
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(title, style: _G.f(19, FontWeight.w800, _G.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF4F1EA), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 17, color: _G.textMed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Item'),
            const SizedBox(height: 7),
            _field(nameCtrl, 'e.g. Paper towels', focused: true, autofocus: true),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Quantity'),
                      const SizedBox(height: 7),
                      _field(qtyCtrl, 'e.g. 2'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Category'),
                      const SizedBox(height: 7),
                      GestureDetector(
                        onTap: onPickCategory,
                        child: Obx(() {
                          final typed = nameRx.value.trim();
                          final cat = category.value == 'Uncategorized' &&
                                  typed.isNotEmpty
                              ? autoDetect(typed)
                              : category.value;
                          return Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _G.fieldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _G.fieldBorder),
                            ),
                            child: Row(
                              children: [
                                Text(_G.emoji(cat),
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(cat,
                                      style: _G.f(
                                          13, FontWeight.w600, _G.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const Icon(Icons.expand_more_rounded,
                                    size: 18, color: _G.textHint),
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
              onTap: onSubmit,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _G.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(buttonLabel,
                    style: _G.f(16, FontWeight.w700, Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: _G.f(12, FontWeight.w700, const Color(0xFF9A938A), ls: 0.4));

  Widget _field(TextEditingController c, String hint,
      {bool focused = false, bool autofocus = false}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: _G.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: focused ? _G.primary : _G.fieldBorder,
            width: focused ? 1.5 : 1),
        boxShadow: focused
            ? [
                BoxShadow(
                    color: _G.primary.withValues(alpha: 0.1),
                    blurRadius: 0,
                    spreadRadius: 3),
              ]
            : null,
      ),
      child: TextField(
        controller: c,
        autofocus: autofocus,
        cursorColor: _G.primary,
        style: _G.f(16, FontWeight.w600, _G.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _G.f(15, FontWeight.w400, _G.textHint),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
