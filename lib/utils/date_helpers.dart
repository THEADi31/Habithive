/// Small helpers on DateTime (Dart extension methods).
extension DateHelpers on DateTime {
  /// "2026-10-10" - used as the key when storing completed days.
  String get dateKey =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Same date at 00:00 local time.
  DateTime get dayOnly => DateTime(year, month, day);

  /// Add (or subtract, if negative) whole calendar days, safe across DST.
  DateTime addDays(int n) => DateTime(year, month, day + n);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
