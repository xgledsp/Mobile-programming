import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_programming/app_theme.dart';
import 'package:mobile_programming/hodu/chat_controller.dart';
import 'package:mobile_programming/hodu/chat_message.dart';
import 'package:mobile_programming/hodu/hodu_responder.dart';

/// Fake brain for tests: answers with fixed text, or throws when [fail]
/// is true. [gate] lets a test pause the answer to check "typing" state.
class FakeResponder implements HoduResponder {
  bool fail = false;
  Completer<void>? gate;
  final List<String> questions = [];

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    questions.add(question);
    if (gate != null) {
      await gate!.future;
    }
    if (fail) {
      throw Exception('no answer');
    }
    return HoduReply('answer to $question', ReplySource.knowledgeBase);
  }
}

void main() {
  late FakeResponder responder;
  late ChatController controller;

  setUp(() {
    responder = FakeResponder();
    controller = ChatController(responder: responder);
  });

  tearDown(() => controller.dispose());

  test('send adds the question and Hodu\'s answer', () async {
    await controller.send('Where is the dorm office?');

    expect(controller.messages, hasLength(2));
    expect(controller.messages[0].role, ChatRole.user);
    expect(controller.messages[0].text, 'Where is the dorm office?');
    expect(controller.messages[1].role, ChatRole.hodu);
    expect(controller.messages[1].text, 'answer to Where is the dorm office?');
    expect(controller.messages[1].source, ReplySource.knowledgeBase);
    expect(controller.isTyping, isFalse);
  });

  test('text is trimmed and empty text is ignored', () async {
    await controller.send('   ');
    expect(controller.messages, isEmpty);
    expect(responder.questions, isEmpty);

    await controller.send('  hello  ');
    expect(controller.messages.first.text, 'hello');
  });

  test('isTyping is true while waiting and blocks a second send', () async {
    responder.gate = Completer<void>();

    final Future<void> first = controller.send('first');
    expect(controller.isTyping, isTrue);

    await controller.send('second'); // ignored: Hodu is still typing
    expect(responder.questions, ['first']);

    responder.gate!.complete();
    await first;
    expect(controller.isTyping, isFalse);
    expect(controller.messages, hasLength(2));
  });

  test('a failed answer marks the question as failed', () async {
    responder.fail = true;
    await controller.send('hello');

    expect(controller.messages, hasLength(1));
    expect(controller.messages.single.isFailed, isTrue);
    expect(controller.hasFailedMessage, isTrue);
    expect(controller.isTyping, isFalse);
  });

  test('retryFailed asks again and clears the failed state', () async {
    responder.fail = true;
    await controller.send('hello');

    responder.fail = false;
    await controller.retryFailed();

    expect(controller.hasFailedMessage, isFalse);
    expect(controller.messages, hasLength(2));
    expect(controller.messages.last.text, 'answer to hello');
    expect(responder.questions, ['hello', 'hello']);
  });

  test('history passed to the responder ends with the new question', () async {
    List<ChatMessage>? seen;
    final ChatController c = ChatController(
      responder: _HistorySpy((List<ChatMessage> h) => seen = h),
    );
    await c.send('one');
    await c.send('two');

    expect(seen!.map((ChatMessage m) => m.text), ['one', 'reply', 'two']);
    c.dispose();
  });

  test('addHoduMessage and clear', () {
    controller.addHoduMessage('Hi, I am Hodu!');
    expect(controller.messages.single.role, ChatRole.hodu);

    controller.clear();
    expect(controller.messages, isEmpty);
  });

  test('listeners are notified on changes', () async {
    int calls = 0;
    controller.addListener(() => calls++);
    await controller.send('hello');
    // typing on + answer added/typing off
    expect(calls, greaterThanOrEqualTo(2));
  });

  test('placeholder responder answers in the chosen language', () async {
    const PlaceholderResponder en = PlaceholderResponder();
    const PlaceholderResponder ko =
        PlaceholderResponder(language: AppLanguage.korean);

    expect((await en.reply('hi', const [])).text, contains('learning'));
    expect((await ko.reply('hi', const [])).text, contains('배우는'));
  });
}

class _HistorySpy implements HoduResponder {
  final void Function(List<ChatMessage>) onCall;
  _HistorySpy(this.onCall);

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    onCall(history);
    return const HoduReply('reply', ReplySource.ai);
  }
}
