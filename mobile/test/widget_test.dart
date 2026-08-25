import 'package:flutter_test/flutter_test.dart';

import 'package:dayskew/src/models/schedule_result.dart';
import 'package:dayskew/src/models/task.dart';
import 'package:dayskew/src/utils/time_format.dart';

void main() {
  group('TimeFormat', () {
    test('hhmm pads and converts minutes since midnight', () {
      expect(TimeFormat.hhmm(0), '00:00');
      expect(TimeFormat.hhmm(555), '09:15');
      expect(TimeFormat.hhmm(1439), '23:59');
    });

    test('hhmmAmPm renders 12h labels', () {
      expect(TimeFormat.hhmmAmPm(0), '12:00 AM');
      expect(TimeFormat.hhmmAmPm(555), '9:15 AM');
      expect(TimeFormat.hhmmAmPm(720), '12:00 PM');
      expect(TimeFormat.hhmmAmPm(915), '3:15 PM');
    });

    test('drift labels early, on-time and late placement', () {
      expect(TimeFormat.drift(540, 540), 'on time');
      expect(TimeFormat.drift(555, 510), '+45m shift');
      expect(TimeFormat.drift(450, 510), '-1h shift');
      expect(TimeFormat.drift(600, 510), '+1h 30m shift');
    });

    test('duration chips', () {
      expect(TimeFormat.duration(45), '+45m');
      expect(TimeFormat.longDuration(90), '1h 30m');
      expect(TimeFormat.longDuration(60), '1h');
      expect(TimeFormat.longDuration(30), '30m');
    });
  });

  group('models', () {
    test('Task.fromJson maps backend entity', () {
      final task = Task.fromJson({
        'id': '9d00c0fe-0dd4-4e64-be5b-3be78e844948',
        'name': 'Standup',
        'duration': 30,
        'preferredStart': 540,
        'isStartSensitive': false,
        'isEndSensitive': true,
        'priority': 1,
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      });
      expect(task.id, '9d00c0fe-0dd4-4e64-be5b-3be78e844948');
      expect(task.name, 'Standup');
      expect(task.duration, 30);
      expect(task.preferredStart, 540);
      expect(task.isStartSensitive, false);
      expect(task.isEndSensitive, true);
      expect(task.priority, 1);
      expect(task.isLocked, false);
      expect(task.rigidEnd, 570);
    });

    test('a task with both flags is locked', () {
      final task = Task.fromJson({
        'id': 'x',
        'name': '1:1',
        'duration': 45,
        'preferredStart': 900,
        'isStartSensitive': true,
        'isEndSensitive': true,
        'priority': 2,
      });
      expect(task.isLocked, true);
    });

    test('ScheduleResult.fromJson splits timeline from conflicts', () {
      final result = ScheduleResult.fromJson({
        'timeline': [
          {
            'task': {
              'id': 'a',
              'name': 'Placed',
              'duration': 30,
              'preferredStart': 540,
              'isStartSensitive': false,
              'isEndSensitive': false,
              'priority': 3,
            },
            'computedStart': 555,
            'computedEnd': 585,
          },
        ],
        'conflicts': [
          {
            'id': 'b',
            'name': 'Unplaced',
            'duration': 60,
            'preferredStart': 600,
            'isStartSensitive': true,
            'isEndSensitive': true,
            'priority': 1,
          },
        ],
      });
      expect(result.timeline, hasLength(1));
      expect(result.timeline.first.computedStart, 555);
      expect(result.timeline.first.computedEnd, 585);
      expect(result.timeline.first.task.name, 'Placed');
      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.first.name, 'Unplaced');
    });
  });
}