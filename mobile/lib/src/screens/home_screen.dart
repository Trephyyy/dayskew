import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/conflict_drawer.dart';
import '../widgets/neo_button.dart';
import '../widgets/reflow_hero.dart';
import '../widgets/timeline_task_card.dart';
import 'task_form_screen.dart';
import 'task_list_screen.dart';

/// DaySkew home: wake-time hero, computed timeline, and the Bump Zone.
class HomeScreen extends StatefulWidget {
  final AppController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _dismissedConflicts = {};

  AppController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.loadTasks().then((_) => c.reflow());
    });
  }

  Future<void> _pickWakeTime() async {
    final current = c.wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Actual wake-up time',
    );
    if (picked != null) c.setWakeTime(picked.hour * 60 + picked.minute);
  }

  Future<void> _reflow() async {
    await c.reflow();
    if (c.error == null && mounted) {
      final bumped = c.conflicts.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bumped == 0
                ? 'Day placed \u2014 zero conflicts.'
                : 'Day placed \u00b7 $bumped task${bumped == 1 ? '' : 's'} bumped.',
          ),
        ),
      );
    }
  }

  Future<void> _openForm({Task? initial}) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(initial: initial)),
    );
    if (result == null || !mounted) return;
    try {
      if (initial == null) {
        await c.addTask(result);
      } else {
        await c.updateTask(result.copyWith(id: initial.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _seedSampleDay() async {
    try {
      await c.seedSampleDay();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sample day loaded')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleConflicts = c.conflicts
        .where((t) => !_dismissedConflicts.contains(t.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAYSKEW'),
        actions: [
          IconButton(
            tooltip: 'Manage tasks',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TaskListScreen(controller: c),
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.loading || c.reflowing ? null : () => c.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: NeoButton(
        label: 'NEW TASK',
        onPressed: () => _openForm(),
        background: AppColors.medium,
        foreground: AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: const Icon(Icons.add, size: 18),
      ),
      body: RefreshIndicator(
        onRefresh: () => c.refresh(),
        color: AppColors.medium,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            ReflowHero(
              wakeTime: c.wakeTime,
              isReflowing: c.reflowing,
              onTimeTap: _pickWakeTime,
              onReflow: _reflow,
            ),
            if (c.error != null) _ErrorBanner(message: c.error!),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'TIMELINE',
              trailing:
                  '${TimeFormat.hhmm(c.wakeTime)} WOKE',
            ),
            const SizedBox(height: 4),
            if (c.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.medium)),
              )
            else if (c.tasks.isEmpty)
              _EmptyDay(onSeed: _seedSampleDay)
            else if (c.timeline.isEmpty && c.conflicts.isEmpty)
              _NothingToPlace(wakeLabel: TimeFormat.hhmm(c.wakeTime))
            else ...[
              for (final placed in c.timeline)
                TimelineTaskCard(
                  placed: placed,
                  onTap: () => _openForm(initial: placed.task),
                ),
              if (visibleConflicts.isNotEmpty)
                ConflictDrawer(
                  conflicts: visibleConflicts,
                  onDrop: (t) async {
                    _dismissedConflicts.add(t.id);
                    setState(() {});
                    await c.dropConflict(t);
                  },
                  onOverride: (t) => _openForm(initial: t),
                  onTomorrow: (t) {
                    setState(() => _dismissedConflicts.add(t.id));
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTheme.bodyMuted.copyWith(
            fontFamily: AppTheme.monoStack,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTheme.mono.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final VoidCallback onSeed;

  const _EmptyDay({required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_sunny_outlined,
              size: 44, color: AppColors.conflict),
          const SizedBox(height: 12),
          Text('No tasks for the day yet.', style: AppTheme.h2),
          const SizedBox(height: 6),
          Text(
            'Seed a sample day to see the reflow in action, or add your own tasks.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMuted,
          ),
          const SizedBox(height: 16),
          NeoButton(
            label: 'LOAD SAMPLE DAY',
            onPressed: onSeed,
            background: AppColors.conflict,
            foreground: AppColors.canvas,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

class _NothingToPlace extends StatelessWidget {
  final String wakeLabel;

  const _NothingToPlace({required this.wakeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_bottom_rounded,
              size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Nothing fits after $wakeLabel', style: AppTheme.h2),
          const SizedBox(height: 6),
          Text(
            'Every task bumped out of the day. Resolve them below or loosen constraints.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A0A12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.high, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.high, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'API error: $message',
              style: AppTheme.bodyMuted.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}