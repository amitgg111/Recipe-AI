import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:share_plus/share_plus.dart';

class _GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;

  const _GroceryItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final displayName = item.name
        .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), '')
        .trim();

    return TweenAnimationBuilder<double>(
      // Subtle fade + slide whenever this tile is (re)built, e.g. when it
      // first appears in the list. Purely additive, no layout/design change.
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: item.animating ? 0.6 : 1,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              leading: _IngredientAvatar(name: displayName),
              title: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: item.animating ? 0.4 : 1,
                    child: CustomText(
                      displayName,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: item.checked ? Colors.grey : null,
                    ),
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    height: 2,
                    width: item.animating || item.checked ? 250 : 0,
                    color: Colors.grey,
                  ),
                ],
              ),
              subtitle: item.quantity.isNotEmpty
                  ? CustomText(
                      item.quantity,
                      color: item.checked
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    )
                  : null,
              trailing: GestureDetector(
                onTap: onToggle,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  scale: item.checked ? 1.08 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.checked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: item.checked
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: item.checked
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1, indent: 76),
        ],
      ),
    );
  }
}

// // ─────────────────────────────────────────────────────────────────────────────
// // Ingredient emoji avatar
// // ─────────────────────────────────────────────────────────────────────────────

class _IngredientAvatar extends StatelessWidget {
  final String name;

  const _IngredientAvatar({required this.name});

  static const Map<String, List<String>> emojiKeywords = {
    // Vegetables
    '🧅': ['onion', 'shallot', 'spring onion'],
    '🧄': ['garlic'],
    '🫚': ['ginger'],
    '🍅': ['tomato'],
    '🍠': ['sweet potato'],
    '🥔': ['potato'],
    '🥕': ['carrot'],
    '🌽': ['corn', 'sweet corn'],
    '🥦': ['broccoli'],
    '🥒': ['cucumber', 'zucchini'],
    '🥬': [
      'lettuce',
      'cabbage',
      'spinach',
      'kale',
      'bok choy',
      'mustard greens',
    ],
    '🫛': ['peas', 'pea', 'green beans', 'french beans', 'snap peas'],
    '🫘': [
      'beans',
      'kidney beans',
      'rajma',
      'black beans',
      'chickpeas',
      'chana',
      'lentils',
      'dal',
      'moong',
      'toor',
      'urad',
    ],
    '🍄': ['mushroom'],
    '🍆': ['eggplant', 'aubergine', 'brinjal'],
    '🥑': ['avocado'],
    '🌶️': ['chili', 'chilli', 'pepper', 'capsicum', 'bell pepper', 'jalapeno'],

    // Fruits
    '🍎': ['apple'],
    '🍌': ['banana'],
    '🍊': ['orange', 'mandarin'],
    '🍋': ['lemon', 'lime'],
    '🍇': ['grape'],
    '🍓': ['strawberry'],
    '🫐': ['blueberry', 'blackberry'],
    '🍉': ['watermelon'],
    '🍍': ['pineapple'],
    '🥭': ['mango'],
    '🥥': ['coconut', 'coconut oil'],
    '🍑': ['peach'],
    '🍐': ['pear'],
    '🍒': ['cherry'],
    '🥝': ['kiwi'],
    '🍈': ['melon'],
    '🍏': ['green apple'],

    // Herbs
    '🌿': [
      'coriander',
      'cilantro',
      'parsley',
      'basil',
      'rosemary',
      'thyme',
      'oregano',
      'dill',
      'sage',
      'cardamom',
      'clove',
    ],
    '🌱': ['mint', 'chia'],
    '🍃': ['bay leaf', 'bay leaves'],

    // Dairy
    '🥛': ['milk', 'curd', 'yogurt', 'yoghurt', 'cream', 'buttermilk'],
    '🧈': ['butter', 'ghee'],
    '🧀': ['paneer', 'cheese', 'mozzarella', 'cheddar', 'parmesan'],

    // Eggs
    '🥚': ['egg'],

    // Grains
    '🍚': ['rice', 'sugar'],
    '🌾': [
      'flour',
      'wheat',
      'atta',
      'maida',
      'oats',
      'barley',
      'quinoa',
      'millet',
      'ragi',
      'jowar',
      'bajra',
    ],
    '🍞': ['bread', 'bun'],
    '🍜': ['pasta', 'noodle', 'vermicelli'],

    // Nuts & Seeds
    '🥜': ['cashew', 'peanut', 'pistachio', 'nut', 'hazelnut', 'macadamia'],
    '🌰': [
      'almond',
      'walnut',
      'sesame',
      'pumpkin seed',
      'sunflower seed',
      'flax seed',
      'cumin',
      'mustard',
      'fennel',
      'fenugreek',
    ],

    // Oils
    '🫒': ['olive oil'],

    '🫙': [
      'oil',
      'sunflower oil',
      'vegetable oil',
      'canola oil',
      'mustard oil',
    ],

    // Sweeteners
    '🍯': ['honey', 'jaggery', 'syrup'],
    '🍫': ['chocolate', 'cocoa'],

    // Spices
    '🟡': ['turmeric'],
    '🪵': ['cinnamon'],

    // Meat
    '🍗': ['chicken'],
    '🦃': ['turkey'],
    '🥩': ['beef'],
    '🍖': ['mutton', 'lamb'],
    '🥓': ['bacon', 'ham'],

    // Seafood
    '🐟': ['fish', 'salmon', 'tuna'],
    '🦐': ['shrimp', 'prawn'],
    '🦀': ['crab'],
    '🦑': ['squid', 'calamari'],
    '🦞': ['lobster'],

    // Drinks
    '☕': ['coffee'],
    '🍵': ['tea', 'green tea'],
    '🧃': ['juice'],
    '🍷': ['wine'],

    // Sauces
    '🥫': [
      'ketchup',
      'sauce',
      'soy sauce',
      'tomato sauce',
      'mayonnaise',
      'vinegar',
    ],

    // Baking
    '🧁': ['baking powder', 'baking soda'],
    '🌼': ['vanilla'],
  };

  String get emoji {
    final ingredient = name.toLowerCase().trim();

    for (final entry in emojiKeywords.entries) {
      for (final keyword in entry.value) {
        if (ingredient.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return '🥘';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: CustomText(emoji, fontSize: 24),
    );
  }
}

// // ─────────────────────────────────────────────────────────────────────────────
// // Empty state
// // ─────────────────────────────────────────────────────────────────────────────

class _EmptyGroceries extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGroceries({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 16),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              CustomText(
                'Your grocery list is empty',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              CustomText(
                'Add ingredients from a recipe or tap + to add items manually.',
                textAlign: TextAlign.center,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const CustomText('Add item', color: Colors.white),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GrocerySort { aisle, recipe, aToZ, recentlyAdded }

class GroceriesScreen extends StatelessWidget {
  final RxBool _showRecipes = false.obs;
  final Rx<GrocerySort> _currentSort = GrocerySort.aisle.obs;

  GroceriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<GroceryStore>();
    final homeController = Get.find<HomeController>();

    void shareGroceries() {
      final items = store.items;
      if (items.isEmpty) return;

      final text =
          '''
🛒 GROCERY LIST

${items.map((e) => '☐ ${e.name} ${e.quantity.isNotEmpty ? "(${e.quantity})" : ""}').join('\n')}

Generated with Recipe AI ❤️
''';
      Share.share(text, subject: 'My Grocery List');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const CustomText(
          'Grocery List',
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _BouncyTap(
              onTap: () => _showAddItemSheet(context, store, ''),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.textPrimary(context),
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _AppBarCircleBtn(
              icon: Icons.share_outlined,
              onTap: shareGroceries,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AppBarCircleBtn(
              icon: Icons.more_horiz,
              onTap: () => _showMoreMenu(context, store),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final totalCount = store.items.length;
        if (totalCount == 0) {
          return _EmptyGroceries(
            onAdd: () => _showAddItemSheet(context, store, ''),
          );
        }

        final checkedItems = store.items.where((i) => i.checked).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Recipes Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Recipes',
                    isSelected: _showRecipes.value,
                    onTap: () => _showRecipes.toggle(),
                  ),
                ],
              ),
            ),

            // Recipes Horizontal List
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: !_showRecipes.value
                  ? const SizedBox.shrink()
                  : _buildRecipesSection(store, homeController),
            ),

            const Divider(height: 24),

            // Count + Sort
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    '$totalCount item${totalCount == 1 ? '' : 's'}',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showSortBottomSheet(context),
                    icon: const Icon(Icons.swap_vert, size: 16),
                    label: Obx(
                      () => CustomText(_getSortLabel(_currentSort.value)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            if (_currentSort.value == GrocerySort.aisle)
              _buildAisleSections(store, checkedItems)
            else
              _buildFlatList(store, checkedItems),
          ],
        );
      }),
    );
  }

  // ==================== AISLE SECTIONS (Exact match to your images) ====================
  Widget _buildAisleSections(
    GroceryStore store,
    List<GroceryItem> checkedItems,
  ) {
    return Column(
      children: [
        ...store.sortedAisles.map((aisle) {
          final itemsInAisle = (store.byAisle[aisle] ?? [])
              .where((i) => !i.checked)
              .toList();

          if (itemsInAisle.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: CustomText(
                  aisle.toUpperCase(),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.blue.shade700,
                ),
              ),
              for (final item in itemsInAisle)
                _GroceryItemTile(
                  item: item,
                  onToggle: () => store.toggleItem(item),
                ),
            ],
          );
        }),

        // ── CHECKED section (added) ──────────────────────────────
        if (checkedItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'CHECKED',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Colors.grey.shade500,
                ),
                GestureDetector(
                  onTap: () => store.clearChecked(),
                  child: CustomText(
                    'Clear Checked',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          for (final item in checkedItems)
            _GroceryItemTile(
              item: item,
              onToggle: () => store.toggleItem(item),
            ),
        ],
      ],
    );
  }

  Widget _buildFlatList(GroceryStore store, List<GroceryItem> checkedItems) {
    final sortedItems = _getSortedItems(store);

    return Column(
      children: [
        for (final item in sortedItems.where((i) => !i.checked))
          _GroceryItemTile(item: item, onToggle: () => store.toggleItem(item)),

        if (checkedItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'CHECKED',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Colors.grey.shade500,
                ),
                GestureDetector(
                  onTap: () => store.clearChecked(),
                  child: CustomText(
                    'Clear Checked',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          for (final item in checkedItems)
            _GroceryItemTile(
              item: item,
              onToggle: () => store.toggleItem(item),
            ),
        ],
      ],
    );
  }

  Widget _buildRecipesSection(
    GroceryStore store,
    HomeController homeController,
  ) {
    final recipeIds = store.items
        .map((e) => e.recipeId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final recipesWithGroceries = homeController.recipes
        .where((recipe) => recipeIds.contains(recipe.id))
        .toList();

    if (recipesWithGroceries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CustomText('No recipes in list', color: Colors.grey),
      );
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recipesWithGroceries.length,
        itemBuilder: (context, index) {
          final recipe = recipesWithGroceries[index];
          return GestureDetector(
            onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // Replace with your RecipeImage widget
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(recipe.imageUrl ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _BouncyTap(
                            onTap: () =>
                                store.removeGroceriesByRecipe(recipe.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CustomText(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<GroceryItem> _getSortedItems(GroceryStore store) {
    final unchecked = store.items.where((i) => !i.checked).toList();

    switch (_currentSort.value) {
      case GrocerySort.aisle:
        return unchecked;
      case GrocerySort.recipe:
        return unchecked..sort((a, b) {
          if (a.recipeId.isEmpty && b.recipeId.isEmpty) return 0;
          if (a.recipeId.isEmpty) return 1;
          if (b.recipeId.isEmpty) return -1;
          return a.recipeId.compareTo(b.recipeId);
        });
      case GrocerySort.aToZ:
        return unchecked..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case GrocerySort.recentlyAdded:
        return unchecked.reversed.toList();
    }
  }

  String _getSortLabel(GrocerySort sort) {
    switch (sort) {
      case GrocerySort.aisle:
        return 'Aisle';
      case GrocerySort.recipe:
        return 'Recipe';
      case GrocerySort.aToZ:
        return 'A to Z';
      case GrocerySort.recentlyAdded:
        return 'Recently Added';
    }
  }

  // ====================== Bottom Sheets ======================
  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const CustomText(
              'Sort by',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 12),
            _SortOptionTile(
              title: 'Aisle',
              isSelected: _currentSort.value == GrocerySort.aisle,
              onTap: () {
                _currentSort.value = GrocerySort.aisle;
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              title: 'Recipe',
              isSelected: _currentSort.value == GrocerySort.recipe,
              onTap: () {
                _currentSort.value = GrocerySort.recipe;
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              title: 'A to Z',
              isSelected: _currentSort.value == GrocerySort.aToZ,
              onTap: () {
                _currentSort.value = GrocerySort.aToZ;
                Navigator.pop(context);
              },
            ),
            _SortOptionTile(
              title: 'Recently Added',
              isSelected: _currentSort.value == GrocerySort.recentlyAdded,
              onTap: () {
                _currentSort.value = GrocerySort.recentlyAdded;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    GroceryStore store,
    String recipeId,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const CustomText(
                  'Add Item',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quantity (e.g. 2 cups)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        final name = nameCtrl.text.trim();
                        final aisle = store.detectAisle(name);
                        store.items.add(
                          GroceryItem(
                            name: name,
                            quantity: qtyCtrl.text.trim(),
                            recipeId: recipeId,
                            aisle: aisle,
                          ),
                        );
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: const CustomText('Add to list'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoreMenu(BuildContext context, GroceryStore store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const CustomText('Clear checked items'),
              onTap: () {
                Navigator.pop(context);
                store.clearChecked();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const CustomText('Clear all items', color: Colors.red),
              onTap: () {
                Navigator.pop(context);
                store.clearAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Helper Widgets ======================
  // (All your existing helper widgets)
}

class _BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BouncyTap({required this.child, required this.onTap});

  @override
  State<_BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<_BouncyTap> {
  double _scale = 1.0;
  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.88),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

class _AppBarCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _BouncyTap(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.border(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : null,
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: isSelected ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  const _SortOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: CustomText(title, fontWeight: FontWeight.w500),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// Keep your existing _GroceryItemTile, _IngredientAvatar, _EmptyGroceries widgets here...
// (Copy them from your previous code)
