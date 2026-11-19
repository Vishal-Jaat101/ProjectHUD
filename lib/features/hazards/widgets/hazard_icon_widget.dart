/// Road-sign-style hazard icon widget.
///
/// Draws an equilateral warning triangle border around the hazard icon.
/// Colors: Signal Amber for standard warning, Signal Red for active danger.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/hazard_models.dart';

class HazardIconWidget extends StatelessWidget {
  const HazardIconWidget({
    super.key,
    required this.type,
    this.size = 56,
    this.isDanger = false,
  });

  final HazardType type;
  final double size;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final strokeColor = isDanger ? AppColors.danger : AppColors.amber;

    return CustomPaint(
      size: Size(size, size),
      painter: _WarningTrianglePainter(
        color: strokeColor,
        strokeWidth: size > 40 ? 3.0 : 2.0,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.18),
            child: Icon(
              type.icon,
              color: strokeColor,
              size: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningTrianglePainter extends CustomPainter {
  const _WarningTrianglePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.panel
      ..style = PaintingStyle.fill;

    final path = Path();
    final pad = strokeWidth;

    // Equilateral triangle coordinates
    path.moveTo(size.width / 2, pad);
    path.lineTo(size.width - pad, size.height - pad);
    path.lineTo(pad, size.height - pad);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WarningTrianglePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
