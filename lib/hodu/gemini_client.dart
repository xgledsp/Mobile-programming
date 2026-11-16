import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ai_client.dart';
import 'hodu_config.dart';

// ================================================================
// GEMINI CLIENT - talks to the Google Gemini API (free tier)
// ================================================================
//
//   POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
//   header: x-goog-api-key
//   body:   {
//             systemInstruction: { parts: [ {text} ] },
//             contents: [ { role: "user" | "model", parts: [ {text} ] } ],
//             generationConfig: { maxOutputTokens, thinkingConfig }
//           }
//
// Gemini calls the assistant "model" instead of "assistant".
// The answer is in candidates[0].content.parts[].text. Parts marked
// "thought": true are the model's private reasoning and are skipped.
//
// NOTE: on the free tier Google may use the chats to improve its
// products, so users should not type personal data (passport / ARC
// numbers). For the final app use the paid tier or Claude.
// ================================================================

class GeminiClient implements AiClient {
  static const String officialBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final HoduConfig config;
  final http.Client _http;
  final Duration timeout;
  final int maxOutputTokens;

  GeminiClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 25),
    this.maxOutputTokens = 8192,
  }) : _http = httpClient ?? http.Client();

  Uri get endpoint => Uri.parse(config.usesProxy
      ? config.apiUrl
      : '$officialBase/${config.model}:generateContent');

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
            headers: {
              'content-type': 'application/json',
              // With a proxy the key is added on the server, not here.
              if (config.apiKey.isNotEmpty) 'x-goog-api-key': config.apiKey,
            },
            body: jsonEncode(buildBody(system, messages)),
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

  Map<String, dynamic> buildBody(String system, List<AiMessage> messages) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        for (final AiMessage m in messages)
          {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
      ],
      'generationConfig': {
        'maxOutputTokens': maxOutputTokens,
        // Chat answers do not need deep reasoning: low thinking is faster.
        // Only Gemini 3 and newer understand thinkingLevel.
        if (_supportsThinkingLevel) 'thinkingConfig': {'thinkingLevel': 'LOW'},
      },
    };
  }

  bool get _supportsThinkingLevel {
    final RegExpMatch? match = RegExp(r'^gemini-(\d+)').firstMatch(config.model);
    return match != null && int.parse(match.group(1)!) >= 3;
  }

  // ---------------------------------------------------------- response

  static const Set<String> _blockedReasons = {
    'SAFETY',
    'PROHIBITED_CONTENT',
    'BLOCKLIST',
    'SPII',
    'RECITATION',
  };

  String _parseText(http.Response response) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const AiException(AiErrorKind.badResponse, 'The AI response was not valid JSON.');
    }

    // The question itself was blocked by Google's safety filter.
    final Object? feedback = json['promptFeedback'];
    if (feedback is Map<String, dynamic> && feedback['blockReason'] != null) {
      throw AiException(AiErrorKind.refusal, 'Question blocked: ${feedback['blockReason']}');
    }

    final Object? candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiException(AiErrorKind.badResponse, 'The AI response had no answer.');
    }
    final Map<String, dynamic> first = candidates.first as Map<String, dynamic>;

    final Object? content = first['content'];
    final Object? parts = content is Map<String, dynamic> ? content['parts'] : null;
    final String text = (parts is List ? parts : const [])
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> p) => p['thought'] != true && p['text'] is String)
        .map((Map<String, dynamic> p) => p['text'] as String)
        .join()
        .trim();

    if (text.isEmpty) {
      final String reason = (first['finishReason'] as String?) ?? 'UNKNOWN';
      if (_blockedReasons.contains(reason)) {
        throw AiException(AiErrorKind.refusal, 'Answer blocked: $reason');
      }
      throw AiException(AiErrorKind.badResponse, 'The AI answer was empty ($reason).');
    }
    // finishReason MAX_TOKENS still gives useful (cut) text, so we keep it.
    return text;
  }

  AiException _errorFromResponse(http.Response response) {
    final int code = response.statusCode;
    final String? detail = _errorMessage(response);

    // Real Google errors always have a JSON message. Without one, the
    // error came from a busy front-end server (we saw random empty 404s
    // on the free tier), so it is worth trying again.
    if (detail == null) {
      return AiException(AiErrorKind.server, 'Gemini error: empty HTTP $code', statusCode: code);
    }
    // Gemini answers a wrong API key with 400 INVALID_ARGUMENT.
    final AiErrorKind kind = (code == 400 && detail.toLowerCase().contains('api key'))
        ? AiErrorKind.auth
        : AiException.kindForStatus(code);
    return AiException(kind, 'Gemini error: $detail', statusCode: code);
  }

  /// Google errors look like {"error":{"code":..,"message":..,"status":..}}.
  /// Returns null when the body has no such message.
  String? _errorMessage(http.Response response) {
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
    return null;
  }
}
