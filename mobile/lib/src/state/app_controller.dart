import 'package:flutter/foundation.dart';

import '../models/placed_task.dart';
import '../models/task.dart';
import '../services/api_client.dart';

/// Central app state: task collection, the active "wake" time, the latest
/// computed timeline and the Pass 2 conflict list.
class AppController extends ChangeNotifier {
  final ApiClient api;

  AppController({ApiClient? api}) : api = api ?? ApiClient();

  List<Task> _tasks = [];
  List<PlacedTask> _timeline = [];
  List<Task> _conflicts = [];
  int _wakeTime = 7 * 60; // default 07:00
  bool _loading = false;
  bool _reflowing = false;
  String? _error;

  List<Task> get tasks => _tasks;
  List<PlacedTask> get timeline => _timeline;
  List<Task> get conflicts => _conflicts;
  int get wakeTime => _wakeTime;
  bool get loading => _loading;
  bool get reflowing => _reflowing;
  String? get error => _error;

  void setWakeTime(int minutes) {
    if (_wakeTime == minutes) return;
    _wakeTime = minutes;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await api.listTasks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reflow() async {
    _reflowing = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.schedule(_wakeTime);
      _timeline = result.timeline;
      _conflicts = result.conflicts;
    } catch (e) {
      _error = e.toString();
    } finally {
      _reflowing = false;
      notifyListeners();
    }
  }

  /// Refreshes tasks then recomputes the schedule. Used after any mutation so
  /// drops/edits are reflected immediately in the timeline.
  Future<void> refresh() async {
    try {
      _tasks = await api.listTasks();
      final result = await api.schedule(_wakeTime);
      _timeline = result.timeline;
      _conflicts = result.conflicts;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await api.createTask(task);
    await refresh();
  }

  Future<void> updateTask(Task task) async {
    await api.updateTask(task);
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await api.deleteTask(id);
    await refresh();
  }

  /// Pass 2 manual-resolution helper: remove a conflicting task entirely.
  Future<void> dropConflict(Task task) async {
    await deleteTask(task.id);
  }

  /// Seeds a representative demo day so the reflow is visible immediately.
  Future<void> seedSampleDay() async {
    if (_tasks.isNotEmpty) {
      for (final t in _tasks.toList()) {
        await api.deleteTask(t.id);
      }
    }
    final samples = <Task>[
      Task(
        id: '',
        name: 'Sleep recovery buffer',
        duration: 90,
        preferredStart: 6 * 60,
        isStartSensitive: false,
        isEndSensitive: false,
        priority: 3,
      ),
      Task(
        id: '',
        name: 'Morning standup',
        duration: 30,
        preferredStart: 9 * 60,
        isStartSensitive: false,
        isEndSensitive: true,
        priority: 1,
      ),
      Task(
        id: '',
        name: 'Deep work sprint',
        duration: 150,
        preferredStart: 9 * 60 + 45,
        isStartSensitive: true,
        isEndSensitive: false,
        priority: 1,
      ),
      Task(
        id: '',
        name: 'Lunch',
        duration: 60,
        preferredStart: 12 * 60 + 30,
        isStartSensitive: false,
        isEndSensitive: false,
        priority: 2,
      ),
      Task(
        id: '',
        name: '1:1 with Ada',
        duration: 45,
        preferredStart: 15 * 60,
        isStartSensitive: true,
        isEndSensitive: true,
        priority: 2,
      ),
      Task(
        id: '',
        name: 'Exercise',
        duration: 60,
        preferredStart: 17 * 60,
        isStartSensitive: false,
        isEndSensitive: false,
        priority: 3,
      ),
      Task(
        id: '',
        name: 'Inbox zero',
        duration: 30,
        preferredStart: 11 * 60,
        isStartSensitive: false,
        isEndSensitive: true,
        priority: 3,
      ),
    ];
    for (final t in samples) {
      await api.createTask(t);
    }
    await refresh();
  }
}