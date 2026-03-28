import 'dart:convert';

import 'chat_action.dart';

/// Result of parsing an AI chat response.
class ParsedChatResponse {
  const ParsedChatResponse({required this.textContent, this.action});

  /// Human-readable text with the JSON action block stripped.
  final String textContent;

  /// Parsed action, or `null` if no valid action was found.
  final ChatAction? action;
}

/// Extracts structured [ChatAction] JSON blocks from raw AI responses.
///
/// The AI is instructed to embed a fenced JSON block (```json ... ```) when
/// it wants to suggest an action. This parser finds, extracts, and validates
/// that block, returning the remaining text separately.
class ChatResponseParser {
  ChatResponseParser._();

  /// Fenced JSON block: ```json\n{...}\n```
  /// Uses greedy match to capture the outermost `}` before the closing fence,
  /// correctly handling nested objects in the JSON.
  static final _fencedJsonRegex = RegExp(
    r'```json\s*(\{[\s\S]*\})\s*```',
  );

  /// Bare JSON with an "action" key (fallback for models that omit fences).
  static final _bareJsonRegex = RegExp(
    r'(\{[^{}]*"action"\s*:\s*"[^"]+?"[^{}]*\})',
  );

  /// Parse [rawContent] into text + optional action.
  static ParsedChatResponse parse(String rawContent) {
    // Try fenced JSON first.
    var match = _fencedJsonRegex.firstMatch(rawContent);
    RegExp? matchedPattern;
    if (match != null) {
      matchedPattern = _fencedJsonRegex;
    } else {
      // Fallback: bare JSON with "action" key.
      match = _bareJsonRegex.firstMatch(rawContent);
      if (match != null) matchedPattern = _bareJsonRegex;
    }

    // Layer 3: Balanced-brace extraction for edge cases where JSON is
    // embedded in markdown or malformed fences.
    if (match == null || matchedPattern == null) {
      final braceResult = _extractBalancedBrace(rawContent);
      if (braceResult != null) {
        try {
          final decoded = jsonDecode(braceResult) as Map<String, dynamic>;
          final action = ChatAction.fromJson(decoded);
          if (action != null) {
            final textContent = rawContent
                .replaceFirst(braceResult, '')
                .replaceAll(RegExp(r'\n{3,}'), '\n\n')
                .trim();
            return ParsedChatResponse(
              textContent: _maybeSanitize(textContent),
              action: action,
            );
          }
        } catch (_) {
          // Balanced brace found but not valid JSON — fall through.
        }
      }
      return ParsedChatResponse(textContent: _maybeSanitize(rawContent));
    }

    final jsonStr = match.group(1)!;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final action = ChatAction.fromJson(decoded);
      if (action == null) {
        return ParsedChatResponse(textContent: rawContent);
      }

      // Strip the matched JSON block from the text.
      final textContent = rawContent
          .replaceFirst(matchedPattern, '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // collapse excessive newlines
          .trim();

      return ParsedChatResponse(
        textContent: _maybeSanitize(textContent),
        action: action,
      );
    } catch (_) {
      // Malformed JSON — treat entire response as plain text.
      return ParsedChatResponse(textContent: _maybeSanitize(rawContent));
    }
  }

  /// Apply safety-net only if text still contains JSON indicators.
  static String _maybeSanitize(String text) {
    if (text.contains('"action"') || text.contains('"type":')) {
      return _sanitizeRemainingJson(text);
    }
    return text;
  }

  /// Extract the first balanced `{...}` block containing `"action"`.
  /// Handles nested objects that regex alone misses.
  static String? _extractBalancedBrace(String text) {
    final actionIdx = text.indexOf('"action"');
    if (actionIdx == -1) return null;

    // Walk backwards to find the opening brace.
    int start = -1;
    for (int i = actionIdx - 1; i >= 0; i--) {
      if (text[i] == '{') {
        start = i;
        break;
      }
    }
    if (start == -1) return null;

    // Walk forward from start to find the matching closing brace.
    int depth = 0;
    for (int i = start; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
    return null;
  }

  /// Final safety net: strip any remaining action-JSON fragments that
  /// slipped past the 2-layer parser (e.g., split across stream chunks,
  /// nested in unrecognized markdown, or malformed responses).
  static String _sanitizeRemainingJson(String text) {
    // Strip any bare {...} block containing "action" key.
    var cleaned = text.replaceAll(
      RegExp(r'\{[^{}]*"action"\s*:\s*"[^"]*"[^{}]*\}'),
      '',
    );
    // Clean up leftover whitespace.
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return cleaned.isEmpty ? text : cleaned;
  }
}
