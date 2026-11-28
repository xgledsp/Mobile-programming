import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'chat_message.dart';
import 'hodu_responder.dart';

// ================================================================
// HODU CHAT - CONTROLLER (the logic of the chat screen)
// ================================================================
//
// Holds the list of messages and the "Hodu is typing..." state.
// The screen listens to this controller (ChangeNotifier) and rebuilds
// every time notifyListeners() is called.
//
//   user taps send
//      -> send(text)
//      -> user message is added, isTyping = true
//      -> responder.reply(...) is awaited
//      -> Hodu's message is added, isTyping = false
//
// If the responder throws, the user's message is marked as failed and
// the user can tap "retry".
// ================================================================

class ChatController extends ChangeNotifier {
  final HoduResponder _responder;
  final DateTime Function() _clock;

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _disposed = false;
  int _idCounter = 0;

  ChatController({
    required HoduResponder responder,
    List<ChatMessage> initialMessages = const [],
    DateTime Function()? clock,
  })  : _responder = responder,
        _clock = clock ?? DateTime.now {
    _messages.addAll(initialMessages);
  }

  /// All messages, oldest first. Read-only for the UI.
  UnmodifiableListView<ChatMessage> get messages =>
      UnmodifiableListView<ChatMessage>(_messages);

  /// True while Hodu is preparing an answer.
  bool get isTyping => _isTyping;

  /// True when the last user message could not be answered.
  bool get hasFailedMessage => _messages.any((ChatMessage m) => m.isFailed);

  /// Sends [rawText] to Hodu. Empty text is ignored, and a new message
  /// cannot be sent while Hodu is still answering the previous one.
  Future<void> send(String rawText) async {
    final String text = rawText.trim();
    if (text.isEmpty || _isTyping) {
      return;
    }

    final ChatMessage question = _newMessage(ChatRole.user, text);
    _messages.add(question);
    await _askResponder(question);
  }

  /// Tries again to answer the failed message.
  Future<void> retryFailed() async {
    if (_isTyping) {
      return;
    }
    final int index = _messages.lastIndexWhere((ChatMessage m) => m.isFailed);
    if (index == -1) {
      return;
    }
    final ChatMessage question =
        _messages[index].copyWith(status: MessageStatus.sent);
    _messages[index] = question;
    await _askResponder(question);
  }

  /// Adds a message from Hodu without asking the responder
  /// (used for the greeting when the chat opens).
  void addHoduMessage(String text, {ReplySource source = ReplySource.fallback}) {
    _messages.add(_newMessage(ChatRole.hodu, text, source: source));
    _notify();
  }

  /// Removes every message.
  void clear() {
    if (_isTyping) {
      return;
    }
    _messages.clear();
    _notify();
  }

  Future<void> _askResponder(ChatMessage question) async {
    _isTyping = true;
    _notify();

    try {
      final HoduReply reply = await _responder.reply(
        question.text,
        List<ChatMessage>.unmodifiable(_messages),
      );
      if (_disposed) {
        return;
      }
      _messages.add(_newMessage(ChatRole.hodu, reply.text, source: reply.source));
    } catch (error) {
      if (_disposed) {
        return;
      }
      debugPrint('Hodu could not answer: $error');
      final int index = _messages.indexWhere((ChatMessage m) => m.id == question.id);
      if (index != -1) {
        _messages[index] = question.copyWith(status: MessageStatus.failed);
      }
    } finally {
      _isTyping = false;
      _notify();
    }
  }

  ChatMessage _newMessage(ChatRole role, String text, {ReplySource? source}) {
    _idCounter++;
    final DateTime now = _clock();
    return ChatMessage(
      id: '${now.microsecondsSinceEpoch}-$_idCounter',
      role: role,
      text: text,
      createdAt: now,
      source: source,
    );
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
