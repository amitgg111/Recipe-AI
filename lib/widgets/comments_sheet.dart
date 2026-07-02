import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/Service/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Comments bottom sheet — matched to the HTML "Comments (sheet)" design.
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textBody = Color(0xFF5A5147);
  static const textHint = Color(0xFFA89F90);
  static const textLight = Color(0xFF9A938A);
  static const line = Color(0xFFF4ECDF);
  static const fieldBg = Color(0xFFFBF7F0);
  static const fieldBorder = Color(0xFFE7DECE);
  static const avatarBg = Color(0xFFEDE5D7);
}

TextStyle _f(double s, FontWeight w, Color c, {double? h}) =>
    GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h);

class CommentsSheet extends StatefulWidget {
  final String ownerId;
  final String recipeId;

  /// Fires immediately when the current user posts a comment, so callers can
  /// bump their own comment counter optimistically (no round-trip needed).
  final VoidCallback? onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.ownerId,
    required this.recipeId,
    this.onCommentAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String ownerId,
    required String recipeId,
    VoidCallback? onCommentAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x731E1B18),
      builder: (_) => CommentsSheet(
        ownerId: ownerId,
        recipeId: recipeId,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await RecipeSocialService.addComment(widget.ownerId, widget.recipeId,
          text: text);
      widget.onCommentAdded?.call();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _reply(String name) {
    _ctrl.text = '@$name ';
    _ctrl.selection =
        TextSelection.collapsed(offset: _ctrl.text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenH * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E0D2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            // Header with live count
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream:
                  RecipeSocialService.recipeStream(widget.ownerId, widget.recipeId),
              builder: (_, snap) {
                final count =
                    (snap.data?.data()?['commentsCount'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text('Comments · $count',
                      style: _f(16, FontWeight.w800, _C.textDark)),
                );
              },
            ),
            const Divider(height: 1, color: _C.line),
            // Comment list
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: RecipeSocialService.commentsStream(
                    widget.ownerId, widget.recipeId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: CircularProgressIndicator(color: _C.primary)),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 46),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mode_comment_outlined,
                              size: 40,
                              color: _C.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No comments yet',
                              style: _f(15, FontWeight.w700, _C.textBody)),
                          const SizedBox(height: 3),
                          Text('Be the first to leave one.',
                              style: _f(13, FontWeight.w500, _C.textLight)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    itemCount: docs.length,
                    itemBuilder: (_, i) => _commentRow(docs[i].data()),
                  );
                },
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _commentRow(Map<String, dynamic> d) {
    final name = (d['userName'] as String?)?.trim();
    final avatar = d['userAvatar'] as String?;
    final text = d['text'] as String? ?? '';
    final ts = d['createdAt'];
    final when = ts is Timestamp ? _ago(ts.toDate()) : '';
    final display = (name != null && name.isNotEmpty) ? name : 'Anonymous';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(avatar, display, 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(display, style: _f(13.5, FontWeight.w800, _C.textDark)),
                    if (when.isNotEmpty) ...[
                      const SizedBox(width: 7),
                      Text(when, style: _f(12, FontWeight.w600, _C.textHint)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: _f(13.5, FontWeight.w400, _C.textBody, h: 1.45)),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => _reply(display),
                  behavior: HitTestBehavior.opaque,
                  child: Text('Reply',
                      style: _f(12, FontWeight.w700, _C.textLight)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    final avatar = AuthService.currentUser?.photoURL;
    final name = AuthService.currentUser?.displayName ?? 'You';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          _avatar(avatar, name, 36),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.fieldBorder),
              ),
              padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      cursorColor: _C.primary,
                      style: _f(14, FontWeight.w500, _C.textDark),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        hintStyle: _f(14, FontWeight.w500, _C.textHint),
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _C.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded,
                              size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? url, String name, double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _C.avatarBg,
      backgroundImage:
          (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: _f(size * 0.36, FontWeight.w800, _C.textDark))
          : null,
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return 'now';
  }
}
