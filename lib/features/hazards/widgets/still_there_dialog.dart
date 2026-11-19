/// "Still there?" verification dialog for reported hazards.
///
/// Triggers when rider is within 100m of a previously reported hazard.
/// Riders answer by voice ("yes" / "no") or tap one big button (64dp+).
///
/// Rules:
///   - 5 independent confirmations required for verification consensus.
///   - YES adds confirmation, NO reduces trust score.
///   - Auto-dismisses after 8 seconds without input.

import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/hazard_models.dart';
import 'hazard_icon_widget.dart';

class StillThereDialog extends StatefulWidget {
  const StillThereDialog({
    super.key,
    required this.hazard,
    required this.onConfirmed,
    required this.onDenied,
  });

  final HazardReport hazard;
  final VoidCallback onConfirmed;
  final VoidCallback onDenied;

  @override
  State<StillThereDialog> createState() => _StillThereDialogState();
}

class _StillThereDialogState extends State<StillThereDialog> {
  int _countdown = 8;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_countdown > 1) {
          setState(() => _countdown--);
        } else {
          _timer?.cancel();
          widget.onDenied(); // Default to timeout dismiss
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              HazardIconWidget(type: widget.hazard.type, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.hazard.type.label.toUpperCase()} REPORTED',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.amber,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Still there? Say "Yes" or "No" ($_countdown s)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // YES button (Green, confirmed)
              Expanded(
                child: SizedBox(
                  height: 64, // >= 64dp safety rule
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verified,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      widget.onConfirmed();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'YES',
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // NO button (Amber / secondary)
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.amber,
                      side: const BorderSide(color: AppColors.amber, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      widget.onDenied();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'NO',
                          style: AppTypography.button.copyWith(
                            color: AppColors.amber,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
