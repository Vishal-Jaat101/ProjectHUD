/// Data models for the hazard reporting system.
///
/// Hazard consensus threshold: 5 independent confirmations
/// before a hazard is broadcast to other riders.

import 'package:flutter/material.dart';

/// Types of road hazards
enum HazardType {
  pothole('Pothole', '🕳️', Icons.warning_rounded),
  accident('Accident', '💥', Icons.car_crash_rounded),
  waterlogging('Waterlogging', '🌊', Icons.water_rounded),
  roadWork('Road Work', '🚧', Icons.construction_rounded),
  policeCheck('Police Check', '👮', Icons.local_police_rounded),
  speedBreaker('Speed Breaker', '⏏️', Icons.speed_rounded);

  const HazardType(this.label, this.emoji, this.icon);
  final String label;
  final String emoji;
  final IconData icon;

  /// Spoken warning in English
  String get spokenWarningEn {
    switch (this) {
      case HazardType.pothole:
        return 'Pothole ahead. Slow down.';
      case HazardType.accident:
        return 'Accident reported ahead. Proceed with caution.';
      case HazardType.waterlogging:
        return 'Waterlogging ahead. Reduce speed.';
      case HazardType.roadWork:
        return 'Road work ahead. Watch for diversions.';
      case HazardType.policeCheck:
        return 'Police check point ahead.';
      case HazardType.speedBreaker:
        return 'Speed breaker ahead. Slow down.';
    }
  }

  /// Spoken warning in Hindi
  String get spokenWarningHi {
    switch (this) {
      case HazardType.pothole:
        return 'आगे गड्ढा है। धीरे चलें।';
      case HazardType.accident:
        return 'आगे दुर्घटना की सूचना है। सावधानी से चलें।';
      case HazardType.waterlogging:
        return 'आगे पानी भरा है। रफ्तार कम करें।';
      case HazardType.roadWork:
        return 'आगे सड़क का काम चल रहा है। ध्यान दें।';
      case HazardType.policeCheck:
        return 'आगे पुलिस चेक पॉइंट है।';
      case HazardType.speedBreaker:
        return 'आगे स्पीड ब्रेकर है। धीरे चलें।';
    }
  }
}

/// A single hazard report
class HazardReport {
  final String id;
  final HazardType type;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  final String reportedBy; // anonymised user ID
  final int confirmations;
  final int denials;
  final bool isVerified; // confirmations >= 5
  final DateTime? lastConfirmedAt;

  const HazardReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.reportedBy,
    this.confirmations = 1,
    this.denials = 0,
    this.isVerified = false,
    this.lastConfirmedAt,
  });

  /// Trust score: confirmations - denials
  int get trustScore => confirmations - denials;

  /// Whether this hazard is still considered active
  bool get isActive {
    if (trustScore <= -3) return false;
    final hoursSinceReport =
        DateTime.now().difference(reportedAt).inHours;
    if (hoursSinceReport > 24 && lastConfirmedAt == null) return false;
    if (lastConfirmedAt != null) {
      final hoursSinceConfirm =
          DateTime.now().difference(lastConfirmedAt!).inHours;
      if (hoursSinceConfirm > 12) return false;
    }
    return true;
  }

  HazardReport copyWith({
    int? confirmations,
    int? denials,
    bool? isVerified,
    DateTime? lastConfirmedAt,
  }) {
    return HazardReport(
      id: id,
      type: type,
      latitude: latitude,
      longitude: longitude,
      reportedAt: reportedAt,
      reportedBy: reportedBy,
      confirmations: confirmations ?? this.confirmations,
      denials: denials ?? this.denials,
      isVerified: isVerified ?? this.isVerified,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'reportedAt': reportedAt.toIso8601String(),
      'reportedBy': reportedBy,
      'confirmations': confirmations,
      'denials': denials,
      'isVerified': isVerified,
      'lastConfirmedAt': lastConfirmedAt?.toIso8601String(),
    };
  }

  factory HazardReport.fromFirestore(String id, Map<String, dynamic> data) {
    return HazardReport(
      id: id,
      type: HazardType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => HazardType.pothole,
      ),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      reportedAt: DateTime.parse(data['reportedAt'] as String),
      reportedBy: data['reportedBy'] as String,
      confirmations: data['confirmations'] as int? ?? 1,
      denials: data['denials'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      lastConfirmedAt: data['lastConfirmedAt'] != null
          ? DateTime.parse(data['lastConfirmedAt'] as String)
          : null,
    );
  }
}
