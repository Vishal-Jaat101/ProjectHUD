import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/hazard_models.dart';

/// Animated hazard alert banner shown at the bottom of the HUD.
///
/// Red (#FF3B30) background, white text. Shows hazard type icon inside a
/// triangle + distance string (e.g. "Pothole 300 m ahead").
///
/// Animation: single opacity pulse from 0→1 over 300 ms, then stays solid.
/// Does NOT flash continuously — per NHTSA safety rules.
class HazardBannerWidget extends StatefulWidget {
  const HazardBannerWidget({
    super.key,
    required this.hazard,
    required this.distanceMeters,
  });

  final HazardReport hazard;
  final double distanceMeters;

  @override
  State<HazardBannerWidget> createState() => _HazardBannerWidgetState();
}

class _HazardBannerWidgetState extends State<HazardBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    // Single pulse: 0 → 1, then hold.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.danger,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hazard icon inside a triangle shape
              _HazardTriangleIcon(icon: widget.hazard.type.icon),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  '${widget.hazard.type.label} ${_formatDistance(widget.distanceMeters)} ahead',
                  style: const TextStyle(
                    fontFamily: 'BarlowSemiCondensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a hazard icon inside a road-sign-style triangle.
class _HazardTriangleIcon extends StatelessWidget {
  const _HazardTriangleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _TrianglePainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(icon, color: AppColors.danger, size: 20),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Inner dark triangle for contrast
    final innerPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.fill;

    final inset = 4.0;
    final innerPath = Path()
      ..moveTo(size.width / 2, inset * 1.8)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(inset, size.height - inset)
      ..close();

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
