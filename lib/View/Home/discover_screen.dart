import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/View/Home/public_recipe_view_screen.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart'
    show CookbookPickerSheet;
import 'package:recipe_ai/widgets/comments_sheet.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants (matched to the HTML "Discover (feed)" design)
// ─────────────────────────────────────────────────────────────────────────────
class _D {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const border = Color(0xFFF0E7D6);
  static const chipBorder = Color(0xFFEDE3D2);
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textBody = Color(0xFF5A5147);
  static const textHint = Color(0xFFA89F90);
  static const textLight = Color(0xFF9A938A);
}

TextStyle _f(double s, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: s,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final DiscoverController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DiscoverController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _D.bg,
      body: Column(
        children: [
          // ── Header: logo + credits ──
          Container(
            color: _D.bg,
            padding: EdgeInsets.only(top: top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Row(
                    children: [
                      const AppLogo(size: 28),
                      const SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Recipe',
                          style: _f(18, FontWeight.w800, _D.textDark, ls: -0.3),
                          children: [
                            TextSpan(
                              text: ' AI',
                              style: _f(
                                18,
                                FontWeight.w800,
                                _D.primary,
                                ls: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _creditsBadge(),
                    ],
                  ),
                ),

                // Search bar (opens search focus on the community feed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchField(controller: controller),
                ),
                const SizedBox(height: 12),

                // Category chips
                Obx(() {
                  final selected = controller.selectedCategory.value;
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = controller.categories[i];
                        final on = selected == cat;
                        return GestureDetector(
                          onTap: () => controller.selectCategory(cat),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: on ? _D.primary : _D.card,
                              borderRadius: BorderRadius.circular(20),
                              border: on
                                  ? null
                                  : Border.all(color: _D.chipBorder),
                              boxShadow: on
                                  ? [
                                      BoxShadow(
                                        color: _D.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                        spreadRadius: -10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              textAlign: TextAlign.center,
                              cat,
                              style: _f(
                                13,
                                on ? FontWeight.w700 : FontWeight.w600,
                                on ? Colors.white : _D.textBody,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Feed ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: _D.primary),
                );
              }
              final items = controller.filteredRecipes;
              if (items.isEmpty) {
                return _emptyState();
              }
              return RefreshIndicator(
                color: _D.primary,
                onRefresh: () => controller.fetchDiscoverRecipes(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _RecipeCard(recipe: items[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _creditsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFD0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 13, color: _D.primary),
          const SizedBox(width: 5),
          Text('5/5', style: _f(13, FontWeight.w700, const Color(0xFFC0860F))),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 56,
            color: _D.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No recipes found',
            style: _f(16, FontWeight.w600, AppColors.textMedium),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different category or search',
            style: _f(13, FontWeight.w400, _D.textHint),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Search field (readonly-styled, drives controller.searchQuery)
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchField extends StatelessWidget {
  final DiscoverController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.chipBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: _D.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              cursorColor: _D.primary,
              style: _f(14, FontWeight.w500, _D.textDark),
              decoration: InputDecoration(
                hintText: 'Search community recipes',
                hintStyle: _f(14, FontWeight.w500, _D.textHint),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recipe post card
// ═══════════════════════════════════════════════════════════════════════════════

class _RecipeCard extends StatefulWidget {
  final DiscoverRecipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  DiscoverRecipe get recipe => widget.recipe;

  late int _likes = recipe.likesCount;
  late int _shares = recipe.sharesCount;
  late int _saves = recipe.savesCount;
  late int _comments = recipe.commentsCount;
  bool _liked = false;
  bool _saved = false;
  bool _busyLike = false;
  bool _busySave = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final liked = await RecipeSocialService.isLiked(recipe.userId, recipe.id);
      final saved = await RecipeSocialService.isSaved(recipe.userId, recipe.id);
      if (mounted) {
        setState(() {
          _liked = liked;
          _saved = saved;
        });
      }
    } catch (_) {}
  }

  String get _time =>
      recipe.totalTime ?? recipe.cookTime ?? recipe.prepTime ?? '';

  String _ago() {
    final dt = recipe.createdAt;
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'just now';
  }

  void _open() => Get.to(() => PublicRecipeViewScreen(recipe: recipe));

  void _openAuthor() {
    if (recipe.userId.isEmpty) return;
    Get.to(
      () => CreatorProfileScreen(
        userId: recipe.userId,
        fallbackName: recipe.userName,
        fallbackAvatar: recipe.userAvatar,
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_busyLike) return;
    _busyLike = true;
    final target = !_liked;
    // Optimistic: update the UI instantly, then persist in the background.
    setState(() {
      _liked = target;
      _likes += target ? 1 : -1;
    });
    try {
      await RecipeSocialService.setLike(recipe.userId, recipe.id, target);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !target;
          _likes += target ? -1 : 1;
        });
      }
    } finally {
      _busyLike = false;
    }
  }

  // Save → copy the recipe into my collection, then open the multi-select
  // "add to cookbook" sheet so the user can file it into one or more cookbooks.
  Future<void> _openSaveSheet() async {
    if (_busySave) return;
    _busySave = true;
    try {
      final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);
      if (copyId == null || !mounted) return;
      await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CookbookPickerSheet(
          cookbookController: Get.find<CookbookController>(),
          recipeId: copyId,
          recipeImageUrl: recipe.imageUrl,
        ),
      );
      // Copy now lives in My Recipes → mark as saved.
      if (mounted && !_saved) {
        setState(() {
          _saved = true;
          _saves += 1;
        });
      }
      RecipeSocialService.setSave(recipe.userId, recipe.id, true);
    } finally {
      _busySave = false;
    }
  }

  void _share() {
    final buf = StringBuffer()
      ..writeln(recipe.title)
      ..writeln();
    if (recipe.ingredients.isNotEmpty) {
      buf.writeln('INGREDIENTS');
      for (final i in recipe.ingredients) {
        buf.writeln('• $i');
      }
    }
    Share.share(buf.toString(), subject: recipe.title);
    RecipeSocialService.registerShare(recipe.userId, recipe.id);
    if (mounted) setState(() => _shares += 1);
  }

  @override
  Widget build(BuildContext context) {
    final ago = _ago();
    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _D.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A211B).withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -26,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAuthor,
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFEDE5D7),
                    backgroundImage:
                        (recipe.userAvatar != null &&
                            recipe.userAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(recipe.userAvatar!)
                        : null,
                    child:
                        (recipe.userAvatar == null ||
                            recipe.userAvatar!.isEmpty)
                        ? Text(
                            recipe.userName.isNotEmpty
                                ? recipe.userName[0].toUpperCase()
                                : 'C',
                            style: _f(14, FontWeight.w800, _D.textDark),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openAuthor,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.userName.isNotEmpty
                              ? recipe.userName
                              : 'Recipe creator',
                          style: _f(13.5, FontWeight.w800, _D.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ago.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            ago,
                            style: _f(11.5, FontWeight.w600, _D.textLight),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _open,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View recipe',
                        style: _f(12.5, FontWeight.w700, _D.primary),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: _D.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Photo with title + time overlay
          GestureDetector(
            onTap: _open,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 900,
                              placeholder: (_, __) => _imgPh(),
                              errorWidget: (_, __, ___) => _imgPh(),
                            )
                          : _imgPh(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00140F0A), Color(0xB8140F0A)],
                            stops: [0.45, 1.0],
                          ),
                        ),
                      ),
                      if (_time.isNotEmpty)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: _D.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _time,
                                  style: _f(12, FontWeight.w800, _D.textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 13,
                        child: Text(
                          recipe.title,
                          style: _f(
                            19,
                            FontWeight.w800,
                            Colors.white,
                            h: 1.15,
                            ls: -0.38,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action bar with counters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _action(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? _D.primary : _D.textDark,
                  count: _likes,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 20),
                _action(
                  icon: Icons.mode_comment_outlined,
                  color: _D.textDark,
                  count: _comments,
                  onTap: () => CommentsSheet.show(
                    context,
                    ownerId: recipe.userId,
                    recipeId: recipe.id,
                    onCommentAdded: () {
                      if (mounted) setState(() => _comments += 1);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                _action(
                  icon: Icons.send_outlined,
                  color: _D.textDark,
                  count: _shares,
                  showCount: false,
                  onTap: _share,
                ),
                const Spacer(),
                _action(
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _saved ? _D.primary : _D.textDark,
                  count: _saves,
                  showCount: false,
                  onTap: _openSaveSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    bool showCount = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          if (showCount && count > 0) ...[
            const SizedBox(width: 7),
            Text('$count', style: _f(13, FontWeight.w700, _D.textBody)),
          ],
        ],
      ),
    );
  }

  Widget _imgPh() => Container(
    color: const Color(0xFFEDE5D7),
    child: const Center(
      child: Icon(Icons.restaurant_rounded, size: 40, color: Color(0xFFC7BCAC)),
    ),
  );
}
