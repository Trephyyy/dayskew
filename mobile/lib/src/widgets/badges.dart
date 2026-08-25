import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

/// Sticker-style pill tag. Rotated a hair for tactile vibes.
class StickerBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;

  const StickerBadge({
    super.key,
    required this.text,
    required this.background,
    this.foreground = AppColors.canvas,
    this.icon,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.canvas, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: foreground),
              const SizedBox(width: 3),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.monoStack,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: 0.3,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge trio decorating a timeline card: locked / start / end sensitivity.
class SensitivityBadges extends StatelessWidget {
  final bool isStartSensitive;
  final bool isEndSensitive;
  final bool isLocked;
  final int preferredStart;
  final int duration;

  const SensitivityBadges({
    super.key,
    required this.isStartSensitive,
    required this.isEndSensitive,
    required this.isLocked,
    required this.preferredStart,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (isLocked)
        const StickerBadge(
          text: 'LOCKED',
          background: AppColors.lockedBase,
          foreground: AppColors.lockedBorder,
          icon: Icons.lock_outline,
        ),
      if (isStartSensitive)
        StickerBadge(
          text: 'START \u2265 ${TimeFormat.hhmm(preferredStart)}',
          background: AppColors.high,
        ),
      if (isEndSensitive)
        StickerBadge(
          text: 'END \u2264 ${TimeFormat.hhmm(preferredStart + duration)}',
          background: AppColors.medium,
        ),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges,
    );
  }
}