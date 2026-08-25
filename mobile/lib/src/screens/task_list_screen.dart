import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/badges.dart';
import '../widgets/neo_button.dart';
import 'task_form_screen.dart';

/// Management view: every task in the system grouped by priority tier, with
/// tap-to-edit and an add FAB. Mirrors the backend `/tasks` endpoints.
class TaskListScreen extends StatelessWidget {
  final AppController controller;

  const TaskListScreen({super.key, required this.controller});

  Future<void> _openForm(BuildContext context, {Task? initial}) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(initial: initial)),
    );
    if (result == null || !context.mounted) return;
    try {
      if (initial == null) {
        await controller.addTask(result);
      } else {
        await controller.updateTask(result.copyWith(id: initial.id));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(initial == null ? 'Task created' : 'Task updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _delete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drop this task?'),
        content: Text('"${task.name}" will be removed from the day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.high),
            child: const Text('Drop'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task dropped')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasks;
    final groups = <int, List<Task>>{};
    for (final t in tasks) {
      groups.putIfAbsent(t.priority, () => []).add(t);
    }
    final order = [1, 3, 2]; // render locked/high first, then medium, then low

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASKS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${tasks.length} TOTAL',
                style: AppTheme.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: NeoButton(
        label: 'ADD',
        onPressed: () => _openForm(context),
        background: AppColors.medium,
        foreground: AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: const Icon(Icons.add, size: 18),
      ),
      body: tasks.isEmpty
          ? const _EmptyList()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final tier in order)
                  if (groups.containsKey(tier)) ...[
                    _TierHeader(
                      tier: tier,
                      count: groups[tier]!.length,
                    ),
                    for (final t in groups[tier]!)
                      _ListTileTask(
                        task: t,
                        onTap: () => _openForm(context, initial: t),
                        onDelete: () => _delete(context, t),
                      ),
                  ],
              ],
            ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.linear_scale_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No tasks yet', style: AppTheme.h2),
          const SizedBox(height: 6),
          Text('Add your day with the ADD button.', style: AppTheme.bodyMuted),
        ],
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  final int tier;
  final int count;

  const _TierHeader({required this.tier, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = tier == 1
        ? AppColors.high
        : tier == 2
            ? AppColors.medium
            : AppColors.low;
    final title = tier == 1
        ? 'TIER 1 \u00b7 HIGH'
        : tier == 2
            ? 'TIER 2 \u00b7 MEDIUM'
            : 'TIER 3 \u00b7 LOW';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.bodyMuted.copyWith(
              fontFamily: AppTheme.monoStack,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTileTask extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListTileTask({
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tier = task.isLocked ? AppColors.lockedBorder : AppColors.forPriority(task.priority);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isLocked ? AppColors.lockedBorder : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: tier, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (task.isLocked)
                        const StickerBadge(
                          text: 'LOCKED',
                          background: AppColors.lockedBase,
                          foreground: AppColors.lockedBorder,
                          fontSize: 9,
                        ),
                      StickerBadge(
                        text: AppColors.priorityLabel(task.priority),
                        background: AppColors.forPriority(task.priority),
                        fontSize: 9,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(TimeFormat.hhmm(task.preferredStart), style: AppTheme.mono.copyWith(fontWeight: FontWeight.w800, color: AppColors.medium)),
                const SizedBox(height: 2),
                Text(TimeFormat.longDuration(task.duration), style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.high,
              tooltip: 'Drop',
            ),
          ],
        ),
      ),
    );
  }
}