import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Service/auth_service.dart';

/// Handles social engagement (like / save / comment / share) on public recipes.
///
/// Recipes live at `users/{ownerId}/recipes/{recipeId}`. Per-user engagement is
/// stored in sub-collections keyed by the acting user's uid:
///   • `.../likes/{uid}`    → { uid, createdAt }
///   • `.../saves/{uid}`    → { uid, createdAt }
///   • `.../comments/{id}`  → { userId, userName, userAvatar, text, createdAt }
///
/// Aggregate counters (`likesCount`, `commentsCount`, `sharesCount`,
/// `savesCount`) live on the recipe document and are updated with
/// `FieldValue.increment`.
///
/// The mutating methods are **target-based & idempotent** so the UI can update
/// optimistically (instantly) and fire the write in the background.
class RecipeSocialService {
  RecipeSocialService._();

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _recipeRef(
          String ownerId, String recipeId) =>
      _db.collection('users').doc(ownerId).collection('recipes').doc(recipeId);

  // ── Likes ──────────────────────────────────────────────────────────────────

  /// Sets the current user's like to [liked]. Idempotent — only touches the
  /// counter when the state actually changes.
  static Future<void> setLike(
      String ownerId, String recipeId, bool liked) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final recipe = _recipeRef(ownerId, recipeId);
    final likeRef = recipe.collection('likes').doc(uid);
    final exists = (await likeRef.get()).exists;
    if (liked && !exists) {
      await likeRef.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await recipe.update({'likesCount': FieldValue.increment(1)});
    } else if (!liked && exists) {
      await likeRef.delete();
      await recipe.update({'likesCount': FieldValue.increment(-1)});
    }
  }

  static Stream<bool> likedStream(String ownerId, String recipeId) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _recipeRef(ownerId, recipeId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  static Future<bool> isLiked(String ownerId, String recipeId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    return (await _recipeRef(ownerId, recipeId).collection('likes').doc(uid).get())
        .exists;
  }

  // ── Saves (marker + counter on the original recipe) ─────────────────────────

  static Future<void> setSave(
      String ownerId, String recipeId, bool saved) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final recipe = _recipeRef(ownerId, recipeId);
    final saveRef = recipe.collection('saves').doc(uid);
    final exists = (await saveRef.get()).exists;
    if (saved && !exists) {
      await saveRef.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await recipe.update({'savesCount': FieldValue.increment(1)});
    } else if (!saved && exists) {
      await saveRef.delete();
      await recipe.update({'savesCount': FieldValue.increment(-1)});
    }
  }

  static Future<bool> isSaved(String ownerId, String recipeId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    return (await _recipeRef(ownerId, recipeId).collection('saves').doc(uid).get())
        .exists;
  }

  // ── Save a copy into the current user's own recipes ─────────────────────────
  // A public recipe belongs to another user, so its id can't appear in the
  // current user's cookbooks / My Recipes. Saving therefore copies it (private)
  // into `users/{me}/recipes` so it shows up like any owned recipe.

  /// Returns the id of the current user's copy (creating it if needed), or the
  /// original id when the recipe already belongs to the current user.
  static Future<String?> saveCopyToMyRecipes(DiscoverRecipe r) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return null;
    if (r.userId == uid) return r.id; // already mine

    final col = _db.collection('users').doc(uid).collection('recipes');

    // De-dupe: reuse an existing copy of the same source recipe.
    final existing =
        await col.where('savedFromRecipeId', isEqualTo: r.id).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final doc = await col.add({
      'title': r.title,
      'description': r.description,
      'imageUrl': r.imageUrl,
      'sourceUrl': '',
      'prepTime': r.prepTime,
      'cookTime': r.cookTime,
      'totalTime': r.totalTime,
      'servings': r.servings,
      'category': r.category,
      'cuisine': r.cuisine,
      'keywords': <String>[],
      'ingredients': r.ingredients,
      'instructions': r.instructions,
      'ingredientSections': [
        {'name': null, 'items': r.ingredients}
      ],
      'instructionSections': [
        {'name': null, 'steps': r.instructions}
      ],
      // Copies are always private and owned by the current user, and are
      // tagged as 'discovered' so they can never be published back to Discover
      // (which would duplicate the original). See RecipePublishPolicy.
      'visibility': 'private',
      'isPublic': false,
      'recipeSource': 'discovered',
      'originalRecipeId': r.id,
      'ownerId': uid,
      'isDeleted': false,
      'likesCount': 0,
      'commentsCount': 0,
      'savesCount': 0,
      'sharesCount': 0,
      'viewsCount': 0,
      // Provenance so we can de-dupe / remove on un-save.
      'savedFromRecipeId': r.id,
      'savedFromOwnerId': r.userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Deletes the current user's saved copy of [r] (if any).
  static Future<void> removeSavedCopy(DiscoverRecipe r) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || r.userId == uid) return;
    final col = _db.collection('users').doc(uid).collection('recipes');
    final existing = await col.where('savedFromRecipeId', isEqualTo: r.id).get();
    for (final d in existing.docs) {
      await d.reference.delete();
    }
  }

  // ── Ratings ──────────────────────────────────────────────────────────────
  // Each user stores one rating in `.../ratings/{uid}` = { rating 1-5 }.
  // The recipe doc keeps `ratingSum` + `ratingCount`; average = sum / count.

  static Future<int> getMyRating(String ownerId, String recipeId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return 0;
    final d = await _recipeRef(ownerId, recipeId)
        .collection('ratings')
        .doc(uid)
        .get();
    return (d.data()?['rating'] as num?)?.toInt() ?? 0;
  }

  /// Sets (or changes) the current user's rating and keeps the aggregate
  /// (`ratingSum`, `ratingCount`) on the recipe document in sync.
  static Future<void> setRating(
      String ownerId, String recipeId, int rating) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || rating < 1 || rating > 5) return;
    final recipe = _recipeRef(ownerId, recipeId);
    final ref = recipe.collection('ratings').doc(uid);
    final old = ((await ref.get()).data()?['rating'] as num?)?.toInt() ?? 0;

    await ref.set({
      'rating': rating,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (old == 0) {
      await recipe.update({
        'ratingSum': FieldValue.increment(rating),
        'ratingCount': FieldValue.increment(1),
      });
    } else if (old != rating) {
      await recipe.update({'ratingSum': FieldValue.increment(rating - old)});
    }
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  static Future<void> addComment(
    String ownerId,
    String recipeId, {
    required String text,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final recipe = _recipeRef(ownerId, recipeId);
    await recipe.collection('comments').add({
      'userId': user.uid,
      'userName': (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName
          : 'Anonymous',
      'userAvatar': user.photoURL,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await recipe.update({'commentsCount': FieldValue.increment(1)});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
    String ownerId,
    String recipeId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _recipeRef(ownerId, recipeId)
        .collection('comments')
        .orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots();
  }

  // ── Shares ─────────────────────────────────────────────────────────────────

  static Future<void> registerShare(String ownerId, String recipeId) async {
    try {
      await _recipeRef(ownerId, recipeId)
          .update({'sharesCount': FieldValue.increment(1)});
    } catch (_) {
      // best-effort; sharing itself must never fail because of this
    }
  }

  // ── Live recipe doc (counts) ──────────────────────────────────────────────

  static Stream<DocumentSnapshot<Map<String, dynamic>>> recipeStream(
          String ownerId, String recipeId) =>
      _recipeRef(ownerId, recipeId).snapshots();
}
