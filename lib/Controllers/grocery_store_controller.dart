// grocery_store.dart
// Firebase-backed grocery store.

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';

class GroceryItem {
  final String name;
  final String quantity;
  final String aisle;
  final String recipeId;
  bool checked;
  bool animating;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.aisle,
    required this.recipeId,
    this.checked = false,

    this.animating = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'aisle': aisle,
      'recipeId': recipeId,
      'checked': checked,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      aisle: map['aisle'] ?? '',
      recipeId: map['recipeId'] ?? '',
      checked: map['checked'] ?? false,
    );
  }
}

class GroceryStore extends GetxController {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final GroceryStore _instance = GroceryStore._internal();
  factory GroceryStore() => _instance;
  GroceryStore._internal();

  // ── State ──────────────────────────────────────────────────────────────────
  final RxList<GroceryItem> items = <GroceryItem>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadFromFirebase();
  }

  // ── Firebase persistence ───────────────────────────────────────────────────
  void _loadFromFirebase() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('groceries')
        .snapshots()
        .listen((snapshot) {
          items.value = snapshot.docs
              .map((doc) => GroceryItem.fromMap(doc.data()))
              .toList();
        });
  }

  bool _saving = false;
  bool _savePending = false;

  Future<void> _saveToFirebase() async {
    // Single-flight guard: if a save is already running, flag that another is
    // needed and let the in-flight one re-run once when it finishes. This
    // coalesces overlapping saves so two concurrent read-delete-readd batches
    // can never race and duplicate the whole grocery list in Firestore.
    if (_saving) {
      _savePending = true;
      return;
    }
    _saving = true;
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      final batch = _firestore.batch();
      final ref =
          _firestore.collection('users').doc(uid).collection('groceries');

      // Clear existing
      final existing = await ref.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Add all items
      for (final item in items) {
        batch.set(ref.doc(), item.toMap());
      }

      await batch.commit();
    } finally {
      _saving = false;
      if (_savePending) {
        _savePending = false;
        await _saveToFirebase();
      }
    }
  }

  // ── Aisle keyword map ──────────────────────────────────────────────────────
  static const Map<String, String> _aisleMap = {
    // Fresh produce
    'onion': 'Produce',
    'tomato': 'Produce',
    'ginger': 'Produce',
    'garlic': 'Produce',
    'coriander leaves': 'Produce',
    'cilantro': 'Produce',
    'lemon': 'Produce',
    'lime': 'Produce',
    'spinach': 'Produce',
    'potato': 'Produce',
    'carrot': 'Produce',
    'capsicum': 'Produce',
    'chilli': 'Produce',
    'chili': 'Produce',
    'mint': 'Produce',
    'parsley': 'Produce',
    'mushroom': 'Produce',
    'broccoli': 'Produce',
    'celery': 'Produce',
    'cucumber': 'Produce',
    'zucchini': 'Produce',
    'pea': 'Produce',
    // Dairy
    'cream': 'Dairy & Eggs',
    'paneer': 'Dairy & Eggs',
    'butter': 'Dairy & Eggs',
    'milk': 'Dairy & Eggs',
    'cheese': 'Dairy & Eggs',
    'yogurt': 'Dairy & Eggs',
    'curd': 'Dairy & Eggs',
    'egg': 'Dairy & Eggs',
    'ghee': 'Dairy & Eggs',
    // Herbs & spices
    'cardamom': 'Spices & Seasonings',
    'cinnamon': 'Spices & Seasonings',
    'clove': 'Spices & Seasonings',
    'bay leaf': 'Spices & Seasonings',
    'turmeric': 'Spices & Seasonings',
    'cumin': 'Spices & Seasonings',
    'coriander powder': 'Spices & Seasonings',
    'garam masala': 'Spices & Seasonings',
    'kasuri methi': 'Spices & Seasonings',
    'fenugreek': 'Spices & Seasonings',
    'chilli powder': 'Spices & Seasonings',
    'chili powder': 'Spices & Seasonings',
    'paprika': 'Spices & Seasonings',
    'salt': 'Spices & Seasonings',
    'pepper': 'Spices & Seasonings',
    'oregano': 'Spices & Seasonings',
    'thyme': 'Spices & Seasonings',
    'basil': 'Spices & Seasonings',
    'rosemary': 'Spices & Seasonings',
    'nutmeg': 'Spices & Seasonings',
    'saffron': 'Spices & Seasonings',
    'star anise': 'Spices & Seasonings',
    'mustard seed': 'Spices & Seasonings',
    'fennel': 'Spices & Seasonings',
    // Oils & vinegars
    ' oil': 'Pantry / Canned & Jarred',
    'vinegar': 'Pantry / Canned & Jarred',
    'olive oil': 'Pantry / Canned & Jarred',
    'sesame oil': 'Pantry / Canned & Jarred',
    // Flours & sugars
    'sugar': 'Pantry / Canned & Jarred',
    'jaggery': 'Pantry / Canned & Jarred',
    'flour': 'Pantry / Canned & Jarred',
    'honey': 'Pantry / Canned & Jarred',
    'corn starch': 'Pantry / Canned & Jarred',
    'baking powder': 'Pantry / Canned & Jarred',
    'baking soda': 'Pantry / Canned & Jarred',
    // Pantry
    'cashew': 'Pantry / Canned & Jarred',
    'almond': 'Pantry / Canned & Jarred',
    'tomato paste': 'Pantry / Canned & Jarred',
    'coconut milk': 'Pantry / Canned & Jarred',
    'stock': 'Pantry / Canned & Jarred',
    'broth': 'Pantry / Canned & Jarred',
    'soy sauce': 'Pantry / Canned & Jarred',
    'bread': 'Pantry / Canned & Jarred',
    // Grains & Pasta
    'rice': 'Grains & Pasta',
    'pasta': 'Grains & Pasta',
    'noodle': 'Grains & Pasta',
    'spaghetti': 'Grains & Pasta',
    'macaroni': 'Grains & Pasta',
    'dal': 'Grains & Pasta',
    'lentil': 'Grains & Pasta',
    'oats': 'Grains & Pasta',
    'quinoa': 'Grains & Pasta',
    'couscous': 'Grains & Pasta',
    'barley': 'Grains & Pasta',
    // Meat & Seafood (existing aisle — previously had no detection keywords)
    'chicken': 'Meat & Poultry',
    'beef': 'Meat & Poultry',
    'pork': 'Meat & Poultry',
    'lamb': 'Meat & Poultry',
    'mutton': 'Meat & Poultry',
    'turkey': 'Meat & Poultry',
    'bacon': 'Meat & Poultry',
    'sausage': 'Meat & Poultry',
    'mince': 'Meat & Poultry',
    'steak': 'Meat & Poultry',
    'salmon': 'Seafood',
    'tuna': 'Seafood',
    'shrimp': 'Seafood',
    'prawn': 'Seafood',
    'fish': 'Seafood',
    'crab': 'Seafood',
    'squid': 'Seafood',
    // Bakery (existing aisle — previously had no detection keywords)
    'bun': 'Bakery',
    'bagel': 'Bakery',
    'croissant': 'Bakery',
    'tortilla': 'Bakery',
    'baguette': 'Bakery',
    'muffin': 'Bakery',
    // Frozen (existing aisle — previously had no detection keywords)
    'frozen': 'Frozen',
    'ice cream': 'Frozen',
    // Beverages
    'juice': 'Beverages',
    'soda': 'Beverages',
    'cola': 'Beverages',
    'coffee': 'Beverages',
    'sparkling water': 'Beverages',
    'wine': 'Beverages',
    'beer': 'Beverages',
    // Snacks & Sweets
    'chocolate': 'Snacks & Sweets',
    'candy': 'Snacks & Sweets',
    'cookie': 'Snacks & Sweets',
    'biscuit': 'Snacks & Sweets',
    'chips': 'Snacks & Sweets',
    'crisps': 'Snacks & Sweets',
    // Household (existing aisle — previously had no detection keywords)
    'foil': 'Household',
    'napkin': 'Household',
    'detergent': 'Household',
    'paper towel': 'Household',
  };

  static const List<String> _aisleOrder = [
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

  // ── Aisle detection ────────────────────────────────────────────────────────
  String detectAisle(String ingredient) {
    final lower = ingredient.toLowerCase();
    // longest match first to avoid 'oil' matching before 'olive oil'
    final sorted = _aisleMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in sorted) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'Other';
  }

  // ── Aisle / category emoji (shared with the groceries + recipe screens) ─────
  static const Map<String, String> _aisleEmoji = {
    'Produce': '🥬',
    'Meat & Poultry': '🥩',
    'Seafood': '🐟',
    'Dairy & Eggs': '🥛',
    'Pantry / Canned & Jarred': '🥫',
    'Grains & Pasta': '🌾',
    'Spices & Seasonings': '🧂',
    'Frozen': '🧊',
    'Bakery': '🍞',
    'Beverages': '🥤',
    'Snacks & Sweets': '🍫',
    'Household': '🧻',
    'Other': '📦',
  };

  /// Emoji icon for a category/aisle name (falls back to a cart).
  static String aisleEmoji(String aisle) => _aisleEmoji[aisle] ?? '🛒';

  /// Convenience: the category emoji for a raw ingredient string.
  String emojiForIngredient(String ingredient) =>
      aisleEmoji(detectAisle(ingredient));

  // ── Ingredient parsing ─────────────────────────────────────────────────────
  /// Splits "1 tablespoon (15 ml) oil" → name="oil", qty="1 tablespoon"
  (String name, String qty) parseIngredient(String raw) {
    // Strip parenthetical notes and brackets (both closed and unclosed)
    final cleaned = raw
        .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length < 2) return (cleaned, '');

    final first = parts[0];
    final isNum = RegExp(r'^[\d½⅓⅔¼¾⅛⅜⅝⅞./]+$').hasMatch(first);
    if (!isNum) return (cleaned, '');

    const units = {
      'tablespoon',
      'tablespoons',
      'tbsp',
      'teaspoon',
      'teaspoons',
      'tsp',
      'cup',
      'cups',
      'g',
      'kg',
      'ml',
      'l',
      'oz',
      'lb',
      'inch',
      'small',
      'large',
      'medium',
      'cloves',
      'clove',
      'piece',
      'pieces',
    };

    String qty;
    String name;
    if (parts.length > 2 && units.contains(parts[1].toLowerCase())) {
      qty = '${parts[0]} ${parts[1]}';
      name = parts.sublist(2).join(' ').trim();
    } else {
      qty = parts[0];
      name = parts.sublist(1).join(' ').trim();
    }
    name = name
        .replaceAll(RegExp(r'\s*[\(\[].*?([\)\]]|$)\s*'), '')
        .replaceAll(RegExp(r'[,;]+$'), '')
        .trim();
    return (name.isEmpty ? cleaned : name, qty);
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  /// Add ingredients from a recipe; skips duplicates by name (case-insensitive).
  // void addFromRecipe(List<String> ingredients) {
  //   for (final raw in ingredients) {
  //     final (name, qty) = parseIngredient(raw);
  //     final exists = items.any(
  //       (i) => i.name.toLowerCase() == name.toLowerCase(),
  //     );
  //     if (!exists) {
  //       items.add(
  //         GroceryItem(name: name, quantity: qty, aisle: detectAisle(raw)),
  //       );
  //     }
  //   }
  //   _saveToFirebase();
  // }
  void addFromRecipe(String recipeId, List<String> ingredients) {
    // Requirements 6/7/12 — adding the SAME recipe again must UPDATE its
    // grocery items with the latest (serving-scaled) quantities instead of
    // creating duplicates. We:
    //   1. remember the checked/unchecked state of this recipe's current items
    //      (keyed by ingredient name) so the user's progress is preserved,
    //   2. remove this recipe's existing items,
    //   3. re-add them from the latest ingredient list, restoring checked state.
    // Items from OTHER recipes are never touched.
    final previousChecked = <String, bool>{};
    for (final item in items) {
      if (item.recipeId == recipeId) {
        previousChecked[item.name.toLowerCase()] = item.checked;
      }
    }
    items.removeWhere((item) => item.recipeId == recipeId);

    for (final raw in ingredients) {
      final (name, qty) = parseIngredient(raw);

      items.add(
        GroceryItem(
          name: name,
          quantity: qty,
          aisle: detectAisle(raw),
          recipeId: recipeId,
          checked: previousChecked[name.toLowerCase()] ?? false,
        ),
      );
    }

    _saveToFirebase();
  }
  // void addFromRecipe(String recipeId, List<String> ingredients) {
  //   for (final raw in ingredients) {
  //     final (name, qty) = parseIngredient(raw);

  //     items.add(
  //       GroceryItem(name: name, quantity: qty, aisle: detectAisle(raw)),
  //     );
  //   }

  //   _saveToFirebase();
  // }

  // void toggleItem(GroceryItem item) {
  //   item.checked = !item.checked;
  //   items.refresh();
  //   _saveToFirebase();
  // }
  Future<void> toggleItem(GroceryItem item) async {
    // Ignore taps while this item's check animation/save is already in flight —
    // otherwise a rapid second tap re-enters and fires a duplicate delayed save.
    if (item.animating) return;
    if (!item.checked) {
      item.animating = true;
      items.refresh();

      // Must match the AnimatedContainer duration in _GroceryItemTile
      // (the strike-through line), so the item moves to CHECKED
      // right when the line finishes — no extra lag.
      await Future.delayed(const Duration(milliseconds: 350));

      item.checked = true;
      item.animating = false;
    } else {
      item.checked = false;
    }

    items.refresh();
    _saveToFirebase();
  }

  void removeItem(GroceryItem item) {
    items.remove(item);
    _saveToFirebase();
  }

  void clearChecked() {
    items.removeWhere((i) => i.checked);
    _saveToFirebase();
  }

  void clearAll() {
    items.clear();
    _saveToFirebase();
  }

  /// Remove groceries that belong to a specific recipe
  // void removeGroceriesByRecipe(List<String> ingredients) {
  //   for (final raw in ingredients) {
  //     final (name, _) = parseIngredient(raw);
  //     items.removeWhere((i) => i.name.toLowerCase() == name.toLowerCase());
  //   }
  //   _saveToFirebase();
  // }

  void removeGroceriesByRecipe(String recipeId) {
    items.removeWhere((item) => item.recipeId == recipeId);
    _saveToFirebase();
  }

  // ── Grouped accessors ──────────────────────────────────────────────────────
  Map<String, List<GroceryItem>> get byAisle {
    final map = <String, List<GroceryItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.aisle, () => []).add(item);
    }
    return map;
  }

  List<String> get sortedAisles {
    final present = byAisle.keys.toSet();
    final ordered = _aisleOrder.where(present.contains).toList();
    final extra = present.where((a) => !_aisleOrder.contains(a)).toList()
      ..sort();
    return [...ordered, ...extra];
  }
}
