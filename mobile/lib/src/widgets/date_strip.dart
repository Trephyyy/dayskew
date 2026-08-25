import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

/// Horizontal day navigator: today + the next two weeks plus a jump-to-date
/// picker. Tapping a day reloads that day's schedule.
class DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const DateStrip({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _JumpTodayChip(
            active: selected == todayDay,
            onTap: () => onSelected(todayDay),
          ),
          for (var i = 0; i < 14; i++)
            _DayChip(
              day: todayDay.add(Duration(days: i)),
              selectedIso: TimeFormat.isoDate(selected),
              isToday: i == 0,
              onTap: () => onSelected(todayDay.add(Duration(days: i))),
            ),
          _CalendarJumpChip(onSelected: onSelected),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final String selectedIso;
  final bool isToday;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.selectedIso,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iso = TimeFormat.isoDate(day);
    final selected = iso == selectedIso;
    final fg = selected ? AppColors.canvas : AppColors.textPrimary;
    final bg = selected ? AppColors.medium : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.medium : AppColors.border,
            width: 2,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.medium, offset: Offset(3, 3))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'TODAY' : TimeFormat.weekdayAbbrev(iso).toUpperCase(),
              style: AppTheme.mono.copyWith(
                fontSize: 9,
                letterSpacing: 0.8,
                color: selected ? AppColors.canvas : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day.day.toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpTodayChip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _JumpTodayChip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.low : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.low : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny_outlined,
                size: 20,
                color: active ? AppColors.canvas : AppColors.conflict),
            const SizedBox(height: 3),
            Text(
              'NOW',
              style: AppTheme.mono.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.canvas : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarJumpChip extends StatelessWidget {
  final ValueChanged<DateTime> onSelected;

  const _CalendarJumpChip({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year),
          lastDate: DateTime(now.year + 5),
          helpText: 'Jump to a day',
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        width: 58,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: const Icon(Icons.calendar_month_outlined,
            color: AppColors.textMuted, size: 22),
      ),
    );
  }
}