/// Adds [months] calendar months to [date], clipping the day-of-month
/// instead of overflowing into the following month.
///
/// e.g. Jan 31 + 1 month => Feb 28 (or 29 in a leap year), not Mar 3.
DateTime addMonths(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;
  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  );
}
