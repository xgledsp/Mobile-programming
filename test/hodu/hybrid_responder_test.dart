import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_programming/hodu/ai_client.dart';
import 'package:mobile_programming/hodu/ai_responder.dart';
import 'package:mobile_programming/hodu/chat_message.dart';
import 'package:mobile_programming/hodu/gemini_client.dart';
import 'package:mobile_programming/hodu/hodu_config.dart';
import 'package:mobile_programming/hodu/hodu_prompt.dart';
import 'package:mobile_programming/hodu/hodu_responder.dart';
import 'package:mobile_programming/hodu/hybrid_responder.dart';
import 'package:mobile_programming/hodu/knowledge/knowledge_base.dart';
import 'package:mobile_programming/hodu/knowledge_responder.dart';
import 'package:mobile_programming/hodu/resilient_ai_client.dart';
import 'package:mobile_programming/app_theme.dart';

/// Fake online brain: answers, or throws the error it is given.
class _FakeAi implements HoduResponder {
  Object? error;
  int calls = 0;

  @override
  Future<HoduReply> reply(String question, List<ChatMessage> history) async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return const HoduReply('AI answer', ReplySource.ai);
  }
}

const AiException _noInternet = AiException(AiErrorKind.network, 'no internet');
const AiException _busy = AiException(AiErrorKind.server, 'busy', statusCode: 503);

void main() {
  group('HybridResponder', () {
    late _FakeAi ai;
    late DateTime now;
    late HybridResponder hybrid;

    setUp(() {
      ai = _FakeAi();
      now = DateTime(2026, 11, 16, 12);
      hybrid = HybridResponder(
        online: ai,
        offline: const KnowledgeResponder(),
        clock: () => now,
      );
    });

    tearDown(() => hybrid.dispose());

    Future<HoduReply> ask([String q = 'How do I get my ARC?']) => hybrid.reply(q, const []);

    test('uses the AI when it works', () async {
      final HoduReply reply = await ask();
      expect(reply.source, ReplySource.ai);
      expect(hybrid.isOnline.value, isTrue);
    });

    test('no internet -> knowledge base answer and offline mode', () async {
      ai.error = _noInternet;
      final HoduReply reply = await ask();

      expect(reply.source, ReplySource.knowledgeBase);
      expect(reply.text, contains('90 days'));
      expect(hybrid.isOnline.value, isFalse);
      expect(hybrid.lastError, _noInternet);
    });

    test('while offline the AI is skipped (instant answers)', () async {
      ai.error = _noInternet;
      await ask();
      await ask();
      await ask();
      expect(ai.calls, 1);
      expect(hybrid.isPaused, isTrue);
    });

    test('after the pause the AI is tried again', () async {
      ai.error = _noInternet;
      await ask();

      now = now.add(const Duration(seconds: 31));
      ai.error = null;
      final HoduReply reply = await ask();

      expect(reply.source, ReplySource.ai);
      expect(ai.calls, 2);
      expect(hybrid.isOnline.value, isTrue);
    });

    test('a busy AI gives an offline answer but does not switch to offline mode', () async {
      ai.error = _busy;
      final HoduReply reply = await ask();

      expect(reply.source, ReplySource.knowledgeBase);
      expect(hybrid.isOnline.value, isTrue);
      expect(hybrid.isPaused, isFalse);
    });

    test('a timeout also switches to offline mode', () async {
      ai.error = const AiException(AiErrorKind.timeout, 'slow');
      await ask();
      expect(hybrid.isOnline.value, isFalse);
    });

    test('unknown questions while offline get the honest fallback', () async {
      ai.error = _noInternet;
      final HoduReply reply = await ask('Where can I buy a cheap mattress?');
      expect(reply.source, ReplySource.fallback);
      expect(reply.text, contains("don't have an offline answer"));
    });

    test('resetOfflinePause goes back online immediately', () async {
      ai.error = _noInternet;
      await ask();
      hybrid.resetOfflinePause();
      expect(hybrid.isPaused, isFalse);
      expect(hybrid.isOnline.value, isTrue);
    });

    test('a bug (not an AiException) is not hidden', () async {
      ai.error = StateError('bug');
      await expectLater(ask(), throwsStateError);
    });
  });

  group('grounding: the AI gets verified facts', () {
    late Map<String, dynamic> sentBody;

    AiResponder responder() {
      final MockClient mock = MockClient((http.Request request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'},
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          })),
          200,
        );
      });
      return AiResponder(
        client: GeminiClient(config: const HoduConfig(apiKey: 'k'), httpClient: mock),
        knowledgeBase: const KnowledgeBase(),
      );
    }

    String systemText() =>
        ((sentBody['systemInstruction'] as Map<String, dynamic>)['parts'] as List<dynamic>)
            .map((dynamic p) => (p as Map<String, dynamic>)['text'])
            .join();

    test('matching facts are added to the system prompt', () async {
      final AiResponder r = responder();
      await r.reply('How do I get my ARC?', [
        ChatMessage(
          id: '1',
          role: ChatRole.user,
          text: 'How do I get my ARC?',
          createdAt: DateTime(2026),
        ),
      ]);
      final String system = systemText();
      expect(system, contains('Verified facts'));
      expect(system, contains('<facts>'));
      expect(system, contains('[arc_apply]'));
      expect(system, contains('Official source: HiKorea'));
    });

    test('no facts section when nothing matches', () async {
      final AiResponder r = responder();
      await r.reply('Where can I buy a cheap mattress?', [
        ChatMessage(
          id: '1',
          role: ChatRole.user,
          text: 'Where can I buy a cheap mattress?',
          createdAt: DateTime(2026),
        ),
      ]);
      expect(systemText(), isNot(contains('<facts>')));
    });

    test('factsFor is limited to maxFacts', () {
      final AiResponder r = AiResponder(
        client: GeminiClient(config: const HoduConfig(apiKey: 'k')),
        knowledgeBase: const KnowledgeBase(),
        maxFacts: 1,
      );
      expect(r.factsFor('bank account and sim card and arc'), hasLength(1));
    });

    test('HoduPrompt without facts has no facts section', () {
      expect(HoduPrompt(language: AppLanguage.english).build(), isNot(contains('<facts>')));
    });
  });

  test('no-internet errors are not retried (so offline answers come fast)', () async {
    int calls = 0;
    final ResilientAiClient client = ResilientAiClient(
      clients: [_ThrowingClient(() => calls++)],
      sleep: (_) async {},
    );
    await expectLater(
      client.createReply(system: 's', messages: const [AiMessage.user('hi')]),
      throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', AiErrorKind.network)),
    );
    expect(calls, 1);
  });
}

class _ThrowingClient implements AiClient {
  final void Function() onCall;
  _ThrowingClient(this.onCall);

  @override
  Future<String> createReply({required String system, required List<AiMessage> messages}) async {
    onCall();
    throw _noInternet;
  }

  @override
  void close() {}
}
