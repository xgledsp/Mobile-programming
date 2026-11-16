// ================================================================
// HODU CHAT - MESSAGE MODEL
// ================================================================
//
// One bubble in the Hodu chat. Messages are immutable: when something
// changes (for example a message failed to send) we create a copy with
// copyWith() instead of editing the old object.
// ================================================================

/// Who wrote the message.
enum ChatRole { user, hodu }

/// Delivery state of a message written by the user.
enum MessageStatus { sent, failed }

/// Where Hodu's answer came from. The chat screen uses this to show a
/// small label, e.g. "offline answer" for knowledge-base replies.
enum ReplySource {
  /// Answer found in the local knowledge base bundled with the app.
  knowledgeBase,

  /// Answer written by the online AI model.
  ai,

  /// The topic guard refused an off-topic question.
  guard,

  /// Hodu could not find an answer (generic fallback text).
  fallback,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  /// Only set for Hodu's messages.
  final ReplySource? source;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.source,
  });

  bool get isUser => role == ChatRole.user;
  bool get isFailed => status == MessageStatus.failed;

  ChatMessage copyWith({String? text, MessageStatus? status}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      createdAt: createdAt,
      status: status ?? this.status,
      source: source,
    );
  }

  @override
  String toString() => 'ChatMessage(${role.name}, "$text", ${status.name})';
}

/// What a responder gives back for one user question.
class HoduReply {
  final String text;
  final ReplySource source;

  const HoduReply(this.text, this.source);
}
