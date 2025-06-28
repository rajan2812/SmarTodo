import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Extension method for TimeOfDay to format in 12-hour format
extension TimeOfDayExtension on TimeOfDay {
  String format12Hour() {
    final hour = this.hour % 12 == 0 ? 12 : this.hour % 12;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Convert TimeOfDay to DateTime for easier comparison and scheduling
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  // Check if this time is before another time
  bool isBefore(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  // Check if this time is after another time
  bool isAfter(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  // Format time for display in notification
  String formatForNotification() {
    return format12Hour();
  }
}

// Format a DateTime for display in notifications
String formatDateForNotification(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (dateToCheck.isAtSameMomentAs(today)) {
    return 'Today';
  } else if (dateToCheck.isAtSameMomentAs(tomorrow)) {
    return 'Tomorrow';
  } else {
    return DateFormat('MMM d').format(dateTime);
  }
}

// Get a user-friendly string for when a task is due
String getTaskDueText(DateTime? dueDate, TimeOfDay? dueTime) {
  if (dueDate == null) {
    return 'No due date';
  }

  final dateText = formatDateForNotification(dueDate);

  if (dueTime == null) {
    return 'Due $dateText';
  } else {
    return 'Due $dateText at ${dueTime.format12Hour()}';
  }
}
