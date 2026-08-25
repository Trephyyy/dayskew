/// Mirror of the backend `task.Task` entity.
///
/// All times are "minutes since midnight" (0-1439). A task with both
/// sensitivity flags set is a "Locked" event forming the day's skeleton.
class Task {
  final String id;
  final String name;
  final int duration;
  final int preferredStart;
  final bool isStartSensitive;
  final bool isEndSensitive;
  final int priority;

  const Task({
    required this.id,
    required this.name,
    required this.duration,
    required this.preferredStart,
    required this.isStartSensitive,
    required this.isEndSensitive,
    required this.priority,
  });

  /// [id] is filled in by the backend on create.
  Task copyWith({
    String? id,
    String? name,
    int? duration,
    int? preferredStart,
    bool? isStartSensitive,
    bool? isEndSensitive,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      preferredStart: preferredStart ?? this.preferredStart,
      isStartSensitive: isStartSensitive ?? this.isStartSensitive,
      isEndSensitive: isEndSensitive ?? this.isEndSensitive,
      priority: priority ?? this.priority,
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
      };

  /// JSON for PUT /tasks/{id}.
  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        ...toCreateJson(),
      };
}