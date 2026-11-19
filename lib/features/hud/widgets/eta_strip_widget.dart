import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Thin info strip showing remaining distance + ETA.
///
/// Amber text on transparent background.
/// Format: "4.2 km · 12 min"
class EtaStripWidget extends StatelessWidget {
  const EtaStripWidget({
    super.key,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
  });

  final double remainingDistanceMeters;
  final double remainingDurationSeconds;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Text(
        'Remaining: ${_formatDistance(remainingDistanceMeters)} · ${_formatDuration(remainingDurationSeconds)}',
        style: AppTypography.hudInfo,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

typedef ETAStripWidget = EtaStripWidget;
