import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Format a date for display in a user-friendly format
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format a date in short format (MM/DD/YYYY)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format a date to ISO format (YYYY-MM-DD)
  static String formatIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Parse an ISO date string to DateTime
  static DateTime? parseIsoDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Calculate age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Get the difference between two dates in days
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Get a relative time string (e.g., "2 days ago", "Yesterday", "Today")
  static String getRelativeTimeString(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).round();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).round();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).round();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Format date for scan history display
  static String formatScanDate(DateTime date) {
    if (isToday(date)) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (isYesterday(date)) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else {
      return '${formatDate(date)} at ${DateFormat('h:mm a').format(date)}';
    }
  }
}