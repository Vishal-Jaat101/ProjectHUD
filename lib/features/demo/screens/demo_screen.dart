/// DemoScreen — Simulated ride in Jaipur (JECRC → Poornima).
///
/// Features:
///   - Clearly labels "SIMULATED RIDE" in accordance with guidelines.
///   - Pre-ride briefing with route map summary.
///   - Live HUD view driving through the simulated route.
///   - Triggers turn announcements, pothole alert, and Phase 3 risk warning.
///   - Fast forward & End Demo controls.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../hud/widgets/eta_strip_widget.dart';
import '../../hud/widgets/hazard_banner_widget.dart';
import '../../hud/widgets/speed_display_widget.dart';
import '../../hud/widgets/turn_arrow_widget.dart';
import '../providers/demo_providers.dart';

class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen> {
  bool _hasStarted = false;

  void _startDemo() {
    setState(() => _hasStarted = true);
    final controller = ref.read(demoControllerProvider);
    controller.startSimulation(
      onFinished: () {
        if (mounted) {
          context.go('/ride-summary');
        }
      },
    );
  }

  void _stopAndExit() {
    ref.read(demoControllerProvider).stopSimulation();
    context.pop();
  }

  @override
  void dispose() {
    ref.read(demoControllerProvider).stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(isDemoRunningProvider);
    final wpIndex = ref.watch(demoCurrentWaypointIndexProvider);
    final currentWp = demoWaypoints[wpIndex];
    final rideState = ref.watch(rideStateProvider);

    if (!_hasStarted) {
      return _buildBriefingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Top Bar: Simulated Status & Controls ────────────────────
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: AppColors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SIMULATED GPS: JAIPUR',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: _stopAndExit,
                  ),
                ],
              ),
            ),

            // ── Center Simulation Events Display ────────────────────────
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panel.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP ${wpIndex + 1} OF ${demoWaypoints.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'JECRC → POORNIMA',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentWp.instruction,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (currentWp.riskZoneAlert != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Text(
                          '⚠️ PHASE 3 PREDICTION TRIGGERED',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Lower Third: Pure HUD Guidance ──────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hazard alert if active at this waypoint
                    if (currentWp.hazardAlert != null) ...[
                      HazardBannerWidget(
                        hazard: HazardReport(
                          id: 'DEMO_HAZ',
                          type: currentWp.hazardAlert!,
                          latitude: currentWp.lat,
                          longitude: currentWp.lng,
                          reportedAt: DateTime.now(),
                          reportedBy: 'fleet',
                        ),
                        distanceMeters: 300,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Primary Guidance Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TurnArrowWidget(
                          direction: currentWp.direction,
                          distanceMeters: currentWp.distanceToNextTurnMeters,
                          size: 96,
                        ),
                        SpeedDisplayWidget(
                          speedKmh: currentWp.speedKmh,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ETA Strip
                    ETAStripWidget(
                      remainingDistanceMeters: currentWp.remainingDistanceMeters,
                      remainingDurationSeconds:
                          currentWp.remainingDistanceMeters / 8.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DEMO MODE SIMULATION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science,
                      color: AppColors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'TABLETOP EVALUATION MODE — SIMULATED GPS & SEEDED DATA',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Route Briefing Card
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
                      'JAIPUR ROUTE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRouteLeg(
                      icon: Icons.radio_button_checked,
                      title: 'JECRC University',
                      subtitle: 'RIICO Industrial Area, Sitapura',
                      color: AppColors.amber,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(
                        width: 2,
                        height: 28,
                        color: AppColors.border,
                      ),
                    ),
                    _buildRouteLeg(
                      icon: Icons.location_on,
                      title: 'Poornima University',
                      subtitle: 'ISI-2, RIICO Institutional Area',
                      color: AppColors.verified,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('DISTANCE', '3.8 km'),
                        _buildStat('EST. TIME', '9 min'),
                        _buildStat('WAYPOINTS', '8 stages'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Included Demonstration Highlights
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
                      'DEMONSTRATION SEQUENCE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHighlightItem('Turn alerts at 500m & 100m marks'),
                    _buildHighlightItem('Dynamic GPS speed updates (20-48 km/h)'),
                    _buildHighlightItem('Verified Pothole hazard warning alert'),
                    _buildHighlightItem('Phase 3 Predictive Accident-Risk Zone warning'),
                    _buildHighlightItem('Full post-ride safety summary (Phone touches: 0)'),
                  ],
                ),
              ),

              const Spacer(),

              // Start Demo Button (64dp target)
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _startDemo,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'START DEMO RIDE',
                        style: AppTypography.buttonLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteLeg({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.heading3.copyWith(fontSize: 16)),
            Text(subtitle, style: AppTypography.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
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

  Widget _buildHighlightItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.verified, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
