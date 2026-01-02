import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
  }

  static String getGroupKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}

