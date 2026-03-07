import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// Clips a rounded rectangle with a smooth semicircular notch at center-top
/// for the FAB to nestle into.
class NotchedNavClipper extends CustomClipper<Path> {
  const NotchedNavClipper({
    this.notchRadius = AppSizes.navNotchRadius,
    this.notchMargin = AppSizes.navNotchMargin,
    this.borderRadius = AppSizes.borderRadiusLg,
  });

  final double notchRadius;
  final double notchMargin;
  final double borderRadius;

  @override
  Path getClip(Size size) => _buildNotchedPath(size);

  @override
  bool shouldReclip(NotchedNavClipper oldClipper) =>
      notchRadius != oldClipper.notchRadius ||
      notchMargin != oldClipper.notchMargin ||
      borderRadius != oldClipper.borderRadius;

  /// Builds the path: rounded rect with a semicircular notch carved from
  /// the top edge center.
  Path _buildNotchedPath(Size size) {
    final r = notchRadius + notchMargin;
    final centerX = size.width / 2;
    final notchLeft = centerX - r;
    final notchRight = centerX + r;

    final path = Path();

    // Start from top-left corner (after border radius arc).
    path.moveTo(borderRadius, 0);

    // Top edge → notch left approach.
    path.lineTo(notchLeft, 0);

    // Smooth curve into the notch using a quadratic bezier for each side.
    // Left side of notch: gentle entry from flat edge into the semicircle.
    path.quadraticBezierTo(
      centerX - r * 0.6, 0, // control point: slightly right, same Y
      centerX - r * math.cos(math.pi / 4),
      r * (1 - math.sin(math.pi / 4)), // point on semicircle at 45°
    );

    // Semicircular arc for the notch bowl.
    path.arcToPoint(
      Offset(
        centerX + r * math.cos(math.pi / 4),
        r * (1 - math.sin(math.pi / 4)),
      ),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // Right side of notch: smooth exit from semicircle back to flat edge.
    path.quadraticBezierTo(
      centerX + r * 0.6, 0, // control point: slightly left, same Y
      notchRight, 0,
    );

    // Top edge → top-right corner.
    path.lineTo(size.width - borderRadius, 0);

    // Top-right corner arc.
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Right edge.
    path.lineTo(size.width, size.height - borderRadius);

    // Bottom-right corner arc.
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );

    // Bottom edge.
    path.lineTo(borderRadius, size.height);

    // Bottom-left corner arc.
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Left edge.
    path.lineTo(0, borderRadius);

    // Top-left corner arc.
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    path.close();
    return path;
  }
}

/// Strokes the same notched path to draw the glass border overlay.
class NotchedNavBorderPainter extends CustomPainter {
  const NotchedNavBorderPainter({
    required this.borderColor,
    this.borderWidth = AppSizes.glassBorderWidth,
    this.notchRadius = AppSizes.navNotchRadius,
    this.notchMargin = AppSizes.navNotchMargin,
    this.borderRadius = AppSizes.borderRadiusLg,
  });

  final Color borderColor;
  final double borderWidth;
  final double notchRadius;
  final double notchMargin;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = NotchedNavClipper(
      notchRadius: notchRadius,
      notchMargin: notchMargin,
      borderRadius: borderRadius,
    );
    final path = clipper._buildNotchedPath(size);

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NotchedNavBorderPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth ||
      notchRadius != oldDelegate.notchRadius ||
      notchMargin != oldDelegate.notchMargin ||
      borderRadius != oldDelegate.borderRadius;
}
