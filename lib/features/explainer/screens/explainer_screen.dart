/// ExplainerScreen — Pitch-ready presentation of Phase 3 Accident Prediction.
///
/// Documents:
///   1. The Core Vision: Every phone is a sensor.
///   2. Telemetry ingestion into Google Cloud BigQuery.
///   3. Machine Learning model on Vertex AI.
///   4. Real-time sub-second hazard prediction delivered before danger zones.
///   5. Road safety impact in India (200,000+ two-wheeler fatalities annually).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';

class ExplainerScreen extends StatelessWidget {
  const ExplainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PHASE 3: ACCIDENT PREDICTION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Vision Statement Banner ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amber, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE CORE VISION',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every phone running ProjectHUD becomes a real-time road sensor.',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rather than reacting after a crash has occurred, ProjectHUD predicts danger BEFORE the rider arrives — alerting them hands-free to reduce speed.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 4-Stage Architecture Pipeline ─────────────────────────
              Text(
                'END-TO-END PREDICTIVE ENGINE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),

              _buildPipelineStage(
                stepNumber: '01',
                title: 'Sensor Probe on Phone',
                techStack: 'Flutter + Sensors Plus (Gyro + Accelerometer)',
                description:
                    'Passively detects harsh braking events (-7 m/s²), high-speed swerves (150°/s), and near misses. Telemetry is fully anonymised at the device level.',
              ),
              const SizedBox(height: 12),
              _buildPipelineStage(
                stepNumber: '02',
                title: 'Telemetry Warehouse',
                techStack: 'Google Cloud BigQuery + Cloud Storage',
                description:
                    'Millions of probe points partition by geohash, road segment, hour of day, and weather. Near-miss clusters highlight invisible accident hotspots.',
              ),
              const SizedBox(height: 12),
              _buildPipelineStage(
                stepNumber: '03',
                title: 'Accident Risk Model',
                techStack: 'Google Vertex AI + BigQuery ML',
                description:
                    'Gradient-boosted decision trees train on historical crash frequencies and real-time probe anomalies to generate a 0.0 to 1.0 danger score per segment.',
              ),
              const SizedBox(height: 12),
              _buildPipelineStage(
                stepNumber: '04',
                title: 'Predictive In-Helmet Alert',
                techStack: 'Cloud Run API + BLE HUD Projector',
                description:
                    'The phone receives the warning ~300 metres before the hazard and announces: "High accident risk zone ahead — slow down" in Hindi/English.',
              ),

              const SizedBox(height: 24),

              // ── Indian Road Safety Context ────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHY THIS MATTERS IN INDIA',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow('170,000+', 'Fatal road crashes in India each year'),
                    const SizedBox(height: 8),
                    _buildStatRow('44%', 'Two-wheeler riders share of all road casualties'),
                    const SizedBox(height: 8),
                    _buildStatRow('0 Eyes Off Road', 'ProjectHUD HUD guarantee via voice & glance'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Back to Home Button
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'RETURN TO COCKPIT',
                    style: AppTypography.buttonLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStage({
    required String stepNumber,
    required String title,
    required String techStack,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontFamily: 'BarlowSemiCondensed',
                color: AppColors.background,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading3.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  techStack,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String stat, String desc) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            stat,
            style: AppTypography.heading3.copyWith(
              color: AppColors.amber,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
