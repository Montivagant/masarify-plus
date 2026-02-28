import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// Number keypad for PIN entry (0-9 + backspace).
/// All buttons meet the 48dp minimum tap target.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.bottomLeft,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  /// Optional widget for the bottom-left cell (e.g. biometric button).
  final Widget? bottomLeft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(context, [1, 2, 3]),
          _row(context, [4, 5, 6]),
          _row(context, [7, 8, 9]),
          _bottomRow(context),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _digitButton(context, d)).toList(),
    );
  }

  Widget _bottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bottom-left: biometric or empty space.
        SizedBox(
          width: 72,
          height: 72,
          child: bottomLeft ?? const SizedBox.shrink(),
        ),
        _digitButton(context, 0),
        // Backspace
        SizedBox(
          width: 72,
          height: 72,
          child: IconButton(
            onPressed: onBackspace,
            icon: const Icon(AppIcons.backspace),
            iconSize: AppSizes.iconMd,
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            style: IconButton.styleFrom(
              minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
            ),
          ),
        ),
      ],
    );
  }

  Widget _digitButton(BuildContext context, int digit) {
    return SizedBox(
      width: AppSizes.pinKeypadButtonSize,
      height: AppSizes.pinKeypadButtonSize,
      child: TextButton(
        onPressed: () => onDigit(digit),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
        child: Text(
          '$digit',
          style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
