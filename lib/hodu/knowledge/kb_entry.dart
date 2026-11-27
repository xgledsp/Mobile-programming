import '../../app_theme.dart';
import '../topic_guard.dart';

// ================================================================
// KNOWLEDGE BASE ENTRY - one prepared answer
// ================================================================
//
// Every entry is written in English AND Korean. The keywords decide
// when the entry is a good match for a question:
//
//   keywords   -> words that point to this entry (English + Korean)
//   category   -> same categories as the TopicGuard, used as a bonus
//   source     -> where the user can confirm the information
// ================================================================

class KbEntry {
  final String id;
  final TopicCategory category;

  /// Short question this entry answers (shown as a title / suggestion).
  final String questionEn;
  final String questionKo;

  final String answerEn;
  final String answerKo;

  /// English and Korean keywords. Korean ones match inside words.
  final List<String> keywords;

  /// Official place to double-check, e.g. "HiKorea (hikorea.go.kr) / 1345".
  final String? sourceEn;
  final String? sourceKo;

  const KbEntry({
    required this.id,
    required this.category,
    required this.questionEn,
    required this.questionKo,
    required this.answerEn,
    required this.answerKo,
    required this.keywords,
    this.sourceEn,
    this.sourceKo,
  });

  String question(AppLanguage language) =>
      language == AppLanguage.korean ? questionKo : questionEn;

  String answer(AppLanguage language) =>
      language == AppLanguage.korean ? answerKo : answerEn;

  String? source(AppLanguage language) =>
      language == AppLanguage.korean ? sourceKo : sourceEn;

  /// Answer + "Check: <source>" line, as shown in the chat.
  String fullAnswer(AppLanguage language) {
    final String? src = source(language);
    if (src == null) {
      return answer(language);
    }
    final String label = language == AppLanguage.korean ? '확인하기' : 'Check';
    return '${answer(language)}\n\n$label: $src';
  }

  /// Short version used when the entry is given to the AI as a fact.
  String asFact() => '[$id] $questionEn\n$answerEn'
      '${sourceEn == null ? '' : '\nOfficial source: $sourceEn'}';

  @override
  String toString() => 'KbEntry($id)';
}
