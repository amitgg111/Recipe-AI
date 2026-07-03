import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/follow_service.dart';
import 'package:recipe_ai/Service/user_service.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/View/Home/social/social_widgets.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/sliding_segmented.dart';

/// Followers / Following list for [userId], with a segmented toggle.
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool showFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late bool _followers = widget.showFollowers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 10),
            _toggle(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _followers
                    ? FollowService.followerUidsStream(widget.userId)
                    : FollowService.followingUidsStream(widget.userId),
                builder: (context, snap) {
                  final uids = snap.data;
                  if (uids == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2.5),
                    );
                  }
                  if (uids.isEmpty) return _empty();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    itemCount: uids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _userRow(uids[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFEFEDE6)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.title.isNotEmpty ? widget.title : 'Profile',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SlidingSegmented.tabs(
        labels: const ['Followers', 'Following'],
        selectedIndex: _followers ? 0 : 1,
        onChanged: (i) => setState(() => _followers = i == 0),
        height: 38,
      ),
    );
  }

  Widget _userRow(String uid) {
    return StreamBuilder<UserModel?>(
      stream: UserService.userStream(uid),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: UserTile(
            user: user,
            onTap: () => Get.to(() => CreatorProfileScreen(
                  userId: user.uid,
                  fallbackName: user.displayName,
                  fallbackAvatar: user.photoUrl,
                )),
          ),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_followers ? Icons.group_outlined : Icons.person_add_alt_1_outlined,
              size: 40, color: AppColors.iconLight),
          const SizedBox(height: 12),
          Text(
            _followers ? 'No followers yet' : 'Not following anyone yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
