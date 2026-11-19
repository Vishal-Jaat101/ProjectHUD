/// Demo simulation provider: Jaipur ride (JECRC University → Poornima University).
///
/// Simulates:
///   1. Moving along realistic road waypoints in Sitapura / Jaipur.
///   2. Realistic speed variations (20 - 48 km/h).
///   3. Turn announcements at 500m and 100m before maneuvers.
///   4. Pothole hazard warning alert at 40% of route.
///   5. Phase 3 accident risk zone predictive warning at 70% of route.
///   6. Seamless transition to Ride Summary upon arrival.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../models/hazard_models.dart';
import '../../../models/navigation_models.dart';
import '../../../models/telemetry_models.dart';
import '../../hazards/providers/hazard_providers.dart';
import '../../voice/services/voice_service.dart';

/// Predefined waypoint on the Jaipur demo route
class DemoWaypoint {
  const DemoWaypoint({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.direction,
    required this.distanceToNextTurnMeters,
    required this.remainingDistanceMeters,
    required this.instruction,
    this.hazardAlert,
    this.riskZoneAlert,
  });

  final double lat;
  final double lng;
  final double speedKmh;
  final TurnDirection direction;
  final double distanceToNextTurnMeters;
  final double remainingDistanceMeters;
  final String instruction;
  final HazardType? hazardAlert;
  final String? riskZoneAlert;
}

final isDemoRunningProvider = StateProvider<bool>((ref) => false);
final demoCurrentWaypointIndexProvider = StateProvider<int>((ref) => 0);

final demoWaypoints = <DemoWaypoint>[
  // 1. Depart JECRC University Gate
  const DemoWaypoint(
    lat: 26.8528,
    lng: 75.8084,
    speedKmh: 22,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 600,
    remainingDistanceMeters: 3800,
    instruction: 'Head straight on RIICO Industrial Area Road',
  ),
  // 2. Approaching Tonk Road turn (500m alert)
  const DemoWaypoint(
    lat: 26.8552,
    lng: 75.8040,
    speedKmh: 38,
    direction: TurnDirection.right,
    distanceToNextTurnMeters: 480,
    remainingDistanceMeters: 3300,
    instruction: 'In 500 metres, turn right onto Tonk Road',
  ),
  // 3. Final turn approach (100m alert)
  const DemoWaypoint(
    lat: 26.8580,
    lng: 75.7980,
    speedKmh: 28,
    direction: TurnDirection.right,
    distanceToNextTurnMeters: 100,
    remainingDistanceMeters: 2800,
    instruction: 'Turn right onto Tonk Road',
  ),
  // 4. On Tonk Road — Hazard encounter: Pothole alert at 40%
  const DemoWaypoint(
    lat: 26.8610,
    lng: 75.7890,
    speedKmh: 42,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 1100,
    remainingDistanceMeters: 2200,
    instruction: 'Continue straight on Tonk Road for 1.1 km',
    hazardAlert: HazardType.pothole,
  ),
  // 5. Passing Pothole — "Still there?" prompt
  const DemoWaypoint(
    lat: 26.8630,
    lng: 75.7830,
    speedKmh: 34,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 750,
    remainingDistanceMeters: 1700,
    instruction: 'Continue straight towards Sanganer Crossing',
  ),
  // 6. At 70%: Phase 3 Accident Risk Zone Warning Trigger
  const DemoWaypoint(
    lat: 26.8670,
    lng: 75.7750,
    speedKmh: 31,
    direction: TurnDirection.slightLeft,
    distanceToNextTurnMeters: 420,
    remainingDistanceMeters: 1100,
    instruction: 'Slight left onto Sitapura Circle',
    riskZoneAlert:
        'Caution: Entering high accident risk zone. Multiple night collisions reported near this crossing.',
  ),
  // 7. Approaching Poornima University turn
  const DemoWaypoint(
    lat: 26.8720,
    lng: 75.7680,
    speedKmh: 26,
    direction: TurnDirection.left,
    distanceToNextTurnMeters: 120,
    remainingDistanceMeters: 450,
    instruction: 'In 100 metres, turn left towards Poornima University',
  ),
  // 8. Arrived at Poornima University
  const DemoWaypoint(
    lat: 26.8764,
    lng: 75.7640,
    speedKmh: 0,
    direction: TurnDirection.arrive,
    distanceToNextTurnMeters: 0,
    remainingDistanceMeters: 0,
    instruction: 'You have arrived at Poornima University',
  ),
];

class DemoSimulationController {
  DemoSimulationController(this._ref);

  final Ref _ref;
  Timer? _timer;
  int _currentIndex = 0;

  void startSimulation({required void Function() onFinished}) {
    _currentIndex = 0;
    _ref.read(isDemoRunningProvider.notifier).state = true;
    _ref.read(demoCurrentWaypointIndexProvider.notifier).state = 0;

    _updateStateForWaypoint(demoWaypoints[0]);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _currentIndex++;
      if (_currentIndex >= demoWaypoints.length) {
        stopSimulation();
        onFinished();
        return;
      }

      _ref.read(demoCurrentWaypointIndexProvider.notifier).state =
          _currentIndex;
      final wp = demoWaypoints[_currentIndex];
      _updateStateForWaypoint(wp);
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _ref.read(isDemoRunningProvider.notifier).state = false;
  }

  void _updateStateForWaypoint(DemoWaypoint wp) {
    // Update global ride state
    _ref.read(rideStateProvider.notifier).updateState(
          RideState(
            isRiding: wp.speedKmh > 0,
            currentSpeedKmh: wp.speedKmh,
            distanceTravelledMeters: 3800 - wp.remainingDistanceMeters,
            remainingDistanceMeters: wp.remainingDistanceMeters,
            remainingDurationSeconds: (wp.remainingDistanceMeters / 9.0),
            distanceToNextStepMeters: wp.distanceToNextTurnMeters,
            currentLat: wp.lat,
            currentLng: wp.lng,
            rideStartTime: DateTime.now().subtract(const Duration(minutes: 6)),
            phoneTouchCount: 0, // Zero touches throughout ride
          ),
        );

    // Hazard trigger check
    if (wp.hazardAlert != null) {
      final hazard = HazardReport(
        id: 'DEMO_HAZ_POTHOLE',
        type: wp.hazardAlert!,
        latitude: wp.lat + 0.001,
        longitude: wp.lng + 0.001,
        reportedAt: DateTime.now(),
        reportedBy: 'demo_fleet',
        confirmations: 6,
        isVerified: true,
      );
      // Trigger voice warning
      final voice = _ref.read(voiceServiceProvider);
      voice.announceHazard(wp.hazardAlert!, 300);
    }

    // Risk zone alert trigger
    if (wp.riskZoneAlert != null) {
      final voice = _ref.read(voiceServiceProvider);
      voice.announceRiskZone('high');
    }
  }
}

final demoControllerProvider = Provider<DemoSimulationController>((ref) {
  return DemoSimulationController(ref);
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});
