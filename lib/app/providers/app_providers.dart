/// Global application-level providers for ProjectHUD.
///
/// Provides location tracking, ride state, and route data
/// that are shared across features.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/navigation_models.dart';

// ── Location ──────────────────────────────────────────────────────────

/// Whether location permission has been granted and location is available.
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
});

/// Current device position, updated via a stream.
final currentPositionProvider =
    StreamProvider.autoDispose<Position>((ref) async* {
  final hasPermission = await ref.watch(locationPermissionProvider.future);
  if (!hasPermission) return;

  // Emit the last known position first for fast UI.
  final lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown != null) yield lastKnown;

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters between updates
    ),
  );
});

// ── Ride State ────────────────────────────────────────────────────────

/// Manages the current ride.
class RideStateNotifier extends StateNotifier<RideState> {
  RideStateNotifier() : super(const RideState());

  void startRide({
    required double lat,
    required double lng,
    required double remainingDistanceMeters,
    required double remainingDurationSeconds,
  }) {
    state = RideState(
      isRiding: true,
      currentLat: lat,
      currentLng: lng,
      remainingDistanceMeters: remainingDistanceMeters,
      remainingDurationSeconds: remainingDurationSeconds,
      rideStartTime: DateTime.now(),
    );
  }

  void updatePosition({
    required double lat,
    required double lng,
    required double bearing,
    required double speedKmh,
  }) {
    state = state.copyWith(
      currentLat: lat,
      currentLng: lng,
      bearing: bearing,
      currentSpeedKmh: speedKmh,
    );
  }

  void updateNavigation({
    required int stepIndex,
    required double distanceToNextStep,
    required double remainingDistance,
    required double remainingDuration,
    required double distanceTravelled,
  }) {
    state = state.copyWith(
      currentStepIndex: stepIndex,
      distanceToNextStepMeters: distanceToNextStep,
      remainingDistanceMeters: remainingDistance,
      remainingDurationSeconds: remainingDuration,
      distanceTravelledMeters: distanceTravelled,
    );
  }

  void recordPhoneTouch() {
    state = state.copyWith(phoneTouchCount: state.phoneTouchCount + 1);
  }

  void endRide() {
    state = state.copyWith(isRiding: false);
  }

  void updateState(RideState newState) {
    state = newState;
  }

  void reset() {
    state = const RideState();
  }
}

final rideStateProvider =
    StateNotifierProvider<RideStateNotifier, RideState>((ref) {
  return RideStateNotifier();
});

// ── Route Data ────────────────────────────────────────────────────────

/// Holds the active route returned from the Directions API.
/// `null` when no route is loaded.
final activeRouteProvider = StateProvider<RouteData?>((ref) => null);
