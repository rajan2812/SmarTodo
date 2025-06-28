import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:smart_todo/models/task_model.dart';
import 'package:smart_todo/utils/time_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Store notifications for in-app display
  final List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // Initialize the notification service
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

      // Define notification settings
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      final initialized = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );

      print('Notifications initialized: $initialized');

      // Request permissions for iOS
      if (Platform.isIOS) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestPermission();
      }

      // Load saved notifications
      await _loadNotifications();

      _isInitialized = true;
      print('NotificationService initialization completed successfully');
      return true;
    } catch (e) {
      print('Error in NotificationService.init(): $e');
      return false;
    }
  }

  // Save notifications to persistent storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toMap()))
          .toList();
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Load notifications from persistent storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];

      _notifications.clear();
      for (final json in notificationsJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _notifications.add(NotificationItem.fromMap(map));
        } catch (e) {
          print('Error parsing notification: $e');
        }
      }

      // Sort notifications by time (newest first)
      _notifications.sort((a, b) => b.time.compareTo(a.time));
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Handle iOS foreground notification
  Future<void> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    print('Received iOS notification: $title');
  }

  // Handle notification tap
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Here you could navigate to the task details page
  }

  // Schedule a reminder for a task
  Future<bool> scheduleTaskReminder(Task task) async {
    if (!await init()) return false;
    if (!task.hasReminder || task.dueDate == null) return false;

    try {
      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: const Color(0xFF7B42F6),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        // Use default sound
        sound: null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Use default sound
        sound: null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate notification time (15 minutes before due time)
      final dueDateTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.dueTime?.hour ?? 9,
        task.dueTime?.minute ?? 0,
      );

      final reminderTime = dueDateTime.subtract(const Duration(minutes: 15));
      final now = DateTime.now();

      // Only schedule if the time is in the future
      if (reminderTime.isAfter(now)) {
        final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

        // Format the notification message
        final dueTimeText = task.dueTime != null
            ? 'at ${task.dueTime!.format12Hour()}'
            : '';
        final dueText = formatDateForNotification(task.dueDate!);

        // Schedule the notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          task.id.hashCode,
          'Upcoming Task: ${task.title}',
          'Due $dueText $dueTimeText',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );

        print('Scheduled notification for task ${task.id} at $scheduledDate');

        // Add to in-app notifications
        addNotification(
          NotificationItem(
            id: task.id.hashCode,
            title: 'Upcoming Task: ${task.title}',
            body: 'Due $dueText $dueTimeText',
            time: DateTime.now(),
            isRead: false,
            taskId: task.id,
            scheduledTime: reminderTime,
          ),
        );

        return true;
      } else {
        print('Cannot schedule notification for past time: $reminderTime');
        return false;
      }
    } catch (e) {
      print('Error scheduling task reminder: $e');
      return false;
    }
  }

  // Show an immediate test notification
  Future<bool> showTestNotification() async {
    if (!await init()) return false;

    try {
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notifications channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        // Use default sound
        sound: null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Use default sound
        sound: null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        'Test Notification',
        'This is a test notification to verify that notifications are working',
        notificationDetails,
      );

      print('Test notification sent');

      // Add to in-app notifications
      addNotification(
        NotificationItem(
          id: 0,
          title: 'Test Notification',
          body: 'This is a test notification to verify that notifications are working',
          time: DateTime.now(),
          isRead: false,
          taskId: 'test',
          scheduledTime: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error showing test notification: $e');
      return false;
    }
  }

  // Cancel a specific task reminder
  Future<void> cancelTaskReminder(String taskId) async {
    if (!await init()) return;

    try {
      await flutterLocalNotificationsPlugin.cancel(taskId.hashCode);

      // Remove from in-app notifications
      _notifications.removeWhere((notification) => notification.taskId == taskId);
      await _saveNotifications();

      print('Cancelled reminder for task $taskId');
    } catch (e) {
      print('Error cancelling task reminder: $e');
    }
  }

  // Cancel all reminders
  Future<void> cancelAllReminders() async {
    if (!await init()) return;

    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      _notifications.clear();
      await _saveNotifications();

      print('Cancelled all reminders');
    } catch (e) {
      print('Error cancelling all reminders: $e');
    }
  }

  // Show an immediate notification for a task
  Future<bool> showTaskNotification(Task task) async {
    if (!await init()) return false;

    try {
      final androidDetails = AndroidNotificationDetails(
        'task_notifications',
        'Task Notifications',
        channelDescription: 'Notifications for tasks',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF7B42F6),
        // Use default sound
        sound: null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Use default sound
        sound: null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        task.id.hashCode,
        'Task Reminder',
        task.title,
        notificationDetails,
        payload: task.id,
      );

      print('Showed immediate notification for task ${task.id}');

      // Add to in-app notifications
      addNotification(
        NotificationItem(
          id: task.id.hashCode,
          title: 'Task Reminder',
          body: task.title,
          time: DateTime.now(),
          isRead: false,
          taskId: task.id,
          scheduledTime: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error showing task notification: $e');
      return false;
    }
  }

  // Add a notification to the in-app list
  void addNotification(NotificationItem notification) {
    // Check if notification with same ID already exists
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    if (existingIndex != -1) {
      _notifications[existingIndex] = notification;
    } else {
      _notifications.add(notification);
    }

    // Sort notifications by time (newest first)
    _notifications.sort((a, b) => b.time.compareTo(a.time));

    // Limit to 20 notifications
    if (_notifications.length > 20) {
      _notifications.removeLast();
    }

    _saveNotifications();
  }

  // Mark a notification as read
  void markNotificationAsRead(int id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
      _saveNotifications();
    }
  }

  // Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _saveNotifications();
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _saveNotifications();
  }

  // Get the count of unread notifications
  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;

  // Check if notifications are pending
  Future<List<dynamic>> getPendingNotifications() async {
    if (!await init()) return [];
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Check if a specific notification is pending
  Future<bool> isNotificationPending(int id) async {
    final pendingNotifications = await getPendingNotifications();
    return pendingNotifications.any((notification) => notification.id == id);
  }

  // Reschedule all task reminders
  Future<void> rescheduleAllReminders(List<Task> tasks) async {
    if (!await init()) return;

    // Cancel all existing reminders
    await cancelAllReminders();

    // Schedule reminders for all tasks with reminders
    for (final task in tasks) {
      if (task.hasReminder && task.dueDate != null && !task.isCompleted) {
        await scheduleTaskReminder(task);
      }
    }
  }

  // Helper method to format date for notification
  String formatDateForNotification(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'today';
    } else if (dateOnly == tomorrow) {
      return 'tomorrow';
    } else {
      return 'on ${date.month}/${date.day}';
    }
  }
}

// Model for in-app notifications
class NotificationItem {
  final int id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final String taskId;
  final DateTime? scheduledTime;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.taskId,
    this.scheduledTime,
  });

  NotificationItem copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? time,
    bool? isRead,
    String? taskId,
    DateTime? scheduledTime,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      taskId: taskId ?? this.taskId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time.millisecondsSinceEpoch,
      'isRead': isRead,
      'taskId': taskId,
      'scheduledTime': scheduledTime?.millisecondsSinceEpoch,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int),
      isRead: map['isRead'] as bool,
      taskId: map['taskId'] as String,
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] as int)
          : null,
    );
  }
}
