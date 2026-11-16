import 'package:flutter/foundation.dart';

import 'ai_client.dart';
import 'chat_message.dart';
import 'hodu_responder.dart';

// ================================================================
// HYBRID RESPONDER - online AI with automatic offline fallback
// ================================================================
//
//   question
//     -> online brain (AI)          works?  -> AI answer
//     -> it failed (AiException)            -> offline brain (knowledge base)
//
// No internet: after a network error or timeout we remember that we are
// offline and skip the AI for [offlinePause]. Otherwise every question
// would wait for the network to fail first.
//
// [isOnline] tells the chat screen what to show in the header
// ("Online" / "Offline mode").
// ================================================================

class HybridResponder implements HoduResponder {
  final HoduResponder online;
  final HoduResponder offline;
  final Duration offlinePause;
  final DateTime Function() _clock;

  /// False after a network problem, true again after the next AI answer.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// The last AI problem (useful for debugging and tests).
  AiException? lastError;

  DateTime? _skipAiUntil;

  HybridResponder({
    required this.online,
    required this.offline,
    this.offlinePause = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// True while the AI is skipped because we recently were offline.
  bool get isPaused => _skipAiUntil != null && _clock().isBefore(_skipAiUntil!);

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    if (isPaused) {
      return offline.reply(question, history);
    }

    try {
      final HoduReply reply = await online.reply(question, history);
      _skipAiUntil = null;
      isOnline.value = true;
      return reply;
    } on AiException catch (error) {
      lastError = error;
      debugPrint('Hodu AI failed, using offline answer: $error');
      if (error.kind == AiErrorKind.network || error.kind == AiErrorKind.timeout) {
        isOnline.value = false;
        _skipAiUntil = _clock().add(offlinePause);
      }
      return offline.reply(question, history);
    }
  }

  /// Forget the offline pause (e.g. when the user taps "try online again").
  void resetOfflinePause() {
    _skipAiUntil = null;
    isOnline.value = true;
  }

  void dispose() => isOnline.dispose();
}
