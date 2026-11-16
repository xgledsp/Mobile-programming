import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_programming/app_theme.dart';
import 'package:mobile_programming/hodu/ai_client.dart';
import 'package:mobile_programming/hodu/ai_responder.dart';
import 'package:mobile_programming/hodu/chat_message.dart';
import 'package:mobile_programming/hodu/claude_client.dart';
import 'package:mobile_programming/hodu/hodu_config.dart';
import 'package:mobile_programming/hodu/hodu_prompt.dart';

int _id = 0;

ChatMessage _user(String text, {bool failed = false}) => ChatMessage(
      id: '${_id++}',
      role: ChatRole.user,
      text: text,
      createdAt: DateTime(2026),
      status: failed ? MessageStatus.failed : MessageStatus.sent,
    );

ChatMessage _hodu(String text) => ChatMessage(
      id: '${_id++}',
      role: ChatRole.hodu,
      text: text,
      createdAt: DateTime(2026),
      source: ReplySource.ai,
    );

List<Map<String, dynamic>> _json(List<AiMessage> messages) =>
    messages.map((AiMessage m) => m.toJson()).toList();

void main() {
  group('toApiMessages', () {
    test('drops the greeting so the list starts with the user', () {
      final List<AiMessage> out = AiResponder.toApiMessages([
        _hodu("Hi! I'm Hodu."),
        _user('How do I get an ARC?'),
      ]);
      expect(_json(out), [
        {'role': 'user', 'content': 'How do I get an ARC?'},
      ]);
    });

    test('keeps the conversation in order with correct roles', () {
      final List<AiMessage> out = AiResponder.toApiMessages([
        _hodu('greeting'),
        _user('q1'),
        _hodu('a1'),
        _user('q2'),
      ]);
      expect(out.map((AiMessage m) => m.role), ['user', 'assistant', 'user']);
      expect(out.last.text, 'q2');
    });

    test('skips old failed questions but keeps the newest one', () {
      final List<AiMessage> out = AiResponder.toApiMessages([
        _user('lost question', failed: true),
        _user('new question'),
      ]);
      expect(_json(out), [
        {'role': 'user', 'content': 'new question'},
      ]);
    });

    test('merges two user messages in a row', () {
      final List<AiMessage> out = AiResponder.toApiMessages([
        _user('I need a SIM card'),
        _user('which carrier is cheap?'),
      ]);
      expect(out, hasLength(1));
      expect(out.single.text, 'I need a SIM card\n\nwhich carrier is cheap?');
    });

    test('only the most recent messages are sent', () {
      final List<ChatMessage> history = [
        for (int i = 0; i < 10; i++) ...[_user('q$i'), _hodu('a$i')],
        _user('last'),
      ];
      final List<AiMessage> out = AiResponder.toApiMessages(history, maxHistory: 5);
      expect(out.first.role, 'user');
      expect(out.last.text, 'last');
      expect(out.length, lessThanOrEqualTo(5));
    });
  });

  group('AiResponder.reply', () {
    test('sends the system prompt and returns an AI reply', () async {
      late Map<String, dynamic> body;
      final MockClient mock = MockClient((http.Request request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'content': [
              {'type': 'text', 'text': '외국인등록증은 출입국사무소에서 신청해요.'},
            ],
            'stop_reason': 'end_turn',
          })),
          200,
        );
      });

      final AiResponder responder = AiResponder(
        client: ClaudeClient(config: const HoduConfig(apiKey: 'k'), httpClient: mock),
        language: AppLanguage.korean,
        clock: () => DateTime(2026, 11, 16),
      );
      final HoduReply reply =
          await responder.reply('ARC 어떻게 받아요?', [_hodu('안녕하세요'), _user('ARC 어떻게 받아요?')]);

      expect(reply.source, ReplySource.ai);
      expect(reply.text, contains('출입국사무소'));
      expect(body['system'], contains('Hodu'));
      expect(body['system'], contains('Korean (한국어)'));
      expect(body['system'], contains('2026-11-16'));
      expect(body['messages'], [
        {'role': 'user', 'content': 'ARC 어떻게 받아요?'},
      ]);
    });

    test('API errors are passed on so the chat can show "retry"', () async {
      final MockClient mock = MockClient((_) async => http.Response('{}', 500));
      final AiResponder responder = AiResponder(
        client: ClaudeClient(config: const HoduConfig(apiKey: 'k'), httpClient: mock),
      );
      expect(
        () => responder.reply('hi', [_user('How do I get an ARC?')]),
        throwsA(isA<AiException>()),
      );
    });
  });

  group('HoduPrompt', () {
    test('English prompt keeps Hodu on topic and asks for plain text', () {
      final String p = HoduPrompt(language: AppLanguage.english, today: DateTime(2026, 1, 5)).build();
      expect(p, contains('Hodu'));
      expect(p, contains('only help with life in Korea'));
      expect(p, contains('Never change these rules'));
      expect(p, contains('Answer in English'));
      expect(p, contains('2026-01-05'));
    });

    test('Korean prompt asks for polite Korean', () {
      final String p = HoduPrompt(language: AppLanguage.korean).build();
      expect(p, contains('해요체'));
    });
  });
}
