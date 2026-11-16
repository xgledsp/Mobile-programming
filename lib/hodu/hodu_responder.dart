import '../app_theme.dart';
import 'chat_message.dart';

// ================================================================
// HODU RESPONDER - "the brain" behind the chat
// ================================================================
//
// The chat controller does not know HOW an answer is made. It only asks
// a HoduResponder. This lets us swap the brain without touching the UI:
//
//   PlaceholderResponder  -> step 1, fixed text (no AI yet)
//   KnowledgeBaseResponder -> offline answers from the local data
//   AiResponder            -> online answers from the AI model
//
// In tests we pass a fake responder so we can test the controller
// without internet.
// ================================================================

abstract class HoduResponder {
  /// Returns Hodu's answer to [question].
  ///
  /// [history] is the conversation so far (oldest first) and already
  /// contains the user's new question as the last item.
  /// Throws an exception if the answer could not be produced.
  Future<HoduReply> reply(String question, List<ChatMessage> history);
}

/// Temporary brain used until the knowledge base and the AI are ready.
class PlaceholderResponder implements HoduResponder {
  final AppLanguage language;

  const PlaceholderResponder({this.language = AppLanguage.english});

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    final String text = language == AppLanguage.korean
        ? '아직 배우는 중이에요! 곧 비자, 기숙사, 은행 같은 질문에 답할 수 있어요.'
        : "I'm still learning! Soon I can answer questions about visas, "
            'dorms, banks and life in Korea.';
    return HoduReply(text, ReplySource.fallback);
  }
}
