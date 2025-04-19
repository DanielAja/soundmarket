import 'package:intl/intl.dart';

/// DateTime extension methods
extension DateTimeExtensions on DateTime {
  // Format date as "Jan 1, 2023"
  String get formatted {
    return DateFormat('MMM d, yyyy').format(this);
  }

  // Format date as "January 1, 2023"
  String get formattedLong {
    return DateFormat('MMMM d, yyyy').format(this);
  }

  // Format date as "01/01/2023"
  String get formattedNumeric {
    return DateFormat('MM/dd/yyyy').format(this);
  }

  // Format date as "2023-01-01"
  String get formattedISO {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  // Format time as "1:30 PM"
  String get formattedTime {
    return DateFormat('h:mm a').format(this);
  }

  // Format time as "13:30"
  String get formattedTime24 {
    return DateFormat('HH:mm').format(this);
  }

  // Format date and time as "Jan 1, 2023 1:30 PM"
  String get formattedDateTime {
    return DateFormat('MMM d, yyyy h:mm a').format(this);
  }

  // Format date and time as "2023-01-01T13:30:00"
  String get formattedISODateTime {
    return DateFormat('yyyy-MM-ddTHH:mm:ss').format(this);
  }

  // Format relative time (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Get start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  // Get end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  // Get start of week (Sunday)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday % 7));
  }

  // Get end of week (Saturday)
  DateTime get endOfWeek {
    return startOfWeek.add(
      const Duration(
        days: 6,
        hours: 23,
        minutes: 59,
        seconds: 59,
        milliseconds: 999,
      ),
    );
  }

  // Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  // Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  // Get start of year
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  // Get end of year
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  // Add days
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  // Subtract days
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  // Add weeks
  DateTime addWeeks(int weeks) {
    return add(Duration(days: weeks * 7));
  }

  // Subtract weeks
  DateTime subtractWeeks(int weeks) {
    return subtract(Duration(days: weeks * 7));
  }

  // Add months
  DateTime addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    return DateTime(newYear, newMonth, day);
  }

  // Subtract months
  DateTime subtractMonths(int months) {
    var newMonth = month - months;
    var newYear = year;

    while (newMonth <= 0) {
      newMonth += 12;
      newYear--;
    }

    return DateTime(newYear, newMonth, day);
  }

  // Add years
  DateTime addYears(int years) {
    return DateTime(year + years, month, day);
  }

  // Subtract years
  DateTime subtractYears(int years) {
    return DateTime(year - years, month, day);
  }

  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  // Check if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }

  // Check if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  // Check if date is in the same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  // Check if date is in the same week
  bool isSameWeek(DateTime other) {
    final thisWeekStart = startOfWeek;
    final otherWeekStart = other.startOfWeek;
    return thisWeekStart.isSameDay(otherWeekStart);
  }

  // Check if date is in the same month
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  // Check if date is in the same year
  bool isSameYear(DateTime other) {
    return year == other.year;
  }

  // Get day of year (1-366)
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }

  // Get week of year (1-53)
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final dayOfYear = difference(firstDayOfYear).inDays;
    return ((dayOfYear - firstDayOfYear.weekday + 10) / 7).floor();
  }

  // Get quarter (1-4)
  int get quarter {
    return ((month - 1) / 3).floor() + 1;
  }
}
