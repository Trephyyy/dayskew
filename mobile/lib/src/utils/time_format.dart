/// Utilities for formatting "minutes since midnight" integers (0-1439) and
/// calendar dates ("YYYY-MM-DD").
abstract final class TimeFormat {
  /// `09:15` style 24h label.
  static String hhmm(int minutes) {
    final m = minutes % 1440;
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  /// `09:15 AM` style 12h label for the wake-up hero picker.
  static String hhmmAmPm(int minutes) {
    final m = minutes % 1440;
    final h24 = m ~/ 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mm = (m % 60).toString().padLeft(2, '0');
    final period = h24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $period';
  }

  /// Human drift label, e.g. `+1h 15m shift`, `-30m shift`, or `on time`.
  static String drift(int computedStart, int preferredStart) {
    final delta = computedStart - preferredStart;
    if (delta == 0) return 'on time';
    final sign = delta > 0 ? '+' : '-';
    final abs = delta.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    if (h > 0 && m > 0) return '$sign${h}h ${m}m shift';
    if (h > 0) return '$sign${h}h shift';
    return '$sign${m}m shift';
  }

  /// `+45m` style duration chip label.
  static String duration(int minutes) => '+${minutes}m';

  /// Human duration label, e.g. `1h 30m`.
  static String longDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// "YYYY-MM-DD" for a [DateTime]'s calendar day.
  static String isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// "YYYY-MM-DD" for today.
  static String todayIso() => isoDate(DateTime.now());

  /// Parses a "YYYY-MM-DD" (or RFC3339) into a DateTime, else null.
  static DateTime? tryParseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    DateTime? t;
    if (s.contains('T')) {
      t = DateTime.tryParse(s);
    } else {
      t = DateTime.tryParse('${s}T00:00:00');
    }
    return t;
  }

  /// "Tue" style weekday abbrev for a "YYYY-MM-DD" string.
  static String weekdayAbbrev(String date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = tryParseDate(date);
    if (d == null) return '?';
    // DateTime.weekday: Monday=1.
    return names[d.weekday - 1];
  }

  /// "Aug 26" style short label for a "YYYY-MM-DD" string.
  static String shortDate(String date) {
    final d = tryParseDate(date);
    if (d == null) return date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
