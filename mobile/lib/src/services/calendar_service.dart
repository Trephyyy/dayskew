import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show MissingPluginException;

import '../models/placed_task.dart';

/// Result of a "save day to calendar" run.
class DaySaveResult {
  final int created;
  final int failed;
  final String? calendarName;

  const DaySaveResult({
    required this.created,
    required this.failed,
    this.calendarName,
  });

  bool get ok => failed == 0 && created > 0;
}

/// Writes a computed timeline into the device's calendars (the OS calendar
/// accounts, which include Google Calendar when it's synced on the device).
///
/// Events are created under a dedicated "DaySkew" calendar so the day is easy
/// to find and clean up. On unsupported platforms (web/desktop) a friendly
/// error is surfaced instead of a crash.
class CalendarService {
  static const String _calendarName = 'DaySkew';

  final DeviceCalendarPlugin _plugin;

  CalendarService({DeviceCalendarPlugin? plugin})
    : _plugin = plugin ?? DeviceCalendarPlugin();

  /// Saves every placed task on [date] as an event in the DaySkew calendar.
  ///
  /// [date] is the local calendar day (the selected day in the app). Times are
  /// computed minutes-since-midnight so the events land at the device's local
  /// clock.
  Future<DaySaveResult> saveDay({
    required DateTime date,
    required List<PlacedTask> timeline,
  }) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      default:
        throw CalendarUnsupportedException(
          'Saving to the device calendar is only available on Android, iOS and macOS.',
        );
    }
    if (timeline.isEmpty) {
      throw CalendarNothingToSaveException();
    }

    bool granted;
    try {
      final permission = await _plugin.requestPermissions();
      granted = permission.data == true;
    } on MissingPluginException {
      throw CalendarUnsupportedException(
        'Device calendar is not available on this platform.',
      );
    }
    if (!granted) {
      throw CalendarPermissionDeniedException();
    }

    final calendar = await _ensureDaySkewCalendar();
    if (calendar == null) {
      throw CalendarUnsupportedException(
        'No writable calendar found on this device.',
      );
    }

    final base = DateTime(date.year, date.month, date.day);
    int created = 0;
    int failed = 0;

    for (final placed in timeline) {
      final start = base.add(Duration(minutes: placed.computedStart));
      final end = base.add(Duration(minutes: placed.computedEnd));

      final event = Event(
        calendar.id,
        title: placed.task.name,
        description: _eventDescription(placed),
        start: TZDateTime.from(start, local),
        end: TZDateTime.from(end, local),
        availability: Availability.Busy,
        status: EventStatus.Confirmed,
      );

      final result = await _plugin.createOrUpdateEvent(event);
      if (result == null || !result.isSuccess) {
        failed++;
      } else {
        created++;
      }
    }

    return DaySaveResult(created: created, failed: failed);
  }

  /// Finds the DaySkew calendar, creating it if the platform supports local
  /// calendars. Picks an existing writable DaySkew calendar, else creates one,
  /// else falls back to the first writable calendar.
  Future<Calendar?> _ensureDaySkewCalendar() async {
    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess) return null;
    final calendars = calendarsResult.data ?? List.unmodifiable(<Calendar>[]);

    Calendar? firstWhere(bool Function(Calendar) test) {
      for (final c in calendars) {
        if (test(c)) return c;
      }
      return null;
    }

    final existing = firstWhere(
      (c) => c.name == _calendarName && c.isReadOnly == false,
    );
    if (existing != null) return existing;

    // Try to create it; if the platform rejects local calendars, fall back to
    // any writable calendar so the day still saves.
    final created = await _plugin.createCalendar(
      _calendarName,
      calendarColor: const Color(0xFFEC3750),
      localAccountName: 'DaySkew',
    );
    if (created.isSuccess && created.data != null) {
      return Calendar(id: created.data, name: _calendarName, isReadOnly: false);
    }

    return firstWhere((c) => c.isReadOnly == false);
  }

  String _eventDescription(PlacedTask placed) {
    final t = placed.task;
    final tier = t.isLocked
        ? 'LOCKED'
        : t.priority == 1
        ? 'HIGH'
        : t.priority == 2
        ? 'MED'
        : 'LOW';
    final sensitivities = <String>[
      if (t.isStartSensitive) 'start\u2265${t.preferredStart}',
      if (t.isEndSensitive) 'end\u2264${t.rigidEnd}',
    ];
    final flags = sensitivities.isEmpty ? '-' : sensitivities.join(', ');
    return 'DaySkew \u00b7 P$tier \u00b7 $flags';
  }
}

/// Writes events only when there's something to write.
class CalendarNothingToSaveException implements Exception {
  final String message;
  CalendarNothingToSaveException([this.message = 'The timeline is empty.']);
  @override
  String toString() => message;
}

class CalendarPermissionDeniedException implements Exception {
  final String message;
  CalendarPermissionDeniedException([
    this.message = 'Calendar permission was not granted.',
  ]);
  @override
  String toString() => message;
}

class CalendarUnsupportedException implements Exception {
  final String message;
  CalendarUnsupportedException(this.message);
  @override
  String toString() => message;
}
