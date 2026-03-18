extension DateTimeX on DateTime {
  /// Start of day (midnight 00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// True if same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// True if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Add [months] clamping the day to avoid date drift.
  ///
  /// Jan 31 + 1 month → Feb 28 (not Mar 3).
  DateTime addMonths(int months) {
    final targetMonth = month + months;
    final targetYear = year + (targetMonth - 1) ~/ 12;
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final clampedDay = day > maxDay ? maxDay : day;
    return DateTime(targetYear, normalizedMonth, clampedDay);
  }
}
