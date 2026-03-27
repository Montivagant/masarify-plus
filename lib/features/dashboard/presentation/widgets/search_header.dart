import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/home_filter_provider.dart';

/// Inline search bar that replaces the balance header when search is active
/// (D-11).
///
/// Features:
/// - Debounced 300ms text filtering
/// - Result count display
/// - Auto-focus on mount
/// - Cancel button to exit search mode
class SearchHeader extends ConsumerStatefulWidget {
  const SearchHeader({super.key, this.resultCount});

  /// Number of results matching the current query. Shown below the search field.
  final int? resultCount;

  @override
  ConsumerState<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends ConsumerState<SearchHeader> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Restore existing search query if re-entering search mode.
    final current = ref.read(homeFilterProvider);
    if (current.searchQuery.isNotEmpty) {
      _controller.text = current.searchQuery;
    }
    // Auto-focus the search field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      final current = ref.read(homeFilterProvider);
      ref.read(homeFilterProvider.notifier).state =
          current.copyWith(searchQuery: text.trim());
    });
  }

  void _cancelSearch() {
    final current = ref.read(homeFilterProvider);
    ref.read(homeFilterProvider.notifier).state = current.copyWith(
      isSearchActive: false,
      searchQuery: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final filter = ref.watch(homeFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search field ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.l10n.home_search_hint,
                    prefixIcon:
                        const Icon(AppIcons.search, size: AppSizes.iconSm),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              AppIcons.close,
                              size: AppSizes.iconSm,
                            ),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusMd),
                      borderSide: BorderSide(
                        color: cs.outline
                            .withValues(alpha: AppSizes.opacityLight4),
                      ),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest
                        .withValues(alpha: AppSizes.opacityMedium),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              TextButton(
                onPressed: _cancelSearch,
                child: Text(context.l10n.common_cancel),
              ),
            ],
          ),

          // ── Result count ─────────────────────────────────────────────
          if (filter.searchQuery.isNotEmpty && widget.resultCount != null) ...[
            const SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSizes.xs),
              child: Text(
                context.l10n.home_search_results(widget.resultCount!),
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
