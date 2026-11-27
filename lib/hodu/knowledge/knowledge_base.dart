import '../text_match.dart';
import '../topic_guard.dart';
import 'kb_data.dart';
import 'kb_entry.dart';

// ================================================================
// KNOWLEDGE BASE SEARCH - finds the best prepared answer
// ================================================================
//
// Simple scoring, works offline and instantly:
//
//   +3  for every keyword of the entry found in the question
//   +2  if the entry is in the question's main topic (from TopicGuard)
//   +1  if the entry is in one of the question's other topics
//
// An entry needs at least one keyword hit to be returned at all, so a
// question never gets an answer only because the topic is similar.
// ================================================================

class KbMatch {
  final KbEntry entry;
  final int score;
  final int keywordHits;

  const KbMatch(this.entry, this.score, this.keywordHits);

  @override
  String toString() => 'KbMatch(${entry.id}, score: $score, hits: $keywordHits)';
}

class KnowledgeBase {
  static const int keywordWeight = 3;
  static const int mainCategoryBonus = 2;
  static const int otherCategoryBonus = 1;

  final List<KbEntry> entries;
  final TopicGuard guard;

  const KnowledgeBase({
    this.entries = hoduKnowledgeBase,
    this.guard = const TopicGuard(),
  });

  /// All matching entries, best first.
  List<KbMatch> search(String question, {int limit = 3}) {
    final String text = TextMatch.normalize(question);
    if (text.isEmpty) {
      return const [];
    }
    final List<TopicCategory> categories = guard.classify(question).categories;

    final List<KbMatch> matches = [];
    for (final KbEntry entry in entries) {
      final int hits = TextMatch.countKeywords(text, entry.keywords);
      if (hits == 0) {
        continue;
      }
      int score = hits * keywordWeight;
      if (categories.isNotEmpty && categories.first == entry.category) {
        score += mainCategoryBonus;
      } else if (categories.contains(entry.category)) {
        score += otherCategoryBonus;
      }
      matches.add(KbMatch(entry, score, hits));
    }

    matches.sort((KbMatch a, KbMatch b) {
      final int byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.keywordHits.compareTo(a.keywordHits);
    });
    return matches.take(limit).toList();
  }

  /// The single best entry, or null when nothing matches.
  KbEntry? bestAnswer(String question) {
    final List<KbMatch> matches = search(question, limit: 1);
    return matches.isEmpty ? null : matches.first.entry;
  }

  /// Entries of one topic (used for "try asking..." suggestions).
  List<KbEntry> inCategory(TopicCategory category) =>
      entries.where((KbEntry e) => e.category == category).toList();

  KbEntry? byId(String id) {
    for (final KbEntry e in entries) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }
}
