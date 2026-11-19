import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Displays the current speed as a large amber number with "km/h" label below.
///
/// Uses [AppTypography.hudSpeed] (96 pt BarlowSemiCondensed Bold, amber)
/// with tabular figures so digits don't jump when values change.
class SpeedDisplayWidget extends StatelessWidget {
  const SpeedDisplayWidget({
    super.key,
    required this.speedKmh,
  });

  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          speedKmh.round().toString(),
          style: AppTypography.hudSpeed,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'km/h',
          style: AppTypography.hudUnit,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
