/// HomeScreen — main landing screen for ProjectHUD.
///
/// Layout (top to bottom):
///   1. App bar: "ProjectHUD" heading + language toggle
///   2. Vehicle mode selector (Bike / Auto-Cab)
///   3. "Where to?" search card → navigates to /search
///   4. Recent destinations list
///   5. Bottom feature bar (Demo, BLE, Risk Zones, Phase 3)
///
/// Design system: Asphalt + Signal Amber. No gradients, no glow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/navigation_models.dart';
import '../providers/setup_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleMode = ref.watch(vehicleModeProvider);
    final isEnglish = ref.watch(isEnglishProvider);
    final recentDestinations = ref.watch(recentDestinationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. App Bar ──────────────────────────────────────
              _AppBarRow(isEnglish: isEnglish, ref: ref),
              const SizedBox(height: 24),

              // ── 2. Vehicle Mode Selector ────────────────────────
              _VehicleModeSelector(
                selected: vehicleMode,
                onChanged: (mode) {
                  ref.read(vehicleModeProvider.notifier).state = mode;
                },
              ),
              const SizedBox(height: 20),

              // ── 3. "Where to?" Card ────────────────────────────
              _WhereToCard(isEnglish: isEnglish),
              const SizedBox(height: 16),

              // ── Quick Demo Mode Hero Card ──────────────────────
              _DemoHeroCard(isEnglish: isEnglish),
              const SizedBox(height: 16),

              // ── 4. Recent Destinations ──────────────────────────
              Expanded(
                child: _RecentDestinationsList(
                  destinations: recentDestinations,
                  isEnglish: isEnglish,
                ),
              ),

              // ── 5. Bottom Feature Bar ──────────────────────────
              const _BottomFeatureBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App Bar ─────────────────────────────────────────────────────────────

class _AppBarRow extends StatelessWidget {
  const _AppBarRow({required this.isEnglish, required this.ref});

  final bool isEnglish;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ProjectHUD',
          style: AppTypography.heading1.copyWith(color: AppColors.amber),
        ),
        // Language toggle button
        GestureDetector(
          onTap: () {
            ref.read(isEnglishProvider.notifier).state = !isEnglish;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              isEnglish ? 'EN' : 'हिन्दी',
              style: AppTypography.button.copyWith(
                color: AppColors.amber,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Vehicle Mode Selector ───────────────────────────────────────────────

class _VehicleModeSelector extends StatelessWidget {
  const _VehicleModeSelector({
    required this.selected,
    required this.onChanged,
  });

  final VehicleMode selected;
  final ValueChanged<VehicleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VehicleMode.values.map((mode) {
        final isSelected = mode == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode == VehicleMode.bike ? 8 : 0,
              left: mode == VehicleMode.autoCab ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(mode),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : AppColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode.icon,
                      size: 28,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      mode.label,
                      style: AppTypography.button.copyWith(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── "Where to?" Card ────────────────────────────────────────────────────

class _WhereToCard extends StatelessWidget {
  const _WhereToCard({required this.isEnglish});

  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/search'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.amber, size: 28),
            const SizedBox(width: 16),
            Text(
              isEnglish ? 'Where to?' : 'कहाँ जाना है?',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Demo Mode Hero Card ───────────────────────────────────────────

class _DemoHeroCard extends StatelessWidget {
  const _DemoHeroCard({required this.isEnglish});

  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/demo'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.amber,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'DEMO MODE (JAIPUR)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.verified.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PITCH READY',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.verified,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'JECRC University → Poornima Institute',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simulated ride with turns, pothole hazard & Phase 3 risk warning',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.amber,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Destinations List ────────────────────────────────────────────

class _RecentDestinationsList extends StatelessWidget {
  const _RecentDestinationsList({
    required this.destinations,
    required this.isEnglish,
  });

  final List<RecentDestination> destinations;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isEnglish ? 'No recent rides' : 'कोई हालिया राइड नहीं',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Recent' : 'हालिया',
          style: AppTypography.heading3.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: destinations.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.border,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.amber,
                ),
                title: Text(dest.name, style: AppTypography.body),
                subtitle: Text(
                  dest.address,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // TODO: Navigate directly to this destination
                  context.push('/search');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Bottom Feature Bar ──────────────────────────────────────────────────

class _BottomFeatureBar extends StatelessWidget {
  const _BottomFeatureBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FeatureButton(
            icon: Icons.play_circle_outline,
            label: 'Demo',
            onTap: () => context.push('/demo'),
          ),
          _FeatureButton(
            icon: Icons.bluetooth,
            label: 'HUD',
            onTap: () => context.push('/hud-device'),
          ),
          _FeatureButton(
            icon: Icons.map_outlined,
            label: 'Risk',
            onTap: () => context.push('/risk-zones'),
          ),
          _FeatureButton(
            icon: Icons.insights,
            label: 'Phase 3',
            onTap: () => context.push('/explainer'),
          ),
        ],
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
