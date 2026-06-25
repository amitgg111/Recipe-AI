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

  Future<void> _saveToFirebase() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    final ref = _firestore.collection('users').doc(uid).collection('groceries');

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
    'rice': 'Pantry',
    'dal': 'Pantry',
    'lentil': 'Pantry',
    'pasta': 'Pantry',
    'noodle': 'Pantry',
    'tomato paste': 'Pantry',
    'coconut milk': 'Pantry',
    'stock': 'Pantry',
    'broth': 'Pantry',
    'soy sauce': 'Pantry',
    'bread': 'Pantry',
  };

  static const List<String> _aisleOrder = [
    'Fresh Produce',
    'Dairy, Eggs & Fridge',
    'Herbs & Spices',
    'Oils & Vinegars',
    'Flours & Sugars',
    'Pantry',
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
    for (final raw in ingredients) {
      final (name, qty) = parseIngredient(raw);

      items.add(
        GroceryItem(
          name: name,
          quantity: qty,
          aisle: detectAisle(raw),
          recipeId: recipeId,
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
