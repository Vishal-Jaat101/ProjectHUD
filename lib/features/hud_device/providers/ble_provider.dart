/// BLE provider & packet encoder for ProjectHUD Phase 2 hardware.
///
/// Converts navigation and hazard state into compact 12-byte packets.
/// Supports both physical BLE connection and virtual simulation.

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../models/hazard_models.dart';
import '../../../models/navigation_models.dart';
import '../../hazards/providers/hazard_providers.dart';
import '../../hud/providers/hud_providers.dart';

enum BLEConnectionState {
  disconnected,
  scanning,
  connected,
  virtualConnected,
}

/// Encoded 12-byte telemetry packet with inspection metadata
class EncodedPacket {
  const EncodedPacket({
    required this.bytes,
    required this.hexString,
    required this.turnDirection,
    required this.distanceMeters,
    required this.speedKmh,
    required this.hazardType,
    required this.hazardDistanceMeters,
    required this.riskLevel,
    required this.checksumValid,
  });

  final Uint8List bytes;
  final String hexString;
  final TurnDirection turnDirection;
  final int distanceMeters;
  final double speedKmh;
  final HazardType? hazardType;
  final int hazardDistanceMeters;
  final int riskLevel;
  final bool checksumValid;
}

final bleConnectionStateProvider =
    StateProvider<BLEConnectionState>((ref) => BLEConnectionState.virtualConnected);

final liveBLEPacketProvider = Provider<EncodedPacket>((ref) {
  final rideState = ref.watch(rideStateProvider);
  final hudState = ref.watch(hudStateProvider);
  final activeHazard = ref.watch(activeHazardAlertProvider);

  return encodeBLEPacket(
    direction: hudState.currentDirection,
    distanceMeters: rideState.distanceToNextStepMeters.round(),
    speedKmh: rideState.currentSpeedKmh,
    hazard: activeHazard,
    hazardDistanceMeters: activeHazard != null ? 300 : 0,
    riskLevel: 0,
  );
});

EncodedPacket encodeBLEPacket({
  required TurnDirection direction,
  required int distanceMeters,
  required double speedKmh,
  required HazardReport? hazard,
  required int hazardDistanceMeters,
  required int riskLevel,
}) {
  final buffer = Uint8List(12);

  // Byte 0-1: Magic header "HD"
  buffer[0] = 0x48; // 'H'
  buffer[1] = 0x44; // 'D'

  // Byte 2: Turn direction enum index
  buffer[2] = direction.index.clamp(0, 9);

  // Byte 3-4: Distance to turn (uint16 big-endian)
  final dist = distanceMeters.clamp(0, 65535);
  buffer[3] = (dist >> 8) & 0xFF;
  buffer[4] = dist & 0xFF;

  // Byte 5-6: Speed in km/h * 10 (uint16 big-endian)
  final speedRaw = (speedKmh * 10).round().clamp(0, 65535);
  buffer[5] = (speedRaw >> 8) & 0xFF;
  buffer[6] = speedRaw & 0xFF;

  // Byte 7: Hazard type (0xFF = none)
  buffer[7] = hazard != null ? hazard.type.index : 0xFF;

  // Byte 8-9: Hazard distance (uint16 big-endian)
  final hDist = hazardDistanceMeters.clamp(0, 65535);
  buffer[8] = (hDist >> 8) & 0xFF;
  buffer[9] = hDist & 0xFF;

  // Byte 10: Risk level (0-4)
  buffer[10] = riskLevel.clamp(0, 4);

  // Byte 11: Checksum (XOR of bytes 0..10)
  int checksum = 0;
  for (int i = 0; i < 11; i++) {
    checksum ^= buffer[i];
  }
  buffer[11] = checksum;

  final hexStr = buffer
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  return EncodedPacket(
    bytes: buffer,
    hexString: hexStr,
    turnDirection: direction,
    distanceMeters: dist,
    speedKmh: speedRaw / 10.0,
    hazardType: hazard?.type,
    hazardDistanceMeters: hDist,
    riskLevel: riskLevel,
    checksumValid: true,
  );
}
