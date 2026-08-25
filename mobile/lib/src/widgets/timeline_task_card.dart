import 'package:flutter/material.dart';

import '../models/placed_task.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'badges.dart';

/// Floating rounded card for a placed task. Border / rail tinted by tier,
/// time metrics in mono, with sensitivity stickers and drift indicator.
class TimelineTaskCard extends StatelessWidget {
  final PlacedTask placed;
  final VoidCallback? onTap;

  const TimelineTaskCard({super.key, required this.placed, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = placed.task;
    final tierColor = t.isLocked ? AppColors.lockedBorder : AppColors.forPriority(t.priority);
    final driftColor = _driftColor(placed);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: t.isLocked ? AppColors.lockedBorder : AppColors.border,
            width: 2,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier rail.
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SensitivityBadges(
                      isStartSensitive: t.isStartSensitive,
                      isEndSensitive: t.isEndSensitive,
                      isLocked: t.isLocked,
                      preferredStart: t.preferredStart,
                      duration: t.duration,
                    ),
                    const SizedBox(height: 8),
                    Text(t.name, style: AppTheme.h2),
                    const SizedBox(height: 10),
                    _TimeRow(placed: placed),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ChipBox(
                          label: 'P${t.priority} ${AppColors.priorityLabel(t.priority)}',
                          color: t.isLocked ? AppColors.lockedBorder : AppColors.forPriority(t.priority),
                        ),
                        const SizedBox(width: 8),
                        _ChipBox(
                          label: TimeFormat.longDuration(t.duration),
                          color: AppColors.textMuted,
                        ),
                        const Spacer(),
                        _DriftChip(
                          text: TimeFormat.drift(placed.computedStart, t.preferredStart),
                          color: driftColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _driftColor(PlacedTask p) {
    final delta = p.computedStart - p.task.preferredStart;
    if (delta == 0) return AppColors.conflict;
    if (delta > 5) return AppColors.low;
    return AppColors.medium;
  }
}

class _TimeRow extends StatelessWidget {
  final PlacedTask placed;

  const _TimeRow({required this.placed});

  @override
  Widget build(BuildContext context) {
    final t = placed.task;
    final preferred = TimeFormat.hhmm(t.preferredStart);
    final isPinned = placed.computedStart != t.preferredStart;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${TimeFormat.hhmm(placed.computedStart)} \u2192 ${TimeFormat.hhmm(placed.computedEnd)}',
          style: AppTheme.mono.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isPinned ? AppColors.medium : AppColors.textPrimary,
          ),
        ),
        if (isPinned) ...[
          const SizedBox(width: 10),
          Text(
            'pref $preferred',
            style: AppTheme.mono.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipBox extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipBox({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final border = color == AppColors.textMuted ? AppColors.border : AppColors.canvas;
    final fg = color == AppColors.textMuted ? AppColors.textMuted : AppColors.canvas;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTheme.mono.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

/// Small delta badge showing schedule drift from the preferred time.
class _DriftChip extends StatelessWidget {
  final String text;
  final Color color;

  const _DriftChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: AppTheme.mono.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}