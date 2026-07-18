// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:recipe_ai/Controllers/discover_controller.dart';
// import 'package:recipe_ai/Model/user_model.dart';
// import 'package:recipe_ai/Service/auth_service.dart';

// /// Reads public user profiles, manages unique usernames, and lists a creator's
// /// public recipes.
// class UserService {
//   UserService._();

//   static final FirebaseFirestore _db = FirebaseFirestore.instance;

//   static DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
//       _db.collection('users').doc(uid);

//   static Future<UserModel?> getUser(String uid) async {
//     // Serve an already-cached profile instantly if we have one.
//     final cached = _UserCache.peek(uid);
//     if (cached != null) return cached;
//     final doc = await _userRef(uid).get();
//     return doc.exists ? UserModel.fromDoc(doc) : null;
//   }

//   /// Live profile stream. Many widgets (author cards, follow buttons, follow
//   /// lists) watch the same user — this shares ONE Firestore listener per uid
//   /// and replays the last known value instantly to new subscribers, so cached
//   /// data shows with zero delay while refreshing in the background.
//   static Stream<UserModel?> userStream(String uid) => _UserCache.stream(uid);

//   /// Live count of a user's PUBLIC recipes (for other people's profiles).
//   static Stream<int> publicRecipeCountStream(String uid) => _userRef(uid)
//       .collection('recipes')
//       .where('visibility', isEqualTo: 'public')
//       .snapshots()
//       .map((s) => s.docs.where((d) => d.data()['isDeleted'] != true).length);

//   /// A creator's PUBLIC recipes as [DiscoverRecipe]s (for their profile grid).
//   static Stream<List<DiscoverRecipe>> publicRecipesStream(
//     String uid, {
//     required String authorName,
//     String? authorAvatar,
//   }) {
//     return _userRef(uid)
//         .collection('recipes')
//         .where('visibility', isEqualTo: 'public')
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map(
//           (s) => s.docs
//               .where((d) => d.data()['isDeleted'] != true)
//               .map((d) => _toDiscover(d, uid, authorName, authorAvatar))
//               .toList(),
//         );
//   }

//   static DiscoverRecipe _toDiscover(
//     QueryDocumentSnapshot<Map<String, dynamic>> d,
//     String uid,
//     String authorName,
//     String? authorAvatar,
//   ) {
//     final data = d.data();
//     return DiscoverRecipe(
//       id: d.id,
//       title: data['title']?.toString() ?? 'Untitled',
//       description: data['description']?.toString(),
//       imageUrl: data['imageUrl']?.toString(),
//       category: data['category']?.toString(),
//       cuisine: data['cuisine']?.toString(),
//       prepTime: data['prepTime']?.toString(),
//       cookTime: data['cookTime']?.toString(),
//       totalTime: data['totalTime']?.toString(),
//       servings: data['servings']?.toString(),
//       ingredients: List<String>.from(data['ingredients'] ?? const []),
//       instructions: List<String>.from(data['instructions'] ?? const []),
//       userId: uid,
//       userName: authorName,
//       userAvatar: authorAvatar,
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
//       likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
//       commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
//       sharesCount: (data['sharesCount'] as num?)?.toInt() ?? 0,
//       savesCount: (data['savesCount'] as num?)?.toInt() ?? 0,
//     );
//   }

//   // ─── Usernames (unique) ─────────────────────────────────────────────────────

//   static final RegExp _usernameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

//   static bool isValidUsername(String username) =>
//       _usernameRe.hasMatch(username.toLowerCase());

//   /// Ensures the current user has a stored username, generating a unique one
//   /// from their email/name on first run. Safe to call repeatedly.
//   static Future<void> ensureUsername() async {
//     final user = AuthService.currentUser;
//     if (user == null) return;
//     final doc = await _userRef(user.uid).get();
//     final existing = (doc.data()?['name'] as String?)?.trim() ?? '';
//     if (existing.isNotEmpty) return;

//     final base = _slug(
//       user.email?.split('@').first ?? user.displayName ?? 'chef',
//     );
//     var candidate = base;
//     var n = 0;
//     while (!await _reserveUsername(candidate, user.uid)) {
//       n++;
//       candidate = '$base$n';
//       if (n > 50) {
//         candidate = '$base${user.uid.substring(0, 4)}';
//         await _reserveUsername(candidate, user.uid);
//         break;
//       }
//     }
//     await _userRef(user.uid).set({'name': candidate}, SetOptions(merge: true));
//   }

//   /// Change the current user's username (with a uniqueness check). Returns an
//   /// error string on failure, or null on success.
//   static Future<String?> setUsername(String raw) async {
//     final user = AuthService.currentUser;
//     if (user == null) return 'Not signed in';
//     final username = raw.trim().toLowerCase();
//     if (!isValidUsername(username)) {
//       return '3–20 chars: letters, numbers, _ or .';
//     }
//     final current = (await _userRef(user.uid).get()).data()?['name'] ?? '';
//     if (username == current) return null;

//     final ok = await _reserveUsername(username, user.uid);
//     if (!ok) return 'That username is taken';

//     // Release the previous reservation.
//     if (current is String && current.isNotEmpty) {
//       try {
//         await _db.collection('usernames').doc(current).delete();
//       } catch (_) {}
//     }
//     await _userRef(user.uid).set({'name': username}, SetOptions(merge: true));
//     return null;
//   }

//   /// Reserves `usernames/{name}` for [uid]. Returns true if now owned by uid.
//   static Future<bool> _reserveUsername(String name, String uid) async {
//     final ref = _db.collection('usernames').doc(name);
//     try {
//       return await _db.runTransaction<bool>((tx) async {
//         final snap = await tx.get(ref);
//         if (snap.exists) {
//           return snap.data()?['uid'] == uid;
//         }
//         tx.set(ref, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
//         return true;
//       });
//     } catch (_) {
//       return false;
//     }
//   }

//   static String _slug(String s) {
//     final clean = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
//     if (clean.length < 3) return 'chef${DateTime.now().millisecond}';
//     return clean.length > 16 ? clean.substring(0, 16) : clean;
//   }
// }

// /// Per-uid shared profile stream cache: one Firestore listener is shared across
// /// all subscribers of the same user, the last value is replayed instantly to
// /// late subscribers, and the underlying listener is released when no one is
// /// watching (while keeping the last value for the next instant paint).
// class _UserCache {
//   _UserCache._();

//   static final Map<String, _UserEntry> _entries = {};

//   static UserModel? peek(String uid) => _entries[uid]?.last;

//   static Stream<UserModel?> stream(String uid) =>
//       _entries.putIfAbsent(uid, () => _UserEntry(uid)).stream();
// }

// class _UserEntry {
//   _UserEntry(this.uid) {
//     _controller = StreamController<UserModel?>.broadcast(
//       onListen: _start,
//       onCancel: _stop,
//     );
//   }

//   final String uid;
//   UserModel? last;
//   bool hasValue = false;
//   late final StreamController<UserModel?> _controller;
//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

//   Stream<UserModel?> stream() async* {
//     if (hasValue) yield last; // instant paint from cache
//     yield* _controller.stream;
//   }

//   void _start() {
//     _sub ??= FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .snapshots()
//         .listen((d) {
//           last = d.exists ? UserModel.fromDoc(d) : null;
//           hasValue = true;
//           if (!_controller.isClosed) _controller.add(last);
//         });
//   }

//   void _stop() {
//     // Release the network listener when nobody is watching, but keep [last]
//     // so the next subscriber paints instantly and refreshes in the background.
//     _sub?.cancel();
//     _sub = null;
//   }
// }
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
