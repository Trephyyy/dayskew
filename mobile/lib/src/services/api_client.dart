import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule_result.dart';
import '../models/task.dart';

/// Thin, stateless REST client for the dayskew Go API.
///
/// The base URL defaults to a local backend. Override at build/run time with
/// `--dart-define=API_BASE_URL=http://host:8080`. On Android emulators the
/// host's localhost is reachable at `10.0.2.2`.
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Production API. The `/api` prefix is stripped by a reverse proxy on the
  /// server to reach the backend's root routes. Local dev can override with
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080` (emulator host).
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return 'https://dayskew.danailmihov.com/api';
  }

  Future<List<Task>> listTasks() async {
    final json = await _get('/tasks');
    return (json as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(Task task) async {
    final json = await _send(
      'POST',
      '/tasks',
      body: task.toCreateJson(),
      expected: 201,
    );
    return Task.fromJson(json as Map<String, dynamic>);
  }

  Future<Task> updateTask(Task task) async {
    final json =
        await _send('PUT', '/tasks/${task.id}', body: task.toUpdateJson());
    return Task.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/tasks/$id'));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw ApiException.fromResponse(res);
    }
  }

  Future<ScheduleResult> schedule(int currentTime) async {
    final json = await _send('POST', '/schedule', body: {
      'currentTime': currentTime,
    });
    return ScheduleResult.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path) async {
    final res = await _client.get(Uri.parse('$baseUrl$path'));
    if (res.statusCode != 200) throw ApiException.fromResponse(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    required Map<String, dynamic> body,
    int expected = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    final encoded = jsonEncode(body);
    final res = method == 'POST'
        ? await _client.post(uri, headers: headers, body: encoded)
        : await _client.put(uri, headers: headers, body: encoded);
    if (res.statusCode != expected) throw ApiException.fromResponse(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  factory ApiException.fromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // non-JSON body; keep the generic message
    }
    return ApiException(res.statusCode, message);
  }

  @override
  String toString() => message;
}