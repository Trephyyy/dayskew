import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'badges.dart';
import 'neo_button.dart';

/// Pass 2 conflict surfacing: dotted-border arcade card listing unplaceable
/// tasks with quick manual-resolution actions.
class ConflictDrawer extends StatelessWidget {
  final List<Task> conflicts;
  final Future<void> Function(Task task) onDrop;
  final void Function(Task task) onOverride;
  final void Function(Task task) onTomorrow;

  const ConflictDrawer({
    super.key,
    required this.conflicts,
    required this.onDrop,
    required this.onOverride,
    required this.onTomorrow,
  });

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF241A05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.conflict,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.conflict,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.canvas, size: 18),
              ),
              const SizedBox(width: 8),
              Text('THE BUMP ZONE', style: AppTheme.h2),
              const Spacer(),
              Text(
                '${conflicts.length} BUMPED',
                style: AppTheme.mono.copyWith(
                  color: AppColors.conflict,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These dropped out of the day\u2019s constraints. Resolve them by hand.',
            style: AppTheme.bodyMuted,
          ),
          const SizedBox(height: 12),
          for (final task in conflicts) _ConflictCard(
            task: task,
            onDrop: () => _run(context, () async => onDrop(task)),
            onOverride: () => onOverride(task),
            onTomorrow: () => _run(context, () async => onTomorrow(task)),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDrop;
  final VoidCallback onOverride;
  final VoidCallback onTomorrow;

  const _ConflictCard({
    required this.task,
    required this.onDrop,
    required this.onOverride,
    required this.onTomorrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.conflict, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SensitivityBadges(
            isStartSensitive: task.isStartSensitive,
            isEndSensitive: task.isEndSensitive,
            isLocked: task.isLocked,
            preferredStart: task.preferredStart,
            duration: task.duration,
          ),
          const SizedBox(height: 8),
          Text(task.name, style: AppTheme.h2),
          const SizedBox(height: 4),
          Text(
            'wanted ${TimeFormat.hhmm(task.preferredStart)} \u00b7 ${TimeFormat.longDuration(task.duration)} \u00b7 P${task.priority} ${AppColors.priorityLabel(task.priority)}',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NeoButton(
                label: 'TOMORROW',
                onPressed: onTomorrow,
                background: AppColors.low,
                foreground: AppColors.canvas,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              NeoButton(
                label: 'DROP',
                onPressed: onDrop,
                background: AppColors.high,
                foreground: AppColors.canvas,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              NeoButton(
                label: 'OVERRIDE TIME',
                onPressed: onOverride,
                background: AppColors.conflict,
                foreground: AppColors.canvas,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}