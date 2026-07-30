import 'package:flutter/material.dart';

import 'package:recipe_ai/Service/ai_translation_service.dart';

/// Shows the ML Kit (on-device) translation of an English [data] string in the
/// current app language.
///
/// The app's source of truth is English (Firestore stores English, all logic
/// runs on English); this widget only affects what the user SEES. It renders
/// the cached translation — or the English text — on the first frame, then fills
/// the real translation in asynchronously and rebuilds. So a string that has
/// been seen before never flickers, and a brand-new one shows English for a
/// moment instead of a blank. Purely on-device: no network, no AI/LLM call.
///
/// Drop-in for a `Text(data, style: …)` that displays dynamic Firestore/model
/// content (recipe titles, ingredient names, steps …). Do NOT use it for text
/// that already goes through GetX `.tr` (static UI) or for text that is already
/// translated upstream — that would translate twice.
class TrText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const TrText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  State<TrText> createState() => _TrTextState();
}

class _TrTextState extends State<TrText> {
  late String _text = AiTranslationService.cachedOrSelf(widget.data);

  @override
  void initState() {
    super.initState();
    // _text was already seeded from the cache above. Only go to ML Kit when
    // that was an actual miss (i.e. it handed back the English source), so a
    // list of already-cached rows costs nothing beyond the map lookups.
    if (_text == widget.data.trim()) _load();
  }

  @override
  void didUpdateWidget(covariant TrText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _text = AiTranslationService.cachedOrSelf(widget.data);
      if (_text == widget.data.trim()) _load();
    }
  }

  Future<void> _load() async {
    final translated = await AiTranslationService.translate(widget.data);
    if (mounted && translated != _text) {
      setState(() => _text = translated);
    }
  }

  @override
  Widget build(BuildContext context) => Text(
        _text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
}
