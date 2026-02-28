import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';

/// Native-keyboard amount input for ALL monetary fields.
/// Uses a custom formatter for natural integer entry (typing "150" → displays "150.00").
/// Stores amount internally and emits piastres (INTEGER) on change — Rule #4.
class AmountInput extends StatefulWidget {
  AmountInput({
    super.key,
    required this.onAmountChanged,
    this.initialPiastres = 0,
    String? currencySymbol,
    this.autofocus = true,
    this.compact = false,
    this.textColor,
  }) : currencySymbol = currencySymbol ?? MoneyFormatter.currencySymbol();

  final ValueChanged<int> onAmountChanged;
  final int initialPiastres;
  final String currencySymbol;
  final bool autofocus;

  /// If true, uses a smaller text style suitable for inline card contexts.
  final bool compact;

  /// Optional override for text color.
  final Color? textColor;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPiastres > 0
          ? _fromPiastres(widget.initialPiastres)
          : '',
    );
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AmountInput old) {
    super.didUpdateWidget(old);
    if (old.initialPiastres != widget.initialPiastres &&
        _parsePiastres() == 0 &&
        widget.initialPiastres > 0) {
      _controller.text = _fromPiastres(widget.initialPiastres);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _fromPiastres(int piastres) {
    if (piastres == 0) return '';
    final whole = piastres ~/ 100;
    final cents = piastres % 100;
    return cents == 0 ? '$whole' : '$whole.${cents.toString().padLeft(2, '0')}';
  }

  bool _hasInvalidInput = false;

  int _parsePiastres() {
    final text = _controller.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text) ?? 0;
    return (parsed * 100).round();
  }

  void _onTextChanged() {
    final piastres = _parsePiastres();
    // I14 fix: detect invalid paste (non-empty text that parses as 0)
    final rawText = _controller.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final invalid = rawText.isNotEmpty && piastres == 0;
    if (invalid != _hasInvalidInput) {
      setState(() => _hasInvalidInput = invalid);
    }
    widget.onAmountChanged(piastres);
  }

  @override
  Widget build(BuildContext context) {
    final piastres = _parsePiastres();
    final isZero = piastres == 0;
    final cs = context.colors;
    final effectiveColor = widget.textColor;

    final textStyle = widget.compact
        ? context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor ?? (isZero ? cs.outline : cs.onSurface),
            )
        : context.textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor ?? (isZero ? cs.outline : cs.onSurface),
            );

    final hintStyle = widget.compact
        ? context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.outline.withValues(alpha: AppSizes.opacityMedium),
            )
        : context.textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.outline.withValues(alpha: AppSizes.opacityMedium),
            );

    return Semantics(
      label: context.l10n.common_amount,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          _MoneyInputFormatter(),
        ],
        style: textStyle,
        textAlign: widget.compact ? TextAlign.start : TextAlign.center,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: widget.compact
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSizes.lg),
                  child: Text(
                    widget.currencySymbol,
                    style: hintStyle,
                  ),
                ),
          prefixIconConstraints: widget.compact
              ? null
              : const BoxConstraints(),
          hintText: '0.00',
          hintStyle: hintStyle,
          // I14 fix: show error when pasted text is invalid
          errorText: _hasInvalidInput ? context.l10n.common_invalid_amount : null,
          contentPadding: widget.compact
              ? const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                )
              : const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
          isDense: widget.compact,
        ),
      ),
    );
  }
}

/// Custom input formatter for natural money entry.
/// Allows digits and one decimal point. Max 2 decimal digits.
/// Adds thousand separators on the fly.
class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) return newValue;

    // Remove any non-digit, non-dot characters
    final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one decimal point
    final parts = cleaned.split('.');
    if (parts.length > 2) return oldValue;

    // Limit decimal to 2 digits
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    if (decimalPart != null && decimalPart.length > 2) return oldValue;

    // Limit integer part to reasonable length (prevent overflow)
    if (integerPart.length > 10) return oldValue;

    // Format with thousand separators
    final formattedInteger = _addThousandSeparators(integerPart);
    final formatted = decimalPart != null
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;

    // Compute new cursor position
    final newCursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  static String _addThousandSeparators(String digits) {
    if (digits.isEmpty) return digits;
    final buffer = StringBuffer();
    final length = digits.length;
    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
