import 'dart:async';

import 'ai_client.dart';

// ================================================================
// RESILIENT AI CLIENT - retries and backup model
// ================================================================
//
// Free AI services fail often: "overloaded" (503), "too many requests"
// (429), slow answers (timeout) or random empty errors. Instead of
// showing an error right away, Hodu tries again:
//
//   attempt 1: main model
//   (short wait)
//   attempt 2: backup model
//   (longer wait)
//   attempt 3: main model again
//
// Only TEMPORARY errors are retried. A wrong API key or a bad request
// will fail the same way every time, so those are reported at once.
//
// This is a "decorator" again: it wraps normal AiClients and is itself
// an AiClient, so nothing else in the app has to change.
// ================================================================

class ResilientAiClient implements AiClient {
  /// Clients to rotate through, e.g. [main model, backup model].
  final List<AiClient> clients;

  /// How many requests at most for one question.
  final int maxAttempts;

  /// Wait before attempt 2, 3, ... (the last value is reused).
  final List<Duration> backoff;

  /// Replaceable in tests so they do not really wait.
  final Future<void> Function(Duration) _sleep;

  ResilientAiClient({
    required this.clients,
    this.maxAttempts = 3,
    this.backoff = const [Duration(milliseconds: 800), Duration(seconds: 2)],
    Future<void> Function(Duration)? sleep,
  })  : assert(clients.isNotEmpty),
        assert(maxAttempts >= 1),
        _sleep = sleep ?? Future<void>.delayed;

  @override
  Future<String> createReply({
    required String system,
    required List<AiMessage> messages,
  }) async {
    AiException? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await _sleep(backoff[(attempt - 1).clamp(0, backoff.length - 1)]);
      }
      final AiClient client = clients[attempt % clients.length];
      try {
        return await client.createReply(system: system, messages: messages);
      } on AiException catch (error) {
        if (!error.isTemporary) {
          rethrow; // retrying would not help
        }
        lastError = error;
      }
    }
    throw lastError!;
  }

  @override
  void close() {
    for (final AiClient client in clients) {
      client.close();
    }
  }
}
