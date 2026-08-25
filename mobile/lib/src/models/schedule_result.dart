import 'placed_task.dart';
import 'task.dart';

/// Output of a scheduling run: a chronological timeline plus any unplaceable
/// tasks (Pass 2 conflict list) for the user to resolve manually.
class ScheduleResult {
  final List<PlacedTask> timeline;
  final List<Task> conflicts;

  const ScheduleResult({required this.timeline, required this.conflicts});

  factory ScheduleResult.fromJson(Map<String, dynamic> json) {
    final timeline = (json['timeline'] as List<dynamic>? ?? [])
        .map((e) => PlacedTask.fromJson(e as Map<String, dynamic>))
        .toList();
    final conflicts = (json['conflicts'] as List<dynamic>? ?? [])
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
    return ScheduleResult(timeline: timeline, conflicts: conflicts);
  }
}