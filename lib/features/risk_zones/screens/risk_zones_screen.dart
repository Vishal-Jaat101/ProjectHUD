/// RiskZonesScreen — Phase 3 Accident-Prone Zones Map & Risk Layer.
///
/// Features:
///   1. Heatmap / list of AI-predicted high-risk accident hotspots in Jaipur.
///   2. Segment risk scores (0.0 to 1.0) derived from aggregated telemetry.
///   3. Peak collision hours breakdown.
///   4. Predictive voice warning test trigger.
///   5. Honest labeling of seeded dataset for demo transparency.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/telemetry_models.dart';
import '../providers/risk_zones_provider.dart';

class RiskZonesScreen extends ConsumerWidget {
  const RiskZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskZonesAsync = ref.watch(riskZonesListProvider);
    final selectedZone = ref.watch(selectedRiskZoneProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ACCIDENT RISK ZONES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Dataset Disclaimer Banner ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.panel,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Model trained on BigQuery fleet telemetry · Seeded Jaipur Data',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── List of Predicted Road Segments ─────────────────────────
            Expanded(
              child: riskZonesAsync.when(
                data: (zones) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final zone = zones[index];
                      final isSelected = selectedZone?.segmentId == zone.segmentId;

                      return _RiskSegmentCard(
                        zone: zone,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedRiskZoneProvider.notifier).state =
                              isSelected ? null : zone;
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
                error: (e, _) => Center(
                  child: Text('Error loading risk data: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskSegmentCard extends StatelessWidget {
  const _RiskSegmentCard({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  final RoadSegmentRisk zone;
  final bool isSelected;
  final VoidCallback onTap;

  Color _getRiskColor() {
    switch (zone.riskLevel) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return AppColors.amber;
      default:
        return AppColors.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? riskColor : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Segment ID + Risk Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zone.segmentId.replaceAll('_', ' '),
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    '${zone.riskLevel.toUpperCase()} RISK (${(zone.riskScore * 100).round()}%)',
                    style: AppTypography.caption.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Statistics Row: Braking, Swerves, Accidents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric('Harsh Braking', '${zone.harshBrakingCount}'),
                _buildMetric('Sudden Swerves', '${zone.swerveCount}'),
                _buildMetric('Reported Accidents', '${zone.accidentCount}'),
              ],
            ),

            // Expanded view details
            if (isSelected) ...[
              const Divider(color: AppColors.border, height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peak Risk Hours',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zone.peakHours.isNotEmpty
                              ? zone.peakHours
                                  .map((h) => '${h % 12 == 0 ? 12 : h % 12} ${h >= 12 ? 'PM' : 'AM'}')
                                  .join(', ')
                              : 'Even distribution',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Predictive Spoken Alert: "${zone.spokenAlertEn}"',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.heading3.copyWith(
            color: AppColors.amber,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
