/// Data models for ProjectHUD navigation.

import 'package:flutter/material.dart';

/// Vehicle mode selection
enum VehicleMode {
  bike('Bike', Icons.two_wheeler),
  autoCab('Auto-Cab', Icons.local_taxi);

  const VehicleMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Turn direction for HUD display
enum TurnDirection {
  straight('Straight', '↑'),
  slightLeft('Slight left', '↰'),
  left('Left', '←'),
  sharpLeft('Sharp left', '↲'),
  slightRight('Slight right', '↱'),
  right('Right', '→'),
  sharpRight('Sharp right', '↳'),
  uTurn('U-turn', '↩'),
  arrive('Arrive', '◉'),
  roundabout('Roundabout', '⟳');

  const TurnDirection(this.label, this.symbol);
  final String label;
  final String symbol;
}

/// A single navigation step (turn instruction)
class NavigationStep {
  final TurnDirection direction;
  final String instruction; // e.g. "Turn left onto MG Road"
  final double distanceMeters; // distance to this step from current position
  final double durationSeconds;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String? roadName;

  const NavigationStep({
    required this.direction,
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    this.roadName,
  });

  factory NavigationStep.fromDirectionsApi(Map<String, dynamic> step) {
    return NavigationStep(
      direction: _parseManeuver(step['maneuver'] as String?),
      instruction: _stripHtml(step['html_instructions'] as String? ?? ''),
      distanceMeters: (step['distance']?['value'] as num?)?.toDouble() ?? 0,
      durationSeconds: (step['duration']?['value'] as num?)?.toDouble() ?? 0,
      startLat: (step['start_location']?['lat'] as num?)?.toDouble() ?? 0,
      startLng: (step['start_location']?['lng'] as num?)?.toDouble() ?? 0,
      endLat: (step['end_location']?['lat'] as num?)?.toDouble() ?? 0,
      endLng: (step['end_location']?['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  static TurnDirection _parseManeuver(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return TurnDirection.left;
      case 'turn-right':
        return TurnDirection.right;
      case 'turn-slight-left':
        return TurnDirection.slightLeft;
      case 'turn-slight-right':
        return TurnDirection.slightRight;
      case 'turn-sharp-left':
        return TurnDirection.sharpLeft;
      case 'turn-sharp-right':
        return TurnDirection.sharpRight;
      case 'uturn-left':
      case 'uturn-right':
        return TurnDirection.uTurn;
      case 'roundabout-left':
      case 'roundabout-right':
        return TurnDirection.roundabout;
      default:
        return TurnDirection.straight;
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

/// Full route data
class RouteData {
  final String summary;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final List<NavigationStep> steps;
  final String encodedPolyline;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;

  const RouteData({
    required this.summary,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.steps,
    required this.encodedPolyline,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
  });
}

/// Current ride state
class RideState {
  final bool isRiding;
  final double currentSpeedKmh;
  final double distanceTravelledMeters;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final int currentStepIndex;
  final double distanceToNextStepMeters;
  final double currentLat;
  final double currentLng;
  final double bearing;
  final DateTime? rideStartTime;
  final int phoneTouchCount;

  const RideState({
    this.isRiding = false,
    this.currentSpeedKmh = 0,
    this.distanceTravelledMeters = 0,
    this.remainingDistanceMeters = 0,
    this.remainingDurationSeconds = 0,
    this.currentStepIndex = 0,
    this.distanceToNextStepMeters = 0,
    this.currentLat = 0,
    this.currentLng = 0,
    this.bearing = 0,
    this.rideStartTime,
    this.phoneTouchCount = 0,
  });

  RideState copyWith({
    bool? isRiding,
    double? currentSpeedKmh,
    double? distanceTravelledMeters,
    double? remainingDistanceMeters,
    double? remainingDurationSeconds,
    int? currentStepIndex,
    double? distanceToNextStepMeters,
    double? currentLat,
    double? currentLng,
    double? bearing,
    DateTime? rideStartTime,
    int? phoneTouchCount,
  }) {
    return RideState(
      isRiding: isRiding ?? this.isRiding,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      distanceTravelledMeters:
          distanceTravelledMeters ?? this.distanceTravelledMeters,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      remainingDurationSeconds:
          remainingDurationSeconds ?? this.remainingDurationSeconds,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceToNextStepMeters:
          distanceToNextStepMeters ?? this.distanceToNextStepMeters,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      bearing: bearing ?? this.bearing,
      rideStartTime: rideStartTime ?? this.rideStartTime,
      phoneTouchCount: phoneTouchCount ?? this.phoneTouchCount,
    );
  }

  String get formattedSpeed => currentSpeedKmh.round().toString();

  String get formattedRemainingDistance {
    if (remainingDistanceMeters >= 1000) {
      return '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${remainingDistanceMeters.round()} m';
  }

  String get formattedETA {
    final minutes = (remainingDurationSeconds / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${minutes} min';
  }

  String get formattedDistanceToNextStep {
    if (distanceToNextStepMeters >= 1000) {
      return '${(distanceToNextStepMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceToNextStepMeters.round()} m';
  }

  Duration get rideDuration {
    if (rideStartTime == null) return Duration.zero;
    return DateTime.now().difference(rideStartTime!);
  }
}
