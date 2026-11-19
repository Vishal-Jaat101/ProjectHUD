/// Demo simulation provider: Jaipur ride (JECRC University → Poornima Institute).
///
/// Simulates:
///   1. Moving position along realistic road coordinates in Sitapura / Jaipur.
///   2. Realistic speed variations (20 - 48 km/h).
///   3. Voice turn announcements at 500m and 100m marks.
///   4. One hazard alert (Pothole on Tonk Road at ~40% of route).
///   5. One Phase 3 predictive risk warning (Sitapura High Risk Zone at ~70%).
///   6. Seamless transition to Ride Summary upon arrival.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../models/hazard_models.dart';
import '../../../models/navigation_models.dart';
import '../../../models/telemetry_models.dart';
import '../../hazards/providers/hazard_providers.dart';
import '../../voice/services/voice_service.dart';

/// Predefined waypoint on the Jaipur demo route (JECRC → Poornima)
class DemoWaypoint {
  const DemoWaypoint({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.direction,
    required this.distanceToNextTurnMeters,
    required this.remainingDistanceMeters,
    required this.instruction,
    this.voiceAnnouncement,
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
  final String? voiceAnnouncement;
  final HazardType? hazardAlert;
  final String? riskZoneAlert;
}

final isDemoRunningProvider = StateProvider<bool>((ref) => false);
final isDemoPausedProvider = StateProvider<bool>((ref) => false);
final demoCurrentWaypointIndexProvider = StateProvider<int>((ref) => 0);
final demoVoiceSubtitleProvider = StateProvider<String>((ref) => '');

final demoWaypoints = <DemoWaypoint>[
  // 1. Depart JECRC University Gate
  const DemoWaypoint(
    lat: 26.8528,
    lng: 75.8084,
    speedKmh: 22,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 600,
    remainingDistanceMeters: 3800,
    instruction: 'Depart JECRC University. Head straight on RIICO Road.',
    voiceAnnouncement: 'Starting navigation to Poornima Institute. Head straight.',
  ),
  // 2. Approaching Tonk Road turn (500m alert)
  const DemoWaypoint(
    lat: 26.8552,
    lng: 75.8040,
    speedKmh: 38,
    direction: TurnDirection.right,
    distanceToNextTurnMeters: 500,
    remainingDistanceMeters: 3300,
    instruction: 'In 500 metres, turn right onto Tonk Road',
    voiceAnnouncement: 'In 500 metres, turn right onto Tonk Road.',
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
    voiceAnnouncement: 'Turn right onto Tonk Road.',
  ),
  // 4. On Tonk Road — Hazard encounter: Pothole alert at 40%
  const DemoWaypoint(
    lat: 26.8610,
    lng: 75.7890,
    speedKmh: 44,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 1100,
    remainingDistanceMeters: 2200,
    instruction: 'Continue straight on Tonk Road for 1.1 km',
    voiceAnnouncement: 'Pothole reported 300 metres ahead. Slow down.',
    hazardAlert: HazardType.pothole,
  ),
  // 5. Passing Pothole — "Still there?" prompt
  const DemoWaypoint(
    lat: 26.8630,
    lng: 75.7830,
    speedKmh: 35,
    direction: TurnDirection.straight,
    distanceToNextTurnMeters: 750,
    remainingDistanceMeters: 1700,
    instruction: 'Continue straight towards Sitapura Circle',
    voiceAnnouncement: 'Continue straight towards Sitapura Circle.',
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
    voiceAnnouncement: 'Warning! High accident risk zone ahead. Multiple night collisions reported near this crossing.',
    riskZoneAlert: 'High accident risk zone ahead. Multiple incidents reported near this crossing at night.',
  ),
  // 7. Approaching Poornima Institute turn (100m alert)
  const DemoWaypoint(
    lat: 26.8720,
    lng: 75.7680,
    speedKmh: 24,
    direction: TurnDirection.left,
    distanceToNextTurnMeters: 100,
    remainingDistanceMeters: 450,
    instruction: 'In 100 metres, turn left towards Poornima Institute',
    voiceAnnouncement: 'In 100 metres, turn left towards Poornima Institute.',
  ),
  // 8. Arrived at Poornima Institute
  const DemoWaypoint(
    lat: 26.8764,
    lng: 75.7640,
    speedKmh: 0,
    direction: TurnDirection.arrive,
    distanceToNextTurnMeters: 0,
    remainingDistanceMeters: 0,
    instruction: 'You have arrived at Poornima Institute',
    voiceAnnouncement: 'You have arrived at your destination: Poornima Institute.',
  ),
];

class DemoSimulationController {
  DemoSimulationController(this._ref);

  final Ref _ref;
  Timer? _timer;
  int _currentIndex = 0;
  void Function()? _onFinishedCallback;

  void startSimulation({required void Function() onFinished}) {
    _currentIndex = 0;
    _onFinishedCallback = onFinished;
    _ref.read(isDemoRunningProvider.notifier).state = true;
    _ref.read(isDemoPausedProvider.notifier).state = false;
    _ref.read(demoCurrentWaypointIndexProvider.notifier).state = 0;

    _updateStateForWaypoint(demoWaypoints[0]);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_ref.read(isDemoPausedProvider)) return;

      _currentIndex++;
      if (_currentIndex >= demoWaypoints.length) {
        stopSimulation();
        _onFinishedCallback?.call();
        return;
      }

      _ref.read(demoCurrentWaypointIndexProvider.notifier).state =
          _currentIndex;
      final wp = demoWaypoints[_currentIndex];
      _updateStateForWaypoint(wp);
    });
  }

  void togglePause() {
    final current = _ref.read(isDemoPausedProvider);
    _ref.read(isDemoPausedProvider.notifier).state = !current;
  }

  void advanceToNextStep() {
    if (_currentIndex + 1 < demoWaypoints.length) {
      _currentIndex++;
      _ref.read(demoCurrentWaypointIndexProvider.notifier).state = _currentIndex;
      _updateStateForWaypoint(demoWaypoints[_currentIndex]);
    } else {
      stopSimulation();
      _onFinishedCallback?.call();
    }
  }

  void skipToEnd() {
    _currentIndex = demoWaypoints.length - 1;
    _ref.read(demoCurrentWaypointIndexProvider.notifier).state = _currentIndex;
    _updateStateForWaypoint(demoWaypoints[_currentIndex]);
    stopSimulation();
    _onFinishedCallback?.call();
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _ref.read(isDemoRunningProvider.notifier).state = false;
    _ref.read(isDemoPausedProvider.notifier).state = false;
  }

  void _updateStateForWaypoint(DemoWaypoint wp) {
    // 1. Update global ride state
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
            rideStartTime: DateTime.now().subtract(const Duration(minutes: 9)),
            phoneTouchCount: 0, // Zero touches throughout ride
          ),
        );

    // 2. Set Voice Subtitle
    final voiceText = wp.voiceAnnouncement ?? wp.instruction;
    _ref.read(demoVoiceSubtitleProvider.notifier).state = voiceText;

    // 3. Play Speech Announcement
    final voice = _ref.read(voiceServiceProvider);
    if (wp.hazardAlert != null) {
      voice.announceHazard(wp.hazardAlert!, 300);
    } else if (wp.riskZoneAlert != null) {
      voice.announceRiskMessage(wp.voiceAnnouncement!);
    } else if (wp.voiceAnnouncement != null) {
      voice.speak(wp.voiceAnnouncement!);
    }
  }
}

final demoControllerProvider = Provider<DemoSimulationController>((ref) {
  return DemoSimulationController(ref);
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});
