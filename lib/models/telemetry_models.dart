/// Data models for Phase 3: Telemetry and Accident Prediction.
///
/// Every phone running ProjectHUD becomes a sensor.
/// Telemetry is ANONYMISED — no personal identifiers.

/// Types of telemetry events detected from phone sensors
enum TelemetryEventType {
  harshBraking('Harsh Braking'),
  suddenSwerve('Sudden Swerve'),
  overspeeding('Overspeeding'),
  nearMiss('Near Miss'),
  hazardEncounter('Hazard Encounter');

  const TelemetryEventType(this.label);
  final String label;
}

/// A single telemetry event
class TelemetryEvent {
  final String id;
  final TelemetryEventType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speedKmh;
  final double? accelerationMss; // m/s² for braking events
  final double? gyroscopeDegreesPerSec; // °/s for swerve events
  final String? roadSegmentId; // derived from lat/lng
  final int? hourOfDay;
  final String? weatherCondition; // if available

  const TelemetryEvent({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speedKmh,
    this.accelerationMss,
    this.gyroscopeDegreesPerSec,
    this.roadSegmentId,
    this.hourOfDay,
    this.weatherCondition,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed_kmh': speedKmh,
      if (accelerationMss != null) 'acceleration_mss': accelerationMss,
      if (gyroscopeDegreesPerSec != null)
        'gyroscope_dps': gyroscopeDegreesPerSec,
      if (roadSegmentId != null) 'road_segment_id': roadSegmentId,
      'hour_of_day': hourOfDay ?? timestamp.hour,
      if (weatherCondition != null) 'weather': weatherCondition,
    };
  }
}

/// Risk score for a road segment
class RoadSegmentRisk {
  final String segmentId;
  final double latitude;
  final double longitude;
  final double riskScore; // 0.0 to 1.0
  final int totalEvents;
  final int harshBrakingCount;
  final int swerveCount;
  final int accidentCount;
  final List<int> peakHours; // hours of day with highest risk
  final String riskLevel; // 'low', 'medium', 'high', 'critical'

  const RoadSegmentRisk({
    required this.segmentId,
    required this.latitude,
    required this.longitude,
    required this.riskScore,
    required this.totalEvents,
    this.harshBrakingCount = 0,
    this.swerveCount = 0,
    this.accidentCount = 0,
    this.peakHours = const [],
    this.riskLevel = 'low',
  });

  /// Spoken alert in English when entering a high-risk zone
  String get spokenAlertEn {
    switch (riskLevel) {
      case 'critical':
        return 'Warning! High accident risk zone ahead. '
            'Multiple incidents reported near this area. '
            'Reduce speed and stay alert.';
      case 'high':
        return 'Caution. Accident risk zone ahead. '
            'Stay alert and maintain safe speed.';
      case 'medium':
        return 'Moderate risk zone ahead. Drive carefully.';
      default:
        return '';
    }
  }

  /// Spoken alert in Hindi
  String get spokenAlertHi {
    switch (riskLevel) {
      case 'critical':
        return 'चेतावनी! आगे दुर्घटना का उच्च जोखिम क्षेत्र है। '
            'इस क्षेत्र में कई घटनाएं दर्ज हुई हैं। '
            'रफ्तार कम करें और सतर्क रहें।';
      case 'high':
        return 'सावधान। आगे दुर्घटना जोखिम क्षेत्र। '
            'सतर्क रहें और सुरक्षित रफ्तार बनाए रखें।';
      case 'medium':
        return 'आगे मध्यम जोखिम क्षेत्र। ध्यान से चलें।';
      default:
        return '';
    }
  }
}

/// BLE packet format for HUD projector
/// 
/// Packet format (12 bytes):
/// [0]     Header: 0xHD (0x48, 0x44)
/// [1]     Turn direction: enum index (0-9)
/// [2-3]   Distance to turn: uint16 in meters (big-endian)
/// [4-5]   Current speed: uint16 in km/h * 10 (big-endian, 1 decimal)
/// [6]     Hazard type: enum index (0-5), 0xFF = none
/// [7-8]   Hazard distance: uint16 in meters (big-endian), 0 if no hazard
/// [9]     Risk level: 0=none, 1=low, 2=medium, 3=high, 4=critical
/// [10]    Flags: bit0=riding, bit1=rerouting, bit2=arriving
/// [11]    Checksum: XOR of bytes 0-10
class BLEPacket {
  static const int packetSize = 12;
  static const int headerByte1 = 0x48; // 'H'
  static const int headerByte2 = 0x44; // 'D'

  final TelemetryEventType? activeHazardType;

  // This is documented in the BLE packet spec.
  // See hud_device/docs/ble_packet_format.md for full documentation.
}

/// Ride summary data
class RideSummary {
  final double distanceKm;
  final Duration duration;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final int hazardsReported;
  final int hazardsConfirmed;
  final int phoneTouches;
  final DateTime startTime;
  final DateTime endTime;
  final String routeSummary;

  const RideSummary({
    required this.distanceKm,
    required this.duration,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.hazardsReported,
    required this.hazardsConfirmed,
    required this.phoneTouches,
    required this.startTime,
    required this.endTime,
    required this.routeSummary,
  });
}
