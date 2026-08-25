import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/badges.dart';
import '../widgets/neo_button.dart';
import 'task_form_screen.dart';

/// Management view for the selected day: recurring + date-specific tasks,
/// with tap-to-edit and an add FAB.
class TaskListScreen extends StatelessWidget {
  final AppController controller;

  const TaskListScreen({super.key, required this.controller});

  Future<void> _openForm(BuildContext context, {Task? initial}) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          initial: initial,
          preferDate: initial == null ? controller.selectedDate : null,
        ),
      ),
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
          SnackBar(
            content: Text(initial == null ? 'Task created' : 'Task updated'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _delete(BuildContext context, Task task) async {
    // Inline collapse animation runs in _AnimatedTaskTile._handleDelete before
    // this is invoked; delete immediately for instant feedback.
    try {
      await controller.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dropped "${task.name}"'),
            backgroundColor: const Color(0xFF3A0A12),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayTasks = controller.tasksForSelectedDate;
    final dateLabel = TimeFormat.shortDate(controller.selectedDateIso);

    return Scaffold(
      appBar: AppBar(
        title: Text('TASKS \u00b7 $dateLabel'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${dayTasks.length}',
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
      floatingActionButton: SafeArea(
        top: false,
        child: NeoButton(
          label: 'ADD',
          onPressed: () => _openForm(context),
          background: AppColors.medium,
          foreground: AppColors.canvas,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          leading: const Icon(Icons.add, size: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(),
          color: AppColors.medium,
          backgroundColor: AppColors.surface,
          child: dayTasks.isEmpty
              ? const _EmptyList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: dayTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = dayTasks[i];
                    return _AnimatedTaskTile(
                      key: ValueKey(t.id),
                      index: i,
                      task: t,
                      onTap: () => _openForm(context, initial: t),
                      onDelete: () => _delete(context, t),
                    );
                  },
                ),
        ),
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
          const Icon(
            Icons.linear_scale_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No tasks yet', style: AppTheme.h2),
          const SizedBox(height: 6),
          Text('Add your day with the ADD button.', style: AppTheme.bodyMuted),
        ],
      ),
    );
  }
}

class _AnimatedTaskTile extends StatefulWidget {
  final int index;
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnimatedTaskTile({
    super.key,
    required this.index,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<_AnimatedTaskTile> {
  bool _entered = false;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    // Stagger the entrance so the list pops in row by row.
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) setState(() => _entered = true);
    });
  }

  Future<void> _handleDelete() async {
    if (_removing) return;
    setState(() => _removing = true);
    // Give the shrink/collapse animation time before the row is removed.
    await Future.delayed(const Duration(milliseconds: 240));
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.task.isLocked
        ? AppColors.lockedBorder
        : AppColors.forPriority(widget.task.priority);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      opacity: _removing ? 0 : (_entered ? 1 : 0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        child: _TileContent(
          task: widget.task,
          tier: tier,
          removing: _removing,
          onTap: widget.onTap,
          onDelete: _handleDelete,
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  final Task task;
  final Color tier;
  final bool removing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TileContent({
    required this.task,
    required this.tier,
    required this.removing,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        transform: removing
            ? Matrix4.diagonal3Values(1, 0, 1)
            : Matrix4.identity(),
        alignment: Alignment.topLeft,
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
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: tier,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
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
                      if (task.scheduledDate != null)
                        StickerBadge(
                          text: TimeFormat.shortDate(
                            task.scheduledDate!,
                          ).toUpperCase(),
                          background: AppColors.conflict,
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
                Text(
                  TimeFormat.hhmm(task.preferredStart),
                  style: AppTheme.mono.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TimeFormat.longDuration(task.duration),
                  style: AppTheme.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
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
