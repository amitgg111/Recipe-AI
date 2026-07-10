import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/follow_service.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// Circular avatar for any user — remote photo with an initial fallback.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initial;
  final double size;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.initial,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null &&
        photoUrl!.isNotEmpty &&
        photoUrl!.startsWith('http');
    return ClipOval(
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decode at ~3x the display size instead of full resolution.
              memCacheWidth: (size * 3).round(),
              placeholder: (_, __) => _fallback(),
              errorWidget: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// A live Follow / Following button wired to [FollowService]. Hides itself when
/// the target is the current user.
class FollowButton extends StatefulWidget {
  final String targetUid;
  final bool expand;

  const FollowButton({super.key, required this.targetUid, this.expand = false});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  StreamSubscription<bool>? _sub;
  bool _following = false;
  bool _ready = false;
  bool _busy = false;

  bool get _isSelf => AuthService.currentUser?.uid == widget.targetUid;

  @override
  void initState() {
    super.initState();
    if (!_isSelf) {
      _sub = FollowService.isFollowingStream(widget.targetUid).listen((v) {
        if (!mounted) return;
        // Don't clobber an in-flight optimistic value.
        if (_busy) return;
        setState(() {
          _following = v;
          _ready = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    final next = !_following;
    setState(() {
      _following = next;
      _busy = true;
    });
    try {
      await FollowService.setFollow(widget.targetUid, next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelf) return const SizedBox.shrink();

    final following = _following;
    final child = Container(
      height: 36,
      width: widget.expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: widget.expand ? 0 : 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: following ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Text(
        following ? 'Following' : 'Follow',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: following ? Colors.white : AppColors.primary,
        ),
      ),
    );

    return Opacity(
      opacity: _ready ? 1 : 0.5,
      child: GestureDetector(
        onTap: _ready && !_busy ? _toggle : null,
        child: child,
      ),
    );
  }
}

/// A user row: avatar + name + @handle + follow button. Tapping opens the
/// creator profile.
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final bool showFollowButton;

  const UserTile({
    super.key,
    required this.user,
    required this.onTap,
    this.showFollowButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: [
            UserAvatar(
              photoUrl: user.photoUrl,
              initial: user.initial,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '@${user.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (showFollowButton) ...[
              const SizedBox(width: 10),
              FollowButton(targetUid: user.uid),
            ],
          ],
        ),
      ),
    );
  }
}
