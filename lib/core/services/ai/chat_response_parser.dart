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
  /// Handles one level of nested objects (e.g. {"action":"x","data":{"k":"v"}}).
  static final _bareJsonRegex = RegExp(
    r'(\{\s*"action"\s*:\s*"[^"]+?"(?:[^{}]|\{[^{}]*\})*\})',
  );

  /// Parse [rawContent] into text + optional action.
  static ParsedChatResponse parse(String rawContent) {
    // Try fenced JSON first.
    var match = _fencedJsonRegex.firstMatch(rawContent);
    String? jsonStr;
    String? matchedText; // the full matched text to strip

    if (match != null) {
      jsonStr = match.group(1)!;
      matchedText = match.group(0)!;
    } else {
      // Fallback: bare JSON regex.
      match = _bareJsonRegex.firstMatch(rawContent);
      if (match != null) {
        jsonStr = match.group(1)!;
        matchedText = match.group(0)!;
      } else {
        // Last resort: balanced brace extraction.
        jsonStr = _extractBalancedJson(rawContent);
        matchedText = jsonStr;
      }
    }

    if (jsonStr == null) {
      return ParsedChatResponse(textContent: rawContent);
    }

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final action = ChatAction.fromJson(decoded);
      if (action == null) {
        // JSON found but unrecognized action — strip JSON, return text only.
        return ParsedChatResponse(
          textContent: _stripBlock(rawContent, matchedText!),
        );
      }
      return ParsedChatResponse(
        textContent: _stripBlock(rawContent, matchedText!),
        action: action,
      );
    } catch (_) {
      // Malformed JSON — strip the JSON-like block so it doesn't show raw.
      if (matchedText != null) {
        return ParsedChatResponse(
          textContent: _stripBlock(rawContent, matchedText),
        );
      }
      return ParsedChatResponse(textContent: rawContent);
    }
  }

  /// Strip a matched block from the source and clean up whitespace.
  static String _stripBlock(String source, String block) {
    return source
        .replaceFirst(block, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Fallback: extract balanced JSON containing "action" by counting braces.
  static String? _extractBalancedJson(String content) {
    final actionIdx = content.indexOf('"action"');
    if (actionIdx < 0) return null;

    // Scan backward to find the opening brace.
    var start = -1;
    for (var i = actionIdx - 1; i >= 0; i--) {
      if (content[i] == '{') {
        start = i;
        break;
      }
    }
    if (start < 0) return null;

    // Count braces forward to find balanced end.
    var depth = 0;
    for (var i = start; i < content.length; i++) {
      if (content[i] == '{') depth++;
      if (content[i] == '}') depth--;
      if (depth == 0) return content.substring(start, i + 1);
    }
    return null; // unbalanced
  }
}
