import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/View/Home/settings/upgrade_plus_screen.dart';
import 'package:recipe_ai/widgets/app_logo.dart';
import 'package:recipe_ai/widgets/notification_bell.dart';
import 'package:recipe_ai/View/Home/public_recipe_view_screen.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart'
    show CookbookPickerSheet;
import 'package:recipe_ai/widgets/comments_sheet.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
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
  final ScrollController scrollController = ScrollController();
  late final DiscoverController controller;
  late final ProfileController profileController;
  final ScrollController categoryScrollController = ScrollController();

  final ScrollController feedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    controller = Get.put(DiscoverController(), permanent: true);

    profileController = Get.find<ProfileController>();

    feedScrollController.addListener(_onFeedScroll);

    // Start downloading every loaded card's photo as soon as the feed data
    // arrives, rather than waiting for each card to scroll near the viewport.
    // cacheExtent alone only helps once a card is close to being built; this
    // gets all the requests in flight up front, so a fast scroll finds them
    // already decoded instead of blank.
    _precacheSub = ever<List<DiscoverRecipe>>(controller.recipes, (list) {
      if (!mounted) return;
      _precacheFeedImages(list);
    });
  }

  Worker? _precacheSub;
  final Set<String> _precached = {};

  void _precacheFeedImages(List<DiscoverRecipe> list) {
    // Post-frame so this never competes with the frame that shows the feed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final r in list) {
        final url = r.imageUrl;
        if (url == null || url.isEmpty) continue;
        if (!_precached.add(url)) continue; // already requested
        precacheImage(
          CachedNetworkImageProvider(url, maxWidth: 700),
          context,
          onError: (_, __) {}, // a broken image must not throw here
        );
      }
    });
  }

  @override
  void dispose() {
    _precacheSub?.dispose();
    feedScrollController.removeListener(_onFeedScroll);
    feedScrollController.dispose();
    categoryScrollController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    if (!feedScrollController.hasClients) return;

    final position = feedScrollController.position;

    // Load more when user is close to bottom
    if (position.pixels >= position.maxScrollExtent - 800) {
      if (!controller.isLoading.value && !controller.isLoadingMore) {
        controller.loadMoreRecipes();
      }
    }
  }

  // Translates the displayed chip label only — the underlying category value
  // (used for filtering in DiscoverController) is left untouched.
  String _catLabel(String cat) {
    switch (cat) {
      case 'All':
        return 'All';
      case 'Quick & Easy':
        return 'quick_easy'.tr;
      case 'Vegan':
        return 'vegan'.tr;
      case 'Desserts':
        return 'desserts'.tr;
      case 'Breakfast':
        return 'breakfast'.tr;
      case 'Lunch':
        return 'lunch'.tr;
      case 'Dinner':
        return 'dinner'.tr;
      case 'Drinks':
        return 'drinks'.tr;
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Obx(() {
      final _ = profileController.name.value;
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        const AppLogo(size: 36),
                        const SizedBox(width: 10),
                        const AppWordmark(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        const Spacer(),
                        const NotificationBell(),
                        const SizedBox(width: 10),
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
                        controller: categoryScrollController,
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
                                _catLabel(cat),
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

                // return RefreshIndicator(
                //   color: _D.primary,

                //   onRefresh: () =>
                //       controller.fetchDiscoverRecipes(refresh: true),

                //   child: ListView.separated(
                //     controller: feedScrollController,

                //     // Build ~5 cards beyond the viewport instead of Flutter's
                //     // default 250px (barely half a card here, since each is
                //     // ~400px tall). CachedNetworkImage starts its download when
                //     // the card BUILDS, so with the default the photo only
                //     // begins loading as it scrolls into view — which is why
                //     // images appear late while scrolling. This gives each image
                //     // a head start and costs a few hundred KB of decoded
                //     // bitmaps, bounded by memCacheWidth: 700.
                //     cacheExtent: 2000,

                //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

                //     itemCount:
                //         items.length + (controller.isLoadingMore ? 1 : 0),

                //     separatorBuilder: (_, index) {
                //       if (index >= items.length - 1) {
                //         return const SizedBox.shrink();
                //       }

                //       return const SizedBox(height: 16);
                //     },

                //     itemBuilder: (_, index) {
                //       if (index >= items.length) {
                //         return const Padding(
                //           padding: EdgeInsets.symmetric(vertical: 24),
                //           child: Center(
                //             child: CircularProgressIndicator(color: _D.primary),
                //           ),
                //         );
                //       }

                //       return _RecipeCard(recipe: items[index]);
                //     },
                //   ),
                // );
                return RefreshIndicator(
                  color: _D.primary,
                  backgroundColor: Colors.white,

                  // Pull down = completely refresh first page
                  onRefresh: () async {
                    await controller.fetchDiscoverRecipes(refresh: true);

                    // Refresh pachi top par lai jao
                    if (feedScrollController.hasClients) {
                      await feedScrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },

                  child: ListView.separated(
                    controller: feedScrollController,

                    // Important: enough area for smooth scrolling/pagination
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),

                    cacheExtent: 2500,

                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),

                    itemCount:
                        items.length + (controller.isLoadingMore ? 1 : 0),

                    separatorBuilder: (_, index) {
                      if (index >= items.length - 1) {
                        return const SizedBox.shrink();
                      }

                      return const SizedBox(height: 16);
                    },

                    itemBuilder: (_, index) {
                      // Bottom loading indicator
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _D.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      return _RecipeCard(recipe: items[index]);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _creditsBadge() {
    return Obx(() {
      final sub = SubscriptionService.instance;

      final plus = sub.isPlusListenable.value;

      final remaining = sub.freeCreditsListenable.value.clamp(
        0,
        SubscriptionService.kWeeklyFreeCredits,
      );

      print(
        '[UI] Firebase remaining credits:----------------- '
        '$remaining',
      );

      return GestureDetector(
        onTap: () {
          Get.to(() => const UpgradePlusScreen());
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: plus ? AppColors.purpleBg : AppColors.goldBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: OnboardingLineIcon(
                  plus ? 'crown' : 'sparkF',
                  size: 19,
                  color: plus ? AppColors.purpleDark : AppColors.primary,
                ),
              ),

              const SizedBox(width: 5),

              Text(
                plus ? 'PLUS' : '$remaining Left',
                style: AppTextStyles.chipLabel.copyWith(
                  color: plus ? AppColors.purpleDark : AppColors.gold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft illustration container
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: OnboardingLineIcon(
                      'search',
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'no_recipes_found'.tr,
              textAlign: TextAlign.center,
              style: _f(18, FontWeight.w700, AppColors.textDark),
            ),

            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'try_different_category_or_search'.tr,
                textAlign: TextAlign.center,
                style: _f(
                  13,
                  FontWeight.w400,
                  _D.textHint,
                ).copyWith(height: 1.5),
              ),
            ),
          ],
        ),
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
          const OnboardingLineIcon('search', size: 20, color: _D.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v.trim(),
              cursorColor: _D.primary,
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: _f(14, FontWeight.w500, _D.textDark),
              decoration: InputDecoration(
                hintText: 'search_community_recipes'.tr,
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
  ProfileController get _profile => Get.find<ProfileController>();

  bool _busyLike = false;
  bool _busySave = false;

  bool _isLiked = false;
  bool _isSaved = false;
  DiscoverController get _disc => Get.find<DiscoverController>();
  // NOTE: liked/saved status is no longer fetched per-card here.
  // DiscoverController batch-loads likedOriginalIds/savedOriginalIds ONCE for
  // the whole feed (in fetchDiscoverRecipes), so opening Discover no longer
  // fires 2 Firestore reads per visible card — that was the load/lag source.
  @override
  void initState() {
    super.initState();

    final disc = Get.find<DiscoverController>();

    _isLiked = disc.likedOriginalIds.contains(recipe.id);
    _isSaved = disc.savedOriginalIds.contains(recipe.id);
  }

  String get _time =>
      recipe.totalTime ?? recipe.cookTime ?? recipe.prepTime ?? '';

  /// Normalises whatever time string the recipe stored ("20m", "90m", "50 mins",
  /// "1h 30m"…) into the clean "30 min" / "1 hr 30 min" form used in the design.
  String _prettyTime(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.isEmpty) return '';
    int? hours;
    int? mins;
    final hM = RegExp(r'(\d+)\s*(?:h|hr|hour)').firstMatch(s);
    final mM = RegExp(r'(\d+)\s*(?:m|min)').firstMatch(s);
    if (hM != null) hours = int.tryParse(hM.group(1)!);
    if (mM != null) mins = int.tryParse(mM.group(1)!);
    if (hours == null && mins == null) {
      final n = RegExp(r'(\d+)').firstMatch(s);
      if (n == null) return raw; // no number → show as stored
      mins = int.tryParse(n.group(1)!);
    }
    final total = (hours ?? 0) * 60 + (mins ?? 0);
    if (total <= 0) return raw;
    if (total < 60) return '$total min';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  /// "1204" → "1,204" so big counts read like the design.
  String _fmtNum(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

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

  void _open() {
    // Push on the tap frame. PublicRecipeViewScreen reads the translation
    // cache synchronously as it builds and batches whatever is missing after
    // the first frame, so nothing runs between the tap and the transition.
    //
    // This used to await translateForDetail() — roughly 22 live ML Kit calls
    // for a typical recipe, plus a full cache disk write per batch of 8 —
    // before pushing the route. The feed froze for a second or more with no
    // spinner and not even a ripple, which is the redirect delay.

    Get.to(
      () => PublicRecipeViewScreen(
        recipe: recipe,

        onSocialChanged:
            ({
              int? likes,
              int? saves,
              int? comments,
              bool? liked,
              bool? saved,
            }) {
              _disc.updateRecipeSocial(
                recipe.id,
                likes: likes,
                saves: saves,
                comments: comments,
                liked: liked,
                saved: saved,
              );
            },
      ),
    );
  }

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

    final disc = _disc;
    final previous = _isLiked;
    final target = !previous;

    // Instant UI update
    if (mounted) {
      setState(() {
        _isLiked = target;
      });
    }

    // Update shared state immediately
    if (target) {
      disc.likedOriginalIds.add(recipe.id);
    } else {
      disc.likedOriginalIds.remove(recipe.id);
    }

    disc.likedOriginalIds.refresh();

    _busyLike = true;

    try {
      await RecipeSocialService.setLike(recipe.userId, recipe.id, target);
    } catch (e) {
      // Rollback UI
      if (mounted) {
        setState(() {
          _isLiked = previous;
        });
      }

      // Rollback shared state
      if (previous) {
        disc.likedOriginalIds.add(recipe.id);
      } else {
        disc.likedOriginalIds.remove(recipe.id);
      }

      disc.likedOriginalIds.refresh();

      debugPrint('[_toggleLike] Error: $e');
    } finally {
      _busyLike = false;
    }
  }

  // Save → open the multi-select "add to cookbook" sheet. The recipe only
  // counts as saved when the user actually files it into a cookbook via the
  // sheet's Done button. A copy is created up-front so the picker has something
  // to file, but if the user dismisses the sheet (or taps Done without picking
  // a cookbook) the copy is rolled back out — nothing is left in My Recipes.
  // Future<void> _openSaveSheet() async {
  //   if (_busySave) return;
  //   _busySave = true;
  //   try {
  //     final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);
  //     if (copyId == null || !mounted) return;

  //     final result = await showModalBottomSheet<int>(
  //       context: context,
  //       isScrollControlled: true,
  //       backgroundColor: Colors.transparent,
  //       builder: (_) => CookbookPickerSheet(
  //         cookbookController: Get.find<CookbookController>(),
  //         recipeId: copyId,
  //         recipeImageUrl: recipe.imageUrl,
  //       ),
  //     );

  //     // Saved only if the user tapped Done with at least one cookbook selected
  //     // (the sheet pops the selected-cookbook count; a dismiss returns null).
  //     final confirmed = result != null && result > 0;
  //     if (!confirmed) {
  //       // Roll the copy back out so the discover-save "counts" only on Done.
  //       final deletedIds = await RecipeSocialService.removeSavedCopy(recipe);
  //       if (deletedIds.isNotEmpty && Get.isRegistered<CookbookController>()) {
  //         final cookbooks = Get.find<CookbookController>();
  //         for (final id in deletedIds) {
  //           await cookbooks.removeRecipeFromAllCookbooks(id);
  //         }
  //       }
  //       return;
  //     }

  //     // Filed into a cookbook → mark as saved (shared set drives every bookmark
  //     // for this recipe).
  //     if (mounted && !_saved) {
  //       _disc.savedOriginalIds.add(recipe.id);
  //       _disc.savedOriginalIds.refresh();
  //       // setState(() => _saves += 1);
  //     }
  //     RecipeSocialService.setSave(recipe.userId, recipe.id, true);
  //   } finally {
  //     _busySave = false;
  //   }
  // }
  Future<void> _openSaveSheet() async {
    if (_busySave) return;

    _busySave = true;

    try {
      // 1. First create a temporary saved copy.
      final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);

      if (copyId == null || !mounted) {
        return;
      }

      // 2. Open cookbook picker.
      final result = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CookbookPickerSheet(
          cookbookController: Get.find<CookbookController>(),
          recipeId: copyId,
          recipeImageUrl: recipe.imageUrl,
        ),
      );

      // 3. User must select at least one cookbook and press Done.
      final confirmed = result != null && result > 0;

      // 4. If cancelled/dismissed/no cookbook selected,
      //    delete the temporary copy.
      if (!confirmed) {
        final deletedIds = await RecipeSocialService.removeSavedCopy(recipe);

        if (deletedIds.isNotEmpty && Get.isRegistered<CookbookController>()) {
          final cookbooks = Get.find<CookbookController>();

          for (final id in deletedIds) {
            await cookbooks.removeRecipeFromAllCookbooks(id);
          }
        }

        return;
      }

      // 5. Successfully saved.
      if (mounted) {
        setState(() {
          _isSaved = true;
        });
      }

      _disc.savedOriginalIds.add(recipe.id);
      _disc.savedOriginalIds.refresh();

      // 6. Update Firestore/social save state.
      await RecipeSocialService.setSave(recipe.userId, recipe.id, true);
    } catch (e) {
      debugPrint('[_openSaveSheet] Error: $e');
    } finally {
      _busySave = false;
    }
  }

  Future<void> _toggleSave() async {
    if (_busySave) return;

    // If already saved → remove it.
    // if (_disc.savedOriginalIds.contains(recipe.id)) {
    //   await _unsave();
    //   return;
    // }
    if (_isSaved) {
      await _unsave();
    } else {
      await _openSaveSheet();
    }
    // If not saved → open cookbook picker.
    // await _openSaveSheet();
  }

  // Tapping the bookmark toggles: save (copy in) when unsaved, or permanently
  // remove the saved copy when already saved.
  // Future<void> _toggleSave() async {
  //   if (_busySave) return;

  //   if (_disc.savedOriginalIds.contains(recipe.id)) {
  //     await _unsave();
  //   } else {
  //     await _openSaveSheet();
  //   }
  // }

  // Future<void> _toggleSave() async {
  //   if (_saved) {
  //     await _unsave();
  //   } else {
  //     await _openSaveSheet();
  //   }
  // }

  // Un-save → permanently delete the saved copy from the user's recipes (and
  // any cookbooks it was filed into), then flip the bookmark back to empty.
  // Future<void> _unsave() async {
  //   if (_busySave) return;
  //   _busySave = true;
  //   try {
  //     final deletedIds = await RecipeSocialService.removeSavedCopy(recipe);
  //     if (deletedIds.isNotEmpty && Get.isRegistered<CookbookController>()) {
  //       final cookbooks = Get.find<CookbookController>();
  //       for (final id in deletedIds) {
  //         await cookbooks.removeRecipeFromAllCookbooks(id);
  //       }
  //     }
  //     RecipeSocialService.setSave(recipe.userId, recipe.id, false);
  //     _disc.savedOriginalIds.remove(recipe.id);
  //     _disc.savedOriginalIds.refresh();
  //     // if (mounted) {
  //     //   setState(() {
  //     //     if (_saves > 0) _saves -= 1;
  //     //   });
  //     // }
  //     CustomSnackbar.show(
  //       title: 'removed'.tr,
  //       message: 'recipe_removed_from_saved'.tr,
  //       type: SnackbarType.info,
  //     );
  //   } finally {
  //     _busySave = false;
  //   }
  // }
  Future<void> _unsave() async {
    if (_busySave) return;

    _busySave = true;

    try {
      // 1. Remove saved recipe copy.
      final deletedIds = await RecipeSocialService.removeSavedCopy(recipe);

      // 2. Remove deleted recipe from all cookbooks.
      if (deletedIds.isNotEmpty && Get.isRegistered<CookbookController>()) {
        final cookbooks = Get.find<CookbookController>();

        for (final id in deletedIds) {
          await cookbooks.removeRecipeFromAllCookbooks(id);
        }
      }

      // 3. Update Firestore.
      await RecipeSocialService.setSave(recipe.userId, recipe.id, false);

      // 4. Immediately update UI.
      _disc.savedOriginalIds.remove(recipe.id);
      _disc.savedOriginalIds.refresh();

      if (mounted) {
        setState(() {
          _isSaved = false;
        });
      }

      // 5. Snackbar.
      if (mounted) {
        CustomSnackbar.show(
          title: 'removed'.tr,
          message: 'recipe_removed_from_saved'.tr,
          type: SnackbarType.info,
        );
      }
    } catch (e) {
      debugPrint('[_unsave] Error: $e');
    } finally {
      _busySave = false;
    }
  }

  // void _share() {
  //   final buf = StringBuffer()
  //     ..writeln(recipe.title)
  //     ..writeln();
  //   if (recipe.ingredients.isNotEmpty) {
  //     buf.writeln('INGREDIENTS');
  //     for (final i in recipe.ingredients) {
  //       buf.writeln('• $i');
  //     }
  //   }
  //   Share.share(buf.toString(), subject: recipe.title);
  //   unawaited(RecipeSocialService.registerShare(recipe.userId, recipe.id));
  //   // RecipeSocialService.registerShare(recipe.userId, recipe.id);
  //   // if (mounted) setState(() => _shares += 1);
  // }
  Future<void> _share() async {
    final buf = StringBuffer()
      ..writeln(recipe.title)
      ..writeln();

    if (recipe.ingredients.isNotEmpty) {
      buf.writeln('INGREDIENTS');

      for (final i in recipe.ingredients) {
        buf.writeln('• $i');
      }
    }

    await Share.share(buf.toString(), subject: recipe.title);

    unawaited(RecipeSocialService.registerShare(recipe.userId, recipe.id));
  }

  @override
  Widget build(BuildContext context) {
    final ago = _ago();
    final isCurrentUser = recipe.userId == _profile.uid;
    return Obx(() {
      // Wrapped in Obx so this card rebuilds when the shared liked/saved sets
      // change (batch load completing, or another card/screen mutating them)
      // without each card doing its own network fetch.

      // final liked = _disc.likedOriginalIds.contains(recipe.id);
      // final saved = _disc.savedOriginalIds.contains(recipe.id);
      // final liked = _liked;
      // final saved = _saved;
      final sharedLiked = _disc.likedOriginalIds.contains(recipe.id);
      final sharedSaved = _disc.savedOriginalIds.contains(recipe.id);
      if (sharedLiked != _isLiked && !_busyLike) {
        _isLiked = sharedLiked;
      }

      if (sharedSaved != _isSaved && !_busySave) {
        _isSaved = sharedSaved;
      }

      final liked = _isLiked;
      final saved = _isSaved;

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
                              isCurrentUser && _profile.name.value.isNotEmpty
                                  ? _profile.name.value[0].toUpperCase()
                                  : recipe.userName.isNotEmpty
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
                            isCurrentUser && _profile.name.value.isNotEmpty
                                ? _profile.name.value
                                : recipe.userName.isNotEmpty
                                ? recipe.userName
                                : 'recipe_creator'.tr,
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
                          'view_recipe'.tr,
                          style: _f(12.5, FontWeight.w700, _D.primary),
                        ),
                        const OnboardingLineIcon(
                          'chevR',
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

                                // 280px card height માટે 700px enough છે
                                memCacheWidth: 700,
                                maxWidthDiskCache: 700,
                                // Cache ને લાંબા સમય સુધી રાખશે
                                cacheKey: recipe.imageUrl,

                                // Placeholder ને fade કર્યા વગર instantly show કરે
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,

                                placeholder: (_, __) => _imgPh(),
                                errorWidget: (_, __, ___) => _imgPh(),
                              )
                            : _imgPh(),
                        // Subtle bottom-only gradient — keeps the photo bright
                        // (like the design) while still making the title legible.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00140F0A),
                                Color(0x00140F0A),
                                Color(0x8A140F0A),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        if (recipe.cuisine != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${recipe.cuisine!.trim().replaceAll(' ', '')}',
                                style: _f(6.5, FontWeight.w800, _D.textDark),
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
                                  const OnboardingLineIcon(
                                    'clock',
                                    size: 13,
                                    color: _D.textDark,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _prettyTime(_time),
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
                            style:
                                _f(
                                  19,
                                  FontWeight.w800,
                                  Colors.white,
                                  h: 1.15,
                                  ls: -0.38,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xB3000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
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
                    iconWidget: OnboardingLineIcon(
                      // key: ValueKey('heart_${recipe.id}_$liked'),
                      key: ValueKey(
                        'heart_${recipe.id}_${liked ? 'liked' : 'unliked'}',
                      ),
                      liked ? 'heart' : 'heartO',
                      size: 22,
                      color: liked ? _D.primary : _D.textDark,
                    ),
                    // count: _likes,
                    count: recipe.likesCount,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 4),
                  _action(
                    iconWidget: const OnboardingLineIcon(
                      'comment',
                      size: 22,
                      color: _D.textDark,
                    ),
                    // count: _comments,
                    count: recipe.commentsCount,
                    onTap: () => CommentsSheet.show(
                      context,
                      ownerId: recipe.userId,
                      recipeId: recipe.id,
                      onCommentAdded: () {
                        // if (mounted) setState(() => _comments += 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  _action(
                    iconWidget: const OnboardingLineIcon(
                      'send',
                      size: 22,
                      color: _D.textDark,
                    ),
                    // count: _shares,
                    count: recipe.sharesCount,
                    showCount: false,
                    onTap: _share,
                  ),
                  const Spacer(),
                  _action(
                    iconWidget: OnboardingLineIcon(
                      // key: ValueKey('bookmark_${recipe.id}_$saved'),
                      key: ValueKey(
                        'bookmark_${recipe.id}_${saved ? 'saved' : 'unsaved'}',
                      ),
                      saved ? 'bookmarkF' : 'bookmark',
                      size: 22,
                      color: saved ? _D.primary : _D.textDark,
                    ),

                    // count: _saves,
                    count: recipe.savesCount,
                    showCount: false,
                    onTap: _toggleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _action({
    required Widget iconWidget,
    required int count,
    required VoidCallback onTap,
    bool showCount = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (showCount && count > 0) ...[
              const SizedBox(width: 2),
              Text(_fmtNum(count), style: _f(13, FontWeight.w700, _D.textBody)),
            ],
          ],
        ),
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
