import 'env.dart';

/// AI feature configuration — OpenRouter integration.
///
/// API keys are loaded from [Env] (gitignored env.dart).
/// Can be overridden at build time via `--dart-define=OPENROUTER_API_KEY=...`.
abstract final class AiConfig {
  /// OpenRouter API key — provided via `--dart-define=OPENROUTER_API_KEY=...`.
  static String get openRouterApiKey => Env.openRouterApiKey;

  /// OpenRouter API base URL.
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// Default model for voice transcript parsing.
  static const String defaultModel = modelGeminiFlash;

  /// ── Model IDs (OpenRouter format) ──────────────────────────────────────
  static const String modelGeminiFlash = 'google/gemini-2.0-flash-001';
  static const String modelGemma27b = 'google/gemma-3-27b-it:free';
  static const String modelLlama70b = 'meta-llama/llama-3.3-70b-instruct:free';
  static const String modelMistralSmall =
      'mistralai/mistral-small-3.1-24b-instruct:free';
  static const String modelQwen3_4b = 'qwen/qwen3-4b:free';

  /// Timeout for API calls in seconds.
  static const int apiTimeoutSeconds = 15;

  /// Fallback chain for conversational chat (user-initiated, low volume).
  /// Gemini Flash (paid, reliable) → best free models → last resort.
  static const List<String> chatFallbackChain = [
    modelGeminiFlash,
    modelGemma27b,
    modelLlama70b,
    modelMistralSmall,
    modelQwen3_4b,
  ];

  /// Maximum tokens in the LLM response.
  static const int maxResponseTokens = 1024;

  /// Whether a valid OpenRouter API key has been provided.
  static bool get hasApiKey => openRouterApiKey.isNotEmpty;

  // ── Google AI / Gemini Direct API ──────────────────────────────────────

  /// Google AI Studio API key — provided via `--dart-define=GOOGLE_AI_API_KEY=...`.
  static String get googleAiApiKey => Env.googleAiApiKey;

  /// Whether a valid Google AI API key has been provided.
  static bool get hasGoogleAiKey => googleAiApiKey.isNotEmpty;

  /// Gemini REST API base URL.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Model used for audio transcription + transaction parsing.
  static const String geminiAudioModel = 'gemini-2.5-flash';

  /// Timeout for audio upload + processing (longer than text-only).
  /// 60s WAV ≈ 2.5MB base64 — upload + Gemini processing can exceed 30s.
  static const int geminiAudioTimeoutSeconds = 90;
}
