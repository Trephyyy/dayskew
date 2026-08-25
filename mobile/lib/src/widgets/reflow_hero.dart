import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'badges.dart';
import 'neo_button.dart';

/// Tactile wake-up trigger: a big time picker plus the REFLOW DAY action and
/// a one-tap "just woke up" shortcut.
class ReflowHero extends StatelessWidget {
  final int wakeTime;
  final bool isReflowing;
  final VoidCallback onTimeTap;
  final VoidCallback onReflow;
  final VoidCallback onJustWokeUp;

  const ReflowHero({
    super.key,
    required this.wakeTime,
    required this.isReflowing,
    required this.onTimeTap,
    required this.onReflow,
    required this.onJustWokeUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StickerBadge(
                text: 'WAKE-UP',
                background: AppColors.conflict,
                icon: Icons.wb_sunny_outlined,
              ),
              const Spacer(),
              Text(
                'SKEW\u00B7DRIFT\u00B7FLOW',
                style: AppTheme.bodyMuted.copyWith(
                  fontFamily: AppTheme.monoStack,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('ACTUAL WAKE TIME', style: AppTheme.bodyMuted),
          const SizedBox(height: 4),
          _TimeButton(label: TimeFormat.hhmmAmPm(wakeTime), onTap: onTimeTap),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isReflowing ? null : onJustWokeUp,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 16, color: AppColors.low),
                const SizedBox(width: 4),
                Text(
                  'JUST WOKE UP \u2014 USE NOW',
                  style: AppTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.low,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeoButton(
              label: isReflowing ? 'REFLOWING\u2026' : 'REFLOW DAY',
              onPressed: isReflowing ? null : onReflow,
              leading: isReflowing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.canvas,
                      ),
                    )
                  : const Icon(Icons.bolt, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.mono.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.medium,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
