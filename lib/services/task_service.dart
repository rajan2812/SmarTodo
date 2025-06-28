import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static final _uuid = Uuid();
  static final _notificationService = NotificationService();

  // Get all tasks
  static Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    return tasksJson
        .map((taskJson) => Task.fromMap(jsonDecode(taskJson)))
        .toList();
  }

  // Add a new task
  static Future<Task> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    required String category,
    required String priority,
    bool hasReminder = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      description: description ?? '',
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      priority: priority,
      hasReminder: hasReminder,
      isCompleted: false,
    );

    tasksJson.add(jsonEncode(newTask.toMap()));
    await prefs.setStringList(_tasksKey, tasksJson);

    // Schedule notification if reminder is enabled
    if (hasReminder && dueDate != null) {
      final success = await _notificationService.scheduleTaskReminder(newTask);
      print('Scheduled reminder for task ${newTask.id}: $success');

      // If scheduling failed, try a test notification
      if (!success) {
        await _notificationService.showTestNotification();
      }
    }

    return newTask;
  }

  // Update an existing task
  static Future<Task> updateTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    final tasksList = tasksJson
        .map((taskJson) => Task.fromMap(jsonDecode(taskJson)))
        .toList();

    final index = tasksList.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // Cancel existing reminder
      await _notificationService.cancelTaskReminder(task.id);

      // Update task
      tasksList[index] = task;

      final updatedTasksJson = tasksList
          .map((task) => jsonEncode(task.toMap()))
          .toList();

      await prefs.setStringList(_tasksKey, updatedTasksJson);

      // Schedule new reminder if needed
      if (task.hasReminder && task.dueDate != null && !task.isCompleted) {
        await _notificationService.scheduleTaskReminder(task);
      }

      return task;
    }

    throw Exception('Task not found');
  }

  // Delete a task
  static Future<void> deleteTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    final tasksList = tasksJson
        .map((taskJson) => Task.fromMap(jsonDecode(taskJson)))
        .toList();

    tasksList.removeWhere((task) => task.id == taskId);

    final updatedTasksJson = tasksList
        .map((task) => jsonEncode(task.toMap()))
        .toList();

    await prefs.setStringList(_tasksKey, updatedTasksJson);

    // Cancel reminder
    await _notificationService.cancelTaskReminder(taskId);
  }

  // Toggle task completion status
  static Future<Task> toggleTaskCompletion(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    final tasksList = tasksJson
        .map((taskJson) => Task.fromMap(jsonDecode(taskJson)))
        .toList();

    final index = tasksList.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = tasksList[index];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      tasksList[index] = updatedTask;

      final updatedTasksJson = tasksList
          .map((task) => jsonEncode(task.toMap()))
          .toList();

      await prefs.setStringList(_tasksKey, updatedTasksJson);

      // If task is completed, cancel reminder
      if (updatedTask.isCompleted) {
        await _notificationService.cancelTaskReminder(taskId);
      } else if (updatedTask.hasReminder && updatedTask.dueDate != null) {
        // If task is uncompleted and has reminder, reschedule it
        await _notificationService.scheduleTaskReminder(updatedTask);
      }

      return updatedTask;
    }

    throw Exception('Task not found');
  }

  // Get upcoming tasks (tasks due in the next 7 days)
  static Future<List<Task>> getUpcomingTasks() async {
    try {
      final tasks = await getTasks();

      // Get today and next 7 days
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = today.add(const Duration(days: 7));

      // Filter tasks for the next 7 days, excluding today
      return tasks.where((task) {
        if (task.dueDate == null || task.isCompleted) return false;

        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        return taskDate.isAfter(today) &&
            taskDate.isBefore(nextWeek) ||
            taskDate.isAtSameMomentAs(nextWeek);
      }).toList();
    } catch (e) {
      print('Error getting upcoming tasks: $e');
      return [];
    }
  }

  // Schedule reminders for all upcoming tasks
  static Future<void> scheduleAllReminders() async {
    try {
      final tasks = await getTasks();

      // Filter for tasks with reminders
      final tasksWithReminders = tasks.where((task) =>
      task.hasReminder &&
          task.dueDate != null &&
          !task.isCompleted
      ).toList();

      // Schedule each reminder
      for (final task in tasksWithReminders) {
        await _notificationService.scheduleTaskReminder(task);
      }

      print('Scheduled reminders for ${tasksWithReminders.length} tasks');
    } catch (e) {
      print('Error scheduling reminders: $e');
      // Don't rethrow - allow app to continue
    }
  }

  // Send a test notification
  static Future<bool> sendTestNotification() async {
    return await _notificationService.showTestNotification();
  }

  // Get pending notifications
  static Future<List<dynamic>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }
}
