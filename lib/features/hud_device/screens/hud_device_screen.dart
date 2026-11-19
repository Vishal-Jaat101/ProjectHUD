/// HUDDeviceScreen — Phase 2 Hardware connection management.
///
/// Features:
///   1. BLE mode: scan/connect + Virtual Device Simulator.
///   2. Google Cast mode: Wi-Fi second-screen streaming for cabs/autos.
///   3. Clear Placement Rule diagram & instructions (NHTSA compliant).
///   4. Live preview of outgoing 12-byte BLE packets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../providers/ble_provider.dart';

class HUDDeviceScreen extends ConsumerStatefulWidget {
  const HUDDeviceScreen({super.key});

  @override
  ConsumerState<HUDDeviceScreen> createState() => _HUDDeviceScreenState();
}

class _HUDDeviceScreenState extends ConsumerState<HUDDeviceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleConnectionStateProvider);
    final packet = ref.watch(liveBLEPacketProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HUD HARDWARE CONNECTION'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amber,
          labelColor: AppColors.amber,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'BLE PROJECTOR (BIKE)'),
            Tab(text: 'GOOGLE CAST (AUTO/CAB)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: BLE Projector (Phase 2 Hardware) ──────────────────
          _buildBLETab(context, bleState, packet),

          // ── TAB 2: Google Cast Second-Screen ─────────────────────────
          _buildCastTab(context),
        ],
      ),
    );
  }

  Widget _buildBLETab(
    BuildContext context,
    BLEConnectionState state,
    EncodedPacket packet,
  ) {
    final isConnected = state == BLEConnectionState.connected ||
        state == BLEConnectionState.virtualConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected ? AppColors.verified : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bluetooth_connected_rounded,
                  color: isConnected ? AppColors.verified : AppColors.textSecondary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected
                            ? 'CONNECTED: VIRTUAL HUD PROJECTOR'
                            : 'DISCONNECTED',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 16,
                          color: isConnected
                              ? AppColors.verified
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12-byte telemetry channel active · <15ms latency',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Placement Rule Card (NHTSA Compliance)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SAFETY PLACEMENT RULE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'The mini HUD module clips onto the lower corner of the visor or windshield. '
                  'It projects ONLY 3 essentials: Turn Arrow, Distance, and Speed. '
                  'The center of the road view is NEVER blocked.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live BLE Packet Inspector
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIVE BLE PACKET STREAM (12 BYTES)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verified.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'RATE: 2.5 HZ',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.verified,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
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
                    packet.hexString,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: AppColors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Decoded: Turn=${packet.turnDirection.label} | Dist=${packet.distanceMeters}m | '
                  'Speed=${packet.speedKmh} km/h | Checksum=0x${packet.bytes[11].toRadixString(16).toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Launch HUD Simulator Screen Button (64dp)
          SizedBox(
            height: 64,
            child: ElevatedButton(
              onPressed: () => context.push('/hud-simulator'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'OPEN HUD DEVICE SIMULATOR',
                    style: AppTypography.buttonLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cast_rounded,
                  color: AppColors.amber,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'GOOGLE CAST & SECOND SCREEN',
                  style: AppTypography.heading3.copyWith(color: AppColors.amber),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stream the minimal monochrome HUD display over Wi-Fi directly to an auto/cab Android tablet dashboard or Cast-compatible head unit.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 64,
            child: OutlinedButton(
              onPressed: () => context.push('/hud-landscape'),
              child: Text(
                'PREVIEW CAST DASHBOARD VIEW',
                style: AppTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
