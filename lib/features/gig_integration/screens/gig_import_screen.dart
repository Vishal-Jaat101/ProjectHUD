/// GigImportScreen — Receiver & test harness for gig app destinations.
///
/// Simulates incoming dispatch events from Rapido, Ola, Uber, Swiggy, etc.
/// Allows drivers and evaluators to import an order and launch HUD mode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../models/navigation_models.dart';
import '../services/gig_partner_api.dart';

class GigImportScreen extends ConsumerStatefulWidget {
  const GigImportScreen({super.key});

  @override
  ConsumerState<GigImportScreen> createState() => _GigImportScreenState();
}

class _GigImportScreenState extends ConsumerState<GigImportScreen> {
  GigOrderPayload? _activePayload;

  @override
  void initState() {
    super.initState();
    // Default initial simulated Rapido pickup
    _activePayload = const GigOrderPayload(
      orderId: 'RAPIDO_JPR_98214',
      partnerApp: 'Rapido Bike Taxi',
      stage: 'Customer Pickup',
      destinationName: 'JECRC Main Gate',
      destinationAddress: 'Plot No. IS-2036, Ramchandrapura, Sitapura Industrial Area, Jaipur',
      latitude: 26.8528,
      longitude: 75.8084,
      customerPhone: '+91 98290 XXXXX',
    );
  }

  void _simulatePartnerDispatch(String appName, String dest, String stage, double lat, double lng) {
    setState(() {
      _activePayload = GigOrderPayload(
        orderId: '${appName.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch % 10000}',
        partnerApp: appName,
        stage: stage,
        destinationName: dest,
        destinationAddress: '$dest, Jaipur, Rajasthan',
        latitude: lat,
        longitude: lng,
      );
    });
  }

  void _launchHUDNavigation() {
    if (_activePayload == null) return;

    // Update global ride state
    ref.read(rideStateProvider.notifier).updateState(
          RideState(
            isRiding: true,
            currentSpeedKmh: 0,
            remainingDistanceMeters: 3800,
            remainingDurationSeconds: 600,
            distanceToNextStepMeters: 500,
            currentLat: 26.8528,
            currentLng: 75.8084,
            rideStartTime: DateTime.now(),
          ),
        );

    context.go('/hud');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GIG APP DESTINATION IMPORT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description
              Text(
                'RAPIDO / OLA / UBER INTEGRATION LAYER',
                style: AppTypography.caption.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Riders working on partner apps can dispatch destinations directly to ProjectHUD via Android Share Sheet or Deep Link.',
                style: AppTypography.bodySmall,
              ),

              const SizedBox(height: 20),

              // Simulation trigger chips
              Text(
                'TEST INCOMING DISPATCH INTENTS',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PartnerChip(
                    name: 'Rapido Pickup',
                    icon: Icons.two_wheeler,
                    onTap: () => _simulatePartnerDispatch(
                      'Rapido',
                      'JECRC Gate No 2',
                      'Customer Pickup',
                      26.8528,
                      75.8084,
                    ),
                  ),
                  _PartnerChip(
                    name: 'Ola Drop',
                    icon: Icons.local_taxi,
                    onTap: () => _simulatePartnerDispatch(
                      'Ola Cabs',
                      'Poornima University Campus',
                      'Passenger Drop',
                      26.8764,
                      75.7640,
                    ),
                  ),
                  _PartnerChip(
                    name: 'Uber Auto',
                    icon: Icons.electric_rickshaw,
                    onTap: () => _simulatePartnerDispatch(
                      'Uber Auto',
                      'Sitapura RIICO Circle',
                      'Pickup',
                      26.8640,
                      75.7820,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Received Order Card
              if (_activePayload != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.amber, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _activePayload!.partnerApp.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _activePayload!.orderId,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _activePayload!.stage.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.verified,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activePayload!.destinationName,
                        style: AppTypography.heading2.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _activePayload!.destinationAddress,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${_activePayload!.latitude.toStringAsFixed(4)}, ${_activePayload!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Start Navigation Button (64dp)
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _launchHUDNavigation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation_rounded, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'NAVIGATE IN HUD MODE',
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
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: AppColors.amber, size: 16),
      label: Text(name),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.panel,
      side: const BorderSide(color: AppColors.border),
      onPressed: onTap,
    );
  }
}
