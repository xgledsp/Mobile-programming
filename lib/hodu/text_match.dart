// ================================================================
// TEXT MATCHING HELPERS (used by the topic guard and the knowledge base)
// ================================================================
//
// Korean keywords are matched as substrings, because Korean attaches
// particles to words (비자 -> 비자를, 비자가, 비자는).
// English keywords are matched as whole words (+ plural "s"/"es"), so
// "arc" does not match inside "search".
// ================================================================

class TextMatch {
  TextMatch._();

  /// Lower-case, remove punctuation (keep letters of every language,
  /// digits and apostrophes) and collapse spaces.
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\p{L}\p{N}\s'/+-]", unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// True when [normalizedText] (already passed through [normalize])
  /// contains [keyword].
  static bool containsKeyword(String normalizedText, String keyword) {
    if (!_latin.hasMatch(keyword)) {
      return normalizedText.contains(keyword);
    }
    final RegExp pattern = _regexCache.putIfAbsent(
      keyword,
      () => RegExp('(^| )${RegExp.escape(keyword)}(s|es)?(?= |\$)'),
    );
    return pattern.hasMatch(normalizedText);
  }

  /// How many of [keywords] appear in [normalizedText].
  static int countKeywords(String normalizedText, Iterable<String> keywords) =>
      keywords.where((String k) => containsKeyword(normalizedText, k)).length;

  static final RegExp _latin = RegExp(r"^[a-z0-9 '/+-]+$");
  static final Map<String, RegExp> _regexCache = {};
}
