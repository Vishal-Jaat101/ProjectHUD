import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/navigation_models.dart';
import '../../../app/theme/app_theme.dart';

/// Draws a large, thick, geometric, road-sign-style turn arrow.
///
/// Renders using [CustomPainter] with the arrow in Signal Amber.
/// Minimum 100×100 dp for the main HUD.
class TurnArrowWidget extends StatelessWidget {
  const TurnArrowWidget({
    super.key,
    required this.direction,
    this.distanceMeters,
    this.size = 120,
    this.color = AppColors.amber,
  });

  final TurnDirection direction;
  final double? distanceMeters;
  final double size;
  final Color color;

  String _formatDistance(double m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(1)} km';
    }
    return '${m.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final arrow = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TurnArrowPainter(
          direction: direction,
          color: color,
        ),
      ),
    );

    if (distanceMeters == null) {
      return arrow;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        arrow,
        const SizedBox(height: 6),
        Text(
          _formatDistance(distanceMeters!),
          style: AppTypography.hudDistance.copyWith(
            color: color,
            fontSize: size * 0.42,
          ),
        ),
      ],
    );
  }
}

class _TurnArrowPainter extends CustomPainter {
  _TurnArrowPainter({
    required this.direction,
    required this.color,
  });

  final TurnDirection direction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    switch (direction) {
      case TurnDirection.straight:
        _drawStraight(canvas, paint, w, h, cx);
      case TurnDirection.slightLeft:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: -30);
      case TurnDirection.left:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: -90);
      case TurnDirection.sharpLeft:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: -135);
      case TurnDirection.slightRight:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: 30);
      case TurnDirection.right:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: 90);
      case TurnDirection.sharpRight:
        _drawTurnArrow(canvas, paint, w, h, cx, angle: 135);
      case TurnDirection.uTurn:
        _drawUTurn(canvas, paint, w, h, cx);
      case TurnDirection.arrive:
        _drawArrive(canvas, paint, w, h, cx);
      case TurnDirection.roundabout:
        _drawRoundabout(canvas, paint, w, h, cx);
    }
  }

  /// Straight arrow — a thick shaft with a chevron head pointing up.
  void _drawStraight(Canvas canvas, Paint paint, double w, double h, double cx) {
    final shaftW = w * 0.22;
    final headW = w * 0.46;
    final headH = h * 0.38;

    final path = Path()
      // Shaft bottom-left → up
      ..moveTo(cx - shaftW / 2, h)
      ..lineTo(cx - shaftW / 2, headH)
      // Head left wing
      ..lineTo(cx - headW, headH)
      // Tip
      ..lineTo(cx, 0)
      // Head right wing
      ..lineTo(cx + headW, headH)
      ..lineTo(cx + shaftW / 2, headH)
      // Shaft bottom-right
      ..lineTo(cx + shaftW / 2, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  /// Turn arrow at a given angle. Rotates around the bottom-centre.
  void _drawTurnArrow(
    Canvas canvas,
    Paint paint,
    double w,
    double h,
    double cx, {
    required double angle,
  }) {
    // We draw a right-angle turn: shaft goes up, then bends, head at the end.
    final isLeft = angle < 0;
    final absAngle = angle.abs();

    if (absAngle <= 45) {
      // Slight turn — angled straight arrow
      canvas.save();
      canvas.translate(cx, h / 2);
      canvas.rotate(angle * math.pi / 180);
      canvas.translate(-cx, -h / 2);
      _drawStraight(canvas, paint, w, h, cx);
      canvas.restore();
      return;
    }

    // 90° or sharp: draw an L-shaped turn arrow
    final shaftW = w * 0.20;
    final headSize = w * 0.36;
    final cornerRadius = w * 0.1;

    final path = Path();

    if (absAngle >= 120) {
      // Sharp turn — hairpin style
      final tipX = isLeft ? w * 0.1 : w * 0.9;
      final tipY = h * 0.72;
      final baseX = isLeft ? w * 0.42 : w * 0.58;

      // Shaft going up from bottom centre
      path.moveTo(cx - shaftW / 2, h);
      path.lineTo(cx - shaftW / 2, h * 0.45);
      path.quadraticBezierTo(
        cx - shaftW / 2,
        h * 0.35 - cornerRadius,
        isLeft ? cx - shaftW / 2 - cornerRadius : cx + cornerRadius,
        h * 0.35,
      );
      // Horizontal to the wing base
      path.lineTo(baseX, h * 0.35);
      // Downward toward tip
      path.lineTo(baseX, tipY - headSize * 0.5);
      // Arrow head wing
      path.lineTo(isLeft ? baseX + headSize * 0.35 : baseX - headSize * 0.35, tipY - headSize * 0.5);
      // Tip
      path.lineTo(tipX, tipY);
      // Other wing
      path.lineTo(isLeft ? baseX + headSize * 0.35 : baseX - headSize * 0.35, tipY + headSize * 0.5);
      path.lineTo(baseX, tipY + headSize * 0.5);
      path.lineTo(baseX, h * 0.35 + shaftW);
      path.lineTo(cx + shaftW / 2, h * 0.35 + shaftW);
      path.quadraticBezierTo(
        cx + shaftW / 2,
        h * 0.45,
        cx + shaftW / 2,
        h * 0.45,
      );
      path.lineTo(cx + shaftW / 2, h);
      path.close();
    } else {
      // 90° turn — classic L-turn
      final tipX = isLeft ? 0.0 : w;
      final tipY = h * 0.30;
      final armEndX = isLeft ? w * 0.22 : w * 0.78;

      // Shaft bottom
      path.moveTo(cx - shaftW / 2, h);
      path.lineTo(cx - shaftW / 2, tipY + shaftW + cornerRadius);
      // Corner
      path.quadraticBezierTo(
        cx - shaftW / 2,
        tipY + shaftW,
        isLeft ? cx - shaftW / 2 - cornerRadius : cx + shaftW / 2 + cornerRadius,
        tipY + shaftW,
      );
      // Horizontal arm to wing base
      path.lineTo(armEndX, tipY + shaftW);
      // Bottom wing of arrowhead
      path.lineTo(armEndX, tipY + headSize / 2);
      // Tip
      path.lineTo(tipX, tipY);
      // Top wing
      path.lineTo(armEndX, tipY - headSize / 2);
      path.lineTo(armEndX, tipY);
      // Horizontal arm back along top edge
      path.lineTo(
        isLeft ? cx - shaftW / 2 - cornerRadius : cx + shaftW / 2 + cornerRadius,
        tipY,
      );
      path.quadraticBezierTo(
        cx + shaftW / 2,
        tipY,
        cx + shaftW / 2,
        tipY + cornerRadius,
      );
      path.lineTo(cx + shaftW / 2, h);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  /// U-turn — a vertical shaft that curves into a 180° and comes back down.
  void _drawUTurn(Canvas canvas, Paint paint, double w, double h, double cx) {
    final shaftW = w * 0.18;
    final arcR = w * 0.22;
    final headSize = w * 0.32;
    final leftX = cx - arcR;
    final rightX = cx + arcR;

    final path = Path()
      // Right shaft going up
      ..moveTo(rightX + shaftW / 2, h)
      ..lineTo(rightX + shaftW / 2, h * 0.35)
      // Arc over the top
      ..arcTo(
        Rect.fromCenter(
          center: Offset(cx, h * 0.35),
          width: arcR * 2 + shaftW,
          height: arcR * 2 + shaftW,
        ),
        0,
        -math.pi,
        false,
      )
      // Left shaft going down — becomes the arrowhead
      ..lineTo(leftX - shaftW / 2, h * 0.55)
      // Left head wing
      ..lineTo(leftX - headSize / 2, h * 0.55)
      // Tip pointing down
      ..lineTo(leftX, h * 0.55 + headSize)
      // Right head wing
      ..lineTo(leftX + headSize / 2, h * 0.55)
      ..lineTo(leftX + shaftW / 2, h * 0.55)
      // Up the inside of the left shaft
      ..lineTo(leftX + shaftW / 2, h * 0.35)
      // Inner arc
      ..arcTo(
        Rect.fromCenter(
          center: Offset(cx, h * 0.35),
          width: arcR * 2 - shaftW,
          height: arcR * 2 - shaftW,
        ),
        -math.pi,
        math.pi,
        false,
      )
      ..lineTo(rightX - shaftW / 2, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  /// Arrival indicator — a filled circle with a dot, like a destination pin.
  void _drawArrive(Canvas canvas, Paint paint, double w, double h, double cx) {
    final cy = h * 0.42;
    final outerR = w * 0.36;
    final innerR = w * 0.14;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), outerR, paint);

    // Inner dark circle (cut-out)
    final bgPaint = Paint()..color = const Color(0xFF0C0E0F);
    canvas.drawCircle(Offset(cx, cy), outerR * 0.6, bgPaint);

    // Centre dot
    canvas.drawCircle(Offset(cx, cy), innerR, paint);
  }

  /// Roundabout — a circle with an arrow curving around it.
  void _drawRoundabout(Canvas canvas, Paint paint, double w, double h, double cx) {
    final cy = h * 0.45;
    final radius = w * 0.28;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;

    // Draw circular arc (270°)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      strokePaint,
    );

    // Arrow head at the top of the arc (exit point)
    final headSize = w * 0.18;
    final headPath = Path()
      ..moveTo(cx, cy - radius - headSize)
      ..lineTo(cx + headSize * 0.8, cy - radius + headSize * 0.3)
      ..lineTo(cx - headSize * 0.3, cy - radius + headSize * 0.1)
      ..close();

    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TurnArrowPainter old) =>
      old.direction != direction || old.color != color;
}
