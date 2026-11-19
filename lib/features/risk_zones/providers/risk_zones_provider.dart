/// Providers for Phase 3 Risk Zones layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/telemetry_models.dart';
import '../../hazards/providers/hazard_providers.dart';

final riskZonesListProvider = FutureProvider<List<RoadSegmentRisk>>((ref) async {
  final firestore = ref.read(firestoreServiceProvider);
  return firestore.getRiskZones(
    centerLat: 26.8528,
    centerLng: 75.8084,
  );
});

final selectedRiskZoneProvider = StateProvider<RoadSegmentRisk?>((ref) => null);
