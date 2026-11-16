import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_programming/hodu/ai_client.dart';
import 'package:mobile_programming/hodu/ai_client_factory.dart';
import 'package:mobile_programming/hodu/claude_client.dart';
import 'package:mobile_programming/hodu/gemini_client.dart';
import 'package:mobile_programming/hodu/hodu_config.dart';

const HoduConfig _config = HoduConfig(apiKey: 'gemini-key');

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _answer(List<Map<String, dynamic>> parts, {String finish = 'STOP'}) => {
      'candidates': [
        {
          'content': {'role': 'model', 'parts': parts},
          'finishReason': finish,
          'index': 0,
        },
      ],
      'usageMetadata': {'promptTokenCount': 10, 'candidatesTokenCount': 5},
    };

Future<String> _ask(http.Client mock,
    {HoduConfig config = _config, List<AiMessage>? messages}) {
  return GeminiClient(config: config, httpClient: mock).createReply(
    system: 'You are Hodu.',
    messages: messages ?? const [AiMessage.user('How do I get an ARC?')],
  );
}

Matcher _throwsKind(AiErrorKind kind) =>
    throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', kind));

void main() {
  group('request', () {
    late http.Request sent;

    Future<void> send({HoduConfig config = _config, List<AiMessage>? messages}) async {
      final MockClient mock = MockClient((http.Request request) async {
        sent = request;
        return _json(_answer([
          {'text': 'ok'},
        ]));
      });
      await _ask(mock, config: config, messages: messages);
    }

    test('goes to generateContent of the default model with the key header', () async {
      await send();
      expect(sent.method, 'POST');
      expect(sent.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent');
      expect(sent.headers['x-goog-api-key'], 'gemini-key');
      // The key must never be put in the URL (URLs end up in logs).
      expect(sent.url.toString(), isNot(contains('gemini-key')));
    });

    test('system prompt goes to systemInstruction', () async {
      await send();
      final Map<String, dynamic> body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['systemInstruction'], {
        'parts': [
          {'text': 'You are Hodu.'},
        ],
      });
    });

    test('assistant turns are sent with role "model"', () async {
      await send(messages: const [
        AiMessage.user('q1'),
        AiMessage.assistant('a1'),
        AiMessage.user('q2'),
      ]);
      final List<dynamic> contents =
          (jsonDecode(sent.body) as Map<String, dynamic>)['contents'] as List<dynamic>;
      expect(contents.map((dynamic c) => (c as Map<String, dynamic>)['role']),
          ['user', 'model', 'user']);
      expect(contents.last, {
        'role': 'user',
        'parts': [
          {'text': 'q2'},
        ],
      });
    });

    test('Gemini 3+ models get a low thinking level', () async {
      await send();
      final Map<String, dynamic> config = (jsonDecode(sent.body)
          as Map<String, dynamic>)['generationConfig'] as Map<String, dynamic>;
      expect(config['thinkingConfig'], {'thinkingLevel': 'LOW'});
      expect(config['maxOutputTokens'], greaterThan(0));
    });

    test('older models do not get thinkingLevel (they would reject it)', () async {
      await send(config: const HoduConfig(apiKey: 'k', model: 'gemini-2.5-flash-lite'));
      expect(sent.url.path, endsWith('/gemini-2.5-flash-lite:generateContent'));
      final Map<String, dynamic> config = (jsonDecode(sent.body)
          as Map<String, dynamic>)['generationConfig'] as Map<String, dynamic>;
      expect(config.containsKey('thinkingConfig'), isFalse);
    });

    test('with a proxy URL no key is sent from the app', () async {
      await send(config: const HoduConfig(apiUrl: 'https://hodu-proxy.example.workers.dev/gemini'));
      expect(sent.url.host, 'hodu-proxy.example.workers.dev');
      expect(sent.headers.containsKey('x-goog-api-key'), isFalse);
    });
  });

  group('response', () {
    test('joins the text parts and skips thought parts', () async {
      final MockClient mock = MockClient((_) async => _json(_answer([
            {'text': 'thinking about it...', 'thought': true},
            {'text': 'Go to the '},
            {'text': 'immigration office.'},
          ])));
      expect(await _ask(mock), 'Go to the immigration office.');
    });

    test('Korean text is decoded correctly', () async {
      final MockClient mock = MockClient((_) async => _json(_answer([
            {'text': '출입국사무소에 방문하세요.'},
          ])));
      expect(await _ask(mock), '출입국사무소에 방문하세요.');
    });

    test('a cut answer (MAX_TOKENS) still returns its text', () async {
      final MockClient mock = MockClient((_) async => _json(_answer([
            {'text': 'Bring your passport and'},
          ], finish: 'MAX_TOKENS')));
      expect(await _ask(mock), 'Bring your passport and');
    });

    test('blocked question -> refusal', () async {
      final MockClient mock = MockClient((_) async => _json({
            'promptFeedback': {'blockReason': 'SAFETY'},
          }));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.refusal));
    });

    test('empty answer stopped by SAFETY -> refusal', () async {
      final MockClient mock = MockClient((_) async => _json(_answer([], finish: 'SAFETY')));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.refusal));
    });

    test('no candidates -> bad response', () async {
      final MockClient mock = MockClient((_) async => _json({'candidates': []}));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badResponse));
    });

    test('broken JSON -> bad response', () async {
      final MockClient mock = MockClient((_) async => http.Response('oops', 200));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badResponse));
    });
  });

  group('errors', () {
    Map<String, dynamic> googleError(int code, String message, String status) => {
          'error': {'code': code, 'message': message, 'status': status},
        };

    test('wrong API key (400 "API key not valid") -> auth', () async {
      final MockClient mock = MockClient((_) async => _json(
          googleError(400, 'API key not valid. Please pass a valid API key.', 'INVALID_ARGUMENT'),
          400));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.auth));
    });

    test('other 400 -> bad request', () async {
      final MockClient mock = MockClient(
          (_) async => _json(googleError(400, 'Invalid JSON payload', 'INVALID_ARGUMENT'), 400));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badRequest));
    });

    test('free tier limit (429) -> rate limit, temporary', () async {
      final MockClient mock = MockClient((_) async =>
          _json(googleError(429, 'Resource has been exhausted', 'RESOURCE_EXHAUSTED'), 429));
      await expectLater(
        _ask(mock),
        throwsA(isA<AiException>()
            .having((AiException e) => e.kind, 'kind', AiErrorKind.rateLimit)
            .having((AiException e) => e.isTemporary, 'temporary', isTrue)
            .having((AiException e) => e.message, 'message', contains('exhausted'))),
      );
    });

    test('wrong model name (404) -> bad request', () async {
      final MockClient mock = MockClient(
          (_) async => _json(googleError(404, 'models/x is not found', 'NOT_FOUND'), 404));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badRequest));
    });

    test('503 -> server', () async {
      final MockClient mock = MockClient(
          (_) async => _json(googleError(503, 'The model is overloaded', 'UNAVAILABLE'), 503));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.server));
    });

    test('no internet -> network', () async {
      final MockClient mock =
          MockClient((_) async => throw const SocketException('Failed host lookup'));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.network));
    });

    test('conversation must start with the user', () async {
      await expectLater(
        _ask(MockClient((_) async => _json({})),
            messages: const [AiMessage.assistant('hello')]),
        _throwsKind(AiErrorKind.badRequest),
      );
    });
  });

  group('provider settings', () {
    test('gemini is the default provider', () {
      expect(HoduConfig.fromValues().provider, AiProvider.gemini);
      expect(HoduConfig.fromValues(provider: 'GEMINI').provider, AiProvider.gemini);
      expect(HoduConfig.fromValues(provider: ' Claude ').provider, AiProvider.claude);
    });

    test('each provider has its own default model', () {
      expect(const HoduConfig().model, 'gemini-3.5-flash-lite');
      expect(const HoduConfig(provider: AiProvider.claude).model, 'claude-opus-5-5');
      expect(HoduConfig.fromValues(model: ' gemini-3.5-flash-lite ').model,
          'gemini-3.5-flash-lite');
    });

    test('createSingleClient picks the client for the provider', () {
      expect(createSingleClient(const HoduConfig(apiKey: 'k')), isA<GeminiClient>());
      expect(createSingleClient(const HoduConfig(provider: AiProvider.claude, apiKey: 'k')),
          isA<ClaudeClient>());
    });
  });
}
