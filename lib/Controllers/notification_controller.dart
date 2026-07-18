import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Model/notification_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';

/// Real-time in-app notification feed + unread badge.
///
/// • The unread badge is driven by a dedicated lightweight stream so it stays
///   live everywhere (needs the receiverUserId + isRead index).
/// • The feed uses a growing-`limit` snapshot: page size 20, and [loadMore]
///   simply raises the limit and re-subscribes. This keeps the WHOLE loaded
///   window real-time (new likes/comments appear instantly at the top) while
///   still only fetching what the user has scrolled to (needs the
///   receiverUserId + createdAt index).
///
/// Registered permanent in main() and rebinds itself on every auth change.
class NotificationController extends GetxController {
  static const int pageSize = 20;

  final RxList<AppNotification> items = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasMore = true.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _authSub;
  StreamSubscription? _feedSub;
  StreamSubscription? _unreadSub;

  int _limit = pageSize;
  String? _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  @override
  void onInit() {
    super.onInit();
    _authSub = AuthService.authStateChanges.listen((user) {
      if (user != null) {
        _bind(user.uid);
      } else {
        _unbind();
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _feedSub?.cancel();
    _unreadSub?.cancel();
    super.onClose();
  }

  void _bind(String uid) {
    if (_uid == uid && _feedSub != null) return; // already bound
    _uid = uid;
    _limit = pageSize;
    isLoading.value = true;
    _listenUnread();
    _listenFeed();
  }

  void _unbind() {
    _uid = null;
    _feedSub?.cancel();
    _unreadSub?.cancel();
    _feedSub = null;
    _unreadSub = null;
    items.clear();
    unreadCount.value = 0;
    isLoading.value = false;
  }

  void _listenUnread() {
    final uid = _uid;
    if (uid == null) return;
    _unreadSub?.cancel();
    _unreadSub = _col
        .where('receiverUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snap) => unreadCount.value = snap.docs.length,
          onError: (e) => log('Notif unread stream error: $e'),
        );
  }

  void _listenFeed() {
    final uid = _uid;
    if (uid == null) return;
    _feedSub?.cancel();
    _feedSub = _col
        .where('receiverUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .listen(
          (snap) {
            items.value = snap.docs.map(AppNotification.fromDoc).toList();
            // If we got a full page, there may be more behind it.
            hasMore.value = snap.docs.length >= _limit;
            isLoading.value = false;
          },
          onError: (e) {
            isLoading.value = false;
            log('Notif feed stream error: $e');
          },
        );
  }

  /// Load the next page (called when the user scrolls near the bottom).
  void loadMore() {
    if (!hasMore.value || _uid == null) return;
    _limit += pageSize;
    _listenFeed();
  }

  /// Mark a single notification read (idempotent — skips if already read).
  Future<void> markAsRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await _col.doc(n.id).update({'isRead': true});
    } catch (e) {
      log('markAsRead error: $e');
    }
  }

  /// Mark every currently-unread notification read.
  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await _col
          .where('receiverUserId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      log('markAllRead error: $e');
    }
  }

  /// Delete a single notification (swipe-to-delete). The user owns their own
  /// notifications per the security rules. Removed from the UI instantly via
  /// the feed stream.
  Future<void> delete(AppNotification n) async {
    try {
      await _col.doc(n.id).delete();
    } catch (e) {
      log('delete notification error: $e');
    }
  }

  /// Pull-to-refresh: re-subscribe the live streams. They're already real-time,
  /// so this mainly gives the refresh control something to await.
  @override
  Future<void> refresh() async {
    if (_uid == null) return;
    _listenUnread();
    _listenFeed();
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
