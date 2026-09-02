import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';

/// Follow / unfollow relationships between users.
///
/// Data model:
///   users/{target}/followers/{me}     → { uid, followedAt }
///   users/{me}/following/{target}     → { uid, followedAt }
/// plus denormalized `followersCount` / `followingCount` on each user doc.
class FollowService {
  FollowService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get _me => AuthService.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> _followers(String uid) =>
      _db.collection('users').doc(uid).collection('followers');
  static CollectionReference<Map<String, dynamic>> _following(String uid) =>
      _db.collection('users').doc(uid).collection('following');

  /// Follow or unfollow [targetUid].
  ///
  /// Uses a [WriteBatch] (not a transaction) so the writes — including the
  /// `followersCount` / `followingCount` increments — are applied to Firestore's
  /// LOCAL CACHE immediately. That makes every counter stream update the UI
  /// instantly (transactions only reflect after a server round-trip).
  ///
  /// Idempotency is preserved with a cache-first existence check: the follower
  /// doc is already cached whenever we're following, so we never double-count.
  static Future<void> setFollow(String targetUid, bool follow) async {
    final me = _me;
    if (me == null || me == targetUid) return;

    final followerRef = _followers(targetUid).doc(me);
    final followingRef = _following(me).doc(targetUid);
    final targetRef = _db.collection('users').doc(targetUid);
    final meRef = _db.collection('users').doc(me);

    // Cache-first read is instant; if the relationship is unchanged, do nothing.
    bool already = false;
    try {
      final snap = await followerRef.get(
        const GetOptions(source: Source.cache),
      );
      already = snap.exists;
    } catch (_) {
      already = false; // never cached → not following
    }
    if (follow == already) return;

    final batch = _db.batch();
    if (follow) {
      final now = FieldValue.serverTimestamp();
      batch.set(followerRef, {'uid': me, 'followedAt': now});
      batch.set(followingRef, {'uid': targetUid, 'followedAt': now});
      batch.set(targetRef, {
        'followersCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
      batch.set(meRef, {
        'followingCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } else {
      batch.delete(followerRef);
      batch.delete(followingRef);
      batch.set(targetRef, {
        'followersCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      batch.set(meRef, {
        'followingCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      await batch.commit();
      await AnalyticsService.instance.trackEvent(
        follow ? 'follow_user' : 'unfollow_user',
        parameters: {'target_uid': targetUid},
      );
    }
  }

  /// Whether the current user follows [targetUid] (live).
  static Stream<bool> isFollowingStream(String targetUid) {
    final me = _me;
    if (me == null) return Stream.value(false);
    return _followers(targetUid).doc(me).snapshots().map((d) => d.exists);
  }

  static Future<bool> isFollowing(String targetUid) async {
    final me = _me;
    if (me == null) return false;
    final d = await _followers(targetUid).doc(me).get();
    return d.exists;
  }

  /// Uids that follow [userId] (most recent first).
  static Stream<List<String>> followerUidsStream(String userId) {
    return _followers(userId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }

  /// Uids that [userId] follows (most recent first).
  static Stream<List<String>> followingUidsStream(String userId) {
    return _following(userId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }
}
