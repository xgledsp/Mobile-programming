import '../app_theme.dart';
import 'chat_message.dart';
import 'hodu_responder.dart';
import 'knowledge/kb_entry.dart';
import 'knowledge/knowledge_base.dart';
import 'topic_guard.dart';

// ================================================================
// KNOWLEDGE RESPONDER - Hodu's OFFLINE brain
// ================================================================
//
// Answers from the prepared knowledge base, without internet.
//
//   good match  -> the prepared answer (+ where to check it)
//   no match    -> honest "I don't have an offline answer" message
//                  with questions the user CAN ask about that topic
// ================================================================

class KnowledgeResponder implements HoduResponder {
  final KnowledgeBase knowledgeBase;
  final AppLanguage language;

  const KnowledgeResponder({
    this.knowledgeBase = const KnowledgeBase(),
    this.language = AppLanguage.english,
  });

  bool get _ko => language == AppLanguage.korean;

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    final KbEntry? entry = knowledgeBase.bestAnswer(question);
    if (entry != null) {
      return HoduReply(entry.fullAnswer(language), ReplySource.knowledgeBase);
    }
    return HoduReply(_noAnswerText(question), ReplySource.fallback);
  }

  String _noAnswerText(String question) {
    final TopicCategory? topic = knowledgeBase.guard.classify(question).mainCategory;
    final List<KbEntry> related =
        topic == null ? const [] : knowledgeBase.inCategory(topic).take(3).toList();

    // Fall back to the most common questions when the topic is unknown.
    final List<KbEntry> suggestions = related.isNotEmpty
        ? related
        : [
            for (final String id in const ['arc_apply', 'bank_account', 'sim_card'])
              if (knowledgeBase.byId(id) != null) knowledgeBase.byId(id)!,
          ];

    final String list =
        suggestions.map((KbEntry e) => '• ${e.question(language)}').join('\n');

    return _ko
        ? '죄송해요, 그 질문에 대한 오프라인 답변은 아직 없어요. '
            '인터넷에 연결되면 더 자세히 도와드릴 수 있어요.\n\n이런 질문은 바로 답할 수 있어요:\n$list'
        : "Sorry, I don't have an offline answer for that yet. "
            'When you are online I can help in more detail.\n\nI can answer these right away:\n$list';
  }
}
