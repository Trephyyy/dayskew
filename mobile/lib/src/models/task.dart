/// Mirror of the backend `task.Task` entity.
///
/// All times are "minutes since midnight" (0-1439). A task with both
/// sensitivity flags set is a "Locked" event forming the day's skeleton.
///
/// [scheduledDate] is the calendar day ("YYYY-MM-DD") the task runs on, or
/// null for a recurring daily task. [timezone] interprets the minute-of-day
/// values when syncing to external calendars; [googleEventId] back-references
/// the synced Google Calendar event once calendar sync is wired up.
class Task {
  final String id;
  final String name;
  final int duration;
  final int preferredStart;
  final bool isStartSensitive;
  final bool isEndSensitive;
  final int priority;
  final String? scheduledDate;
  final String timezone;
  final String? googleEventId;

  const Task({
    required this.id,
    required this.name,
    required this.duration,
    required this.preferredStart,
    required this.isStartSensitive,
    required this.isEndSensitive,
    required this.priority,
    this.scheduledDate,
    this.timezone = 'UTC',
    this.googleEventId,
  });

  /// Recurring tasks apply to every day.
  bool get isRecurring => scheduledDate == null;

  /// [id] is filled in by the backend on create.
  Task copyWith({
    String? id,
    String? name,
    int? duration,
    int? preferredStart,
    bool? isStartSensitive,
    bool? isEndSensitive,
    int? priority,
    String? scheduledDate,
    bool clearScheduledDate = false,
    String? timezone,
    String? googleEventId,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      preferredStart: preferredStart ?? this.preferredStart,
      isStartSensitive: isStartSensitive ?? this.isStartSensitive,
      isEndSensitive: isEndSensitive ?? this.isEndSensitive,
      priority: priority ?? this.priority,
      scheduledDate: clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      timezone: timezone ?? this.timezone,
      googleEventId: googleEventId ?? this.googleEventId,
    );
  }

  bool get isLocked => isStartSensitive && isEndSensitive;

  /// Latest minute at which an end-sensitive task may finish.
  int get rigidEnd => preferredStart + duration;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: json['duration'] as int,
      preferredStart: json['preferredStart'] as int,
      isStartSensitive: json['isStartSensitive'] as bool,
      isEndSensitive: json['isEndSensitive'] as bool,
      priority: json['priority'] as int,
      scheduledDate: _normalizeDate(json['scheduledDate']),
      timezone: json['timezone'] as String? ?? 'UTC',
      googleEventId: json['googleEventId'] as String?,
    );
  }

  /// JSON for POST /tasks. The backend generates the id/timestamps.
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'duration': duration,
        'preferredStart': preferredStart,
        'isStartSensitive': isStartSensitive,
        'isEndSensitive': isEndSensitive,
        'priority': priority,
        'scheduledDate': scheduledDate,
        'timezone': timezone,
        'googleEventId': googleEventId,
      };

  /// JSON for PUT /tasks/{id}.
  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        ...toCreateJson(),
      };

  /// Backend may someday emit "YYYY-MM-DD" or RFC3339; normalize to
  /// "YYYY-MM-DD" so the app compares dates lexicographically.
  static String? _normalizeDate(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    final i = s.indexOf('T');
    return i > 0 ? s.substring(0, i) : s;
  }
}