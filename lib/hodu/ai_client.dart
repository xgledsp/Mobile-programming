// ================================================================
// AI CLIENT - common contract for every AI provider
// ================================================================
//
// Hodu can talk to different AI services:
//
//   GeminiClient  -> Google Gemini (free tier, used while developing)
//   ClaudeClient  -> Anthropic Claude (paid, better quality)
//
// Both implement AiClient, so the rest of the app (AiResponder, chat
// screen, tests) never needs to know which one is used. Switching is
// one setting: HODU_PROVIDER in hodu_secrets.json.
//
// All providers report problems the same way: an AiException with an
// AiErrorKind, so the chat can react the same way to every provider.
// ================================================================

abstract class AiClient {
  /// Sends the [system] instructions and the conversation, returns the
  /// AI's answer text. Throws [AiException] on any problem.
  Future<String> createReply({
    required String system,
    required List<AiMessage> messages,
  });

  /// Frees the network connection.
  void close();
}

/// One turn of the conversation sent to the AI.
class AiMessage {
  /// "user" or "assistant". Each client converts this to its own format
  /// (Gemini calls the assistant "model").
  final String role;
  final String text;

  const AiMessage.user(this.text) : role = 'user';
  const AiMessage.assistant(this.text) : role = 'assistant';

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'content': text};

  @override
  String toString() => 'AiMessage($role, "$text")';
}

enum AiErrorKind {
  /// No internet / server could not be reached.
  network,

  /// The server took too long.
  timeout,

  /// Wrong or missing API key.
  auth,

  /// Too many requests, free-tier limit or no credit left (429).
  rateLimit,

  /// The provider had a problem (5xx).
  server,

  /// Our request was wrong (400/404) - a bug or a wrong model name.
  badRequest,

  /// The AI declined to answer (safety filter).
  refusal,

  /// The response could not be read.
  badResponse,
}

class AiException implements Exception {
  final AiErrorKind kind;
  final String message;
  final int? statusCode;

  const AiException(this.kind, this.message, {this.statusCode});

  /// Errors where trying again later can help.
  bool get isTemporary =>
      kind == AiErrorKind.network ||
      kind == AiErrorKind.timeout ||
      kind == AiErrorKind.rateLimit ||
      kind == AiErrorKind.server;

  /// Maps an HTTP status code to an error kind (same for every provider).
  static AiErrorKind kindForStatus(int status) {
    if (status == 401 || status == 403) {
      return AiErrorKind.auth;
    }
    if (status == 429) {
      return AiErrorKind.rateLimit;
    }
    if (status >= 500) {
      return AiErrorKind.server;
    }
    return AiErrorKind.badRequest;
  }

  @override
  String toString() => 'AiException(${kind.name}, $statusCode, $message)';
}

/// Checks the rules every provider has for the message list.
void checkConversation(List<AiMessage> messages) {
  if (messages.isEmpty || !messages.first.isUser) {
    throw const AiException(
      AiErrorKind.badRequest,
      'The conversation must start with a user message.',
    );
  }
}
