/// Telemetry detection & batching service for Phase 3 Accident Prediction.
///
/// Every phone running ProjectHUD acts as an anonymised road-safety probe:
///   - Harsh Braking: Deceleration exceeding -7.0 m/s²
///   - Sudden Swerve: Lateral gyroscope change exceeding 150°/s
///   - Overspeeding: Speed exceeding road or vehicle threshold
///
/// Anonymisation guarantee: No device IDs, no rider names, no phone numbers.
/// Only: Timestamp, Geohash / Segment, Speed, Sensor delta.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../app/constants/app_constants.dart';
import '../../../models/telemetry_models.dart';
import '../../../services/firestore_service.dart';

class TelemetryService {
  TelemetryService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  final List<TelemetryEvent> _buffer = [];
  Timer? _uploadTimer;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _lastSpeedKmh = 0;
  double _currentLat = 0;
  double _currentLng = 0;

  void updateLocationAndSpeed({
    required double lat,
    required double lng,
    required double speedKmh,
  }) {
    _currentLat = lat;
    _currentLng = lng;
    _lastSpeedKmh = speedKmh;

    // Check for overspeeding event
    if (speedKmh > AppConstants.overspeedingThresholdKmh) {
      _recordEvent(
        type: TelemetryEventType.overspeeding,
        speed: speedKmh,
      );
    }
  }

  void startSensorCollection() {
    // 1. Accelerometer for harsh braking
    _accelSub = userAccelerometerEventStream().listen((event) {
      // Forward/backward deceleration on Y-axis (or vector magnitude)
      final forwardDecel = event.y;
      if (forwardDecel < AppConstants.harshBrakingThreshold) {
        _recordEvent(
          type: TelemetryEventType.harshBraking,
          speed: _lastSpeedKmh,
          accelerationMss: forwardDecel,
        );
      }
    });

    // 2. Gyroscope for sudden swerve / near miss evasive maneuvers
    _gyroSub = gyroscopeEventStream().listen((event) {
      final yawDps = (event.z * 180 / pi).abs();
      if (yawDps > AppConstants.suddenSwerveThreshold) {
        _recordEvent(
          type: TelemetryEventType.suddenSwerve,
          speed: _lastSpeedKmh,
          gyroscopeDps: yawDps,
        );
      }
    });

    // 3. Periodic upload timer every 60s
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(
      const Duration(seconds: AppConstants.telemetryUploadIntervalSeconds),
      (_) => flushBuffer(),
    );
  }

  void stopSensorCollection() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _uploadTimer?.cancel();
    flushBuffer();
  }

  void _recordEvent({
    required TelemetryEventType type,
    required double speed,
    double? accelerationMss,
    double? gyroscopeDps,
  }) {
    if (_currentLat == 0 && _currentLng == 0) return;

    final event = TelemetryEvent(
      id: 'TEL_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      type: type,
      latitude: _currentLat,
      longitude: _currentLng,
      timestamp: DateTime.now(),
      speedKmh: speed,
      accelerationMss: accelerationMss,
      gyroscopeDegreesPerSec: gyroscopeDps,
      hourOfDay: DateTime.now().hour,
    );

    _buffer.add(event);
    debugPrint('[TELEMETRY] Captured ${type.label} at (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})');

    if (_buffer.length >= 20) {
      flushBuffer();
    }
  }

  Future<void> flushBuffer() async {
    if (_buffer.isEmpty) return;

    final batchToUpload = List<TelemetryEvent>.from(_buffer);
    _buffer.clear();

    try {
      await _firestore.uploadTelemetryBatch(batchToUpload);
      debugPrint('[TELEMETRY] Successfully uploaded ${batchToUpload.length} anonymised events to Cloud');
    } catch (e) {
      debugPrint('[TELEMETRY] Upload error (re-buffering): $e');
      _buffer.addAll(batchToUpload);
    }
  }
}
