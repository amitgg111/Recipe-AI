import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/user_service.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart';
import 'package:recipe_ai/widgets/tr_text.dart';
import 'package:recipe_ai/View/Home/settings/edit_profile_screen.dart';
import 'package:recipe_ai/View/Home/settings/my_recipes_screen.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/View/Home/social/follow_list_screen.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with WidgetsBindingObserver {
  final HomeController _home = Get.find<HomeController>();
  String _bio = '';
  String _contact = '';
  final String _username = '';
  int _followers = 0;
  int _following = 0;

  StreamSubscription<UserModel?>? _userSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadUserDoc();

    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _userSub = UserService.userStream(uid).listen((u) {
        if (u == null || !mounted) return;

        setState(() {
          _bio = u.bio;
          _followers = u.followersCount;
          _following = u.followingCount;
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserDoc();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadUserDoc() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();

      if (data != null && mounted) {
        setState(() {
          _bio = (data['bio'] as String?)?.trim() ?? '';
          _contact = (data['contact'] as String?)?.trim() ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final recipes = _home.recipes;
          final preview = recipes.take(3).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              SettingsUi.header(
                'profile'.tr,
                trailing: SettingsUi.squareIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () async {
                    await Get.to(() => const EditProfileScreen());

                    if (!mounted) return;

                    await _refreshProfile();
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Avatar + name + bio
              Column(
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
                    child: const ProfileAvatar(size: 96),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : 'user'.tr,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_username.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '@$_username',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                  if (_bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // Stats
              _statsCard(recipes.length),

              // Details
              SettingsUi.label('section_details'.tr),
              SettingsUi.card(
                rows: [
                  _detailRow(
                    Icons.mail_outline_rounded,
                    'email'.tr,
                    user?.email ?? '—',
                    iconWidget: const OnboardingLineIcon(
                      'mail',
                      size: 20,
                      color: AppColors.textBodyDark,
                    ),
                  ),
                  _detailRow(
                    Icons.phone_outlined,
                    'contact'.tr,
                    _contact.isEmpty ? 'not_set'.tr : _contact,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _privacyNote(),

              // Favorites — recipes the user hearted on their cards.
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: GestureDetector(
                  onTap: () =>
                      Get.to(() => const MyRecipesScreen(favoritesOnly: true)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.pinterest.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const OnboardingLineIcon(
                            'heart',
                            size: 18,
                            color: AppColors.pinterest,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'favorite_recipes'.tr,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${recipes.where((r) => r.isFavorite).length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // My recipes
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 22, 4, 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'my_recipes_count'.trParams({
                        'count': '${recipes.length}',
                      }),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHint,
                        letterSpacing: 0.72,
                      ),
                    ),
                    if (recipes.isNotEmpty)
                      GestureDetector(
                        onTap: () => Get.to(() => const MyRecipesScreen()),
                        child: Text(
                          'see_all'.tr,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (preview.isEmpty)
                _emptyRecipes()
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
                      for (var i = 0; i < preview.length; i++)
                        _recipeRow(preview[i], i != preview.length - 1),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statsCard(int recipeCount) {
    final uid = AuthService.currentUser?.uid;
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'profile'.tr;
    void openList(bool followers) {
      if (uid == null) return;
      Get.to(
        () => FollowListScreen(
          userId: uid,
          title: name,
          showFollowers: followers,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _stat('$recipeCount', 'recipes'.tr, null),
          _divider(),
          _stat(_fmtCount(_followers), 'followers'.tr, () => openList(true)),
          _divider(),
          _stat(_fmtCount(_following), 'following'.tr, () => openList(false)),
        ],
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  Widget _stat(String value, String label, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFFF0ECE4));

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Widget? iconWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          iconWidget ?? Icon(icon, size: 20, color: AppColors.textBodyDark),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.greenBgLight,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.greenBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingLineIcon('lock', size: 18, color: AppColors.green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'email_contact_private'.tr,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.green.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipeRow(RecipeModel recipe, bool showDivider) {
    return Column(
      children: [
        InkWell(
          onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                _thumb(recipe.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recipe.category?.isNotEmpty == true
                            ? recipe.category!
                            : 'recipe'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _visibilityBadge(recipe.isPublic),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant_rounded, color: Colors.white),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,

        // Small thumbnail mate enough.
        memCacheWidth: 100,
        memCacheHeight: 100,

        // Cache ma hoy to immediately show.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,

        placeholder: (_, __) =>
            Container(width: 50, height: 50, color: AppColors.shimmerBase),

        errorWidget: (_, __, ___) => Container(
          color: AppColors.shimmerBase,
          child: const Icon(Icons.restaurant_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _visibilityBadge(bool isPublic) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.greenBgLight : const Color(0xFFF2EEE6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: OnboardingLineIcon(
        isPublic ? 'globe' : 'lock',
        size: 16,
        color: isPublic ? AppColors.green : AppColors.textMedium,
      ),
    );
  }

  Widget _emptyRecipes() {
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
          const OnboardingLineIcon(
            'book',
            size: 34,
            color: AppColors.iconLight,
          ),
          const SizedBox(height: 10),
          Text(
            'no_recipes_yet'.tr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
