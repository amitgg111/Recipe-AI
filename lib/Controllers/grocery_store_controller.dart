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
    'onion': 'Fresh Produce',
    'tomato': 'Fresh Produce',
    'ginger': 'Fresh Produce',
    'garlic': 'Fresh Produce',
    'coriander leaves': 'Fresh Produce',
    'cilantro': 'Fresh Produce',
    'lemon': 'Fresh Produce',
    'lime': 'Fresh Produce',
    'spinach': 'Fresh Produce',
    'potato': 'Fresh Produce',
    'carrot': 'Fresh Produce',
    'capsicum': 'Fresh Produce',
    'chilli': 'Fresh Produce',
    'chili': 'Fresh Produce',
    'mint': 'Fresh Produce',
    'parsley': 'Fresh Produce',
    'mushroom': 'Fresh Produce',
    'broccoli': 'Fresh Produce',
    'celery': 'Fresh Produce',
    'cucumber': 'Fresh Produce',
    'zucchini': 'Fresh Produce',
    'pea': 'Fresh Produce',
    // Dairy
    'cream': 'Dairy, Eggs & Fridge',
    'paneer': 'Dairy, Eggs & Fridge',
    'butter': 'Dairy, Eggs & Fridge',
    'milk': 'Dairy, Eggs & Fridge',
    'cheese': 'Dairy, Eggs & Fridge',
    'yogurt': 'Dairy, Eggs & Fridge',
    'curd': 'Dairy, Eggs & Fridge',
    'egg': 'Dairy, Eggs & Fridge',
    'ghee': 'Dairy, Eggs & Fridge',
    // Herbs & spices
    'cardamom': 'Herbs & Spices',
    'cinnamon': 'Herbs & Spices',
    'clove': 'Herbs & Spices',
    'bay leaf': 'Herbs & Spices',
    'turmeric': 'Herbs & Spices',
    'cumin': 'Herbs & Spices',
    'coriander powder': 'Herbs & Spices',
    'garam masala': 'Herbs & Spices',
    'kasuri methi': 'Herbs & Spices',
    'fenugreek': 'Herbs & Spices',
    'chilli powder': 'Herbs & Spices',
    'chili powder': 'Herbs & Spices',
    'paprika': 'Herbs & Spices',
    'salt': 'Herbs & Spices',
    'pepper': 'Herbs & Spices',
    'oregano': 'Herbs & Spices',
    'thyme': 'Herbs & Spices',
    'basil': 'Herbs & Spices',
    'rosemary': 'Herbs & Spices',
    'nutmeg': 'Herbs & Spices',
    'saffron': 'Herbs & Spices',
    'star anise': 'Herbs & Spices',
    'mustard seed': 'Herbs & Spices',
    'fennel': 'Herbs & Spices',
    // Oils & vinegars
    ' oil': 'Oils & Vinegars',
    'vinegar': 'Oils & Vinegars',
    'olive oil': 'Oils & Vinegars',
    'sesame oil': 'Oils & Vinegars',
    // Flours & sugars
    'sugar': 'Flours & Sugars',
    'jaggery': 'Flours & Sugars',
    'flour': 'Flours & Sugars',
    'honey': 'Flours & Sugars',
    'corn starch': 'Flours & Sugars',
    'baking powder': 'Flours & Sugars',
    'baking soda': 'Flours & Sugars',
    // Pantry
    'cashew': 'Pantry',
    'almond': 'Pantry',
    'tomato paste': 'Pantry',
    'coconut milk': 'Pantry',
    'stock': 'Pantry',
    'broth': 'Pantry',
    'soy sauce': 'Pantry',
    'bread': 'Pantry',
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
    'chicken': 'Meat & Seafood',
    'beef': 'Meat & Seafood',
    'pork': 'Meat & Seafood',
    'lamb': 'Meat & Seafood',
    'mutton': 'Meat & Seafood',
    'turkey': 'Meat & Seafood',
    'bacon': 'Meat & Seafood',
    'sausage': 'Meat & Seafood',
    'mince': 'Meat & Seafood',
    'steak': 'Meat & Seafood',
    'salmon': 'Meat & Seafood',
    'tuna': 'Meat & Seafood',
    'shrimp': 'Meat & Seafood',
    'prawn': 'Meat & Seafood',
    'fish': 'Meat & Seafood',
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
    'Fresh Produce',
    'Meat & Seafood',
    'Dairy, Eggs & Fridge',
    'Bakery',
    'Grains & Pasta',
    'Herbs & Spices',
    'Oils & Vinegars',
    'Flours & Sugars',
    'Pantry',
    'Frozen',
    'Beverages',
    'Snacks & Sweets',
    'Household',
    'Uncategorized',
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
    return 'Uncategorized';
  }

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
