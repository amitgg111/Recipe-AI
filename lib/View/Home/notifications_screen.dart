import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/notification_controller.dart';
import 'package:recipe_ai/Model/notification_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/follow_service.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class _N {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const unreadBg = Color(0xFFFDF1E9);
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textBody = Color(0xFF5A5147);
  static const textHint = Color(0xFFA89F90);
  static const line = Color(0xFFF0ECE4);
  static const avatarBg = Color(0xFFEDE5D7);
  static const green = Color(0xFF2E9E6B);
}

TextStyle _f(double s, FontWeight w, Color c, {double? h}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _c = Get.find<NotificationController>();
  final ScrollController _scroll = ScrollController();
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load the next page as the user nears the bottom.
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _c.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _N.bg,
      body: Column(
        children: [
          // Header
          Container(
            color: _N.bg,
            padding: EdgeInsets.fromLTRB(8, top + 6, 12, 8),
            child: Row(
              children: [
                _iconButton('back', () => Get.back()),
                const SizedBox(width: 4),
                Text('Notifications',
                    style: _f(19, FontWeight.w800, _N.textDark)),
                const Spacer(),
                Obx(() => _c.unreadCount.value > 0
                    ? TextButton(
                        onPressed: _c.markAllRead,
                        child: Text('Mark all read',
                            style: _f(13, FontWeight.w700, _N.primary)),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_c.isLoading.value && _c.items.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: _N.primary));
              }
              final items = _c.items;
              return RefreshIndicator(
                color: _N.primary,
                onRefresh: _c.refresh,
                child: items.isEmpty
                    ? ListView(
                        // Scrollable so pull-to-refresh still works when empty.
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.24),
                          _empty(),
                        ],
                      )
                    : ListView.separated(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                        itemCount: items.length + (_c.hasMore.value ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (i >= items.length) return _loadingMore();
                          return _tile(items[i]);
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingLineIcon('bell',
              size: 46, color: _N.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text('No notifications yet',
              style: _f(16, FontWeight.w800, _N.textBody)),
          const SizedBox(height: 4),
          Text('Likes, comments and new followers show up here.',
              style: _f(13, FontWeight.w500, _N.textHint)),
        ],
      ),
    );
  }

  Widget _loadingMore() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _N.primary),
          ),
        ),
      );

  Widget _tile(AppNotification n) {
    // Swipe-to-delete (endToStart) over a modern card. The unread → read
    // colour/border change animates smoothly via AnimatedContainer.
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _c.delete(n),
      background: _swipeBg(),
      child: GestureDetector(
        onTap: () => _open(n),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: n.isRead ? _N.card : _N.unreadBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.isRead ? _N.line : _N.primary.withValues(alpha: 0.30),
              width: n.isRead ? 1 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatarWithBadge(n),
              const SizedBox(width: 12),
              Expanded(child: _textBlock(n)),
              const SizedBox(width: 10),
              _trailing(n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swipeBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0481F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const OnboardingLineIcon('trash', size: 22, color: Colors.white),
    );
  }

  // Avatar (tap → sender profile) with a small type badge in the corner, the
  // way Instagram/Facebook mark each notification.
  Widget _avatarWithBadge(AppNotification n) {
    return GestureDetector(
      onTap: () => _openProfile(n),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _senderAvatar(n),
            Positioned(right: -1, bottom: -1, child: _typeBadge(n)),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(AppNotification n) {
    final color = n.isFollow
        ? _N.green
        : n.isComment
            ? const Color(0xFF3B82F6)
            : _N.primary;
    final icon = n.isFollow
        ? 'user'
        : n.isComment
            ? 'comment'
            : 'heart';
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: OnboardingLineIcon(icon, size: 11, color: Colors.white),
    );
  }

  Widget _textBlock(AppNotification n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: _f(13.5, FontWeight.w500, _N.textBody, h: 1.35),
            children: [
              TextSpan(
                text: n.senderName,
                style: _f(13.5, FontWeight.w800, _N.textDark),
              ),
              TextSpan(text: ' ${_action(n)}'),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_relativeTime(n.createdAt),
                style: _f(11.5, FontWeight.w600, _N.textHint)),
            if (!n.isRead) ...[
              const SizedBox(width: 7),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _N.primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Follow notifications get a Follow/Following button; like/comment get the
  // recipe thumbnail.
  Widget _trailing(AppNotification n) {
    if (n.isFollow) return _FollowButton(targetUid: n.senderUserId);
    if (n.hasRecipe && (n.recipeImage?.isNotEmpty ?? false)) {
      return _recipeThumb(n.recipeImage!);
    }
    return const SizedBox.shrink();
  }

  // Human-friendly action phrase, kept in sync with the backend copy.
  String _action(AppNotification n) {
    if (n.isLike) return 'liked your recipe.';
    if (n.isComment) return 'commented on your recipe.';
    if (n.isFollow) return 'started following you.';
    return n.message;
  }

  Widget _senderAvatar(AppNotification n) {
    final url = n.senderPhoto;
    return CircleAvatar(
      radius: 24,
      backgroundColor: _N.avatarBg,
      backgroundImage:
          url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      child: url.isEmpty
          ? Text(
              n.senderName.isNotEmpty ? n.senderName[0].toUpperCase() : '?',
              style: _f(18, FontWeight.w800, _N.textDark),
            )
          : null,
    );
  }

  Widget _recipeThumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        memCacheWidth: 120,
        placeholder: (_, __) => Container(color: _N.avatarBg),
        errorWidget: (_, __, ___) => _typeGlyph(null),
      ),
    );
  }

  Widget _typeGlyph(AppNotification? n) {
    final icon = n == null
        ? 'bowl'
        : n.isFollow
            ? 'user'
            : n.isComment
                ? 'comment'
                : 'heart';
    final color = (n?.isFollow ?? false) ? _N.green : _N.primary;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: OnboardingLineIcon(icon, size: 20, color: color),
    );
  }

  Widget _iconButton(String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: OnboardingLineIcon(icon, size: 20, color: _N.textDark),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  // Tapping the avatar always opens the sender's profile.
  void _openProfile(AppNotification n) {
    _c.markAsRead(n);
    Get.to(() => CreatorProfileScreen(
          userId: n.senderUserId,
          fallbackName: n.senderName,
          fallbackAvatar: n.senderPhoto,
        ));
  }

  Future<void> _open(AppNotification n) async {
    if (_opening) return;
    _opening = true;
    _c.markAsRead(n); // fire-and-forget; UI updates via the stream
    try {
      if (n.isFollow) {
        Get.to(() => CreatorProfileScreen(
              userId: n.senderUserId,
              fallbackName: n.senderName,
              fallbackAvatar: n.senderPhoto,
            ));
        return;
      }
      // Like / comment → the recipe is the receiver's OWN recipe.
      final recipe = await _fetchOwnRecipe(n.recipeId);
      if (recipe == null) {
        CustomSnackbar.show(
          title: 'Unavailable',
          message: 'This recipe is no longer available.',
          type: SnackbarType.info,
        );
        return;
      }
      Get.to(() => RecipeDetailScreen(
            recipe: recipe,
            focusCommentId: n.isComment ? n.commentId : null,
          ));
    } finally {
      _opening = false;
    }
  }

  Future<RecipeModel?> _fetchOwnRecipe(String? recipeId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null || recipeId == null || recipeId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (!doc.exists) return null;
      return RecipeModel.fromDocument(doc);
    } catch (_) {
      return null;
    }
  }

  // 2m ago · 1h ago · Yesterday · Jul 3
  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

/// Live Follow / Following button used on follow notifications. Reflects the
/// current follow state in real time and toggles it on tap (backend handled by
/// the existing FollowService — no notification backend is touched).
class _FollowButton extends StatelessWidget {
  final String targetUid;
  const _FollowButton({required this.targetUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FollowService.isFollowingStream(targetUid),
      builder: (context, snap) {
        final following = snap.data ?? false;
        return GestureDetector(
          onTap: () => FollowService.setFollow(targetUid, !following),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: following ? Colors.transparent : _N.primary,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: following ? _N.line : _N.primary,
                width: 1.4,
              ),
            ),
            child: Text(
              following ? 'Following' : 'Follow',
              style: _f(
                12.5,
                FontWeight.w800,
                following ? _N.textBody : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
