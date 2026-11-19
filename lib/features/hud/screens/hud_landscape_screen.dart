/// HUDLandscapeScreen — Second-screen / Google Cast display view.
///
/// Designed for auto/cab dashboards and Cast-enabled head units over Wi-Fi.
/// Follows the same Signal Amber monochrome symbology and 3-element constraint.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../hazards/providers/hazard_providers.dart';
import '../providers/hud_providers.dart';
import '../widgets/eta_strip_widget.dart';
import '../widgets/hazard_banner_widget.dart';
import '../widgets/speed_display_widget.dart';
import '../widgets/turn_arrow_widget.dart';

class HUDLandscapeScreen extends ConsumerStatefulWidget {
  const HUDLandscapeScreen({super.key});

  @override
  ConsumerState<HUDLandscapeScreen> createState() => _HUDLandscapeScreenState();
}

class _HUDLandscapeScreenState extends ConsumerState<HUDLandscapeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideStateProvider);
    final hudState = ref.watch(hudStateProvider);
    final activeAlert = ref.watch(activeHazardAlertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            children: [
              // Cast indicator bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cast_connected,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CAST DISPLAY ACTIVE — PROJECTHUD',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.amber,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'DASHBOARD MODE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Active Hazard Alert if any
              if (activeAlert != null) ...[
                HazardBannerWidget(
                  hazard: activeAlert,
                  distanceMeters: 300,
                ),
                const SizedBox(height: 16),
              ],

              // Main Symbology Area (Landscape balanced)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Turn maneuver
                  TurnArrowWidget(
                    direction: hudState.currentDirection,
                    distanceMeters: rideState.distanceToNextStepMeters,
                    size: 130,
                  ),

                  // Vertical divider
                  Container(
                    width: 2,
                    height: 120,
                    color: AppColors.border,
                  ),

                  // Big Speedometer
                  SpeedDisplayWidget(
                    speedKmh: rideState.currentSpeedKmh,
                  ),
                ],
              ),

              const Spacer(),

              // ETA Strip
              ETAStripWidget(
                remainingDistanceMeters: rideState.remainingDistanceMeters,
                remainingDurationSeconds: rideState.remainingDurationSeconds,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
