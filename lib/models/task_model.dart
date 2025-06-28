import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final String category;
  final String priority;
  final bool hasReminder;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    required this.category,
    required this.priority,
    required this.hasReminder,
    required this.isCompleted,
  });

  // Make sure toMap() handles nullable fields properly
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'dueTime': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
      'category': category,
      'priority': priority,
      'hasReminder': hasReminder,
      'isCompleted': isCompleted,
    };
  }

  // Make sure fromMap() handles nullable fields properly
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int) : null,
      dueTime: map['dueTime'] != null ? _timeOfDayFromString(map['dueTime'] as String) : null,
      category: map['category'] as String,
      priority: map['priority'] as String,
      hasReminder: map['hasReminder'] as bool,
      isCompleted: map['isCompleted'] as bool,
    );
  }

  // Helper method to convert string to TimeOfDay
  static TimeOfDay _timeOfDayFromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Make sure copyWith() handles nullable fields properly
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? category,
    String? priority,
    bool? hasReminder,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      hasReminder: hasReminder ?? this.hasReminder,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
