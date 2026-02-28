import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/ai_transaction_parser.dart';
import '../../core/services/ai/ai_voice_parser.dart';
import '../../core/services/ai/openrouter_service.dart';
import 'preferences_provider.dart';

/// OpenRouter HTTP client singleton.
final openRouterServiceProvider = Provider<OpenRouterService>(
  (ref) => const OpenRouterService(),
);

/// AI-powered voice transcript parser with rule-based fallback.
final aiVoiceParserProvider = Provider<AiVoiceParser>(
  (ref) => AiVoiceParser(openRouter: ref.watch(openRouterServiceProvider)),
);

/// AI-powered SMS/notification transaction enricher.
final aiTransactionParserProvider = Provider<AiTransactionParser>(
  (ref) =>
      AiTransactionParser(openRouter: ref.watch(openRouterServiceProvider)),
);

/// User's AI model preference ('auto' or a specific model ID).
final aiModelPreferenceProvider = FutureProvider<String>((ref) async {
  // CR-3 fix: capture future before await
  final prefsFuture = ref.watch(preferencesFutureProvider.future);
  final prefs = await prefsFuture;
  return prefs.aiModel;
});
