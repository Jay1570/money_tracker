class TimeUtils {
  static String timeAgo(Object value) {
    late final DateTime date;

    if (value is String) {
      date = DateTime.parse(value);
    } else if (value is DateTime) {
      date = value;
    } else {
      throw ArgumentError('Expected String or DateTime');
    }

    return _timeAgo(date);
  }

  static String _timeAgo(DateTime date) {
    date = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  static const monthAbbreviations = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  static const weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday', //
  ];

  static String monthAbbreviation(int month) => monthAbbreviations[month - 1];

  static String monthYearLabel(DateTime date) =>
      '${monthAbbreviation(date.month)} ${date.year}';

  static String dayMonthLabel(DateTime date) =>
      '${date.day} ${monthAbbreviation(date.month)}';

  static String weekdayLabel(DateTime date) => weekdayNames[date.weekday - 1];
}
