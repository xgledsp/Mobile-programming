import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ai_client.dart';
import 'hodu_config.dart';

// ================================================================
// CLAUDE CLIENT - talks to the Anthropic Claude Messages API
// ================================================================
//
// There is no official Anthropic SDK for Dart, so we send the HTTP
// request ourselves:
//
//   POST https://api.anthropic.com/v1/messages
//   headers: x-api-key, anthropic-version, content-type
//   body:    { model, max_tokens, system, messages: [ {role, content} ] }
//
// The answer is a list of "content blocks". We keep only the "text"
// blocks (the model may also return e.g. empty "thinking" blocks).
// ================================================================

class ClaudeClient implements AiClient {
  static const String officialUrl = 'https://api.anthropic.com/v1/messages';
  static const String apiVersion = '2026-10-21';

  /// Beta needed for the server-side "fallbacks" option (see [_buildBody]).
  static const String fallbackBeta = 'server-side-fallback-2026-07-01';

  final HoduConfig config;
  final http.Client _http;
  final Duration timeout;
  final int maxTokens;

  ClaudeClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 60),
    this.maxTokens = 16000,
  }) : _http = httpClient ?? http.Client();

  Uri get endpoint => Uri.parse(config.usesProxy ? config.apiUrl : officialUrl);

  @override
  Future<String> createReply({
    required String system,
    required List<AiMessage> messages,
  }) async {
    checkConversation(messages);

    final http.Response response;
    try {
      response = await _http
          .post(
            endpoint,
            headers: _buildHeaders(),
            body: jsonEncode(_buildBody(system, messages)),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiException(AiErrorKind.timeout, 'The AI took too long to answer.');
    } on SocketException catch (e) {
      throw AiException(AiErrorKind.network, 'No connection: ${e.message}');
    } on http.ClientException catch (e) {
      throw AiException(AiErrorKind.network, 'Connection problem: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw _errorFromResponse(response);
    }
    return _parseText(response);
  }

  @override
  void close() => _http.close();

  // ---------------------------------------------------------- request

  Map<String, String> _buildHeaders() {
    return {
      'content-type': 'application/json',
      'anthropic-version': apiVersion,
      'anthropic-beta': fallbackBeta,
      // With a proxy the key is added on the server, not here.
      if (config.apiKey.isNotEmpty) 'x-api-key': config.apiKey,
    };
  }

  Map<String, dynamic> _buildBody(String system, List<AiMessage> messages) {
    return {
      'model': config.model,
      'max_tokens': maxTokens,
      'system': system,
      'messages': messages.map((AiMessage m) => m.toJson()).toList(),
      // Chat answers do not need deep reasoning: "low" effort is faster
      // and cheaper.
      'output_config': {'effort': 'low'},
      // If the model's safety check declines a normal question by mistake,
      // the API retries on a fallback model automatically.
      'fallbacks': 'default',
    };
  }

  // ---------------------------------------------------------- response

  String _parseText(http.Response response) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const AiException(AiErrorKind.badResponse, 'The AI response was not valid JSON.');
    }

    if (json['stop_reason'] == 'refusal') {
      throw const AiException(AiErrorKind.refusal, 'The AI declined to answer.');
    }

    final Object? content = json['content'];
    if (content is! List) {
      throw const AiException(AiErrorKind.badResponse, 'The AI response had no content.');
    }

    final String text = content
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> block) => block['type'] == 'text')
        .map((Map<String, dynamic> block) => (block['text'] as String?) ?? '')
        .join()
        .trim();

    if (text.isEmpty) {
      throw const AiException(AiErrorKind.badResponse, 'The AI answer was empty.');
    }
    return text;
  }

  AiException _errorFromResponse(http.Response response) {
    final int code = response.statusCode;
    return AiException(
      AiException.kindForStatus(code),
      'Claude error: ${_errorMessage(response)}',
      statusCode: code,
    );
  }

  /// Anthropic errors look like {"type":"error","error":{"type":..,"message":..}}.
  String _errorMessage(http.Response response) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final Object? error = json['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
    } catch (_) {
      // Not JSON - fall through.
    }
    return 'HTTP ${response.statusCode}';
  }
}
