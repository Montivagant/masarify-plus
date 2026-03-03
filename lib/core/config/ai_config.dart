import 'env.dart';

/// AI feature configuration — OpenRouter integration.
///
/// API keys are loaded from [Env] (gitignored env.dart).
/// Can be overridden at build time via `--dart-define=OPENROUTER_API_KEY=...`.
abstract final class AiConfig {
  /// Master gate — enables AI-powered voice parsing.
  static const bool isEnabled = true;

  /// Build-time overrides (optional).
  static const String _envOverride =
      String.fromEnvironment('OPENROUTER_API_KEY');

  /// OpenRouter API key — env.dart primary, --dart-define override.
  static String get openRouterApiKey =>
      _envOverride.isNotEmpty ? _envOverride : Env.openRouterApiKey;

  /// OpenRouter API base URL.
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// Default model for voice transcript parsing.
  static const String defaultModel = modelGemma27b;

  /// ── Model IDs (OpenRouter format) ──────────────────────────────────────
  static const String modelGemma27b = 'google/gemma-3-27b-it:free';
  static const String modelQwen3_4b = 'qwen/qwen3-4b:free';

  /// Priority-ordered fallback chain for Auto mode (free models only).
  static const List<String> fallbackChain = [
    modelGemma27b,
    modelQwen3_4b,
  ];

  /// Timeout for API calls in seconds.
  static const int apiTimeoutSeconds = 15;

  /// Maximum tokens in the LLM response.
  static const int maxResponseTokens = 1024;

  /// Whether a valid OpenRouter API key has been provided.
  static bool get hasApiKey => openRouterApiKey.isNotEmpty;
}
