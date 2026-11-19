import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../models/navigation_models.dart';
import '../../../models/hazard_models.dart';

// ── HUD State ───────────────────────────────────────────────────────────────
class HUDState {
  final TurnDirection currentDirection;
  final bool isAlertActive;

  const HUDState({
    this.currentDirection = TurnDirection.straight,
    this.isAlertActive = false,
  });

  HUDState copyWith({
    TurnDirection? currentDirection,
    bool? isAlertActive,
  }) {
    return HUDState(
      currentDirection: currentDirection ?? this.currentDirection,
      isAlertActive: isAlertActive ?? this.isAlertActive,
    );
  }
}

final hudStateProvider = StateProvider<HUDState>((ref) {
  final currentStep = ref.watch(currentStepProvider);
  return HUDState(
    currentDirection: currentStep?.direction ?? TurnDirection.straight,
  );
});

// ── Current Navigation Step ─────────────────────────────────────────────────
/// Derived: the step the rider is currently approaching.
final currentStepProvider = Provider<NavigationStep?>((ref) {
  final route = ref.watch(activeRouteProvider);
  final rideState = ref.watch(rideStateProvider);
  if (route == null || route.steps.isEmpty) return null;
  final idx = rideState.currentStepIndex.clamp(0, route.steps.length - 1);
  return route.steps[idx];
});

// ── Active Hazard Provider ──────────────────────────────────────────────────
/// The closest active hazard ahead on the route (if any).
final activeHazardProvider = StateProvider<HazardReport?>((ref) => null);

// ── Hazard Alert Visibility ─────────────────────────────────────────────────
/// Whether the hazard alert banner is showing.
final hazardAlertVisibleProvider = StateProvider<bool>((ref) => false);

// ── Hazard Distance Provider ────────────────────────────────────────────────
/// Distance in meters to the active hazard.
final hazardDistanceProvider = StateProvider<double>((ref) => 0);

// ── HUD Destination Info ────────────────────────────────────────────────────
/// Destination metadata passed when navigating to HUD screen.
class HudDestination {
  final String name;
  final double lat;
  final double lng;

  const HudDestination({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

final hudDestinationProvider = StateProvider<HudDestination?>((ref) => null);

// ── Hazard Report Picker Visibility ─────────────────────────────────────────
/// Whether the quick-report hazard type picker overlay is open.
final hazardPickerVisibleProvider = StateProvider<bool>((ref) => false);

// ── Voice Overlay Visibility ────────────────────────────────────────────────
/// Whether the voice assistant overlay is showing (triggered by long-press).
final voiceOverlayVisibleProvider = StateProvider<bool>((ref) => false);
