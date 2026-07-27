// grocery_store.dart
// Firebase-backed grocery store.

import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';

class GroceryItem {
  final String name;
  final String quantity;
  final String aisle;
  final String recipeId;
  bool checked;
  bool animating;

  /// Stable position in the list. Persisted so checking an item (which rewrites
  /// every doc) never reshuffles the list — items stay exactly where they are.
  int order;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.aisle,
    required this.recipeId,
    this.checked = false,
    this.order = 0,
    this.animating = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'aisle': aisle,
      'recipeId': recipeId,
      'checked': checked,
      'order': order,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      aisle: map['aisle'] ?? '',
      recipeId: map['recipeId'] ?? '',
      checked: map['checked'] ?? false,
      order: (map['order'] as num?)?.toInt() ?? 0,
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

  StreamSubscription? _authSub;
  StreamSubscription? _grocSub;

  @override
  void onInit() {
    super.onInit();
    // Re-load from Firestore whenever auth changes. This store is permanent and
    // is created BEFORE login (e.g. after a fresh install / reinstall), so the
    // grocery list must be (re)loaded once the user actually signs in — not only
    // at startup when there may be no user yet.
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        _loadFromFirebase();
      } else {
        _grocSub?.cancel();
        items.clear();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _grocSub?.cancel();
    super.onClose();
  }

  // ── Firebase persistence ───────────────────────────────────────────────────
  void _loadFromFirebase() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    _grocSub?.cancel();
    _grocSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('groceries')
        .snapshots()
        .listen((snapshot) {
          final loaded =
              snapshot.docs
                  .map((doc) => GroceryItem.fromMap(doc.data()))
                  .toList()
                // Restore the saved order — Firestore returns docs by id, which is
                // random after a delete-and-re-add, so sort by the persisted index.
                ..sort((a, b) => a.order.compareTo(b.order));
          items.value = loaded;
          _translateNames();
        });
  }

  // ── Ingredient-name translation (DISPLAY ONLY) ─────────────────────────────
  // Grocery data stays English: merging, emoji, aisle detection and edits all
  // key off the English [GroceryItem.name]. This only provides translated text
  // for RENDERING via [trName], so none of that logic can break.

  /// English name -> translated name for the current language.
  final Map<String, String> _nameTr = {};

  /// The display name for an English ingredient name (falls back to English).
  String trName(String englishName) => _nameTr[englishName] ?? englishName;

  /// Build [_nameTr] for the loaded items in the current language, then refresh
  /// the list so the UI re-renders with the translations. No-op for English.
  Future<void> _translateNames() async {
    if (!AiTranslationService.isTranslating) {
      if (_nameTr.isNotEmpty) {
        _nameTr.clear();
        items.refresh();
      }
      return;
    }
    final names = items.map((i) => i.name).toSet();
    var changed = false;
    for (final n in names) {
      if (_nameTr.containsKey(n)) continue;
      _nameTr[n] = await AiTranslationService.translate(n);
      changed = true;
    }
    if (changed) items.refresh();
  }

  /// Re-translate ingredient names after the app language changes.
  Future<void> refreshLanguage() async {
    _nameTr.clear();
    await _translateNames();
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
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('groceries');

      // Clear existing
      final existing = await ref.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Add all items, stamping each with its current position so the order
      // survives the delete-and-re-add rewrite (Firestore has no inherent
      // ordering, so without this the list reshuffles on every save).
      for (var i = 0; i < items.length; i++) {
        items[i].order = i;
        batch.set(ref.doc(), items[i].toMap());
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
    'maggi': 'Grains & Pasta',
    'ramen': 'Grains & Pasta',
    'vermicelli': 'Grains & Pasta',
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

    // ── Added keywords so common condiments / sauces / produce no longer fall
    //    into "Other". Existing aisles + mappings are unchanged; these only add
    //    new detections (longest-keyword-first matching keeps specifics right,
    //    e.g. 'mustard seed' → Spices still beats 'mustard' → Pantry). ──
    // More produce
    'cabbage': 'Produce',
    'avocado': 'Produce',
    'lettuce': 'Produce',
    'kale': 'Produce',
    'cauliflower': 'Produce',
    'bell pepper': 'Produce',
    'eggplant': 'Produce',
    'aubergine': 'Produce',
    'beetroot': 'Produce',
    'sweet potato': 'Produce',
    'spring onion': 'Produce',
    'scallion': 'Produce',
    'shallot': 'Produce',
    'leek': 'Produce',
    'asparagus': 'Produce',
    'radish': 'Produce',
    'salad greens': 'Produce',
    'mixed greens': 'Produce',
    'salad': 'Produce',
    'greens': 'Produce',
    'green bean': 'Produce',
    'french bean': 'Produce',
    'bean sprout': 'Produce',
    'bean':
        'Produce', // generic fresh beans; canned variants below win by length
    // Condiments / sauces / canned & jarred
    'olive': 'Pantry / Canned & Jarred',
    'cornstarch': 'Pantry / Canned & Jarred',
    'cornflour': 'Pantry / Canned & Jarred',
    'ketchup': 'Pantry / Canned & Jarred',
    'worcestershire': 'Pantry / Canned & Jarred',
    'soya sauce': 'Pantry / Canned & Jarred',
    'fish sauce': 'Pantry / Canned & Jarred',
    'oyster sauce': 'Pantry / Canned & Jarred',
    'hot sauce': 'Pantry / Canned & Jarred',
    'chili sauce': 'Pantry / Canned & Jarred',
    'chilli sauce': 'Pantry / Canned & Jarred',
    'tomato sauce': 'Pantry / Canned & Jarred',
    'pasta sauce': 'Pantry / Canned & Jarred',
    'bbq sauce': 'Pantry / Canned & Jarred',
    'barbecue sauce': 'Pantry / Canned & Jarred',
    'mayonnaise': 'Pantry / Canned & Jarred',
    'mayo': 'Pantry / Canned & Jarred',
    'mustard': 'Pantry / Canned & Jarred',
    'dijon': 'Pantry / Canned & Jarred',
    'salsa': 'Pantry / Canned & Jarred',
    'pickle': 'Pantry / Canned & Jarred',
    'peanut butter': 'Pantry / Canned & Jarred',
    'tahini': 'Pantry / Canned & Jarred',
    'chickpea': 'Pantry / Canned & Jarred',
    'kidney bean': 'Pantry / Canned & Jarred',
    'black bean': 'Pantry / Canned & Jarred',
    'baked bean': 'Pantry / Canned & Jarred',
    'coconut cream': 'Pantry / Canned & Jarred',
    'peanut': 'Pantry / Canned & Jarred',
    'raisin': 'Pantry / Canned & Jarred',
    'jam': 'Pantry / Canned & Jarred',
    'jelly': 'Pantry / Canned & Jarred',
    // More spices & seasonings
    'seasoning': 'Spices & Seasonings',
    'tastemaker': 'Spices & Seasonings',
    'masala': 'Spices & Seasonings',
    'curry powder': 'Spices & Seasonings',
    'chilli flakes': 'Spices & Seasonings',
    'chili flakes': 'Spices & Seasonings',
    'red pepper flakes': 'Spices & Seasonings',
    'coriander seed': 'Spices & Seasonings',
    'allspice': 'Spices & Seasonings',
    'vanilla': 'Spices & Seasonings',
    'ginger powder': 'Spices & Seasonings',
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

  // ── Per-ingredient emoji ────────────────────────────────────────────────────
  // Specific emoji per ingredient keyword so different ingredients no longer
  // share the same category emoji. Matched longest-keyword-first (so
  // "olive oil" beats "oil", "sweet potato" beats "potato", etc.).
  static const Map<String, String> _ingredientEmoji = {
    // ── Vegetables ──
    'cherry tomato': '🍅', 'tomato': '🍅',
    'red onion': '🧅', 'spring onion': '🧅', 'green onion': '🧅',
    'scallion': '🧅', 'shallot': '🧅', 'leek': '🧅', 'onion': '🧅',
    'garlic': '🧄', 'sweet potato': '🍠', 'yam': '🍠', 'potato': '🥔',
    'carrot': '🥕', 'butternut squash': '🎃', 'butternut': '🎃',
    'pumpkin': '🎃', 'squash': '🎃', 'gourd': '🎃',
    'yellow pepper': '🫑', 'bell pepper': '🫑', 'green pepper': '🫑',
    'red pepper flake': '🌶️', 'red pepper': '🫑', 'capsicum': '🫑',
    'chili pepper': '🌶️',
    'chili': '🌶️',
    'chilli': '🌶️',
    'jalapeno': '🫑',
    'serrano': '🌿',
    'habanero': '🔥',
    'cayenne': '🌋',
    'paprika': '🧂',
    'pepper flake': '✨', 'pepper': '🫑',
    'sweetcorn': '🌽',
    'baby corn': '🌾',
    'cornmeal': '🥣',
    'polenta': '🍲',
    'cornstarch': '🥄',
    'cornflour': '🍞',
    'corn': '🌽',
    'cucumber': '🥒',
    'zucchini': '🥬',
    'courgette': '🌱',
    'gherkin': '🫙',
    'pickle': '🥫',
    'lettuce': '🥬',
    'cabbage': '🥬',
    'spinach': '🌿',
    'kale': '🍃',
    'chard': '🌱',
    'celery': '🥒',
    'radish': '🌶️',
    'arugula': '🍀',
    'rocket': '🚀',
    'bok choy': '🥬',
    'asparagus': '🎍',
    'artichoke': '🌼',
    'okra': '🫛',
    'brussels sprout': '🟢',
    'watercress': '💧',
    'beetroot': '🍠',
    'beet': '🍠',
    'turnip': '⚪',
    'parsnip': '🥕',
    'fennel': '🌿', 'broccoli': '🥦', 'cauliflower': '🥦',
    'shiitake': '🍄', 'portobello': '🍄', 'mushroom': '🍄',
    'eggplant': '🍆', 'aubergine': '🍆', 'brinjal': '🍆',
    'avocado': '🥑', 'ginger': '🫚', 'galangal': '🫚',
    'green bean': '🫛', 'snap pea': '🫛', 'snow pea': '🫛', 'edamame': '🫛',
    'peas': '🫛', 'pea': '🫛', 'olive': '🫒',
    // ── Herbs & greens ──
    'basil': '🌿',
    'cilantro': '🍃',
    'coriander': '🌱',
    'parsley': '🥬',
    'mint': '🌿',
    'thyme': '🌾',
    'rosemary': '🌲',
    'oregano': '🍂',
    'sage': '🍁',
    'chive': '🧅',
    'tarragon': '🌿',
    'dill': '🌾',
    'lemongrass': '🎋',
    'pesto': '🍝',
    'herb': '🌿',
    'bay leaf': '🍃', 'curry leaf': '🍃', 'seaweed': '🍃', 'nori': '🍃',
    // ── Fruits ──
    'lemon juice': '🍋', 'lime juice': '🍋', 'lemonade': '🍋', 'lemon': '🍋',
    'lime': '🍋',
    'mandarin': '🍊', 'tangerine': '🍊', 'clementine': '🍊',
    'grapefruit': '🍊', 'marmalade': '🍊', 'orange': '🍊',
    'green apple': '🍏', 'apple cider': '🍎', 'apple': '🍎',
    'plantain': '🍌', 'banana': '🍌',
    'strawberr': '🍓', 'raspberr': '🍓', 'cranberr': '🍒',
    'blueberr': '🫐', 'blackberr': '🫐',
    'raisin': '🍇', 'currant': '🍇', 'sultana': '🍇', 'grape': '🍇',
    'pineapple': '🍍', 'papaya': '🥭', 'mango': '🥭',
    'coconut milk': '🥥', 'coconut cream': '🥥', 'coconut oil': '🥥',
    'coconut': '🥥',
    'apricot': '🍑', 'nectarine': '🍑', 'plum': '🍑', 'peach': '🍑',
    'cherry': '🍒', 'watermelon': '🍉', 'cantaloupe': '🍈', 'honeydew': '🍈',
    'melon': '🍈', 'pear': '🍐', 'kiwi': '🥝', 'lychee': '🍒',
    'pomegranate': '🍎', 'fig': '🍇', 'date': '🌴',
    // ── Meat & poultry ──
    'chicken breast': '🍗', 'chicken thigh': '🍗', 'chicken wing': '🍗',
    'drumstick': '🍗', 'chicken': '🍗', 'poultry': '🍗', 'duck': '🦆',
    'turkey': '🦃',
    'ground beef': '🥩', 'ground meat': '🥩', 'meatball': '🥩', 'sirloin': '🥩',
    'brisket': '🥩', 'veal': '🥩', 'beef': '🥩', 'steak': '🥩', 'mince': '🥩',
    'meat': '🥩',
    'bacon': '🥓', 'pork': '🥓', 'lard': '🥓',
    'ham': '🍖', 'lamb': '🍖', 'mutton': '🍖', 'goat': '🍖', 'ribs': '🍖',
    'rib': '🍖',
    'chorizo': '🌭', 'pepperoni': '🌭', 'salami': '🌭', 'hot dog': '🌭',
    'sausage': '🌭',
    // ── Seafood ──
    'salmon': '🍣',
    'tuna': '🐟',
    'cod': '🎣',
    'tilapia': '🐠',
    'halibut': '🐡',
    'haddock': '🌊',
    'trout': '🏞️',
    'mackerel': '🐟',
    'sardine': '🥫',
    'anchovy': '🍕',
    'caviar': '⚫',
    'fish': '🐟', 'shrimp': '🦐', 'prawn': '🦐', 'crab': '🦀', 'lobster': '🦞',
    'crayfish': '🦞', 'calamari': '🦑', 'squid': '🦑', 'octopus': '🐙',
    'oyster': '🦪', 'clam': '🦪', 'mussel': '🦪', 'scallop': '🦪',
    'sushi': '🍣',
    // ── Dairy & eggs ──
    'egg white': '🥚', 'egg yolk': '🥚', 'egg': '🥚', 'buttermilk': '🥛',
    'condensed milk': '🥫',
    'evaporated milk': '🫙',
    'almond milk': '🌰',
    'soy milk': '🫘',
    'oat milk': '🌾',
    'milk': '🥛',
    'mozzarella': '🤍',
    'parmesan': '🟨',
    'cheddar': '🟧',
    'feta': '⬜',
    'paneer': '🥛',
    'ricotta': '🥣',
    'gouda': '🟡',
    'brie': '🍽️',
    'cream cheese': '🥯',
    'cheese': '🧀',
    'sour cream': '🥛', 'heavy cream': '🥛', 'whipping cream': '🥛',
    'yogurt': '🥛', 'yoghurt': '🥛', 'curd': '🥛', 'cream': '🥛',
    'ice cream': '🍨', 'custard': '🍮', 'pudding': '🍮',
    'butter bean': '🫘', 'peanut butter': '🥜', 'almond butter': '🥜',
    'butter': '🧈', 'ghee': '🧈', 'margarine': '🧈',
    // ── Nuts, seeds, legumes ──
    'peanut': '🥜',
    'almond': '🌰',
    'cashew': '🌙',
    'walnut': '🧠',
    'pistachio': '💚',
    'hazelnut': '🌰',
    'pecan': '🍂',
    'macadamia': '🤍',
    'pine nut': '🌲',
    'tahini': '🥣',
    'nut': '🥜', 'chestnut': '🌰',
    'sunflower seed': '🌻', 'pumpkin seed': '🎃',
    'sesame': '🌱', 'flax': '🌱', 'chia': '🌱', 'poppy seed': '🌱',
    'chickpea': '🫘', 'lentil': '🫘', 'kidney bean': '🫘', 'black bean': '🫘',
    'pinto bean': '🫘', 'cannellini': '🫘', 'soybean': '🫘', 'bean': '🫘',
    'tofu': '🧊', 'tempeh': '🧊',
    // ── Grains & bakery ──
    'basmati': '🍚', 'jasmine rice': '🍚', 'risotto': '🍚', 'rice flour': '🍚',
    'rice noodle': '🍜', 'rice': '🍚',
    'spaghetti': '🍝',
    'macaroni': '🧀',
    'penne': '🪶',
    'fusilli': '🌀',
    'lasagna': '🥘',
    'lasagne': '🥘',
    'fettuccine': '🍜',
    'linguine': '🥢',
    'pasta': '🍝',
    'ramen': '🍜',
    'udon': '🍜',
    'vermicelli': '🍜',
    'noodle': '🍜',
    'breadcrumb': '🥄',
    'crouton': '🥗',
    'toast': '🍞',
    'sourdough': '🥖',
    'brioche': '🧈', 'gingerbread': '🍪', 'bread': '🍞', 'baguette': '🥖',
    'flour': '🥣',
    'oat': '🌾',
    'wheat': '🌾',
    'quinoa': '🫙',
    'barley': '🌱',
    'bulgur': '🍚',
    'couscous': '🥄',
    'semolina': '🟡',
    'millet': '🌼',
    'bran': '🥣',
    'grain': '🌾', 'granola': '🥜', // nuts-based granola
    'muesli': '🍎', // often served with fruits
    'cereal': '🥣', // breakfast cereal bowl 'tortilla': '🌮',
    'naan': '🧈',
    'roti': '🫓',
    'pita': '🥙',
    'chapati': '🫓',
    'flatbread': '🫓',
    'croissant': '🥐',
    'bagel': '🥯',
    'pretzel': '🥨',
    'waffle': '🧇',
    'pancake': '🥞', 'crepe': '🥞',
    'cupcake': '🧁', 'muffin': '🧁', 'brownie': '🍫', 'cake': '🍰',
    'pie': '🥧', 'tart': '🥧', 'cookie': '🍪', 'biscuit': '🍪',
    'cracker': '🍘', 'donut': '🍩', 'doughnut': '🍩',
    // ── Pantry, condiments, spices, sweets ──
    'olive oil': '🫒', 'sunflower oil': '🌻', 'vegetable oil': '🛢️',
    'sesame oil': '🛢️', 'canola': '🛢️', 'oil': '🛢️',
    'maple syrup': '🍯', 'molasses': '🍯', 'agave': '🍯', 'honey': '🍯',
    'syrup': '🍯',
    'brown sugar': '🍬', 'powdered sugar': '🍬', 'sugar': '🍬',
    'sweetener': '🍬', 'candy': '🍭',
    'chocolate chip': '🍫', 'chocolate': '🍫', 'cocoa': '🍫', 'nutella': '🍫',
    'vanilla': '🍦',
    'black pepper': '⚫',
    'white pepper': '⚪',
    'peppercorn': '🫛',

    'salt': '🧂',

    'cinnamon': '🪵',
    'turmeric': '🟡',
    'cumin': '🌰',
    'nutmeg': '🥜',
    'clove': '🌸',
    'cardamom': '🫛',

    'garam masala': '🍛',
    'curry powder': '🍛',
    'masala': '🌶️',
    'spice': '🌶️',

    'saffron': '🌼',
    'star anise': '⭐',

    'allspice': '🌿',
    'coriander seed': '🌿',
    'fennel seed': '🌱',
    'mustard seed': '🟡',

    'baking powder': '🥣',
    'baking soda': '🥄',
    'yeast': '🍞',

    'bouillon': '🍲',
    'balsamic': '🍶', 'vinegar': '🍶', 'soy sauce': '🍶', 'fish sauce': '🍶',
    'oyster sauce': '🍶', 'hoisin': '🍶', 'worcestershire': '🍶',
    'ketchup': '🍅',
    'tomato paste': '🥫',
    'tomato puree': '🥣',
    'passata': '🫙',
    'salsa': '🥣',
    'sriracha': '🔥',
    'hot sauce': '🌡️',
    'chili sauce': '🫙',
    'chili powder': '🌶️',
    'mayonnaise': '🥚',
    'mayo': '🥚',
    'mustard': '🟡',
    'bbq sauce': '🍖',
    'barbecue': '🔥',
    'relish': '🥒',
    'sauce': '🫙',
    'canned': '🥫', 'jam': '🍓',
    'jelly': '🍇',
    'preserve': '🫙', 'stock': '🦴',
    'broth': '🍲',
    'gravy': '🥣',

    // ── Beverages ──
    'sparkling water': '💧', 'water': '💧', 'espresso': '☕', 'coffee': '☕',
    'matcha': '🍃',
    'green tea': '🫖',
    'tea': '🍵',
    'red wine': '🍷',
    'white wine': '🥂',
    'wine': '🍾', 'cider': '🍏',
    'beer': '🍺',
    'whiskey': '🥃',
    'whisky': '🥃',
    'bourbon': '🥂',
    'brandy': '🍇', 'rum': '🏴‍☠️',
    'vodka': '❄️',
    'champagne': '🥂', 'sake': '🍶',
    'orange juice': '🍹',
    'apple juice': '🧃',
    'juice': '🧃',
    'smoothie': '🍓',
    'milkshake': '🍦',
    'soda': '🥤',
    'cola': '🥤',
    'cocktail': '🍹',
    'poori': '🫓',
    'puri': '🫓',
    'bhatura': '🫓',
  };

  /// Keywords sorted longest-first so the most specific match wins.
  static final List<MapEntry<String, String>> _ingredientEmojiSorted =
      _ingredientEmoji.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));

  /// A specific emoji for a raw ingredient string. Falls back to the aisle
  /// emoji only when no ingredient keyword matches, so different ingredients no
  /// longer all share one repeated category emoji.
  String emojiForIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    for (final entry in _ingredientEmojiSorted) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return aisleEmoji(detectAisle(ingredient));
  }

  // ── Ingredient parsing ─────────────────────────────────────────────────────
  /// Non-convertible "count" / container units. These can't be expressed in
  /// ml/g, but they are still real units, so they must be split OFF the name
  /// (never left glued to it) — e.g. "3 cloves garlic" → name "garlic".
  static const Set<String> _countUnits = {
    'clove', 'cloves', 'piece', 'pieces', 'pc', 'pcs', 'can', 'cans',
    'tin', 'tins', 'jar', 'jars', 'bottle', 'bottles', 'pack', 'packs',
    'packet', 'packets', 'box', 'boxes', 'bag', 'bags', 'bunch', 'bunches',
    'head', 'heads', 'stalk', 'stalks', 'stick', 'sticks', 'sprig', 'sprigs',
    'slice', 'slices', 'sheet', 'sheets', 'leaf', 'leaves', 'pinch', 'pinches',
    'dash', 'dashes', 'handful', 'handfuls', 'drop', 'drops', 'cube', 'cubes',
    'ball', 'balls', 'fillet', 'fillets', 'strip', 'strips', 'wedge', 'wedges',
    'knob', 'knobs', 'dollop', 'dollops', 'loaf', 'loaves', 'ear', 'ears',
    'scoop', 'scoops', 'rasher', 'rashers',
    // size descriptors commonly used as the "unit" ("1 large onion")
    'small', 'medium', 'large', 'whole',
  };

  /// A single token is a unit when it is a convertible unit (per
  /// [UnitConverter]) OR one of the non-convertible count units above.
  static bool _isUnitToken(String token) {
    final t = token.toLowerCase();
    return UnitConverter.isUnitWord(t) || _countUnits.contains(t);
  }

  /// True when a token is (part of) a numeric quantity: an integer, decimal,
  /// fraction ("1/2"), range ("1-2") or unicode vulgar fraction ("½", "1½").
  static final RegExp _numToken = RegExp(r'^[\d½⅓⅔¼¾⅛⅜⅝⅞./-]+$');
  static final RegExp _hasDigit = RegExp(r'[\d½⅓⅔¼¾⅛⅜⅝⅞]');

  /// Splits an ingredient line into a clean (name, quantity) pair so the name
  /// NEVER carries a leading amount and the quantity keeps a convertible unit:
  ///   "1 tablespoon (15 ml) olive oil" → ("olive oil", "1 tablespoon")
  ///   "500 grams paneer"               → ("paneer",     "500 grams")
  ///   "2 pounds chicken breast"        → ("chicken breast", "2 pounds")
  ///   "3 cloves garlic"                → ("garlic",     "3 cloves")
  ///   "Salt to taste"                  → ("Salt to taste", "")
  (String name, String qty) parseIngredient(String raw) {
    // Strip parenthetical notes / brackets (both closed and unclosed).
    final cleaned = raw
        .replaceAll(RegExp(r'[\(\[][^\)\]]*[\)\]]'), ' ')
        .replaceAll(RegExp(r'[\(\[][^\)\]]*$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return (raw.trim(), '');

    final tokens = cleaned.split(' ');
    var i = 0;

    // 1) Consume the leading numeric amount ("1", "1.5", "1/2", "1 1/2", "½",
    //    "1½", or a range "2-3" / "2 to 3").
    final numberTokens = <String>[];
    while (i < tokens.length &&
        _numToken.hasMatch(tokens[i]) &&
        _hasDigit.hasMatch(tokens[i])) {
      numberTokens.add(tokens[i]);
      i++;
      // Allow "2 to 3" ranges: pull in "to" + the following number.
      if (i + 1 < tokens.length &&
          tokens[i].toLowerCase() == 'to' &&
          _numToken.hasMatch(tokens[i + 1]) &&
          _hasDigit.hasMatch(tokens[i + 1])) {
        numberTokens.add(tokens[i]); // "to"
        i++;
      }
    }

    // No leading number → the whole line is the name (e.g. "Salt to taste").
    if (numberTokens.isEmpty) return (cleaned, '');

    // 2) Consume a unit after the number. Handle the two-word "fl oz" /
    //    "fluid ounce" first, then any single-word convertible/count unit.
    var unit = '';
    if (i < tokens.length) {
      final t1 = tokens[i].toLowerCase();
      final t2 = (i + 1 < tokens.length) ? tokens[i + 1].toLowerCase() : '';
      if ((t1 == 'fl' && t2 == 'oz') ||
          (t1 == 'fluid' && (t2 == 'oz' || t2 == 'ounce' || t2 == 'ounces'))) {
        unit = '${tokens[i]} ${tokens[i + 1]}';
        i += 2;
      } else if (_isUnitToken(t1)) {
        unit = tokens[i];
        i++;
      }
    }

    // 3) Whatever remains is the ingredient name. Drop a leading "of"
    //    ("2 cups of flour" → "flour") and any trailing punctuation.
    var name = tokens
        .sublist(i)
        .join(' ')
        .replaceAll(RegExp(r'^of\s+', caseSensitive: false), '')
        // Strip stray brackets/punctuation left dangling on either end, e.g. a
        // lone ")" from "water (approx)" → "water )".
        .replaceAll(RegExp(r'^[\s)\]}]+|[\s([{)\]},;.]+$'), '')
        .trim();

    // Guard: if nothing is left as a name, the "number" was really the item
    // (rare) — fall back to the cleaned line so we never show an empty name.
    if (name.isEmpty) return (cleaned, '');

    final qty = [...numberTokens, if (unit.isNotEmpty) unit].join(' ');
    return (name, qty);
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

  // ── Multi-recipe merging (By meal "Used in many meals" / By category) ───────
  /// Lowercased ingredient names that appear across MORE THAN ONE recipe
  /// (recipe-sourced only — user "Extra items" have an empty recipeId).
  Set<String> get multiMealNames {
    final recipesByName = <String, Set<String>>{};
    for (final it in items) {
      if (it.recipeId.isEmpty) continue;
      recipesByName
          .putIfAbsent(it.name.toLowerCase(), () => <String>{})
          .add(it.recipeId);
    }
    return recipesByName.entries
        .where((e) => e.value.length > 1)
        .map((e) => e.key)
        .toSet();
  }

  /// Check/uncheck a whole merged group at once (used by the merged rows).
  Future<void> setCheckedAll(List<GroceryItem> group, bool checked) async {
    for (final it in group) {
      it.checked = checked;
      it.animating = false;
    }
    items.refresh();
    await _saveToFirebase();
  }

  /// Combine quantities that share a unit ("3 cloves" + "2 cloves" → "5 cloves",
  /// "1 can" + "1 can" → "2 cans"); otherwise join the originals with " + ".
  static String combineQuantities(Iterable<String> qtys) {
    final list = qtys.map((q) => q.trim()).where((q) => q.isNotEmpty).toList();
    if (list.isEmpty) return '';
    if (list.length == 1) return list.first;

    // Parse each into (number, unit).
    final parsed = <({double n, String unit})>[];
    for (final q in list) {
      // Greedy (+) so multi-digit amounts are captured whole: "237 ml" →
      // number "237". A non-greedy (+?) match grabbed only the first digit
      // ("2") and folded the rest into the unit ("37 ml"), wrecking the sum.
      final m = RegExp(r'^\s*([\d./½⅓⅔¼¾⅛⅜⅝⅞\s]+)\s*(.*)$').firstMatch(q);
      if (m == null) return list.join(' + ');
      final n = _parseQtyNum(m.group(1)!);
      if (n == null) return list.join(' + ');
      parsed.add((n: n, unit: m.group(2)!.trim()));
    }

    String norm(String u) {
      final l = u.toLowerCase().trim();
      return (l.length > 1 && l.endsWith('s'))
          ? l.substring(0, l.length - 1)
          : l;
    }

    // 1) Same unit (ignoring singular/plural) → simple sum, e.g. "5 cloves".
    final baseUnit = norm(parsed.first.unit);
    if (parsed.every((p) => norm(p.unit) == baseUnit)) {
      final sum = parsed.fold<double>(0, (a, p) => a + p.n);
      final display = parsed.first.unit;
      if (display.isEmpty) return _fmtQtyNum(sum);
      return '${_fmtQtyNum(sum)} ${sum > 1 ? _pluralUnit(display) : display}';
    }

    // 2) Different but convertible units of the SAME dimension → convert to a
    // base unit, sum, and format as ONE total (e.g. "5 ml" + "1 tsp" → "10 ml").
    if (parsed.every((p) => UnitConverter.isConvertible(p.unit))) {
      final dim = UnitConverter.dimensionOf(parsed.first.unit);
      if (dim != null &&
          parsed.every((p) => UnitConverter.dimensionOf(p.unit) == dim)) {
        final base = switch (dim) {
          UnitDimension.volume => 'ml',
          UnitDimension.mass => 'g',
          UnitDimension.length => 'cm',
          _ => null,
        };
        if (base != null) {
          var sum = 0.0;
          var ok = true;
          for (final p in parsed) {
            final c = UnitConverter.convert(
              value: p.n,
              fromUnit: p.unit,
              toUnit: base,
            );
            if (c == null) {
              ok = false;
              break;
            }
            sum += c;
          }
          if (ok) return UnitConverter.format(sum, base);
        }
      }
    }

    // 3) Units don't match and aren't convertible — but every part has a known
    // number, so still show ONE direct total (never a "2 + 2" breakdown). Use
    // the most common unit for display.
    final sum = parsed.fold<double>(0, (a, p) => a + p.n);
    final counts = <String, int>{};
    for (final p in parsed) {
      if (p.unit.isNotEmpty) counts[p.unit] = (counts[p.unit] ?? 0) + 1;
    }
    if (counts.isEmpty) return _fmtQtyNum(sum);
    final unit = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return '${_fmtQtyNum(sum)} ${sum > 1 ? _pluralUnit(unit) : unit}';
  }

  static const Map<String, double> _uniFractions = {
    '½': 0.5,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '¼': 0.25,
    '¾': 0.75,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

  static double? _parseQtyNum(String s) {
    var total = 0.0;
    var any = false;
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      if (_uniFractions.containsKey(ch)) {
        total += _uniFractions[ch]!;
        any = true;
      } else {
        buf.write(ch);
      }
    }
    for (final part in buf.toString().trim().split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      if (part.contains('/')) {
        final f = part.split('/');
        final a = double.tryParse(f[0].trim());
        final b = f.length > 1 ? double.tryParse(f[1].trim()) : null;
        if (a == null || b == null || b == 0) return null;
        total += a / b;
      } else {
        final d = double.tryParse(part);
        if (d == null) return null;
        total += d;
      }
      any = true;
    }
    return any ? total : null;
  }

  static String _fmtQtyNum(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');

  static const Set<String> _pluralizable = {
    'can',
    'clove',
    'cup',
    'piece',
    'bottle',
    'jar',
    'bunch',
    'slice',
    'tin',
    'pack',
    'box',
    'stick',
    'sprig',
    'head',
    'stalk',
    'leaf',
    'sheet',
    'bag',
  };

  static String _pluralUnit(String unit) {
    final lower = unit.toLowerCase();
    if (lower.endsWith('s')) return unit;
    if (_pluralizable.contains(lower)) {
      if (lower == 'leaf') return 'leaves';
      if (lower == 'box') return 'boxes';
      if (lower == 'bunch') return 'bunches';
      return '${unit}s';
    }
    return unit;
  }
}
