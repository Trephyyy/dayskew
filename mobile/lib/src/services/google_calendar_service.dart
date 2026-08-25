import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;

import '../models/placed_task.dart';

/// Result of a "save day to Google Calendar" run.
class DaySaveResult {
  final int created;
  final int failed;
  final String calendarName;

  const DaySaveResult({
    required this.created,
    required this.failed,
    this.calendarName = 'DaySkew',
  });

  bool get ok => failed == 0 && created > 0;
}

/// Writes a computed timeline into the user's Google Calendar via the Google
/// Calendar API. Uses OAuth (google_sign_in) and keeps everything in a
/// dedicated \"DaySkew\" calendar.
///
/// Requires a Google OAuth client configured for this app. Provide the web
/// (server) client id at build time:
///   flutter run --dart-define=GOOGLE_CLIENT_ID={{web-client-id}}
/// On Android, the app package + SHA-1 must also be registered in Google Cloud
/// Console; otherwise the sign-in prompt fails with a platform error.
class GoogleCalendarService {
  static const String calendarName = 'DaySkew';
  static const String calendarScope =
      'https://www.googleapis.com/auth/calendar';

  /// Optional web/server OAuth client id, injected with --dart-define.
  static const String configuredClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  final GoogleSignIn _signIn;
  bool _initialized = false;

  GoogleCalendarService() : _signIn = GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Must be called exactly once and completed before any other call.
    await _signIn.initialize(
      serverClientId:
          configuredClientId.isEmpty ? null : configuredClientId,
    );
    _initialized = true;
  }

  /// Returns the authenticated account, prompting if needed.
  Future<GoogleSignInAccount> _authenticate() async {
    await _ensureInitialized();

    final lightweight =
        await _signIn.attemptLightweightAuthentication();
    if (lightweight != null) return lightweight;

    try {
      return await _signIn.authenticate(scopeHint: [calendarScope]);
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw const CalendarAuthCancelledException();
        default:
          throw CalendarAuthException(
            'Google sign-in failed: ${e.description}. Is the OAuth client '
            'configured for this app?',
          );
      }
    }
  }

  Future<String> _accessToken(GoogleSignInAccount account) async {
    final client = account.authorizationClient;
    final authz = await client.authorizationForScopes([calendarScope]) ??
        await client.authorizeScopes([calendarScope]);
    return authz.accessToken;
  }

  /// Saves every placed task on [date] as a Google Calendar event.
  Future<DaySaveResult> saveDay({
    required DateTime date,
    required List<PlacedTask> timeline,
  }) async {
    if (timeline.isEmpty) {
      throw const CalendarNothingToSaveException();
    }

    final account = await _authenticate();
    final token = await _accessToken(account);

    final client = _AuthHttpClient(token);
    final api = cal.CalendarApi(client);
    try {
      final calendarId = await _ensureCalendar(api);

      int created = 0;
      int failed = 0;
      final base = DateTime(date.year, date.month, date.day);

      for (final placed in timeline) {
        final startLocal = base.add(Duration(minutes: placed.computedStart));
        final endLocal = base.add(Duration(minutes: placed.computedEnd));

        final event = cal.Event(
          summary: placed.task.name,
          description: _eventDescription(placed),
          start: cal.EventDateTime(dateTime: startLocal.toUtc()),
          end: cal.EventDateTime(dateTime: endLocal.toUtc()),
        );

        try {
          await api.events.insert(event, calendarId);
          created++;
        } catch (_) {
          failed++;
        }
      }

      return DaySaveResult(created: created, failed: failed);
    } finally {
      client.close();
    }
  }

  /// Finds the DaySkew calendar (by summary), creating it if missing.
  Future<String> _ensureCalendar(cal.CalendarApi api) async {
    final list = await api.calendarList.list();
    final existing = (list.items ?? [])
        .where((c) => c.summary == calendarName)
        .firstOrNull;
    if (existing?.id != null) return existing!.id!;

    final created = await api.calendars.insert(
      cal.Calendar(
        summary: calendarName,
        description: 'Computed days from DaySkew',
      ),
    );
    return created.id!;
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
      if (t.isStartSensitive) 'start>=${t.preferredStart}',
      if (t.isEndSensitive) 'end<=${t.rigidEnd}',
    ];
    final flags = sensitivities.isEmpty ? '-' : sensitivities.join(', ');
    return 'DaySkew · P$tier · $flags';
  }
}

class CalendarNothingToSaveException implements Exception {
  final String message;
  const CalendarNothingToSaveException([
    this.message = 'The timeline is empty.',
  ]);
  @override
  String toString() => message;
}

class CalendarAuthCancelledException implements Exception {
  final String message;
  const CalendarAuthCancelledException([
    this.message = 'Google sign-in was cancelled.',
  ]);
  @override
  String toString() => message;
}

class CalendarAuthException implements Exception {
  final String message;
  const CalendarAuthException(this.message);
  @override
  String toString() => message;
}

/// http.Client that attaches the Bearer token on every request.
class _AuthHttpClient extends http.BaseClient {
  _AuthHttpClient(this._token) : _inner = http.Client();

  final String _token;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}