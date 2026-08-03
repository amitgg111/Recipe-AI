import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Model/user_model.dart';

/// Reads public user profiles and lists a creator's public recipes.
/// Everything is keyed off uid — there is no separate username field.
class UserService {
  UserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  static Future<UserModel?> getUser(String uid) async {
    final cached = _UserCache.peek(uid);
    if (cached != null) return cached;
    final doc = await _userRef(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  static Stream<UserModel?> userStream(String uid) => _UserCache.stream(uid);

  static Stream<int> publicRecipeCountStream(String uid) => _db
      .collection('recipes')
      .where('ownerId', isEqualTo: uid)
      .where('isPublic', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.where((d) => d.data()['isDeleted'] != true).length);

  static Stream<List<DiscoverRecipe>> publicRecipesStream(
    String uid, {
    required String authorName,
    String? authorAvatar,
  }) {
    return _db
        .collection('recipes')
        .where('ownerId', isEqualTo: uid)
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map(
          (s) => s.docs
              .where((d) => d.data()['isDeleted'] != true)
              .map((d) => _toDiscover(d, uid, authorName, authorAvatar))
              .toList(),
        );
  }

  static DiscoverRecipe _toDiscover(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String uid,
    String authorName,
    String? authorAvatar,
  ) {
    final data = d.data();
    return DiscoverRecipe(
      id: d.id,
      title: data['title']?.toString() ?? 'Untitled',
      description: data['description']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      category: data['category']?.toString(),
      cuisine: data['cuisine']?.toString(),
      prepTime: data['prepTime']?.toString(),
      cookTime: data['cookTime']?.toString(),
      totalTime: data['totalTime']?.toString(),
      servings: data['servings']?.toString(),
      ingredients: List<String>.from(data['ingredients'] ?? const []),
      instructions: List<String>.from(data['instructions'] ?? const []),
      userId: uid,
      userName: authorName,
      userAvatar: authorAvatar,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
      savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Per-uid shared profile stream cache: one Firestore listener is shared across
/// all subscribers of the same user, the last value is replayed instantly to
/// late subscribers, and the underlying listener is released when no one is
/// watching (while keeping the last value for the next instant paint).
class _UserCache {
  _UserCache._();

  static final Map<String, _UserEntry> _entries = {};

  static UserModel? peek(String uid) => _entries[uid]?.last;

  static Stream<UserModel?> stream(String uid) =>
      _entries.putIfAbsent(uid, () => _UserEntry(uid)).stream();
}

class _UserEntry {
  _UserEntry(this.uid) {
    _controller = StreamController<UserModel?>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final String uid;
  UserModel? last;
  bool hasValue = false;
  late final StreamController<UserModel?> _controller;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Stream<UserModel?> stream() async* {
    if (hasValue) yield last;
    yield* _controller.stream;
  }

  void _start() {
    _sub ??= FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((d) {
          last = d.exists ? UserModel.fromDoc(d) : null;
          hasValue = true;
          if (!_controller.isClosed) _controller.add(last);
        });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }
}
