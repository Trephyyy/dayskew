import 'task.dart';

/// A successfully scheduled task with its computed absolute start/end.
class PlacedTask {
  final Task task;
  final int computedStart;
  final int computedEnd;

  const PlacedTask({
    required this.task,
    required this.computedStart,
    required this.computedEnd,
  });

  factory PlacedTask.fromJson(Map<String, dynamic> json) {
    return PlacedTask(
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
      computedStart: json['computedStart'] as int,
      computedEnd: json['computedEnd'] as int,
    );
  }
}