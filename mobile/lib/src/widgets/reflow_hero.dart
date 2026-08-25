import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'neo_button.dart';

/// Wake-up trigger: one-tap "just woke up" sets the current device time and
/// reflows. Shows the applied wake time compactly.
class ReflowHero extends StatelessWidget {
  final int wakeTime;
  final bool isReflowing;
  final VoidCallback onJustWokeUp;
  final VoidCallback onTimeTap;

  const ReflowHero({
    super.key,
    required this.wakeTime,
    required this.isReflowing,
    required this.onJustWokeUp,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
              const Icon(
                Icons.wb_sunny_outlined,
                color: AppColors.conflict,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                TimeFormat.hhmmAmPm(wakeTime),
                style: AppTheme.mono.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isReflowing ? null : onTimeTap,
                child: Text(
                  'SET',
                  style: AppTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.medium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: NeoButton(
              label: isReflowing ? 'REFLOWING\u2026' : 'JUST WOKE UP',
              onPressed: isReflowing ? null : onJustWokeUp,
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
