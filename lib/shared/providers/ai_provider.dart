import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/ai_transaction_parser.dart';
import '../../core/services/ai/gemini_audio_service.dart';
import '../../core/services/ai/openrouter_service.dart';

/// OpenRouter HTTP client singleton.
final openRouterServiceProvider = Provider<OpenRouterService>(
  (ref) => const OpenRouterService(),
);

/// Gemini audio transcription + transaction parsing.
final geminiAudioServiceProvider = Provider<GeminiAudioService>(
  (ref) => const GeminiAudioService(),
);

/// AI-powered SMS/notification transaction enricher.
final aiTransactionParserProvider = Provider<AiTransactionParser>(
  (ref) =>
      AiTransactionParser(openRouter: ref.read(openRouterServiceProvider)),
);
