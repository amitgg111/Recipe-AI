import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_ai/widgets/comments_sheet.dart';
import 'package:recipe_ai/Service/user_service.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/View/Home/social/social_widgets.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart'
    show CookbookPickerSheet;
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
import 'package:recipe_ai/Helper/unit_converter.dart';
import 'package:recipe_ai/Helper/instruction_scaler.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants (matched to the HTML "Public recipe (view)" design)
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  static const bg = Color(0xFFFBF4EA);
  static const card = Colors.white;
  static const border = Color(0xFFEFE6D6);
  static const borderInner = Color(0xFFE7DECE);
  static const rowLine = Color(0xFFF4ECDF);
  static const surfaceLight = Color(0xFFFBF7F0);
  static const primary = Color(0xFFF2623E);
  static const textDark = Color(0xFF2A211B);
  static const textMedium = Color(0xFF8A7E70);
  static const textHint = Color(0xFFA89F90);
  static const textBody = Color(0xFF5A5147);
  static const textBodyDark = Color(0xFF3A352D);
  static const green = Color(0xFF1F7A5E);
  static const goldBg = Color(0xFFFBF1E4);
  static const noteBg = Color(0xFFFCE3DB);
  static const purple = Color(0xFF8B5CF6);
  static const star = Color(0xFFF2A24C);

  static const double outerPad = 22.0;
  static const double cardPad = 16.0;
  static const double cardRadius = 20.0;
  static const double gap = 16.0;
}

TextStyle _f(double s, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: s,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

BoxDecoration _cardDeco() => BoxDecoration(
  color: _P.card,
  borderRadius: BorderRadius.circular(_P.cardRadius),
  border: Border.all(color: _P.border),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF2A211B).withValues(alpha: 0.16),
      blurRadius: 26,
      offset: const Offset(0, 12),
      spreadRadius: -22,
    ),
  ],
);

class PublicRecipeViewScreen extends StatefulWidget {
  final DiscoverRecipe recipe; // ADD THIS
  final void Function({
    int? likes,
    int? saves,
    int? comments,
    bool? liked,
    bool? saved,
  })?
  onSocialChanged;
  const PublicRecipeViewScreen({
    super.key,
    required this.recipe,
    this.onSocialChanged,
  });
  @override
  State<PublicRecipeViewScreen> createState() => _PublicRecipeViewScreenState();
}

class _PublicRecipeViewScreenState extends State<PublicRecipeViewScreen> {
  late int _initialServings;
  late int _servings;
  final Set<int> _checked = {};
  final SettingsController _settings = Get.find<SettingsController>();
  final GroceryStore _grocery = Get.find<GroceryStore>();

  // Optimistic social state (instant UI; persisted in the background).
  late final ValueNotifier<int> _likes;
  late final ValueNotifier<int> _saves;

  late final ValueNotifier<bool> _liked;
  late final ValueNotifier<bool> _saved;

  late final ValueNotifier<int> _myRating;
  late final ValueNotifier<int> _ratingSum;
  late final ValueNotifier<int> _ratingCount;

  late final ValueNotifier<int> _commentsCount;

  bool _busyLike = false;
  bool _busySave = false;

  DiscoverRecipe get recipe => widget.recipe;

  // ── Flat ingredient list used everywhere index/order-based logic needs a
  // single list (checkbox state, emoji lookup, the groceries sheet, cook
  // mode, share text): the section items in document order when
  // ingredientSections is populated, otherwise the plain ingredients list.
  // Computed once and cached — this used to be recomputed (a fresh O(n)
  // list build) on every single emoji lookup, i.e. once per row per
  // rebuild, which is what made the ingredients card noticeably slow to
  // settle whenever a translation batch or the servings stepper triggered
  // a rebuild. Cached here it's O(n) once for the life of the screen.
  List<String>? _effectiveIngredientsCache;

  List<String> get _effectiveIngredients {
    return _effectiveIngredientsCache ??= _computeEffectiveIngredients();
  }

  List<String> _computeEffectiveIngredients() {
    if (recipe.ingredientSections.isNotEmpty) {
      final flat = <String>[];
      for (final section in recipe.ingredientSections) {
        flat.addAll(section.items);
      }
      if (flat.isNotEmpty) return flat;
    }
    return recipe.ingredients;
  }

  // ── Display-only translation ──────────────────────────────────────────────
  // This screen shows OTHER people's public recipes, so per RecipeLocalizer's
  // rule the viewer is a non-owner and sees the canonical English translated
  // into their own app language.
  //
  // Firestore stays English and every logic/write path below keeps reading
  // `recipe` verbatim — cook mode, saving a copy, the grocery write, sharing
  // and the ingredient-emoji lookup all still get English. Only what the user
  // READS goes through _display().
  //
  // cachedOrSelf() is a synchronous map lookup, so the first frame costs
  // nothing and the screen opens instantly. Misses are collected and
  // translated in ONE batch after the frame, landing as a single setState.
  // The Set gates each string to one request, so this cannot loop.
  final Set<String> _trRequested = {};
  List<String>? _trPending;
  bool _trFlushing = false;

  String _display(String? english) {
    final src = english?.trim() ?? '';
    if (src.isEmpty) return '';
    final shown = AiTranslationService.cachedOrSelf(src);
    if (shown == src &&
        AiTranslationService.isTranslating &&
        _trRequested.add(src)) {
      (_trPending ??= <String>[]).add(src);
      if (_trPending!.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _flushTranslations(),
        );
      }
    }
    return shown;
  }

  Future<void> _flushTranslations() async {
    // Coalesce: a rebuild during the await (the servings stepper) queues more
    // strings and schedules another flush. Without this guard those runs
    // overlap, each firing its own ML Kit batches. The loop drains instead.
    if (_trFlushing) return;
    _trFlushing = true;
    try {
      while (_trPending != null && _trPending!.isNotEmpty) {
        final batch = _trPending!;
        _trPending = null;
        await AiTranslationService.translateList(batch);
        if (!mounted) return;
        setState(() {});
      }
    } finally {
      _trFlushing = false;
    }
  }

  @override
  void initState() {
    super.initState();

    int parsed = 2;

    if (recipe.servings != null) {
      final m = RegExp(r'\d+').firstMatch(recipe.servings!);
      if (m != null) {
        parsed = int.tryParse(m.group(0)!) ?? 2;
      }
    }

    _initialServings = parsed <= 0 ? 2 : parsed;
    _servings = _initialServings;

    _likes = ValueNotifier<int>(recipe.likesCount);
    _saves = ValueNotifier<int>(recipe.savesCount);

    _liked = ValueNotifier<bool>(false);
    _saved = ValueNotifier<bool>(false);

    _myRating = ValueNotifier<int>(0);
    _ratingSum = ValueNotifier<int>(0);
    _ratingCount = ValueNotifier<int>(0);

    _commentsCount = ValueNotifier<int>(0);

    _loadSocial();
  }

  @override
  void dispose() {
    _likes.dispose();
    _saves.dispose();

    _liked.dispose();
    _saved.dispose();

    _myRating.dispose();
    _ratingSum.dispose();
    _ratingCount.dispose();

    _commentsCount.dispose();

    super.dispose();
  }

  Future<void> _loadSocial() async {
    try {
      final results = await Future.wait([
        RecipeSocialService.isLiked(recipe.userId, recipe.id),
        RecipeSocialService.isSaved(recipe.userId, recipe.id),
        RecipeSocialService.getMyRating(recipe.userId, recipe.id),
        RecipeSocialService.recipeStream(recipe.userId, recipe.id).first,
      ]);

      final liked = results[0] as bool;
      final saved = results[1] as bool;
      final myRating = results[2] as int;

      final doc = results[3] as DocumentSnapshot<Map<String, dynamic>>;

      final d = doc.data() ?? {};

      if (!mounted) return;

      _liked.value = liked;
      _saved.value = saved;
      _myRating.value = myRating;

      _likes.value = (d['likesCount'] as num?)?.toInt() ?? _likes.value;

      _saves.value = (d['savesCount'] as num?)?.toInt() ?? _saves.value;

      _commentsCount.value = (d['commentsCount'] as num?)?.toInt() ?? 0;

      _ratingSum.value = (d['ratingSum'] as num?)?.toInt() ?? 0;

      _ratingCount.value = (d['ratingCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('Social load error: $e');
    }
  }

  Future<void> _setRating(int r) async {
    final oldRating = _myRating.value;

    if (oldRating == r) return;

    final oldSum = _ratingSum.value;
    final oldCount = _ratingCount.value;

    // ⚡ Optimistic update
    if (oldRating == 0) {
      _ratingCount.value = oldCount + 1;
      _ratingSum.value = oldSum + r;
    } else {
      _ratingSum.value = oldSum + (r - oldRating);
    }

    _myRating.value = r;

    try {
      await RecipeSocialService.setRating(recipe.userId, recipe.id, r);
    } catch (_) {
      if (!mounted) return;

      _ratingSum.value = oldSum;
      _ratingCount.value = oldCount;
      _myRating.value = oldRating;
    }
  }

  Future<void> _toggleLike() async {
    if (_busyLike) return;

    _busyLike = true;

    final oldLiked = _liked.value;
    final oldLikes = _likes.value;

    final target = !oldLiked;
    final newLikes = oldLikes + (target ? 1 : -1);

    // Optimistic UI
    _liked.value = target;
    _likes.value = newLikes;

    // Update Discover screen immediately
    widget.onSocialChanged?.call(likes: newLikes, liked: target);

    try {
      await RecipeSocialService.setLike(recipe.userId, recipe.id, target);
    } catch (_) {
      if (mounted) {
        _liked.value = oldLiked;
        _likes.value = oldLikes;

        // Rollback Discover
        widget.onSocialChanged?.call(likes: oldLikes, liked: oldLiked);
      }
    } finally {
      _busyLike = false;
    }
  }

  String get _firstName => recipe.userName.trim().isEmpty
      ? 'the_author'.tr
      : recipe.userName.split(' ').first;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const heroH = 300.0;

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(child: _buildHero(heroH)),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _P.outerPad,
                      6,
                      _P.outerPad,
                      34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _display(recipe.filterTitle),
                          style: _f(
                            26,
                            FontWeight.w800,
                            _P.textDark,
                            h: 1.12,
                            ls: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetaRow(),
                        const SizedBox(height: 16),
                        RepaintBoundary(child: _buildAuthorCard()),
                        const SizedBox(height: _P.gap),
                        RepaintBoundary(child: _buildEngagementBar()),
                        const SizedBox(height: _P.gap),
                        if ((recipe.filterDescription) != null &&
                            (recipe.filterDescription)!.trim().isNotEmpty) ...[
                          RepaintBoundary(child: _buildNoteCard()),
                          const SizedBox(height: _P.gap),
                        ],
                        RepaintBoundary(child: _buildIngredientsCard()),
                        const SizedBox(height: _P.gap),
                        RepaintBoundary(child: _buildInstructionsCard()),
                        const SizedBox(height: _P.gap),
                        _buildCookButton(),
                        const SizedBox(height: _P.gap),
                        RepaintBoundary(child: _buildNutritionCard()),
                        const SizedBox(height: _P.gap),
                        RepaintBoundary(child: _buildRateCard()),
                        const SizedBox(height: _P.gap),
                        RepaintBoundary(child: _buildCommentsCard()),
                        const SizedBox(height: _P.gap),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topPad + 8,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _floatingBtn(
                  const OnboardingLineIcon(
                    'back',
                    size: 20,
                    color: _P.textDark,
                  ),
                  () => Get.back(),
                ),
                _floatingBtn(
                  const OnboardingLineIcon(
                    'share',
                    size: 20,
                    color: _P.textDark,
                  ),
                  _share,
                ),
              ],
            ),
          ),
          // Centered "Public recipe" badge
          Positioned(
            top: topPad + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: _P.green.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingLineIcon(
                      'globe',
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'public_recipe'.tr,
                      style: _f(12, FontWeight.w800, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────
  Widget _buildHero(double height) {
    return SizedBox(
      width: double.infinity,
      height: height,
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
                colors: [
                  Color(0x66140F0A),
                  Color(0x00140F0A),
                  Color(0x00140F0A),
                  Color(0xFFFBF4EA),
                ],
                stops: [0.0, 0.32, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPh() => Container(
    color: const Color(0xFFF0E6D6),
    child: const Center(
      child: Icon(Icons.restaurant_rounded, size: 60, color: Color(0xFFC7BCAC)),
    ),
  );

  Widget _floatingBtn(Widget icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: icon,
      ),
    );
  }

  // ── Meta row ──────────────────────────────────────────────────────────────
  Widget _buildMetaRow() {
    final time =
        (recipe.totalTime) ?? (recipe.cookTime) ?? (recipe.prepTime) ?? '';
    final items = <Widget>[];
    if (time.isNotEmpty) {
      items.add(
        Expanded(
          child: _metaItem(
            const OnboardingLineIcon('clock', size: 16, color: _P.primary),
            time,
          ),
        ),
      );
    }
    items.add(
      Expanded(
        child: _metaItem(
          const OnboardingLineIcon('friend', size: 16, color: _P.primary),
          'n_servings'.trParams({'count': '$_servings'}),
        ),
      ),
    );
    items.add(
      Expanded(
        child: _metaItem(
          const OnboardingLineIcon('sparkF', size: 16, color: _P.primary),
          'easy'.tr,
        ),
      ),
    );
    final row = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      row.add(items[i]);
      if (i < items.length - 1) {
        row.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              '·',
              style: _f(14, FontWeight.w700, const Color(0xFFD8CFC0)),
            ),
          ),
        );
      }
    }
    return Row(children: row);
  }

  Widget _metaItem(Widget icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: _f(13.5, FontWeight.w700, _P.textBody),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Author card ─────────────────────────────────────────────────────────
  Widget _buildAuthorCard() {
    final creatorId = recipe.userId;
    void openProfile() {
      if (creatorId.isEmpty) return;
      Get.to(
        () => CreatorProfileScreen(
          userId: creatorId,
          fallbackName: recipe.userName,
          fallbackAvatar: recipe.userAvatar,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _cardDeco(),
      child: Row(
        children: [
          GestureDetector(
            onTap: openProfile,
            child: UserAvatar(
              photoUrl: recipe.userAvatar,
              initial: recipe.userName.isNotEmpty
                  ? recipe.userName[0].toUpperCase()
                  : 'C',
              size: 46,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: openProfile,
              behavior: HitTestBehavior.opaque,
              child: StreamBuilder<UserModel?>(
                stream: creatorId.isEmpty
                    ? null
                    : UserService.userStream(creatorId),
                builder: (context, snap) {
                  final u = snap.data;
                  final name =
                      u?.displayName ??
                      (recipe.userName.isNotEmpty
                          ? recipe.userName
                          : 'recipe_creator'.tr);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: _f(15, FontWeight.w800, _P.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Subtitle matches the creator card design:
                      // "N recipes · Xk followers".
                      StreamBuilder<List<DiscoverRecipe>>(
                        stream: creatorId.isEmpty
                            ? null
                            : UserService.publicRecipesStream(
                                creatorId,
                                authorName: name,
                                authorAvatar: recipe.userAvatar,
                              ),
                        builder: (context, rSnap) {
                          final rc = rSnap.data?.length ?? 0;
                          final followers = u?.followersCount ?? 0;
                          final recipesPart = rc == 1
                              ? 'n_recipe_lc'.trParams({'count': '$rc'})
                              : 'n_recipes_lc'.trParams({'count': '$rc'});
                          final sub =
                              '$recipesPart · '
                              '${'n_followers'.trParams({'count': _fmtCount(followers)})}';
                          return Text(
                            sub,
                            style: _f(12, FontWeight.w600, _P.textMedium),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (creatorId.isNotEmpty) ...[
            const SizedBox(width: 10),
            FollowButton(targetUid: creatorId),
          ],
        ],
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── Author note ───────────────────────────────────────────────────────────
  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_P.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OnboardingLineIcon('pencil', size: 16, color: _P.primary),
              const SizedBox(width: 8),
              Text(
                'note_from'.trParams({'name': _firstName}),
                style: _f(16, FontWeight.w800, _P.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _display(recipe.filterDescription),
            style: _f(14, FontWeight.w400, _P.textBody, h: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Ingredients ────────────────────────────────────────────────────────────
  Widget _buildIngredientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_P.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ingredients'.tr,
                style: _f(18, FontWeight.w800, _P.textDark),
              ),
              const Spacer(),
              _buildStepper(),
            ],
          ),
          const SizedBox(height: 8),
          // Obx(
          // () =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildIngredientRows(_settings.unitSystem),
          ),
          // ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showGrocerySelectionSheet,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OnboardingLineIcon('cart', size: 18, color: _P.primary),
                  const SizedBox(width: 9),
                  Text(
                    'add_to_groceries'.tr,
                    style: _f(14, FontWeight.w700, _P.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the ingredient rows. When the recipe has [DiscoverRecipe.
  /// ingredientSections] populated, groups are rendered with a header per
  /// section (e.g. "For the batter"); otherwise falls back to the plain
  /// flat list — same as before. Either way, rows index into
  /// [_effectiveIngredients] so checkbox state and emoji lookup stay
  /// consistent between the two layouts.
  List<Widget> _buildIngredientRows(UnitSystem system) {
    final multiplier = _servings / _initialServings;
    final rows = <Widget>[];

    if (recipe.ingredientSections.isNotEmpty) {
      var index = 0;
      for (final section in recipe.ingredientSections) {
        if (section.items.isEmpty) continue;

        final sectionName = section.name?.trim();

        if (sectionName != null && sectionName.isNotEmpty) {
          rows.add(_sectionHeader(sectionName));
        }

        for (final raw in section.items) {
          // Scale, convert and split on the ENGLISH original — UnitConverter
          // and the quantity regex both parse English unit words — then
          // translate ONLY the ingredient name.
          final scaled = UnitConverter.scaleAndConvert(raw, multiplier, system);
          final parts = _parseIngredient(scaled);
          rows.add(_ingredientRow(parts.$1, _display(parts.$2), index));
          index++;
        }
      }
    } else {
      for (var i = 0; i < (recipe.ingredients).length; i++) {
        final scaled = UnitConverter.scaleAndConvert(
          (recipe.ingredients)[i],
          multiplier,
          system,
        );
        final parts = _parseIngredient(scaled);
        rows.add(_ingredientRow(parts.$1, _display(parts.$2), i));
      }
    }

    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'no_ingredients_listed'.tr,
            style: _f(13, FontWeight.w500, _P.textHint),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _sectionHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        _display(name),
        style: _f(13, FontWeight.w800, _P.primary, ls: 0.3),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      decoration: BoxDecoration(
        color: _P.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.borderInner),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            'minus',
            _servings > 1,
            () => setState(() => _servings--),
            _P.textDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_servings', style: _f(14, FontWeight.w800, _P.textDark)),
                const SizedBox(width: 3),
                Text(
                  'serv'.tr,
                  style: _f(10, FontWeight.w600, const Color(0xFF9A938A)),
                ),
              ],
            ),
          ),
          _stepBtn('plus', true, () => setState(() => _servings++), _P.primary),
        ],
      ),
    );
  }

  Widget _stepBtn(String icon, bool enabled, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: OnboardingLineIcon(
            icon,
            size: 16,
            color: enabled ? color : _P.textHint,
          ),
        ),
      ),
    );
  }

  /// Emoji for the ingredient at flat [index], matched on its ENGLISH
  /// original. [emojiForIngredient] is an English-keyword dictionary, so a
  /// translated name misses and falls back to a generic category emoji.
  /// [index] refers into [_effectiveIngredients] (section items flattened
  /// in order when sections are present, otherwise the plain list), which
  /// keeps this correct for both layouts. Falls back to [displayName] when
  /// out of range.
  String _ingredientEmoji(int index, String displayName) {
    final source = _effectiveIngredients;
    if (index >= 0 && index < source.length) {
      return _grocery.emojiForIngredient(source[index]);
    }
    return _grocery.emojiForIngredient(displayName);
  }

  /// [quantity] stays verbatim English/numeric (re-scaled on every servings
  /// change); [name] is the translated ingredient name.
  Widget _ingredientRow(String? quantity, String name, int index) {
    final checked = _checked.contains(index);
    final parts = (quantity, name);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _P.rowLine)),
      ),
      child: Row(
        children: [
          // Grocery category emoji (same one the Groceries screen uses),
          // detected from the ingredient name.
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _P.goldBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _ingredientEmoji(index, parts.$2),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          if (parts.$1 != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Text(
                parts.$1!,
                style: _f(
                  14,
                  FontWeight.w800,
                  checked ? _P.textHint : _P.textDark,
                ),
              ),
            ),
          ],
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              parts.$2,
              style: _f(
                14,
                FontWeight.w500,
                checked ? _P.textHint : _P.textBody,
                h: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String?, String) _parseIngredient(String text) {
    final match = RegExp(
      r'^([\d½¼¾⅓⅔⅛⅜⅝⅞/.\s]+(?:\s*(?:cup|cups|tbsp|tsp|oz|lb|lbs|g|kg|ml|l|piece|pieces|clove|cloves|inch|pinch|bunch|handful|can|cans|packet|packets|slice|slices|medium|large|small)\b)?)\s+(.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final qty = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
    }
    return (null, text);
  }

  // ── Instructions ───────────────────────────────────────────────────────────
  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_P.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('instructions'.tr, style: _f(18, FontWeight.w800, _P.textDark)),
          const SizedBox(height: 6),
          if ((recipe.instructions).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'no_instructions_listed'.tr,
                style: _f(13, FontWeight.w500, _P.textHint),
              ),
            )
          else
            Obx(() {
              final multiplier = _servings / _initialServings;
              final system = _settings.unitSystem;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < (recipe.instructions).length; i++)
                    _instructionRow(
                      i + 1,
                      // Scale on the English original (the scaler parses
                      // English units), then translate for display only.
                      _display(
                        InstructionScaler.scale(
                          (recipe.instructions)[i],
                          multiplier,
                          system,
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _instructionRow(int number, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _P.rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: _P.noteBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: _f(13, FontWeight.w800, _P.primary),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: _f(14, FontWeight.w500, _P.textBodyDark, h: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cook button ────────────────────────────────────────────────────────────
  Widget _buildCookButton() {
    return GestureDetector(
      onTap: () => Get.to(
        () => CookModeScreen(recipe: _toRecipeModel()),
        transition: Transition.downToUp,
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _P.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _P.primary.withValues(alpha: 0.7),
              blurRadius: 26,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('play', color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Text(
              'cook_step_by_step'.tr,
              style: _f(16, FontWeight.w700, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nutrition (Plus, visual) ────────────────────────────────────────────────
  Widget _buildNutritionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_P.cardPad),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'nutrition'.tr.toUpperCase(),
            style: _f(13, FontWeight.w800, _P.primary, ls: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            'per_1_serving'.tr,
            style: _f(12.5, FontWeight.w500, const Color(0xFF9A938A)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1C9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnboardingLineIcon('crown', size: 18, color: _P.purple),
                const SizedBox(width: 11),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _f(
                        13.5,
                        FontWeight.w500,
                        _P.textBodyDark,
                        h: 1.45,
                      ),
                      children: [
                        TextSpan(text: 'this_is_plus_feature'.tr),
                        TextSpan(
                          text: 'subscribe_now'.tr,
                          style: _f(13.5, FontWeight.w800, _P.purple),
                        ),
                        TextSpan(text: 'unlock_nutrition_calculator'.tr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Static placeholder visual (fixed 520 kcal + gauge) — blurred and
          // wrapped in RepaintBoundary since ImageFilter.blur is one of the
          // more expensive things Flutter can repaint; isolating it here
          // means it never repaints just because a sibling card's
          // translation landed.
          RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Opacity(
                opacity: 0.85,
                child: Row(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFF2A24C),
                            Color(0xFFF2A24C),
                            Color(0xFFF08FB0),
                            Color(0xFFF08FB0),
                            Color(0xFF7FD0A8),
                            Color(0xFF7FD0A8),
                          ],
                          stops: [0.0, 0.46, 0.46, 0.72, 0.72, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '520',
                              style: _f(
                                18,
                                FontWeight.w800,
                                const Color(0xFF9A938A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        children: [
                          _nutriBar(const Color(0xFFF08FB0)),
                          const SizedBox(height: 14),
                          _nutriBar(const Color(0xFFF2A24C)),
                          const SizedBox(height: 14),
                          _nutriBar(const Color(0xFF7FD0A8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutriBar(Color dot) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D8C7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 34,
              height: 7,
              decoration: BoxDecoration(
                color: _P.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Rate ────────────────────────────────────────────────────────────────────
  Widget _buildRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_P.cardPad),
      decoration: _cardDeco(),
      child: ValueListenableBuilder<int>(
        valueListenable: _myRating,
        builder: (_, myRating, __) {
          return ValueListenableBuilder<int>(
            valueListenable: _ratingCount,
            builder: (_, ratingCount, __) {
              return ValueListenableBuilder<int>(
                valueListenable: _ratingSum,
                builder: (_, ratingSum, __) {
                  final avg = ratingCount > 0 ? ratingSum / ratingCount : 0;

                  return Column(
                    children: [
                      Text(
                        'cooked_it_rate'.tr,
                        style: _f(16, FontWeight.w800, _P.textDark),
                      ),

                      if (ratingCount > 0) ...[
                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const OnboardingLineIcon(
                              'starF',
                              size: 15,
                              color: _P.star,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${avg.toStringAsFixed(1)}  ·  '
                              '${ratingCount == 1 ? '1_rating'.tr : 'n_ratings'.trParams({'count': '$ratingCount'})}',
                              style: _f(12.5, FontWeight.w700, _P.textBody),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < myRating;

                          return GestureDetector(
                            onTap: () => _setRating(i + 1),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: OnboardingLineIcon(
                                filled ? 'starF' : 'starO',
                                size: 32,
                                color: filled
                                    ? _P.star
                                    : const Color(0xFFE2D8C7),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 9),

                      Text(
                        myRating == 0
                            ? 'tap_a_star_to_rate'.tr
                            : 'you_rated_n'.trParams({'rating': '$myRating'}),
                        style: _f(12, FontWeight.w600, const Color(0xFF9A938A)),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Engagement row — 3 stat cards (Likes / Saves / Ratings), like the HTML ──
  Widget _buildEngagementBar() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _liked,
            builder: (_, liked, __) {
              return ValueListenableBuilder<int>(
                valueListenable: _likes,
                builder: (_, likes, __) {
                  return _statCard(
                    icon: OnboardingLineIcon(
                      liked ? 'heart' : 'heartO',
                      size: 22,
                      color: _P.primary,
                    ),
                    value: '$likes',
                    label: 'likes'.tr,
                    onTap: _toggleLike,
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _saves,
            builder: (_, saves, __) {
              return _statCard(
                icon: const OnboardingLineIcon(
                  'bookmark',
                  size: 22,
                  color: _P.green,
                ),
                value: '$saves',
                label: 'saves'.tr,
                onTap: _saveToCookbook,
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _ratingCount,
            builder: (_, count, __) {
              return ValueListenableBuilder<int>(
                valueListenable: _ratingSum,
                builder: (_, sum, __) {
                  final avg = count > 0 ? sum / count : 0;

                  final label = count == 0
                      ? 'ratings'.tr
                      : count == 1
                      ? '1_rating'.tr
                      : 'n_ratings'.trParams({'count': '$count'});

                  return _statCard(
                    icon: const OnboardingLineIcon(
                      'starF',
                      size: 22,
                      color: _P.star,
                    ),
                    value: count == 0 ? '—' : avg.toStringAsFixed(1),
                    label: label,
                    onTap: () {},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required Widget icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: _cardDeco(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 5),
            Text(value, style: _f(15, FontWeight.w800, _P.textDark)),
            Text(
              label,
              style: _f(11, FontWeight.w600, const Color(0xFF9A938A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Comments ─────────────────────────────────────────────────────────────
  // void _openComments() {
  //   CommentsSheet.show(
  //     context,
  //     ownerId: recipe.userId,
  //     recipeId: recipe.id,
  //     onCommentAdded: () {
  //       _commentsCount.value++;
  //     },
  //   );
  // }
  void _openComments() {
    CommentsSheet.show(
      context,
      ownerId: recipe.userId,
      recipeId: recipe.id,
      onCommentAdded: () {
        final newCount = _commentsCount.value + 1;

        _commentsCount.value = newCount;

        // Update Discover immediately
        widget.onSocialChanged?.call(comments: newCount);
      },
    );
  }

  Widget _buildCommentsCard() {
    return ValueListenableBuilder<int>(
      valueListenable: _commentsCount,
      builder: (context, commentsCount, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_P.cardPad),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'comments'.tr,
                    style: _f(18, FontWeight.w800, _P.textDark),
                  ),
                  const Spacer(),
                  Text(
                    '$commentsCount',
                    style: _f(13, FontWeight.w700, const Color(0xFF9A938A)),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: RecipeSocialService.commentsStream(
                  recipe.userId,
                  recipe.id,
                  limit: 2,
                ),
                builder: (context, snap) {
                  // Loading
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        'loading'.tr,
                        style: _f(13.5, FontWeight.w500, _P.textHint),
                      ),
                    );
                  }

                  final docs =
                      snap.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                  // No comments
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        'be_first_to_comment'.tr,
                        style: _f(13.5, FontWeight.w500, _P.textHint),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final doc in docs) _commentPreview(doc.data()),
                    ],
                  );
                },
              ),

              if (commentsCount > 0) ...[
                const SizedBox(height: 2),

                GestureDetector(
                  onTap: _openComments,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'view_all_n_comments'.trParams({'count': '$commentsCount'}),
                    style: _f(13, FontWeight.w700, _P.primary),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              GestureDetector(
                onTap: _openComments,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: _P.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _P.borderInner),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'add_a_comment'.tr,
                          style: _f(14, FontWeight.w500, _P.textHint),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _P.primary,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const OnboardingLineIcon(
                          'send',
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _commentPreview(Map<String, dynamic> d) {
    final name = (d['name'] as String?)?.trim();
    final display = (name != null && name.isNotEmpty) ? name : 'anonymous'.tr;
    final avatar = d['userAvatar'] as String?;
    final text = (d['text'] as String?) ?? '';
    final ts = d['createdAt'];
    final when = ts is Timestamp ? _timeAgo(ts.toDate()) : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _commentAvatar(avatar, display),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        display,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _f(13.5, FontWeight.w800, _P.textDark),
                      ),
                    ),
                    if (when.isNotEmpty) ...[
                      const SizedBox(width: 7),
                      Text(when, style: _f(12, FontWeight.w600, _P.textHint)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: _f(13.5, FontWeight.w500, _P.textBody, h: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentAvatar(String? url, String name) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFF0E7D6),
      backgroundImage: (url != null && url.isNotEmpty)
          ? CachedNetworkImageProvider(url)
          : null,
      child: (url == null || url.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: _f(13, FontWeight.w800, _P.textDark),
            )
          : null,
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now'.tr;
  }

  // ── Save button ──────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveToCookbook,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _P.green,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _P.green.withValues(alpha: 0.55),
              blurRadius: 26,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingLineIcon('bookmark', color: Colors.white, size: 20),
            const SizedBox(width: 9),
            Text(
              'save_to_my_cookbook'.tr,
              style: _f(16, FontWeight.w700, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions (reuse existing controllers) ─────────────────────────────────────
  RecipeModel _toRecipeModel() => RecipeModel(
    id: recipe.id,
    title: (recipe.title),
    description: (recipe.description),
    imageUrl: recipe.imageUrl,
    sourceUrl: '',
    prepTime: (recipe.prepTime),
    cookTime: (recipe.cookTime),
    totalTime: (recipe.totalTime),
    servings: (recipe.servings),
    category: (recipe.category),
    cuisine: (recipe.cuisine),
    keywords: const [],
    // Flattened section items (in order) when the recipe has grouped
    // ingredients, otherwise the plain list — RecipeModel only carries a
    // flat ingredient list.
    ingredients: _effectiveIngredients,
    instructions: (recipe.instructions),
    ingredientSections: const [],
    instructionSections: const [],
    visibility: 'public',
  );

  void _share() {
    final buf = StringBuffer();
    buf.writeln((recipe.title));
    buf.writeln();
    if ((recipe.description) != null && (recipe.description)!.isNotEmpty) {
      buf.writeln((recipe.description));
      buf.writeln();
    }
    buf.writeln('INGREDIENTS');
    if (recipe.ingredientSections.isNotEmpty) {
      for (final section in recipe.ingredientSections) {
        final sectionName = section.name?.trim();

        if (sectionName != null && sectionName.isNotEmpty) {
          buf.writeln(sectionName.toUpperCase());
        }
        for (final ing in section.items) {
          buf.writeln('• $ing');
        }
      }
    } else {
      for (final ing in (recipe.ingredients)) {
        buf.writeln('• $ing');
      }
    }
    buf.writeln();
    buf.writeln('INSTRUCTIONS');
    for (var i = 0; i < (recipe.instructions).length; i++) {
      buf.writeln('${i + 1}. ${(recipe.instructions)[i]}');
    }
    Share.share(buf.toString(), subject: (recipe.title));
    RecipeSocialService.registerShare(recipe.userId, recipe.id);
  }

  void _showGrocerySelectionSheet() {
    final system = _settings.unitSystem;
    final multiplier = _servings / _initialServings;
    final ingredientsSource = _effectiveIngredients;
    final selectedIndices = List<bool>.generate(
      ingredientsSource.length,
      (_) => true,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801E1B18),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            final checkedCount = selectedIndices.where((c) => c).length;

            final widgets = <Widget>[];

            void toggleIndex(int idx) {
              setStateSheet(() {
                selectedIndices[idx] = !selectedIndices[idx];
              });
            }

            Widget selectionRow(String text, int globalIdx) {
              final isChecked = selectedIndices[globalIdx];
              final parts = _parseIngredient(text);
              return GestureDetector(
                onTap: () => toggleIndex(globalIdx),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _P.rowLine)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isChecked ? _P.primary : Colors.transparent,
                          border: isChecked
                              ? null
                              : Border.all(color: _P.borderInner, width: 2),
                        ),
                        child: isChecked
                            ? const Center(
                                child: OnboardingLineIcon(
                                  'check',
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _P.goldBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _ingredientEmoji(globalIdx, parts.$2),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (parts.$1 != null) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 56),
                          child: Text(
                            "${parts.$1!}  ",
                            style: _f(
                              14,
                              FontWeight.w800,
                              isChecked ? _P.textDark : _P.textHint,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          parts.$2,
                          style: _f(
                            14,
                            FontWeight.w500,
                            isChecked ? _P.textBody : _P.textHint,
                            h: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            for (var i = 0; i < ingredientsSource.length; i++) {
              final scaled = UnitConverter.scaleAndConvert(
                ingredientsSource[i],
                multiplier,
                system,
              );
              widgets.add(selectionRow(scaled, i));
            }

            final allChecked = selectedIndices.every((c) => c);

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E0D2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'add_to_groceries_title'.tr,
                              style: _f(
                                20,
                                FontWeight.w800,
                                _P.textDark,
                                ls: -0.4,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4F1EA),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const OnboardingLineIcon(
                                  'x',
                                  size: 17,
                                  color: _P.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'select_items_to_purchase'.tr,
                              style: _f(13.5, FontWeight.w600, _P.textMedium),
                            ),
                            GestureDetector(
                              onTap: () {
                                setStateSheet(() {
                                  final target = !allChecked;
                                  for (
                                    var i = 0;
                                    i < selectedIndices.length;
                                    i++
                                  ) {
                                    selectedIndices[i] = target;
                                  }
                                });
                              },
                              child: Text(
                                allChecked
                                    ? 'deselect_all'.tr
                                    : 'select_all'.tr,
                                style: _f(13, FontWeight.w700, _P.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: _P.rowLine, height: 1, thickness: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      children: widgets,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      MediaQuery.of(ctx).padding.bottom + 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: _P.rowLine)),
                    ),
                    child: GestureDetector(
                      onTap: checkedCount == 0
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              final groceryController =
                                  Get.find<GroceryStore>();
                              final toAdd = <String>[];
                              for (
                                var i = 0;
                                i < ingredientsSource.length;
                                i++
                              ) {
                                if (selectedIndices[i]) {
                                  final scaledIng =
                                      IngredientScaleHelper.scaleIngredient(
                                        ingredientsSource[i],
                                        multiplier,
                                      );
                                  toAdd.add(scaledIng);
                                }
                              }

                              groceryController.addFromRecipe(recipe.id, toAdd);

                              CustomSnackbar.show(
                                title: 'n_ingredients_added'.trParams({
                                  'count': '$checkedCount',
                                }),
                                actionText: 'view'.tr,
                                onAction: () {
                                  Get.offUntil(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HomeScreen(initialIndex: 3),
                                    ),
                                    (route) => route.isFirst,
                                  );
                                },
                              );
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: checkedCount == 0
                              ? const Color(0xFFF4F1EA)
                              : _P.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          checkedCount == 0
                              ? 'select_items_to_add'.tr
                              : checkedCount == 1
                              ? 'add_1_item_to_groceries'.tr
                              : 'add_n_items_to_groceries'.trParams({
                                  'count': '$checkedCount',
                                }),
                          style: _f(
                            15,
                            FontWeight.w700,
                            checkedCount == 0 ? _P.textHint : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Future<void> _saveToCookbook() async {
  //   if (_busySave) return;

  //   _busySave = true;

  //   final wasSaved = _saved.value;

  //   if (!wasSaved) {
  //     _saved.value = true;
  //     _saves.value++;
  //   }

  //   try {
  //     final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);

  //     if (copyId == null) {
  //       if (mounted && !wasSaved) {
  //         _saved.value = false;
  //         _saves.value--;
  //       }
  //       return;
  //     }

  //     await RecipeSocialService.setSave(recipe.userId, recipe.id, true);

  //     if (!mounted) return;

  //     showModalBottomSheet(
  //       context: context,
  //       isScrollControlled: true,
  //       backgroundColor: Colors.transparent,
  //       builder: (_) => CookbookPickerSheet(
  //         cookbookController: Get.find<CookbookController>(),
  //         recipeId: copyId,
  //         recipeImageUrl: recipe.imageUrl,
  //       ),
  //     );
  //   } catch (_) {
  //     if (mounted && !wasSaved) {
  //       _saved.value = false;
  //       _saves.value--;
  //     }
  //   } finally {
  //     _busySave = false;
  //   }
  // }
  Future<void> _saveToCookbook() async {
    if (_busySave) return;

    _busySave = true;

    try {
      // ─────────────────────────────────────────────────────────────
      // 1. Create temporary copy.
      // This is NOT considered a real save yet.
      // ─────────────────────────────────────────────────────────────
      final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);

      if (copyId == null || !mounted) {
        return;
      }

      // ─────────────────────────────────────────────────────────────
      // 2. Open cookbook picker and WAIT for Done.
      // CookbookPickerSheet should return:
      //   > 0  => Done + at least one cookbook selected
      //   null/0 => dismissed or Done without selection
      // ─────────────────────────────────────────────────────────────
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

      // ─────────────────────────────────────────────────────────────
      // 3. REAL SAVE ONLY AFTER DONE + cookbook selected.
      // ─────────────────────────────────────────────────────────────
      final confirmed = result != null && result > 0;

      // User cancelled / dismissed / pressed Done without selecting
      // any cookbook -> delete temporary copy.
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

      // ─────────────────────────────────────────────────────────────
      // 4. Now the recipe is REALLY saved.
      // ─────────────────────────────────────────────────────────────
      final oldSaves = _saves.value;

      if (mounted) {
        _saved.value = true;
        _saves.value = oldSaves + 1;
      }

      // Update Discover immediately.
      widget.onSocialChanged?.call(saves: _saves.value, saved: true);

      // Update Firestore/social save state ONLY now.
      await RecipeSocialService.setSave(recipe.userId, recipe.id, true);
    } catch (e) {
      print('[_saveToCookbook] Error: $e');
    } finally {
      _busySave = false;
    }
  }
}
