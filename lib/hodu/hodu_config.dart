// ================================================================
// HODU AI SETTINGS
// ================================================================
//
// The API key is NOT written in the code (it would end up on GitHub).
// It is passed when the app is started:
//
//   flutter run --dart-define-from-file=hodu_secrets.json
//
// hodu_secrets.json is in .gitignore. Copy hodu_secrets.example.json,
// rename it and paste the key. Settings:
//
//   HODU_PROVIDER - "gemini" (free, default) or "claude" (paid)
//   HODU_API_KEY  - the key of that provider
//   HODU_MODEL    - optional, which model answers (default per provider)
//   HODU_API_URL  - optional, our own proxy (e.g. a Cloudflare Worker).
//                   Then the key stays on the server, not in the app.
//
// When there is no key and no proxy, the AI is switched off and Hodu
// uses its offline answers.
// ================================================================

enum AiProvider { gemini, claude }

class HoduConfig {
  // Tested on 2026-11-16: gemini-3.5-flash-lite answered in ~1-2 s on the
  // free tier, gemini-3.8-flash often did not answer within 60 s.
  static const Map<AiProvider, String> defaultModels = {
    AiProvider.gemini: 'gemini-3.5-flash-lite',
    AiProvider.claude: 'claude-opus-5-5',
  };

  /// Model tried when the main one is busy. Claude has no backup here
  /// because its API already falls back on the server side.
  static const Map<AiProvider, String> defaultBackupModels = {
    AiProvider.gemini: 'gemini-3.5-flash',
    AiProvider.claude: '',
  };

  final AiProvider provider;
  final String apiKey;

  /// Empty = the provider's official address.
  final String apiUrl;

  /// Empty = the provider's default model.
  final String _model;

  /// Empty = the provider's default backup model. "none" = no backup.
  final String _backupModel;

  const HoduConfig({
    this.provider = AiProvider.gemini,
    this.apiKey = '',
    this.apiUrl = '',
    String model = '',
    String backupModel = '',
  })  : _model = model,
        _backupModel = backupModel;

  /// Reads the values given with --dart-define / --dart-define-from-file.
  factory HoduConfig.fromEnvironment() {
    return HoduConfig.fromValues(
      provider: const String.fromEnvironment('HODU_PROVIDER'),
      apiKey: const String.fromEnvironment('HODU_API_KEY'),
      apiUrl: const String.fromEnvironment('HODU_API_URL'),
      model: const String.fromEnvironment('HODU_MODEL'),
      backupModel: const String.fromEnvironment('HODU_BACKUP_MODEL'),
    );
  }

  /// Builds a config from plain text values (also used by tests).
  factory HoduConfig.fromValues({
    String provider = '',
    String apiKey = '',
    String apiUrl = '',
    String model = '',
    String backupModel = '',
  }) {
    return HoduConfig(
      provider: parseProvider(provider),
      apiKey: apiKey.trim(),
      apiUrl: apiUrl.trim(),
      model: model.trim(),
      backupModel: backupModel.trim(),
    );
  }

  /// The same settings with another model (used to build the backup client).
  HoduConfig withModel(String model) => HoduConfig(
        provider: provider,
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        backupModel: 'none',
      );

  /// Backup model name, or null when there is none.
  String? get backupModel {
    if (_backupModel.toLowerCase() == 'none') {
      return null;
    }
    final String name = _backupModel.isEmpty ? defaultBackupModels[provider]! : _backupModel;
    return (name.isEmpty || name == model) ? null : name;
  }

  /// "claude" -> claude, anything else (or empty) -> gemini.
  static AiProvider parseProvider(String value) {
    return value.trim().toLowerCase() == 'claude' ? AiProvider.claude : AiProvider.gemini;
  }

  String get model => _model.isEmpty ? defaultModels[provider]! : _model;

  /// True when requests go to our own proxy instead of the provider.
  bool get usesProxy => apiUrl.isNotEmpty;

  /// The AI can be used when we have a key, or when a proxy holds the key.
  bool get isAiEnabled => apiKey.isNotEmpty || usesProxy;

  @override
  String toString() => 'HoduConfig(${provider.name}, model: $model, '
      'proxy: ${usesProxy ? apiUrl : 'no'}, key: ${apiKey.isEmpty ? 'none' : 'set'})';
}
