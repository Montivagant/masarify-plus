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

    if (match == null || matchedPattern == null) {
      return ParsedChatResponse(textContent: rawContent);
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

      return ParsedChatResponse(textContent: textContent, action: action);
    } catch (_) {
      // Malformed JSON — treat entire response as plain text.
      return ParsedChatResponse(textContent: rawContent);
    }
  }
}
