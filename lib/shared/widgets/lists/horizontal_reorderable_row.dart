import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';

/// A horizontally scrollable row that supports long-press → drag-to-reorder.
///
/// Tap (< 300ms) is forwarded as a normal tap to the child.
/// Long-press (>= 300ms) enters drag mode: the held item lifts (scale 1.05x),
/// and other items slide aside as the user drags left/right.
/// On drop, [onReorder] is called with the old and new indices.
class HorizontalReorderableRow<T> extends StatefulWidget {
  const HorizontalReorderableRow({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.itemWidth = 110,
    this.spacing = AppSizes.sm,
    this.trailing = const [],
    this.onDoubleTapItem,
  });

  /// The data items to display.
  final List<T> items;

  /// Builds a single item widget. [isDragging] is true for the lifted item.
  final Widget Function(BuildContext context, T item, bool isDragging)
      itemBuilder;

  /// Called when an item is dropped at a new position.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Width of each item (used for position calculations).
  final double itemWidth;

  /// Spacing between items.
  final double spacing;

  /// Trailing widgets appended after the reorderable items.
  final List<Widget> trailing;

  /// Called when an item is double-tapped (e.g. to open an edit sheet).
  final void Function(int index)? onDoubleTapItem;

  @override
  State<HorizontalReorderableRow<T>> createState() =>
      _HorizontalReorderableRowState<T>();
}

class _HorizontalReorderableRowState<T>
    extends State<HorizontalReorderableRow<T>>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  int? _dragIndex;
  double _dragOffset = 0;
  int _targetIndex = 0;

  /// Total width of one item slot (item + spacing).
  double get _slotWidth => widget.itemWidth + widget.spacing;

  void _onLongPressStart(int index, LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragIndex = index;
      _dragOffset = 0;
      _targetIndex = index;
    });
  }

  void _onLongPressMoveUpdate(int index, LongPressMoveUpdateDetails details) {
    if (_dragIndex == null) return;

    setState(() {
      _dragOffset +=
          details.offsetFromOrigin.dx - (_dragOffset != 0 ? _dragOffset : 0);
      _dragOffset = details.offsetFromOrigin.dx;

      // Calculate target index based on drag position.
      final rawTarget = (_dragIndex! + _dragOffset / _slotWidth).round();
      _targetIndex = rawTarget.clamp(0, widget.items.length - 1);
    });

    // Auto-scroll near edges.
    _autoScroll(details.globalPosition.dx);
  }

  void _onLongPressEnd(int index, LongPressEndDetails details) {
    if (_dragIndex == null) return;

    final oldIndex = _dragIndex!;
    final newIndex = _targetIndex;

    setState(() {
      _dragIndex = null;
      _dragOffset = 0;
    });

    if (oldIndex != newIndex) {
      HapticFeedback.lightImpact();
      widget.onReorder(oldIndex, newIndex);
    }
  }

  void _autoScroll(double globalX) {
    if (!_scrollController.hasClients) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localX = renderBox.globalToLocal(Offset(globalX, 0)).dx;
    final width = renderBox.size.width;
    const edgeThreshold = 40.0;
    const scrollStep = 8.0;

    if (localX < edgeThreshold) {
      _scrollController.jumpTo(
        max(0, _scrollController.offset - scrollStep),
      );
    } else if (localX > width - edgeThreshold) {
      _scrollController.jumpTo(
        min(
          _scrollController.position.maxScrollExtent,
          _scrollController.offset + scrollStep,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      // Disable scroll physics while dragging to avoid conflicts.
      physics: _dragIndex != null
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isDragging = _dragIndex == index;

            // Calculate visual offset for non-dragged items to make room.
            double translateX = 0;
            if (_dragIndex != null && !isDragging) {
              if (_dragIndex! < _targetIndex) {
                // Dragging right: items between old and target slide left.
                if (index > _dragIndex! && index <= _targetIndex) {
                  translateX = -_slotWidth;
                }
              } else if (_dragIndex! > _targetIndex) {
                // Dragging left: items between target and old slide right.
                if (index >= _targetIndex && index < _dragIndex!) {
                  translateX = _slotWidth;
                }
              }
            }

            return GestureDetector(
              onDoubleTap: widget.onDoubleTapItem != null
                  ? () => widget.onDoubleTapItem!(index)
                  : null,
              onLongPressStart: (details) => _onLongPressStart(index, details),
              onLongPressMoveUpdate: (details) =>
                  _onLongPressMoveUpdate(index, details),
              onLongPressEnd: (details) => _onLongPressEnd(index, details),
              child: AnimatedContainer(
                duration: isDragging ? Duration.zero : AppDurations.animQuick,
                curve: Curves.easeOutCubic,
                transform: isDragging
                    ? (Matrix4.translationValues(_dragOffset, 0, 0)
                      ..multiply(Matrix4.diagonal3Values(1.05, 1.05, 1)))
                    : Matrix4.translationValues(translateX, 0, 0),
                child: AnimatedOpacity(
                  duration: AppDurations.microPress,
                  opacity: isDragging ? AppSizes.opacityDragging : 1.0,
                  child: widget.itemBuilder(context, item, isDragging),
                ),
              ),
            );
          }),
          ...widget.trailing,
        ],
      ),
    );
  }
}
