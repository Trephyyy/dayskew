import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/neo_button.dart';

/// Create/edit form for a single task. On save it pops back with a fully
/// populated [Task] (id kept for edits).
///
/// [preferDate] seeds a newly created task onto that calendar day (used when
/// the home screen is viewing a specific day); null keeps it recurring.
class TaskFormScreen extends StatefulWidget {
  final Task? initial;
  final DateTime? preferDate;

  const TaskFormScreen({super.key, this.initial, this.preferDate});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

/// Date assignment mode for a task.
enum _DateMode { recurring, today, specific }

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late int _preferredStart;
  late bool _isStartSensitive;
  late bool _isEndSensitive;
  late int _priority;
  late final bool _isEditing;

  late _DateMode _dateMode;
  late DateTime _specificDate;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _isEditing = t != null;
    _name = TextEditingController(text: t?.name ?? '');
    _duration = TextEditingController(
      text: t == null ? '60' : t.duration.toString(),
    );
    _preferredStart = t?.preferredStart ?? 9 * 60;
    _isStartSensitive = t?.isStartSensitive ?? false;
    _isEndSensitive = t?.isEndSensitive ?? false;
    _priority = t?.priority ?? 2;

    if (t?.scheduledDate != null) {
      final parsed = TimeFormat.tryParseDate(t!.scheduledDate);
      _dateMode = parsed != null ? _DateMode.specific : _DateMode.recurring;
      _specificDate = parsed ?? DateTime.now();
    } else if (widget.preferDate != null) {
      _dateMode =
          TimeFormat.isoDate(widget.preferDate!) == TimeFormat.todayIso()
          ? _DateMode.today
          : _DateMode.specific;
      _specificDate = widget.preferDate!;
    } else {
      _dateMode = _DateMode.recurring;
      _specificDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _preferredStart ~/ 60,
        minute: _preferredStart % 60,
      ),
      helpText: 'Preferred start time',
    );
    if (picked != null) {
      setState(() => _preferredStart = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _pickSpecificDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Schedule this task on',
    );
    if (picked != null) {
      setState(
        () => _specificDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  /// The calendar day to persist, or null for a recurring (every-day) task.
  String? _resolveDate() {
    switch (_dateMode) {
      case _DateMode.recurring:
        return null;
      case _DateMode.today:
        return TimeFormat.todayIso();
      case _DateMode.specific:
        return TimeFormat.isoDate(_specificDate);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final duration = int.parse(_duration.text);
    final scheduled = _resolveDate();
    final task = Task(
      id: widget.initial?.id ?? '',
      name: _name.text.trim(),
      duration: duration,
      preferredStart: _preferredStart,
      isStartSensitive: _isStartSensitive,
      isEndSensitive: _isEndSensitive,
      priority: _priority,
      scheduledDate: scheduled,
      timezone: widget.initial?.timezone ?? 'UTC',
    );
    if (task.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LOCKED event \u2014 anchors the day\u2019s skeleton'),
        ),
      );
    }
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'EDIT TASK' : 'NEW TASK')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              _FieldLabel('NAME'),
              TextFormField(
                controller: _name,
                style: AppTheme.body,
                decoration: _inputDecoration('e.g. Morning run'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('DURATION (MIN)'),
              TextFormField(
                controller: _duration,
                style: AppTheme.mono,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('e.g. 45'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Positive number required';
                  if (_preferredStart + n > 1439) return 'Ends after 23:59';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _FieldLabel('PREFERRED START'),
              _PrefStartTile(
                label: TimeFormat.hhmmAmPm(_preferredStart),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              _FieldLabel('PRIORITY'),
              Row(
                children: [
                  _PriorityPick(
                    label: '1 HIGH',
                    color: AppColors.high,
                    selected: _priority == 1,
                    onTap: () => setState(() => _priority = 1),
                  ),
                  const SizedBox(width: 8),
                  _PriorityPick(
                    label: '2 MED',
                    color: AppColors.medium,
                    selected: _priority == 2,
                    onTap: () => setState(() => _priority = 2),
                  ),
                  const SizedBox(width: 8),
                  _PriorityPick(
                    label: '3 LOW',
                    color: AppColors.low,
                    selected: _priority == 3,
                    onTap: () => setState(() => _priority = 3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldLabel('WHEN DOES IT RUN?'),
              _DateModeSelector(
                mode: _dateMode,
                specificDate: _specificDate,
                onModeChanged: (m) => setState(() => _dateMode = m),
                onPickDate: _pickSpecificDate,
              ),
              const SizedBox(height: 16),
              _FieldLabel('SENSITIVITY'),
              SwitchListTile(
                value: _isStartSensitive,
                onChanged: (v) => setState(() => _isStartSensitive = v),
                activeTrackColor: AppColors.high,
                activeThumbColor: AppColors.canvas,
                title: const Text(
                  'Start sensitive',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Cannot begin before ${TimeFormat.hhmm(_preferredStart)}',
                  style: AppTheme.bodyMuted,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isEndSensitive,
                onChanged: (v) => setState(() => _isEndSensitive = v),
                activeTrackColor: AppColors.medium,
                activeThumbColor: AppColors.canvas,
                title: const Text(
                  'End sensitive',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Must finish by ${TimeFormat.hhmm(_preferredStart + (int.tryParse(_duration.text) ?? 0))}',
                  style: AppTheme.bodyMuted,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              if (_isStartSensitive && _isEndSensitive) ...[
                const SizedBox(height: 8),
                const Text(
                  '\u26A0 Both flags on = LOCKED event. The scheduler will pin this exactly.',
                  style: TextStyle(
                    color: AppColors.conflict,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: NeoButton(
                  label: _isEditing ? 'SAVE CHANGES' : 'CREATE TASK',
                  onPressed: _save,
                  background: AppColors.low,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.bodyMuted,
      filled: true,
      fillColor: AppColors.canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medium, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTheme.bodyMuted.copyWith(
          fontFamily: AppTheme.monoStack,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrefStartTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrefStartTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.medium),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.mono.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.medium,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PriorityPick extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityPick({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 2,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3))]
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.canvas : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Segmented control for task date assignment: recurring (every day), today,
/// or a specific calendar day (future or past).
class _DateModeSelector extends StatelessWidget {
  final _DateMode mode;
  final DateTime specificDate;
  final ValueChanged<_DateMode> onModeChanged;
  final VoidCallback onPickDate;

  const _DateModeSelector({
    required this.mode,
    required this.specificDate,
    required this.onModeChanged,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ModeOption(
              label: 'EVERY DAY',
              selected: mode == _DateMode.recurring,
              onTap: () => onModeChanged(_DateMode.recurring),
            ),
            const SizedBox(width: 8),
            _ModeOption(
              label: 'TODAY',
              selected: mode == _DateMode.today,
              onTap: () => onModeChanged(_DateMode.today),
            ),
            const SizedBox(width: 8),
            _ModeOption(
              label: 'PICK A DAY',
              selected: mode == _DateMode.specific,
              onTap: () => onModeChanged(_DateMode.specific),
            ),
          ],
        ),
        if (mode == _DateMode.specific) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.medium,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TimeFormat.isoDate(specificDate),
                    style: AppTheme.mono.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.medium,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.low : AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.low : AppColors.border,
            width: 2,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3))]
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.mono.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.canvas : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
