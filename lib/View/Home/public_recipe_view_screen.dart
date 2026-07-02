import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_ai/Controllers/discover_controller.dart';
import 'package:recipe_ai/Model/user_model.dart';
import 'package:recipe_ai/Service/recipe_social_service.dart';
import 'package:recipe_ai/Service/user_service.dart';
import 'package:recipe_ai/View/Home/social/creator_profile_screen.dart';
import 'package:recipe_ai/View/Home/social/social_widgets.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/View/Home/cook_mode_screen.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/recipe_detail_screen.dart' show CookbookPickerSheet;
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
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
  static const gold = Color(0xFFD98A12);
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
        fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

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
  final DiscoverRecipe recipe;
  const PublicRecipeViewScreen({super.key, required this.recipe});

  @override
  State<PublicRecipeViewScreen> createState() => _PublicRecipeViewScreenState();
}

class _PublicRecipeViewScreenState extends State<PublicRecipeViewScreen> {
  late int _initialServings;
  late int _servings;
  final Set<int> _checked = {};

  // Optimistic social state (instant UI; persisted in the background).
  late int _likes = recipe.likesCount;
  late int _saves = recipe.savesCount;
  bool _liked = false;
  bool _saved = false;
  bool _busyLike = false;
  bool _busySave = false;

  // Ratings: the current user's rating + the aggregate (sum / count).
  int _myRating = 0;
  int _ratingSum = 0;
  int _ratingCount = 0;
  double get _avgRating => _ratingCount > 0 ? _ratingSum / _ratingCount : 0;

  DiscoverRecipe get recipe => widget.recipe;

  @override
  void initState() {
    super.initState();
    int parsed = 2;
    if (recipe.servings != null) {
      final m = RegExp(r'\d+').firstMatch(recipe.servings!);
      if (m != null) parsed = int.tryParse(m.group(0)!) ?? 2;
    }
    _initialServings = parsed <= 0 ? 2 : parsed;
    _servings = _initialServings;
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    try {
      final liked = await RecipeSocialService.isLiked(recipe.userId, recipe.id);
      final saved = await RecipeSocialService.isSaved(recipe.userId, recipe.id);
      final myRating =
          await RecipeSocialService.getMyRating(recipe.userId, recipe.id);
      final doc =
          await RecipeSocialService.recipeStream(recipe.userId, recipe.id).first;
      final d = doc.data() ?? {};
      if (mounted) {
        setState(() {
        _liked = liked;
        _saved = saved;
        _myRating = myRating;
        _likes = (d['likesCount'] as num?)?.toInt() ?? _likes;
        _saves = (d['savesCount'] as num?)?.toInt() ?? _saves;
        _ratingSum = (d['ratingSum'] as num?)?.toInt() ?? 0;
        _ratingCount = (d['ratingCount'] as num?)?.toInt() ?? 0;
      });
      }
    } catch (_) {}
  }

  Future<void> _setRating(int r) async {
    final old = _myRating;
    if (old == r) return;
    setState(() {
      if (old == 0) {
        _ratingCount += 1;
        _ratingSum += r;
      } else {
        _ratingSum += (r - old);
      }
      _myRating = r;
    });
    try {
      await RecipeSocialService.setRating(recipe.userId, recipe.id, r);
    } catch (_) {
      if (mounted) {
        setState(() {
        if (old == 0) {
          _ratingCount -= 1;
          _ratingSum -= r;
        } else {
          _ratingSum -= (r - old);
        }
        _myRating = old;
      });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_busyLike) return;
    _busyLike = true;
    final target = !_liked;
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


  String get _firstName =>
      recipe.userName.trim().isEmpty ? 'the author' : recipe.userName.split(' ').first;

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
                _buildHero(heroH),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        _P.outerPad, 6, _P.outerPad, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: _f(26, FontWeight.w800, _P.textDark,
                                h: 1.12, ls: -0.5)),
                        const SizedBox(height: 12),
                        _buildMetaRow(),
                        const SizedBox(height: 16),
                        _buildAuthorCard(),
                        const SizedBox(height: _P.gap),
                        _buildEngagementBar(),
                        const SizedBox(height: _P.gap),
                        if (recipe.description != null &&
                            recipe.description!.trim().isNotEmpty) ...[
                          _buildNoteCard(),
                          const SizedBox(height: _P.gap),
                        ],
                        _buildIngredientsCard(),
                        const SizedBox(height: _P.gap),
                        _buildInstructionsCard(),
                        const SizedBox(height: _P.gap),
                        _buildCookButton(),
                        const SizedBox(height: _P.gap),
                        _buildNutritionCard(),
                        const SizedBox(height: _P.gap),
                        _buildRateCard(),
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
                _floatingBtn(Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context)),
                _floatingBtn(Icons.ios_share_rounded, _share),
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
                    const Icon(Icons.public, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Public recipe',
                        style: _f(12, FontWeight.w800, Colors.white)),
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
            child: Icon(Icons.restaurant_rounded,
                size: 60, color: Color(0xFFC7BCAC))),
      );

  Widget _floatingBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
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
        child: Icon(icon, size: 20, color: _P.textDark),
      ),
    );
  }

  // ── Meta row ──────────────────────────────────────────────────────────────
  Widget _buildMetaRow() {
    final time =
        recipe.totalTime ?? recipe.cookTime ?? recipe.prepTime ?? '';
    final items = <Widget>[];
    if (time.isNotEmpty) items.add(_metaItem(Icons.access_time_rounded, time));
    items.add(_metaItem(Icons.people_alt_outlined, '$_servings servings'));
    items.add(_metaItem(Icons.auto_awesome_rounded, 'Easy'));
    final row = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      row.add(items[i]);
      if (i < items.length - 1) {
        row.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text('·',
              style: _f(14, FontWeight.w700, const Color(0xFFD8CFC0))),
        ));
      }
    }
    return Row(children: row);
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _P.primary),
        const SizedBox(width: 6),
        Text(label, style: _f(13.5, FontWeight.w700, _P.textBody)),
      ],
    );
  }

  // ── Author card ─────────────────────────────────────────────────────────
  Widget _buildAuthorCard() {
    final creatorId = recipe.userId;
    void openProfile() {
      if (creatorId.isEmpty) return;
      Get.to(() => CreatorProfileScreen(
            userId: creatorId,
            fallbackName: recipe.userName,
            fallbackAvatar: recipe.userAvatar,
          ));
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
                  final name = u?.displayName ??
                      (recipe.userName.isNotEmpty
                          ? recipe.userName
                          : 'Recipe creator');
                  final sub = u != null
                      ? '@${u.handle} · ${_fmtCount(u.followersCount)} followers'
                      : 'Shared a public recipe';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: _f(15, FontWeight.w800, _P.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: _f(12, FontWeight.w600, _P.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
              const Icon(Icons.edit_outlined, size: 16, color: _P.primary),
              const SizedBox(width: 8),
              Text('Note from $_firstName',
                  style: _f(16, FontWeight.w800, _P.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(recipe.description!.trim(),
              style: _f(14, FontWeight.w400, _P.textBody, h: 1.5)),
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
              Text('Ingredients', style: _f(18, FontWeight.w800, _P.textDark)),
              const Spacer(),
              _buildStepper(),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildIngredientRows(),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _addToGroceries,
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
                  const Icon(Icons.shopping_cart_outlined, size: 18, color: _P.primary),
                  const SizedBox(width: 9),
                  Text('Add all to groceries',
                      style: _f(14, FontWeight.w700, _P.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientRows() {
    final multiplier = _servings / _initialServings;
    final rows = <Widget>[];
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final scaled =
          IngredientScaleHelper.scaleIngredient(recipe.ingredients[i], multiplier);
      rows.add(_ingredientRow(scaled, i));
    }
    if (rows.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No ingredients listed',
            style: _f(13, FontWeight.w500, _P.textHint)),
      ));
    }
    return rows;
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
          _stepBtn(Icons.remove, _servings > 1,
              () => setState(() => _servings--), _P.textDark),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_servings', style: _f(14, FontWeight.w800, _P.textDark)),
                const SizedBox(width: 3),
                Text('serv',
                    style: _f(10, FontWeight.w600, const Color(0xFF9A938A))),
              ],
            ),
          ),
          _stepBtn(Icons.add, true, () => setState(() => _servings++), _P.primary),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 16, color: enabled ? color : _P.textHint),
      ),
    );
  }

  Widget _ingredientRow(String text, int index) {
    final checked = _checked.contains(index);
    final parts = _parseIngredient(text);
    return GestureDetector(
      onTap: () => setState(() =>
          checked ? _checked.remove(index) : _checked.add(index)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _P.rowLine)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: checked ? _P.primary : Colors.transparent,
                border:
                    checked ? null : Border.all(color: _P.borderInner, width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _P.goldBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child:
                  const Icon(Icons.shopping_basket_outlined, size: 15, color: _P.gold),
            ),
            const SizedBox(width: 12),
            if (parts.$1 != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 56),
                child: Text(parts.$1!,
                    style: _f(14, FontWeight.w800,
                        checked ? _P.textHint : _P.textDark)),
              ),
            ],
            Expanded(
              child: Text(parts.$2,
                  style: _f(14, FontWeight.w500,
                      checked ? _P.textHint : _P.textBody, h: 1.35)),
            ),
          ],
        ),
      ),
    );
  }

  (String?, String) _parseIngredient(String text) {
    final match = RegExp(
            r'^([\d½¼¾⅓⅔⅛⅜⅝⅞/.\s]+(?:\s*(?:cup|cups|tbsp|tsp|oz|lb|lbs|g|kg|ml|l|piece|pieces|clove|cloves|inch|pinch|bunch|handful|can|cans|packet|packets|slice|slices|medium|large|small)\b)?)\s+(.*)$',
            caseSensitive: false)
        .firstMatch(text);
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
          Text('Instructions', style: _f(18, FontWeight.w800, _P.textDark)),
          const SizedBox(height: 6),
          if (recipe.instructions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No instructions listed',
                  style: _f(13, FontWeight.w500, _P.textHint)),
            )
          else
            for (var i = 0; i < recipe.instructions.length; i++)
              _instructionRow(i + 1, recipe.instructions[i]),
        ],
      ),
    );
  }

  Widget _instructionRow(int number, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 9, 0, 9),
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
                child: Text('$number', style: _f(13, FontWeight.w800, _P.primary))),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text,
                  style: _f(14, FontWeight.w500, _P.textBodyDark, h: 1.45)),
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
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Text('Cook step-by-step',
                style: _f(16, FontWeight.w700, Colors.white)),
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
          Text('NUTRITION', style: _f(13, FontWeight.w800, _P.primary, ls: 0.6)),
          const SizedBox(height: 2),
          Text('Per 1 serving',
              style: _f(12.5, FontWeight.w500, const Color(0xFF9A938A))),
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
                const Icon(Icons.workspace_premium_rounded, size: 18, color: _P.purple),
                const SizedBox(width: 11),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _f(13.5, FontWeight.w500, _P.textBodyDark, h: 1.45),
                      children: [
                        const TextSpan(text: 'This is a Plus feature. '),
                        TextSpan(
                            text: 'Subscribe now',
                            style: _f(13.5, FontWeight.w800, _P.purple)),
                        const TextSpan(
                            text:
                                " to unlock Recipe AI's nutrition calculator!"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ImageFiltered(
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
                            color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Text('520',
                              style: _f(18, FontWeight.w800,
                                  const Color(0xFF9A938A))),
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
                color: dot, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 54,
                height: 8,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2D8C7),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Container(
                width: 34,
                height: 7,
                decoration: BoxDecoration(
                    color: _P.border, borderRadius: BorderRadius.circular(4))),
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
      child: Column(
        children: [
          Text('Cooked it? Rate this recipe',
              style: _f(16, FontWeight.w800, _P.textDark)),
          if (_ratingCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 15, color: _P.star),
                const SizedBox(width: 5),
                Text(
                  '${_avgRating.toStringAsFixed(1)}  ·  '
                  '${_ratingCount == 1 ? '1 rating' : '$_ratingCount ratings'}',
                  style: _f(12.5, FontWeight.w700, _P.textBody),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _myRating;
              return GestureDetector(
                onTap: () => _setRating(i + 1),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: filled ? _P.star : const Color(0xFFE2D8C7),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 9),
          Text(_myRating == 0 ? 'Tap a star to rate' : 'You rated $_myRating / 5',
              style: _f(12, FontWeight.w600, const Color(0xFF9A938A))),
        ],
      ),
    );
  }

  // ── Engagement row — 3 stat cards (Likes / Saves / Ratings), like the HTML ──
  Widget _buildEngagementBar() {
    final ratingLabel = _ratingCount == 0
        ? 'Ratings'
        : (_ratingCount == 1 ? '1 rating' : '$_ratingCount ratings');
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon:
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            iconColor: _P.primary,
            value: '$_likes',
            label: 'Likes',
            onTap: _toggleLike,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon:
                _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            iconColor: _P.green,
            value: '$_saves',
            label: 'Saves',
            onTap: _saveToCookbook,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.star_rounded,
            iconColor: _P.star,
            value: _ratingCount == 0 ? '—' : _avgRating.toStringAsFixed(1),
            label: ratingLabel,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
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
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 5),
            Text(value, style: _f(15, FontWeight.w800, _P.textDark)),
            Text(label,
                style: _f(11, FontWeight.w600, const Color(0xFF9A938A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
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
            const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 9),
            Text('Save to my cookbook',
                style: _f(16, FontWeight.w700, Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Actions (reuse existing controllers) ─────────────────────────────────────
  RecipeModel _toRecipeModel() => RecipeModel(
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: recipe.imageUrl,
        sourceUrl: '',
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        totalTime: recipe.totalTime,
        servings: recipe.servings,
        category: recipe.category,
        cuisine: recipe.cuisine,
        keywords: const [],
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        ingredientSections: const [],
        instructionSections: const [],
        visibility: 'public',
      );

  void _share() {
    final buf = StringBuffer();
    buf.writeln(recipe.title);
    buf.writeln();
    if (recipe.description != null && recipe.description!.isNotEmpty) {
      buf.writeln(recipe.description);
      buf.writeln();
    }
    buf.writeln('INGREDIENTS');
    for (final ing in recipe.ingredients) {
      buf.writeln('• $ing');
    }
    buf.writeln();
    buf.writeln('INSTRUCTIONS');
    for (var i = 0; i < recipe.instructions.length; i++) {
      buf.writeln('${i + 1}. ${recipe.instructions[i]}');
    }
    Share.share(buf.toString(), subject: recipe.title);
    RecipeSocialService.registerShare(recipe.userId, recipe.id);
  }

  void _addToGroceries() {
    final grocery = Get.find<GroceryStore>();
    final multiplier = _servings / _initialServings;
    final scaled = recipe.ingredients
        .map((i) => IngredientScaleHelper.scaleIngredient(i, multiplier))
        .toList();
    grocery.addFromRecipe(recipe.id, scaled);
    CustomSnackbar.show(
      title: '${recipe.ingredients.length} ingredients added to groceries',
      actionText: 'View',
      onAction: () {
        HomeScreen.activeIndex = 3;
        Get.offUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => route.isFirst,
        );
      },
    );
  }

  Future<void> _saveToCookbook() async {
    if (_busySave) return;
    _busySave = true;
    // Public recipes belong to another user, so we first copy the recipe into
    // the current user's own collection. The cookbook then references OUR copy
    // (cookbooks resolve ids against the current user's recipes).
    final copyId = await RecipeSocialService.saveCopyToMyRecipes(recipe);
    _busySave = false;
    if (copyId == null || !mounted) return;

    // Reflect the save (counter + marker) if not already saved.
    if (!_saved) {
      setState(() {
        _saved = true;
        _saves += 1;
      });
      RecipeSocialService.setSave(recipe.userId, recipe.id, true);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookbookPickerSheet(
        cookbookController: Get.find<CookbookController>(),
        recipeId: copyId,
        recipeImageUrl: recipe.imageUrl,
      ),
    );
  }
}
