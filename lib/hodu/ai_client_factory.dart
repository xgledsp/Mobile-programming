import 'package:http/http.dart' as http;

import 'ai_client.dart';
import 'claude_client.dart';
import 'gemini_client.dart';
import 'hodu_config.dart';
import 'resilient_ai_client.dart';

/// Creates the AI client for the provider chosen in [config]
/// (HODU_PROVIDER in hodu_secrets.json), wrapped with automatic retries
/// and the backup model.
AiClient createAiClient(HoduConfig config, {http.Client? httpClient}) {
  final String? backup = config.backupModel;
  return ResilientAiClient(
    clients: [
      createSingleClient(config, httpClient: httpClient),
      if (backup != null) createSingleClient(config.withModel(backup), httpClient: httpClient),
    ],
  );
}

/// One client for one model, without retries.
AiClient createSingleClient(HoduConfig config, {http.Client? httpClient}) {
  switch (config.provider) {
    case AiProvider.gemini:
      return GeminiClient(config: config, httpClient: httpClient);
    case AiProvider.claude:
      return ClaudeClient(config: config, httpClient: httpClient);
  }
}
