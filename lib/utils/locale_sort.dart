/// Locale-aware string comparison for sorting user-facing names/titles in ANY
/// language.
///
/// Dart's [String.compareTo] orders by raw UTF-16 code units, which mis-sorts
/// real-world names: titles starting with an emoji or punctuation ("🍔 Burger",
/// "  Paneer") jump to the top, accented Latin letters ("Éclair") sort after
/// "z", and mixed scripts clump by Unicode block instead of alphabetically.
///
/// [LocaleSort.compare] normalises each string into a stable sort key first —
/// trimming, dropping leading non-letter characters, lower-casing, and folding
/// common Latin accents. Non-Latin scripts (Gujarati, Hindi, Arabic, Cyrillic,
/// …) are already laid out in alphabetical order within their Unicode block, so
/// they sort correctly through the same path.
class LocaleSort {
  LocaleSort._();

  /// Compares two display names for A→Z ordering. Case-insensitive, ignores
  /// leading emoji/symbols/whitespace, folds common Latin accents, and pushes
  /// blank / symbol-only names to the end. Reverse the arguments for Z→A.
  static int compare(String a, String b) {
    final ka = _sortKey(a);
    final kb = _sortKey(b);

    // Blank keys (empty or emoji-only names) sort last, not first.
    if (ka.isEmpty && kb.isEmpty) return a.trim().compareTo(b.trim());
    if (ka.isEmpty) return 1;
    if (kb.isEmpty) return -1;

    final primary = ka.compareTo(kb);
    if (primary != 0) return primary;

    // Stable tie-break on the lower-cased raw string so equal keys keep a
    // deterministic order.
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// Builds a normalised comparison key: trim → strip leading non-letter/digit
  /// characters (emoji, punctuation, whitespace) → lower-case → fold Latin
  /// diacritics.
  static String _sortKey(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';

    // Drop leading characters that aren't letters or digits in ANY script, so
    // "🍔 Burger", "  Burger" and "-Burger" all key as "burger".
    s = s.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');
    if (s.isEmpty) return '';

    return _foldDiacritics(s.toLowerCase());
  }

  /// Folds common Latin accented letters to their base letter so that, in
  /// Latin-script languages, "é/è/ê" sort with "e", "ñ" with "n", etc. Any
  /// character not in the map (including every non-Latin script) is left as-is.
  static String _foldDiacritics(String s) {
    const map = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
      'ç': 'c', 'č': 'c', 'ć': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i',
      'ñ': 'n', 'ń': 'n',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ß': 'ss', 'ş': 's', 'š': 's', 'ś': 's',
      'ž': 'z', 'ź': 'z', 'ż': 'z',
      'ğ': 'g', 'ł': 'l',
    };

    // Fast path: nothing to fold for the common (non-Latin or plain-ASCII) case.
    var needsFold = false;
    for (final key in map.keys) {
      if (s.contains(key)) {
        needsFold = true;
        break;
      }
    }
    if (!needsFold) return s;

    final sb = StringBuffer();
    for (final ch in s.split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }
}
