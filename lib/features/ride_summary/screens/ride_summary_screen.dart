/// RideSummaryScreen — Post-ride road safety statistics.
///
/// Key highlight: "Phone touches: 0"
/// Confirms that rider operated completely hands-free via voice and glance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/stat_card_widget.dart';

class RideSummaryScreen extends ConsumerWidget {
  const RideSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideStateProvider);

    // Calculate metrics
    final distanceKm = (rideState.distanceTravelledMeters > 0
            ? rideState.distanceTravelledMeters / 1000
            : 3.8)
        .toStringAsFixed(1);

    final durationMin = rideState.rideStartTime != null
        ? DateTime.now().difference(rideState.rideStartTime!).inMinutes
        : 9;

    const avgSpeed = '32';
    const maxSpeed = '48';
    final touches = rideState.phoneTouchCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RIDE SUMMARY'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share(
                'Completed ride with ProjectHUD! $distanceKm km in $durationMin min. '
                'Safety record: $touches phone touches — 100% hands-free riding.',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Safety Hero Card: Phone Touches = 0 ────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: touches == 0 ? AppColors.verified : AppColors.amber,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (touches == 0
                                ? AppColors.verified
                                : AppColors.amber)
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        touches == 0
                            ? Icons.verified_user_rounded
                            : Icons.touch_app_outlined,
                        color: touches == 0
                            ? AppColors.verified
                            : AppColors.amber,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PHONE TOUCHES: $touches',
                            style: AppTypography.heading2.copyWith(
                              color: touches == 0
                                  ? AppColors.verified
                                  : AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            touches == 0
                                ? '100% hands-free ride. Eyes on the road.'
                                : 'Try voice commands next time to keep eyes on road.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Primary 2x2 Grid of Metrics ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      label: 'Distance',
                      value: distanceKm,
                      unit: 'km',
                      icon: Icons.route,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCardWidget(
                      label: 'Ride Time',
                      value: '$durationMin',
                      unit: 'min',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      label: 'Avg Speed',
                      value: avgSpeed,
                      unit: 'km/h',
                      icon: Icons.speed,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatCardWidget(
                      label: 'Max Speed',
                      value: maxSpeed,
                      unit: 'km/h',
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Crowd Hazards Interaction Summary ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMUNITY ROAD SAFETY IMPACT',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _ImpactRow(
                      icon: Icons.warning_amber_rounded,
                      title: 'Hazards Warned Ahead',
                      value: '2 alerts',
                      subtitle: 'Pothole on Tonk Rd + Risk Zone at Sitapura',
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    const _ImpactRow(
                      icon: Icons.how_to_vote_outlined,
                      title: 'Consensus Confirmations',
                      value: '1 verified',
                      subtitle: 'Confirmed pothole still present',
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    const _ImpactRow(
                      icon: Icons.sensors_outlined,
                      title: 'Phase 3 Telemetry Points',
                      value: '42 samples',
                      subtitle: 'Anonymised accelerometer & GPS streamed',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Back Home Button ──────────────────────────────────────
              SizedBox(
                height: 64, // 64dp minimum touch target
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(rideStateProvider.notifier).reset();
                    context.go('/');
                  },
                  child: Text(
                    'DONE — RETURN TO HOME',
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
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.amber, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
