import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Collapsible search bar with debounce and clear button.
/// Used in Transaction List and Categories screens.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hint,
    this.autofocus = false,
    this.debounceMs = AppDurations.searchDebounceMs,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final bool autofocus;
  final int debounceMs;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    if (widget.debounceMs <= 0) {
      widget.onChanged(value);
      return;
    }
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceMs),
      () => widget.onChanged(value),
    );
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.hint ?? context.l10n.common_search,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        onChanged: _onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.hint ?? context.l10n.common_search_hint,
          prefixIcon: const Icon(AppIcons.search, size: AppSizes.iconSm),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) {
              return value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(AppIcons.close, size: AppSizes.iconSm),
                      tooltip: context.l10n.common_clear,
                      onPressed: _clear,
                    );
            },
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm + AppSizes.xs,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.colors.surfaceContainerHighest,
        ),
      ),
    );
  }
}
