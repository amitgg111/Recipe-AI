import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/user_service.dart';
import 'package:recipe_ai/View/Home/public_recipe_view_screen.dart';
import 'package:recipe_ai/View/Home/social/follow_list_screen.dart';
import 'package:recipe_ai/View/Home/social/social_widgets.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// A public creator profile: photo, name, @username, bio, stats, follow button,
/// and their PUBLIC recipes only.
class CreatorProfileScreen extends StatelessWidget {
  final String userId;
  final String? fallbackName;
  final String? fallbackAvatar;

  const CreatorProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
    this.fallbackAvatar,
  });

  bool get _isSelf => AuthService.currentUser?.uid == userId;

  TextStyle _f(double s, FontWeight w, Color c, {double? sp}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: s, fontWeight: w, color: c, letterSpacing: sp);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: UserService.userStream(userId),
          builder: (context, snap) {
            final user = snap.data ??
                UserModel(
                  uid: userId,
                  name: fallbackName ?? '',
                  username: '',
                  bio: '',
                  photoUrl: fallbackAvatar ?? '',
                  email: '',
                  followersCount: 0,
                  followingCount: 0,
                );
            return StreamBuilder<List<DiscoverRecipe>>(
              stream: UserService.publicRecipesStream(
                userId,
                authorName: user.displayName,
                authorAvatar: user.photoUrl.isNotEmpty
                    ? user.photoUrl
                    : fallbackAvatar,
              ),
              builder: (context, rSnap) {
                final recipes = rSnap.data ?? const <DiscoverRecipe>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 10),
                    _identity(user),
                    const SizedBox(height: 18),
                    _statsCard(context, user, recipes.length),
                    const SizedBox(height: 14),
                    if (!_isSelf)
                      FollowButton(targetUid: userId, expand: true),
                    if (!_isSelf) const SizedBox(height: 4),
                    _recipesSection(recipes),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 44,
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
          const Spacer(),
          Text('Profile', style: _f(17, FontWeight.w700, AppColors.textDark)),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _identity(UserModel user) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: UserAvatar(
            photoUrl: user.photoUrl.isNotEmpty ? user.photoUrl : fallbackAvatar,
            initial: user.initial,
            size: 96,
          ),
        ),
        const SizedBox(height: 12),
        Text(user.displayName,
            style: _f(21, FontWeight.w800, AppColors.textDark, sp: -0.3)),
        const SizedBox(height: 3),
        Text('@${user.handle}',
            style: _f(13.5, FontWeight.w600, AppColors.textMedium)),
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: _f(13.5, FontWeight.w500, AppColors.textBodyDark)
                .copyWith(height: 1.45),
          ),
        ],
      ],
    );
  }

  Widget _statsCard(BuildContext context, UserModel user, int publicRecipes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _stat('$publicRecipes', 'Recipes', null),
          _divider(),
          _stat(
            _fmt(user.followersCount),
            'Followers',
            () => Get.to(() => FollowListScreen(
                  userId: userId,
                  title: user.displayName,
                  showFollowers: true,
                )),
          ),
          _divider(),
          _stat(
            _fmt(user.followingCount),
            'Following',
            () => Get.to(() => FollowListScreen(
                  userId: userId,
                  title: user.displayName,
                  showFollowers: false,
                )),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(value, style: _f(19, FontWeight.w800, AppColors.textDark)),
            const SizedBox(height: 2),
            Text(label, style: _f(11.5, FontWeight.w600, AppColors.textMedium)),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFFF0ECE4));

  Widget _recipesSection(List<DiscoverRecipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 11),
          child: Text('PUBLIC RECIPES · ${recipes.length}',
              style: _f(12, FontWeight.w800, AppColors.textHint, sp: 0.72)),
        ),
        if (recipes.isEmpty)
          _empty()
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recipes.length; i++)
                  _recipeRow(recipes[i], i != recipes.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recipeRow(DiscoverRecipe r, bool divider) {
    return Column(
      children: [
        InkWell(
          onTap: () => Get.to(() => PublicRecipeViewScreen(recipe: r)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                _thumb(r.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _f(14, FontWeight.w700, AppColors.textDark)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 5),
                          Text('${r.likesCount}',
                              style: _f(12, FontWeight.w600,
                                  AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.greenBgLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.public_rounded,
                      size: 16, color: AppColors.green),
                ),
              ],
            ),
          ),
        ),
        if (divider)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _thumb(String? url) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.startsWith('http'))
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 150,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.restaurant_rounded, color: Colors.white),
            )
          : const Icon(Icons.restaurant_rounded, color: Colors.white),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.public_off_rounded,
              size: 34, color: AppColors.iconLight),
          const SizedBox(height: 10),
          Text('No public recipes yet',
              style: _f(14, FontWeight.w700, AppColors.textDark)),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
