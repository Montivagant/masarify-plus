import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// One radial bloom painted on the global page gradient.
///
/// Positions are alignment fractions (`Alignment(-1..1, -1..1)`) so they
/// scale with screen size. The X axis is intentionally NOT mirrored for
/// RTL — bloom layout stays the same in Arabic.
@immutable
class BloomSpec {
  const BloomSpec({
    required this.alignment,
    required this.radiusFraction,
    required this.color,
  });

  /// Where the bloom's centre sits, as alignment fractions.
  final Alignment alignment;

  /// Bloom radius as a fraction of the shortest screen side.
  final double radiusFraction;

  /// Colour at the centre. Falls off to transparent at the radius edge.
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloomSpec &&
          alignment == other.alignment &&
          radiusFraction == other.radiusFraction &&
          color == other.color;

  @override
  int get hashCode => Object.hash(alignment, radiusFraction, color);
}

/// Paints a list of [BloomSpec]s on the canvas as soft radial gradients.
///
/// Wrapped in a `RepaintBoundary` by [GradientBackground] — does not
/// repaint on dashboard rebuilds.
class BloomPainter extends CustomPainter {
  const BloomPainter(this.blooms);

  final List<BloomSpec> blooms;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    for (final bloom in blooms) {
      final centre = Offset(
        size.width * (bloom.alignment.x + 1) / 2,
        size.height * (bloom.alignment.y + 1) / 2,
      );
      final radius = shortest * bloom.radiusFraction;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [bloom.color, bloom.color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: radius));
      canvas.drawCircle(centre, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BloomPainter old) =>
      !listEquals(old.blooms, blooms);
}
