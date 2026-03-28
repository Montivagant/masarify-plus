import 'dart:convert';

import 'chat_action.dart';

/// Result of parsing an AI chat response.
class ParsedChatResponse {
  const ParsedChatResponse({
    required this.textContent,
    this.actions = const [],
  });

  /// Human-readable text with all JSON action blocks stripped.
  final String textContent;

  /// Parsed actions (may be empty if no valid actions found).
  final List<ChatAction> actions;

  /// Convenience: first action, for backwards-compatible single-action usage.
  ChatAction? get action => actions.isNotEmpty ? actions.first : null;
}

/// Extracts structured [ChatAction] JSON blocks from raw AI responses.
///
/// The AI is instructed to embed fenced JSON blocks (```json ... ```) when
/// it wants to suggest actions. This parser finds, extracts, and validates
/// all blocks, returning the remaining text separately.
class ChatResponseParser {
  ChatResponseParser._();

  /// Fenced JSON block: ```json\n{...}\n```
  /// Uses greedy match to capture the outermost `}` before the closing fence,
  /// correctly handling nested objects in the JSON.
  static final _fencedJsonRegex = RegExp(
    r'```json\s*(\{[\s\S]*?\})\s*```',
  );

  /// Bare JSON with an "action" key (fallback for models that omit fences).
  static final _bareJsonRegex = RegExp(
    r'(\{[^{}]*"action"\s*:\s*"[^"]+?"[^{}]*\})',
  );

  /// Parse [rawContent] into text + list of actions.
  static ParsedChatResponse parse(String rawContent) {
    final actions = <ChatAction>[];
    var remaining = rawContent;

    // Layer 1: Extract ALL fenced JSON blocks.
    final fencedMatches = _fencedJsonRegex.allMatches(rawContent).toList();
    if (fencedMatches.isNotEmpty) {
      for (final match in fencedMatches) {
        final jsonStr = match.group(1)!;
        final action = _tryParseAction(jsonStr);
        if (action != null) actions.add(action);
        remaining = remaining.replaceFirst(match.group(0)!, '');
      }

      if (actions.isNotEmpty) {
        return ParsedChatResponse(
          textContent: _cleanText(remaining),
          actions: actions,
        );
      }
    }

    // Layer 2: Bare JSON fallback — extract all matches.
    final bareMatches = _bareJsonRegex.allMatches(rawContent).toList();
    if (bareMatches.isNotEmpty) {
      remaining = rawContent;
      for (final match in bareMatches) {
        final jsonStr = match.group(1)!;
        final action = _tryParseAction(jsonStr);
        if (action != null) actions.add(action);
        remaining = remaining.replaceFirst(match.group(0)!, '');
      }

      if (actions.isNotEmpty) {
        return ParsedChatResponse(
          textContent: _cleanText(remaining),
          actions: actions,
        );
      }
    }

    // Layer 3: Balanced-brace extraction for edge cases where JSON is
    // embedded in markdown or malformed fences.
    final braceResult = _extractBalancedBrace(rawContent);
    if (braceResult != null) {
      final action = _tryParseAction(braceResult);
      if (action != null) {
        final textContent = rawContent.replaceFirst(braceResult, '');
        return ParsedChatResponse(
          textContent: _cleanText(textContent),
          actions: [action],
        );
      }
    }

    return ParsedChatResponse(textContent: _maybeSanitize(rawContent));
  }

  /// Try to parse a JSON string into a [ChatAction].
  static ChatAction? _tryParseAction(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ChatAction.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Clean up text after stripping JSON blocks.
  static String _cleanText(String text) {
    final cleaned = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return _maybeSanitize(cleaned);
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
  /// slipped past the parser.
  static String _sanitizeRemainingJson(String text) {
    var cleaned = text.replaceAll(
      RegExp(r'\{[^{}]*"action"\s*:\s*"[^"]*"[^{}]*\}'),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return cleaned.isEmpty ? text : cleaned;
  }

  /// Strip only the Nth JSON action block from [rawContent], preserving
  /// all other blocks. Used for per-action confirm/cancel in multi-action
  /// messages so that confirming one action doesn't destroy the others.
  static String stripActionAtIndex(String rawContent, int index) {
    // Try fenced blocks first (primary format).
    final fencedMatches = _fencedJsonRegex.allMatches(rawContent).toList();
    if (index < fencedMatches.length) {
      return rawContent
          .replaceFirst(fencedMatches[index].group(0)!, '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    }

    // Fallback: try bare JSON blocks.
    final bareMatches = _bareJsonRegex.allMatches(rawContent).toList();
    if (index < bareMatches.length) {
      return rawContent
          .replaceFirst(bareMatches[index].group(0)!, '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    }

    // Index out of range — return content as-is.
    return rawContent;
  }
}
