import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_ai/Controllers/ai_assistant_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:recipe_ai/widgets/tr_text.dart';

/// AI Cooking Assistant chat, scoped to one recipe (designs 76 · start,
/// 77 · swap, 78 · scale). Real chat: AI-powered ingredient swaps + deterministic
/// serving scaling, with "Apply this swap" / "Update recipe" committing the
/// change to the recipe (and cascading to groceries + instructions).
class AiAssistantScreen extends StatefulWidget {
  final RecipeModel recipe;
  const AiAssistantScreen({super.key, required this.recipe});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

// ── palette ──
const _bg = Color(0xFFFBF4EA);
const _ink = Color(0xFF2A211B);
const _purple = Color(0xFF8B5CF6);
const _purpleDeep = Color(0xFF7A45E0);
const _grad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF9466F2), Color(0xFF6D3BD4)],
);
const _cardBorder = Color(0xFFEFE6D6);
const _muted = Color(0xFF8A7E70);
const _iconBg = Color(0xFFF4EEFD);

TextStyle _f(double s, FontWeight w, Color c, {double? h}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: s,
      fontWeight: w,
      color: c,
      height: h,
    );

class _Msg {
  final bool user;
  final String? text;
  final _SwapData? swap;
  final ScalePreview? scale;
  bool applied;
  _Msg({
    this.user = false,
    this.text,
    this.swap,
    this.scale,
    this.applied = false,
  });
}

class _SwapData {
  final String ingredientLine;
  final List<SwapOption> options;
  int selected;
  _SwapData(this.ingredientLine, this.options, [this.selected = 0]);
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = AiAssistantController.to;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[];
  bool _busy = false;

  RecipeModel get recipe => Get.find<HomeController>().recipes.firstWhere(
    (r) => r.id == widget.recipe.id,
    orElse: () => widget.recipe,
  );

  int get _doubleTarget => _ctrl.servingsOf(recipe) * 2;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── actions ──
  Future<void> _startSwap() async {
    final line = await _pickIngredient();
    if (line == null) return;
    final name = _ctrl.nameOf(line);
    setState(() {
      _messages.add(
        _Msg(user: true, text: 'ai_out_of_ingredient_msg'.trParams({'name': name})),
      );
      _busy = true;
    });
    _scrollDown();
    final options = await _ctrl.suggestSwaps(recipe, line);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (options.isEmpty) {
        _messages.add(
          _Msg(text: 'ai_swap_none_found'.tr),
        );
      } else {
        _messages.add(
          _Msg(
            text: 'ai_swaps_intro_msg'.trParams({
              'count': '${options.length}',
              'name': name,
            }),
          ),
        );
        _messages.add(_Msg(swap: _SwapData(line, options)));
      }
    });
    _scrollDown();
  }

  Future<void> _startScale() async {
    final target = await _pickServings();
    if (target == null) return;
    final preview = _ctrl.buildScalePreview(recipe, target);
    setState(() {
      _messages.add(
        _Msg(
          user: true,
          text: 'ai_scale_request_msg'.trParams({'target': '$target'}),
        ),
      );
      _messages.add(
        _Msg(text: 'ai_scale_done_msg'.trParams({'target': '$target'})),
      );
      _messages.add(_Msg(scale: preview));
    });
    _scrollDown();
  }

  /// Lets the user choose any target serving count (stepper + quick picks).
  Future<int?> _pickServings() {
    int value = _doubleTarget;
    final current = _ctrl.servingsOf(recipe);
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E0D2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                'ai_scale_sheet_title'.tr,
                style: _f(17, FontWeight.w800, _ink),
              ),
              const SizedBox(height: 4),
              Text(
                'ai_currently_servings'.trParams({'count': '$current'}),
                style: _f(13, FontWeight.w500, _muted),
              ),
              const SizedBox(height: 22),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _servBtn(
                      'minus',
                      value > 1,
                      () => setSheet(() {
                        if (value > 1) value--;
                      }),
                    ),
                    SizedBox(
                      width: 108,
                      child: Column(
                        children: [
                          Text('$value', style: _f(38, FontWeight.w800, _ink)),
                          Text(
                            'ai_serving_plural'.trParams({'count': '$value'}),
                            style: _f(12, FontWeight.w600, _muted),
                          ),
                        ],
                      ),
                    ),
                    _servBtn('plus', true, () => setSheet(() => value++)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in const [1, 2, 3, 4, 6, 8, 12])
                    GestureDetector(
                      onTap: () => setSheet(() => value = q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: value == q ? _purple : _iconBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$q',
                          style: _f(
                            13.5,
                            FontWeight.w700,
                            value == q ? Colors.white : _purpleDeep,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _grad,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'ai_scale_recipe_btn'.tr,
                    style: _f(15, FontWeight.w800, Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _servBtn(String icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: OnboardingLineIcon(
          icon,
          size: 18,
          color: enabled ? _purpleDeep : _muted,
        ),
      ),
    );
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    // Detect a typed "scale to N" request → deterministic scale.
    final m = RegExp(
      r'(?:scale|make).*?(\d+)\s*(?:servings|people|portions)?',
      caseSensitive: false,
    ).firstMatch(q.toLowerCase());
    if (m != null && q.toLowerCase().contains('scale')) {
      final target = int.tryParse(m.group(1)!) ?? _doubleTarget;
      final preview = _ctrl.buildScalePreview(recipe, target);
      setState(() {
        _messages.add(_Msg(user: true, text: q));
        _messages.add(
          _Msg(text: 'ai_scale_done_msg'.trParams({'target': '$target'})),
        );
        _messages.add(_Msg(scale: preview));
      });
      _scrollDown();
      return;
    }
    setState(() {
      _messages.add(_Msg(user: true, text: q));
      _busy = true;
    });
    _scrollDown();
    final reply = await _ctrl.ask(recipe, q);
    // The assistant answers in English (app logic is English); show it in the
    // user's language via on-device ML Kit — no extra AI call.
    final shown = await AiTranslationService.translate(reply.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _messages.add(_Msg(text: shown));
    });
    _scrollDown();
  }

  Future<void> _applySwap(_SwapData d, _Msg msg) async {
    setState(() => msg.applied = true);
    await _ctrl.applySwap(recipe, d.ingredientLine, d.options[d.selected]);
    if (mounted) Get.back<void>(); // return to detail → banner shows
  }

  Future<void> _applyScale(ScalePreview p, _Msg msg) async {
    setState(() => msg.applied = true);
    await _ctrl.applyScale(recipe, p);
    if (mounted) Get.back<void>();
  }

  Future<String?> _pickIngredient() {
    final lines = _ctrl.ingredientLinesOf(recipe);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0D2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              'ai_pick_ingredient_title'.tr,
              style: _f(17, FontWeight.w800, _ink),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: lines.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF4ECDF)),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => Navigator.pop(context, lines[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lines[i],
                            style: _f(14, FontWeight.w600, _ink),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFC7BCAC),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _messages.isEmpty
                  ? _intro()
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      children: [
                        for (final m in _messages) _bubble(m),
                        if (_busy) _typing(),
                      ],
                    ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  // ── header ──
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          _sqBtn(
            Icons.close_rounded,
            () => Get.back<void>(),
            bg: Colors.white,
            border: true,
            color: _ink,
          ),
          const SizedBox(width: 11),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const OnboardingLineIcon(
              'chat',
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'plus_feature_ai_assistant'.tr,
                  style: _f(15, FontWeight.w800, _ink),
                ),
                const SizedBox(height: 1),
                Text(
                  recipe.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _f(
                    12,
                    FontWeight.w700,
                    _messages.isEmpty ? _muted : const Color(0xFF1F7A5E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text('plus'.tr, style: _f(10, FontWeight.w800, _purpleDeep)),
          ),
        ],
      ),
    );
  }

  // ── intro (design 76) ──
  Widget _intro() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 265.0),
          child: Container(
            width: 55,
            height: 55,
            padding: const EdgeInsets.only(top: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _grad,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: const OnboardingLineIcon(
              'sparkF',
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ai_intro_heading'.tr,
          style: _f(21, FontWeight.w800, _ink, h: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'ai_intro_subtitle'.tr,
          style: _f(14, FontWeight.w500, _muted, h: 1.5),
        ),
        const SizedBox(height: 24),
        Text(
          'ai_try_asking_label'.tr,
          style: _f(
            12,
            FontWeight.w800,
            const Color(0xFFA89F90),
          ).copyWith(letterSpacing: 0.7),
        ),
        const SizedBox(height: 12),
        _tryTile('swap', 'ai_try_swap_label'.tr, _startSwap),
        const SizedBox(height: 10),
        _tryTile('ruler', 'ai_try_scale_label'.tr, _startScale),
      ],
    );
  }

  Widget _tryTile(String iconKey, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: OnboardingLineIcon(iconKey, size: 20, color: _purple),
            ),
            const SizedBox(width: 13),
            Expanded(child: Text(label, style: _f(14, FontWeight.w700, _ink))),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7BCAC)),
          ],
        ),
      ),
    );
  }

  // ── message bubbles ──
  Widget _bubble(_Msg m) {
    if (m.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: _purple,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            m.text ?? '',
            style: _f(14, FontWeight.w500, Colors.white, h: 1.45),
          ),
        ),
      );
    }
    if (m.swap != null) return _swapCard(m);
    if (m.scale != null) return _scaleCard(m);
    // assistant text
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(m.text ?? '', style: _f(14, FontWeight.w500, _ink, h: 1.5)),
      ),
    );
  }

  Widget _swapCard(_Msg m) {
    final d = m.swap!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.82,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0D2F7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                15,
              ), // border width jetlu thoduk ochu, taaki border clean dekhaay
              child: Column(
                children: [
                  for (var i = 0; i < d.options.length; i++)
                    GestureDetector(
                      onTap: m.applied
                          ? null
                          : () => setState(() => d.selected = i),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: i == d.selected
                              ? const Color(0xFFF8F4FF)
                              : Colors.transparent,
                          border: Border(
                            bottom: i == d.options.length - 1
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFFEDE3FC),
                                  ), // niche note ma
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: d.options[i].vegan
                                    ? const Color(0xFFEAF6F0)
                                    : _iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                d.options[i].vegan
                                    ? Icons.eco_rounded
                                    : Icons.swap_horiz_rounded,
                                size: 18,
                                color: d.options[i].vegan
                                    ? const Color(0xFF1F7A5E)
                                    : _purple,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TrText(
                                    d.options[i].replacement,
                                    style: _f(13.5, FontWeight.w800, _ink),
                                  ),
                                  if (d.options[i].note.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    TrText(
                                      d.options[i].note,
                                      style: _f(11.5, FontWeight.w600, _muted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (i == d.selected && !m.applied)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: _purple,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!m.applied)
            _applyPill(
              Icons.swap_horiz_rounded,
              'ai_apply_swap_btn'.tr,
              () => _applySwap(d, m),
            )
          else
            _appliedPill('ai_swap_applied_pill'.tr),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _scaleCard(_Msg m) {
    final p = m.scale!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.84,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0D2F7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 15,
                      color: _purpleDeep,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ai_scaled_badge'.trParams({
                        'from': '${p.fromServings}',
                        'to': '${p.toServings}',
                      }),
                      style: _f(12, FontWeight.w800, _purpleDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < p.rows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: i == p.rows.length - 1
                            ? BorderSide.none
                            : const BorderSide(color: Color(0xFFF4ECDF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.rows[i].name,
                            style: _f(
                              13.5,
                              FontWeight.w600,
                              const Color(0xFF5A5147),
                            ),
                          ),
                        ),
                        Text(
                          p.rows[i].oldQ,
                          style: _f(
                            12,
                            FontWeight.w600,
                            const Color(0xFFA89F90),
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          p.rows[i].newQ,
                          style: _f(13.5, FontWeight.w800, _ink),
                        ),
                      ],
                    ),
                  ),
                if (p.rows.isEmpty)
                  Text(
                    'ai_nothing_to_scale'.tr,
                    style: _f(13, FontWeight.w500, _muted),
                  ),
              ],
            ),
          ),
          if (!m.applied)
            _applyPill(
              Icons.check_rounded,
              'ai_update_recipe_btn'.tr,
              () => _applyScale(p, m),
            )
          else
            _appliedPill('ai_recipe_updated_pill'.tr),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _applyPill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: _f(13, FontWeight.w800, Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _appliedPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6F0),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1F7A5E)),
        const SizedBox(width: 6),
        Text(label, style: _f(13, FontWeight.w800, const Color(0xFF1F7A5E))),
      ],
    ),
  );

  Widget _typing() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_Dot(0), _Dot(200), _Dot(400)],
        ),
      ),
    ),
  );

  // ── input ──
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,

              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7DECE)),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _input,
                cursorColor: const Color(0xFF8B5CF6),
                onSubmitted: (_) => _send(),
                style: _f(14, FontWeight.w500, _ink),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'ai_input_hint'.tr,

                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintStyle: _f(14, FontWeight.w500, const Color(0xFFA89F90)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _grad,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sqBtn(
    IconData icon,
    VoidCallback onTap, {
    required Color bg,
    bool border = false,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: border ? Border.all(color: const Color(0xFFEFEDE6)) : null,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot(this.delayMs);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: _muted, shape: BoxShape.circle),
      ),
    );
  }
}
