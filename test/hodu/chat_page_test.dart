import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_programming/app_theme.dart';
import 'package:mobile_programming/character_chat_page.dart';
import 'package:mobile_programming/hodu/chat_message.dart';
import 'package:mobile_programming/hodu/hodu_responder.dart';

class _EchoResponder implements HoduResponder {
  bool fail = false;

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    if (fail) {
      throw Exception('offline');
    }
    return HoduReply('Echo: $question', ReplySource.knowledgeBase);
  }
}

final Finder _sendButton = find.widgetWithIcon(IconButton, Icons.arrow_upward);

Future<void> _openChat(
  WidgetTester tester,
  HoduResponder responder, {
  AppLanguage language = AppLanguage.english,
}) {
  return tester.pumpWidget(
    MaterialApp(home: CharacterChatPage(language: language, responder: responder)),
  );
}

void main() {
  sourceLabelTests();

  testWidgets('shows the greeting when the chat opens', (WidgetTester tester) async {
    await _openChat(tester, _EchoResponder());
    expect(find.textContaining("I'm Hodu"), findsOneWidget);
  });

  testWidgets('greeting is in Korean in Korean mode', (WidgetTester tester) async {
    await _openChat(tester, _EchoResponder(), language: AppLanguage.korean);
    expect(find.textContaining('저는 호두예요'), findsOneWidget);
  });

  testWidgets('typing and sending shows question and answer', (WidgetTester tester) async {
    await _openChat(tester, _EchoResponder());

    await tester.enterText(find.byType(TextField), 'How do I get an ARC?');
    await tester.pump(); // redraw so the send button becomes enabled
    await tester.tap(_sendButton);
    await tester.pumpAndSettle();

    expect(find.text('How do I get an ARC?'), findsOneWidget);
    expect(find.text('Echo: How do I get an ARC?'), findsOneWidget);
    // The text field is cleared after sending.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('send button is disabled while the field is empty', (WidgetTester tester) async {
    await _openChat(tester, _EchoResponder());

    expect(tester.widget<IconButton>(_sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    expect(tester.widget<IconButton>(_sendButton).onPressed, isNotNull);
  });

  testWidgets('failed message shows retry, retry gets the answer', (WidgetTester tester) async {
    final _EchoResponder responder = _EchoResponder()..fail = true;
    await _openChat(tester, responder);

    await tester.enterText(find.byType(TextField), 'Where is the dorm office?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap to retry'), findsOneWidget);

    responder.fail = false;
    await tester.tap(find.textContaining('Tap to retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap to retry'), findsNothing);
    expect(find.text('Echo: Where is the dorm office?'), findsOneWidget);
  });
}

class _SourceResponder implements HoduResponder {
  final ReplySource source;
  _SourceResponder(this.source);

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async =>
      HoduReply('answer', source);
}

void sourceLabelTests() {
  Future<void> askOnce(WidgetTester tester, ReplySource source, AppLanguage language) async {
    await _openChat(tester, _SourceResponder(source), language: language);
    await tester.enterText(find.byType(TextField), 'How do I open a bank account?');
    await tester.pump();
    await tester.tap(_sendButton);
    await tester.pumpAndSettle();
  }

  testWidgets('knowledge base answers show the "Hodu\'s guide" label', (WidgetTester tester) async {
    await askOnce(tester, ReplySource.knowledgeBase, AppLanguage.english);
    expect(find.textContaining("Hodu's guide"), findsOneWidget);
  });

  testWidgets('AI answers show the "double-check" label', (WidgetTester tester) async {
    await askOnce(tester, ReplySource.ai, AppLanguage.english);
    expect(find.textContaining('AI answer'), findsOneWidget);
  });

  testWidgets('labels are Korean in Korean mode', (WidgetTester tester) async {
    await askOnce(tester, ReplySource.ai, AppLanguage.korean);
    expect(find.textContaining('AI 답변'), findsOneWidget);
  });

  testWidgets('the greeting has no label', (WidgetTester tester) async {
    await _openChat(tester, _SourceResponder(ReplySource.ai));
    expect(find.textContaining('AI answer'), findsNothing);
    expect(find.textContaining("Hodu's guide"), findsNothing);
  });
}
