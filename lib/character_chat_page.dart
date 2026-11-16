import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'hodu/ai_responder.dart';
import 'hodu/chat_controller.dart';
import 'hodu/ai_client.dart';
import 'hodu/ai_client_factory.dart';
import 'hodu/hodu_config.dart';
import 'hodu/chat_message.dart';
import 'hodu/guarded_responder.dart';
import 'hodu/hodu_responder.dart';

// ================================================================
// HODU CHAT PAGE
// ================================================================
//
// The screen only shows what the ChatController holds:
//
//   ChatController  --notifyListeners()-->  ListenableBuilder  --> bubbles
//
// The "brain" (HoduResponder) can be passed in from outside. If nothing
// is passed, the PlaceholderResponder is used.
// ================================================================

class CharacterChatPage extends StatefulWidget {
  final AppLanguage language;

  /// Optional brain for Hodu (used by tests and later steps).
  final HoduResponder? responder;

  const CharacterChatPage({
    super.key,
    this.language = AppLanguage.english,
    this.responder,
  });

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage> {
  late final ChatController _chat;
  AiClient? _client;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool get _isKorean => widget.language == AppLanguage.korean;

  @override
  void initState() {
    super.initState();
    _chat = ChatController(
      // The guard always runs first, whatever brain is behind it.
      responder: GuardedResponder(
        inner: widget.responder ?? _defaultBrain(),
        language: widget.language,
      ),
    );
    _chat.addHoduMessage(_greeting());
    // Every time the chat changes, scroll down to the newest message.
    _chat.addListener(_scrollToBottom);
    // Rebuild the send button when the text field becomes empty / not empty.
    _input.addListener(() => setState(() {}));
  }

  /// Uses the online AI when a key (or proxy) is configured,
  /// otherwise the offline placeholder.
  HoduResponder _defaultBrain() {
    final HoduConfig config = HoduConfig.fromEnvironment();
    if (!config.isAiEnabled) {
      return PlaceholderResponder(language: widget.language);
    }
    _client = createAiClient(config);
    return AiResponder(client: _client!, language: widget.language);
  }

  @override
  void dispose() {
    _client?.close();
    _chat.removeListener(_scrollToBottom);
    _chat.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _greeting() => _isKorean
      ? '안녕하세요! 저는 호두예요. 비자, 기숙사, 은행, 학교 생활 등 한국 생활에 대해 '
          '무엇이든 물어보세요.'
      : "Hi! I'm Hodu (호두). Ask me anything about life in Korea — visas, "
          'dorms, banks, school notices and more.';

  bool get _canSend => _input.text.trim().isNotEmpty && !_chat.isTyping;

  void _send() {
    if (!_canSend) {
      return;
    }
    final String text = _input.text;
    _input.clear();
    _chat.send(text);
  }

  void _scrollToBottom() {
    // Wait until the new bubble is drawn, then scroll to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: ResponsiveLayout(
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _chat,
                builder: (BuildContext context, Widget? _) => _buildMessageList(),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: darkText),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: primaryBlue,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hodu (호두)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
              ),
              ListenableBuilder(
                listenable: _chat,
                builder: (BuildContext context, Widget? _) => Text(
                  _chat.isTyping
                      ? (_isKorean ? '입력 중...' : 'Typing...')
                      : (_isKorean ? '온라인' : 'Online'),
                  style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final List<ChatMessage> messages = _chat.messages;
    // +1 for the date chip at the top, +1 for the typing bubble at the end.
    final int count = messages.length + 1 + (_chat.isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(20),
      itemCount: count,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _buildDateChip(_isKorean ? '오늘' : 'Today');
        }
        final int messageIndex = index - 1;
        if (messageIndex >= messages.length) {
          return const _TypingBubble();
        }
        return _buildChatBubble(messages[messageIndex]);
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderGray)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isKorean ? '호두에게 메시지 보내기' : 'Message Hodu... 메시지 보내기',
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: bgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ListenableBuilder(
              listenable: _chat,
              builder: (BuildContext context, Widget? _) => IconButton.filled(
                tooltip: _isKorean ? '보내기' : 'Send',
                onPressed: _canSend ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: borderGray,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderGray),
        ),
        child: Text(date, style: const TextStyle(fontSize: 12, color: lightText)),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: message.isFailed ? 4 : 16),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isUser ? primaryBlue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : darkText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (message.isFailed) _buildRetryRow(),
        ],
      ),
    );
  }

  /// Shown under a user message that Hodu could not answer.
  Widget _buildRetryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: _chat.isTyping ? null : _chat.retryFailed,
        icon: Icon(Icons.refresh, size: 16, color: Colors.red.shade700),
        label: Text(
          _isKorean ? '전송 실패 · 다시 시도' : 'Not answered · Tap to retry',
          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
        ),
      ),
    );
  }
}

/// "Hodu is typing" bubble with three blinking dots.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (BuildContext context, Widget? _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (int i) {
                // Each dot lights up a bit after the previous one.
                final double phase = (_animation.value * 3 - i) % 3;
                final bool lit = phase < 1;
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: lit ? primaryBlue : borderGray,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
