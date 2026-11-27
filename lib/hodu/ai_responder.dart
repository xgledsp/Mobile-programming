import '../app_theme.dart';
import 'chat_message.dart';
import 'ai_client.dart';
import 'hodu_prompt.dart';
import 'hodu_responder.dart';
import 'knowledge/kb_entry.dart';
import 'knowledge/knowledge_base.dart';

// ================================================================
// AI RESPONDER - Hodu's online brain
// ================================================================
//
// Turns the chat history into the API format, sends it with the system
// prompt, and returns the answer as a HoduReply.
//
// The API has rules for the message list, so we clean it first:
//   • it must start with a "user" message   -> Hodu's greeting is dropped
//   • failed questions are skipped (they were never answered)
//   • only the last [maxHistory] messages are sent, so long chats stay
//     fast and cheap
//   • two messages in a row from the same side are merged into one
// ================================================================

class AiResponder implements HoduResponder {
  final AiClient client;
  final AppLanguage language;
  final int maxHistory;
  final DateTime Function() clock;

  /// When set, the best matching entries are given to the AI as verified
  /// facts ("grounding"), so its answer agrees with the offline answers.
  final KnowledgeBase? knowledgeBase;
  final int maxFacts;

  AiResponder({
    required this.client,
    this.language = AppLanguage.english,
    this.maxHistory = 12,
    this.knowledgeBase,
    this.maxFacts = 2,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    final List<AiMessage> messages = toApiMessages(history, maxHistory: maxHistory);
    final String system = HoduPrompt(
      language: language,
      today: clock(),
      facts: factsFor(question),
    ).build();

    final String text = await client.createReply(system: system, messages: messages);
    return HoduReply(text, ReplySource.ai);
  }

  /// Knowledge-base entries that match [question] (empty without a KB).
  List<KbEntry> factsFor(String question) {
    final KnowledgeBase? kb = knowledgeBase;
    if (kb == null) {
      return const [];
    }
    return kb.search(question, limit: maxFacts).map((KbMatch m) => m.entry).toList();
  }

  /// Converts chat bubbles into the list the API accepts (see notes above).
  /// [history] already ends with the user's new question.
  static List<AiMessage> toApiMessages(
    List<ChatMessage> history, {
    int maxHistory = 12,
  }) {
    // 1. Skip failed questions, but keep the newest one (it is being retried).
    final List<ChatMessage> usable = [
      for (int i = 0; i < history.length; i++)
        if (!history[i].isFailed || i == history.length - 1) history[i],
    ];

    // 2. Keep only the most recent messages.
    final List<ChatMessage> recent = usable.length > maxHistory
        ? usable.sublist(usable.length - maxHistory)
        : usable;

    // 3. Merge same-side neighbours and convert.
    final List<_Turn> turns = [];
    for (final ChatMessage m in recent) {
      if (m.text.trim().isEmpty) {
        continue;
      }
      if (turns.isNotEmpty && turns.last.isUser == m.isUser) {
        turns.last.parts.add(m.text);
      } else {
        turns.add(_Turn(m.isUser, [m.text]));
      }
    }

    // 4. Must start with the user (drops the greeting / old Hodu replies).
    while (turns.isNotEmpty && !turns.first.isUser) {
      turns.removeAt(0);
    }

    return turns
        .map((_Turn t) => t.isUser
            ? AiMessage.user(t.parts.join('\n\n'))
            : AiMessage.assistant(t.parts.join('\n\n')))
        .toList();
  }
}

class _Turn {
  final bool isUser;
  final List<String> parts;
  _Turn(this.isUser, this.parts);
}
