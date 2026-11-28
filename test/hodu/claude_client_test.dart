import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_programming/hodu/ai_client.dart';
import 'package:mobile_programming/hodu/claude_client.dart';
import 'package:mobile_programming/hodu/hodu_config.dart';

const HoduConfig _config = HoduConfig(provider: AiProvider.claude, apiKey: 'test-key');

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _okBody(List<Map<String, dynamic>> content,
        {String stopReason = 'end_turn'}) =>
    {
      'id': 'msg_1',
      'type': 'message',
      'role': 'assistant',
      'model': 'claude-opus-5-5',
      'content': content,
      'stop_reason': stopReason,
      'usage': {'input_tokens': 10, 'output_tokens': 5},
    };

Future<String> _ask(http.Client mock, {HoduConfig config = _config}) {
  return ClaudeClient(config: config, httpClient: mock).createReply(
    system: 'You are Hodu.',
    messages: const [AiMessage.user('How do I get an ARC?')],
  );
}

void main() {
  group('request', () {
    late http.Request sent;

    Future<void> send({HoduConfig config = _config}) async {
      final MockClient mock = MockClient((http.Request request) async {
        sent = request;
        return _json(_okBody([
          {'type': 'text', 'text': 'Go to the immigration office.'},
        ]));
      });
      await _ask(mock, config: config);
    }

    test('goes to the Messages API with the right headers', () async {
      await send();
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent.headers['x-api-key'], 'test-key');
      expect(sent.headers['anthropic-version'], ClaudeClient.apiVersion);
      expect(sent.headers['content-type'], startsWith('application/json'));
    });

    test('body has model, system prompt and messages', () async {
      await send();
      final Map<String, dynamic> body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-opus-5-5');
      expect(body['system'], 'You are Hodu.');
      expect(body['max_tokens'], greaterThan(0));
      expect(body['messages'], [
        {'role': 'user', 'content': 'How do I get an ARC?'},
      ]);
      expect(body['output_config'], {'effort': 'low'});
      expect(body.containsKey('thinking'), isFalse);
    });

    test('model can be changed in the config', () async {
      await send(config: const HoduConfig(provider: AiProvider.claude, apiKey: 'k', model: 'claude-haiku-5-5'));
      expect((jsonDecode(sent.body) as Map<String, dynamic>)['model'], 'claude-haiku-5-5');
    });

    test('with a proxy URL no API key is sent from the app', () async {
      await send(config: const HoduConfig(provider: AiProvider.claude, apiUrl: 'https://hodu-proxy.example.workers.dev'));
      expect(sent.url.host, 'hodu-proxy.example.workers.dev');
      expect(sent.headers.containsKey('x-api-key'), isFalse);
    });

    test('conversation must start with the user', () async {
      final ClaudeClient client =
          ClaudeClient(config: _config, httpClient: MockClient((_) async => _json({})));
      expect(
        () => client.createReply(system: 's', messages: const [AiMessage.assistant('hi')]),
        throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', AiErrorKind.badRequest)),
      );
    });
  });

  group('response', () {
    test('returns the text, ignoring thinking and other blocks', () async {
      final MockClient mock = MockClient((_) async => _json(_okBody([
            {'type': 'thinking', 'thinking': '', 'signature': 'abc'},
            {'type': 'text', 'text': 'Bring your passport '},
            {'type': 'text', 'text': 'and a photo.'},
          ])));
      expect(await _ask(mock), 'Bring your passport and a photo.');
    });

    test('Korean text is decoded correctly', () async {
      final MockClient mock = MockClient((_) async => _json(_okBody([
            {'type': 'text', 'text': '출입국사무소에 가세요.'},
          ])));
      expect(await _ask(mock), '출입국사무소에 가세요.');
    });

    test('refusal stop reason becomes a refusal error', () async {
      final MockClient mock =
          MockClient((_) async => _json(_okBody([], stopReason: 'refusal')));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.refusal));
    });

    test('empty answer is an error', () async {
      final MockClient mock = MockClient((_) async => _json(_okBody([
            {'type': 'text', 'text': '   '},
          ])));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badResponse));
    });

    test('broken JSON is an error', () async {
      final MockClient mock = MockClient((_) async => http.Response('<html>', 200));
      await expectLater(_ask(mock), _throwsKind(AiErrorKind.badResponse));
    });
  });

  group('errors', () {
    Map<String, dynamic> apiError(String type, String message) => {
          'type': 'error',
          'error': {'type': type, 'message': message},
        };

    final Map<int, AiErrorKind> statusCases = {
      400: AiErrorKind.badRequest,
      401: AiErrorKind.auth,
      403: AiErrorKind.auth,
      429: AiErrorKind.rateLimit,
      500: AiErrorKind.server,
      529: AiErrorKind.server,
    };

    statusCases.forEach((int status, AiErrorKind kind) {
      test('HTTP $status -> ${kind.name}', () async {
        final MockClient mock =
            MockClient((_) async => _json(apiError('some_error', 'details here'), status));
        await expectLater(
          _ask(mock),
          throwsA(isA<AiException>()
              .having((AiException e) => e.kind, 'kind', kind)
              .having((AiException e) => e.statusCode, 'status', status)
              .having((AiException e) => e.message, 'message', contains('details here'))),
        );
      });
    });

    test('no internet -> network error (temporary)', () async {
      final MockClient mock =
          MockClient((_) async => throw const SocketException('Failed host lookup'));
      await expectLater(
        _ask(mock),
        throwsA(isA<AiException>()
            .having((AiException e) => e.kind, 'kind', AiErrorKind.network)
            .having((AiException e) => e.isTemporary, 'temporary', isTrue)),
      );
    });

    test('slow server -> timeout error', () async {
      final MockClient mock = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _json(_okBody([]));
      });
      final ClaudeClient client = ClaudeClient(
        config: _config,
        httpClient: mock,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        client.createReply(system: 's', messages: const [AiMessage.user('hi')]),
        _throwsKind(AiErrorKind.timeout),
      );
    });

    test('auth errors are not temporary', () {
      expect(const AiException(AiErrorKind.auth, 'x').isTemporary, isFalse);
    });
  });

  group('HoduConfig', () {
    test('AI is off without a key', () {
      expect(const HoduConfig().isAiEnabled, isFalse);
      expect(const HoduConfig(apiKey: 'k').isAiEnabled, isTrue);
    });
    test('AI is on with a proxy URL even without a key', () {
      expect(const HoduConfig(apiUrl: 'https://proxy.example').isAiEnabled, isTrue);
    });
    test('toString never prints the key', () {
      expect(const HoduConfig(apiKey: 'secret-123').toString(), isNot(contains('secret-123')));
    });
  });
}

Matcher _throwsKind(AiErrorKind kind) =>
    throwsA(isA<AiException>().having((AiException e) => e.kind, 'kind', kind));
