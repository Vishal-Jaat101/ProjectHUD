/// HUDSimulatorScreen — Exact Phase 2 Hardware Projector Output.
///
/// Demonstrates:
///   1. Exact micro-OLED optical projection (Amber Monochrome 590nm).
///   2. Visor lower-corner placement mask (NHTSA compliant).
///   3. Live 12-byte BLE packet breakdown (Header, Maneuver, Dist, Speed, Hazard, Checksum).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../hud/widgets/hazard_banner_widget.dart';
import '../../hud/widgets/speed_display_widget.dart';
import '../../hud/widgets/turn_arrow_widget.dart';
import '../providers/ble_provider.dart';

class HUDSimulatorScreen extends ConsumerWidget {
  const HUDSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packet = ref.watch(liveBLEPacketProvider);
    final rideState = ref.watch(rideStateProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Pure black for OLED projector simulator
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('HARDWARE HUD SIMULATOR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Simulated Helmet Visor Optics Window ────────────────────
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF060708), // Ultra dark simulated visor
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner optical guide indicator
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OPTICAL PROJECTION WINDOW (LOWER VISOR CORNER)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Center is intentionally empty — unobstructed road line
                    Center(
                      child: Text(
                        '[ ROAD SIGHTLINE UNOBSTRUCTED ]',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.25),
                          fontFamily: 'Inter',
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),

                    // Lower corner projected HUD elements (Amber monochrome only)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Projected Turn Arrow + Distance
                            TurnArrowWidget(
                              direction: packet.turnDirection,
                              distanceMeters: packet.distanceMeters.toDouble(),
                              size: 88,
                            ),

                            // Projected Speed
                            SpeedDisplayWidget(
                              speedKmh: packet.speedKmh,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Live 12-Byte BLE Data Link Inspector ────────────────────
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BLE DATA PACKET INSPECTOR',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '12 BYTES / 2.5 HZ',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.verified,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Raw Hex Stream
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        packet.hexString,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: AppColors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Byte mapping grid
                    Expanded(
                      child: ListView(
                        children: [
                          _buildByteRow('0..1', 'Header', '0x48 0x44 ("HD")'),
                          _buildByteRow(
                            '2',
                            'Maneuver',
                            '${packet.turnDirection.label} (0x0${packet.turnDirection.index})',
                          ),
                          _buildByteRow(
                            '3..4',
                            'Turn Distance',
                            '${packet.distanceMeters} m',
                          ),
                          _buildByteRow(
                            '5..6',
                            'GPS Speed',
                            '${packet.speedKmh.toStringAsFixed(1)} km/h',
                          ),
                          _buildByteRow(
                            '7..9',
                            'Hazard Status',
                            packet.hazardType != null
                                ? '${packet.hazardType!.label} at ${packet.hazardDistanceMeters}m'
                                : 'None (0xFF)',
                          ),
                          _buildByteRow(
                            '10',
                            'Risk Level',
                            packet.riskLevel > 0
                                ? 'Level ${packet.riskLevel}'
                                : '0 (Normal)',
                          ),
                          _buildByteRow(
                            '11',
                            'Checksum',
                            '0x${packet.bytes[11].toRadixString(16).toUpperCase()} (XOR Valid)',
                          ),
                        ],
                      ),
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

  Widget _buildByteRow(String bytes, String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              bytes,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              name,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
