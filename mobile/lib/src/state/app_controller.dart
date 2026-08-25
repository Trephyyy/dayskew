import 'package:flutter/foundation.dart';

import '../models/placed_task.dart';
import '../models/task.dart';
import '../services/api_client.dart';
import '../services/calendar_service.dart';
import '../utils/time_format.dart';

/// Central app state: task collection, the active "wake" time, the selected
/// calendar day, and the latest computed timeline + conflict list for it.
class AppController extends ChangeNotifier {
  final ApiClient api;
  final CalendarService calendar;

  AppController({ApiClient? api, CalendarService? calendar})
    : api = api ?? ApiClient(),
      calendar = calendar ?? CalendarService();

  List<Task> _tasks = [];
  List<PlacedTask> _timeline = [];
  List<Task> _conflicts = [];
  int _wakeTime = 7 * 60; // default 07:00
  DateTime _selectedDate = DateTime.now();
  int _scheduleVersion = 0;
  bool _loading = false;
  bool _reflowing = false;
  String? _error;

  List<Task> get tasks => _tasks;
  List<PlacedTask> get timeline => _timeline;
  List<Task> get conflicts => _conflicts;
  int get wakeTime => _wakeTime;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateIso => TimeFormat.isoDate(_selectedDate);

  /// Bumped every time the schedule is recomputed, so views can animate on
  /// each refresh/update.
  int get scheduleVersion => _scheduleVersion;
  bool get loading => _loading;
  bool get reflowing => _reflowing;
  String? get error => _error;

  /// Tasks applicable to the selected day: recurring plus date-specific.
  List<Task> get tasksForSelectedDate => tasks
      .where((t) => t.isRecurring || t.scheduledDate == selectedDateIso)
      .toList();

  void setWakeTime(int minutes) {
    if (_wakeTime == minutes) return;
    _wakeTime = minutes;
    notifyListeners();
  }

  /// Sets the wake-up time to the device's current time, then reflows.
  Future<void> justWokeUp() async {
    final now = DateTime.now();
    setWakeTime(now.hour * 60 + now.minute);
    await reflow();
  }

  /// Writes the placed timeline for the selected day into the device
  /// calendar. Returns the number of events created.
  Future<DaySaveResult> saveDayToCalendar() async {
    return calendar.saveDay(date: _selectedDate, timeline: _timeline);
  }

  /// Switches the viewed day (past days allowed so scheduling today's early
  /// tasks against yesterday's remaining list still works) and reschedules.
  Future<void> selectDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    if (d == _selectedDate) return;
    _selectedDate = d;
    notifyListeners();
    await reflow();
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
      final result = await api.schedule(_wakeTime, date: selectedDateIso);
      _timeline = result.timeline;
      _conflicts = result.conflicts;
      _scheduleVersion++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _reflowing = false;
      notifyListeners();
    }
  }

  /// Refreshes tasks then recomputes the schedule for the selected day. Used
  /// after any mutation so drops/edits are reflected immediately in the timeline.
  Future<void> refresh() async {
    try {
      _tasks = await api.listTasks();
      final result = await api.schedule(_wakeTime, date: selectedDateIso);
      _timeline = result.timeline;
      _conflicts = result.conflicts;
      _scheduleVersion++;
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
