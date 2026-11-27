import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_programming/hodu/ai_client.dart';
import 'package:mobile_programming/hodu/ai_client_factory.dart';
import 'package:mobile_programming/hodu/gemini_client.dart';
import 'package:mobile_programming/hodu/hodu_config.dart';
import 'package:mobile_programming/hodu/resilient_ai_client.dart';

/// Fake client that fails with the given errors first, then answers.
class _ScriptedClient implements AiClient {
  final String name;
  final List<AiException> failures;
  int calls = 0;
  bool closed = false;

  _ScriptedClient(this.name, [this.failures = const []]);

  @override
  Future<String> createReply({
    required String system,
    required List<AiMessage> messages,
  }) async {
    calls++;
    if (calls <= failures.length) {
      throw failures[calls - 1];
    }
    return 'answer from $name';
  }

  @override
  void close() => closed = true;
}

const AiException _busy = AiException(AiErrorKind.server, 'overloaded', statusCode: 503);
const AiException _slow = AiException(AiErrorKind.timeout, 'too slow');
const AiException _badKey = AiException(AiErrorKind.auth, 'bad key', statusCode: 400);

void main() {
  final List<Duration> waits = [];
  Future<void> fakeSleep(Duration d) async => waits.add(d);

  setUp(waits.clear);

  Future<String> ask(ResilientAiClient client) => client.createReply(
        system: 's',
        messages: const [AiMessage.user('How do I get an ARC?')],
      );

  test('first answer is returned without waiting', () async {
    final _ScriptedClient main = _ScriptedClient('main');
    final ResilientAiClient c = ResilientAiClient(clients: [main], sleep: fakeSleep);
    expect(await ask(c), 'answer from main');
    expect(main.calls, 1);
    expect(waits, isEmpty);
  });

  test('busy main model -> backup model answers', () async {
    final _ScriptedClient main = _ScriptedClient('main', [_busy]);
    final _ScriptedClient backup = _ScriptedClient('backup');
    final ResilientAiClient c = ResilientAiClient(clients: [main, backup], sleep: fakeSleep);

    expect(await ask(c), 'answer from backup');
    expect(main.calls, 1);
    expect(backup.calls, 1);
    expect(waits, [const Duration(milliseconds: 800)]);
  });

  test('third attempt goes back to the main model with a longer wait', () async {
    final _ScriptedClient main = _ScriptedClient('main', [_busy]);
    final _ScriptedClient backup = _ScriptedClient('backup', [_slow]);
    final ResilientAiClient c = ResilientAiClient(clients: [main, backup], sleep: fakeSleep);

    expect(await ask(c), 'answer from main');
    expect(main.calls, 2);
    expect(waits, [const Duration(milliseconds: 800), const Duration(seconds: 2)]);
  });

  test('gives up after maxAttempts and throws the last error', () async {
    final _ScriptedClient main = _ScriptedClient('main', [_busy, _busy, _busy]);
    final ResilientAiClient c = ResilientAiClient(clients: [main], sleep: fakeSleep);

    await expectLater(
      ask(c),
      throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', AiErrorKind.server)),
    );
    expect(main.calls, 3);
  });

  test('a wrong key is not retried', () async {
    final _ScriptedClient main = _ScriptedClient('main', [_badKey]);
    final _ScriptedClient backup = _ScriptedClient('backup');
    final ResilientAiClient c = ResilientAiClient(clients: [main, backup], sleep: fakeSleep);

    await expectLater(
      ask(c),
      throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', AiErrorKind.auth)),
    );
    expect(backup.calls, 0);
    expect(waits, isEmpty);
  });

  test('close closes every client', () {
    final _ScriptedClient a = _ScriptedClient('a');
    final _ScriptedClient b = _ScriptedClient('b');
    ResilientAiClient(clients: [a, b]).close();
    expect(a.closed && b.closed, isTrue);
  });

  group('empty Gemini errors are temporary', () {
    Future<AiException> errorFor(http.Response response) async {
      final GeminiClient client = GeminiClient(
        config: const HoduConfig(apiKey: 'k'),
        httpClient: MockClient((_) async => response),
      );
      try {
        await client.createReply(system: 's', messages: const [AiMessage.user('hi')]);
      } on AiException catch (e) {
        return e;
      }
      fail('expected an AiException');
    }

    test('empty 404 -> server (retried)', () async {
      final AiException e = await errorFor(http.Response('', 404));
      expect(e.kind, AiErrorKind.server);
      expect(e.isTemporary, isTrue);
    });

    test('real "model not found" 404 with JSON -> bad request (not retried)', () async {
      final AiException e = await errorFor(http.Response.bytes(
        utf8.encode(jsonEncode({
          'error': {'code': 404, 'message': 'models/x is not found', 'status': 'NOT_FOUND'},
        })),
        404,
      ));
      expect(e.kind, AiErrorKind.badRequest);
      expect(e.isTemporary, isFalse);
    });
  });

  group('backup model settings', () {
    test('gemini uses flash-lite with flash as backup by default', () {
      const HoduConfig c = HoduConfig(apiKey: 'k');
      expect(c.model, 'gemini-3.5-flash-lite');
      expect(c.backupModel, 'gemini-3.5-flash');
    });

    test('backup can be changed or switched off', () {
      expect(HoduConfig.fromValues(backupModel: 'gemini-3.6-flash').backupModel,
          'gemini-3.6-flash');
      expect(HoduConfig.fromValues(backupModel: 'none').backupModel, isNull);
    });

    test('no backup when it equals the main model', () {
      expect(
        HoduConfig.fromValues(model: 'gemini-3.5-flash', backupModel: 'gemini-3.5-flash')
            .backupModel,
        isNull,
      );
    });

    test('claude has no client-side backup', () {
      expect(const HoduConfig(provider: AiProvider.claude).backupModel, isNull);
    });

    test('factory really falls back to the backup model on a busy main model', () async {
      final List<String> urls = [];
      final MockClient mock = MockClient((http.Request request) async {
        urls.add(request.url.path);
        if (request.url.path.contains('flash-lite')) {
          return http.Response('', 503);
        }
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'backup answer'},
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          })),
          200,
        );
      });

      final AiClient client = createAiClient(const HoduConfig(apiKey: 'k'), httpClient: mock);
      final String answer =
          await client.createReply(system: 's', messages: const [AiMessage.user('hi')]);

      expect(answer, 'backup answer');
      expect(urls, [
        '/v1beta/models/gemini-3.5-flash-lite:generateContent',
        '/v1beta/models/gemini-3.5-flash:generateContent',
      ]);
    });
  });
}
