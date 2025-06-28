import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:smart_todo/widgets/modern_tab_bar.dart';
import 'package:smart_todo/utils/screenshot_util.dart';
import 'package:smart_todo/widgets/quick_add_task_form.dart';
import 'package:smart_todo/models/task_model.dart';
import 'package:smart_todo/services/task_service.dart';
import 'package:smart_todo/services/notification_service.dart';
import 'package:smart_todo/widgets/notification_panel.dart';
import 'package:smart_todo/utils/time_utils.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    this.userName = 'Rajan', // Default name for testing
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _cardAnimationController;
  late AnimationController _quickAddButtonController;
  final TextEditingController _quickTaskController = TextEditingController();

  // Add this to the _HomeScreenState class
  int _currentTabIndex = 0;

  // Add this field to the _HomeScreenState class
  final GlobalKey _screenshotKey = GlobalKey();

  // Replace the mock _todayTasks list with this:
  List<Task> _allTasks = [];
  List<Task> _todayTasks = [];
  List<Task> _upcomingTasks = [];
  bool _isLoadingTasks = true;
  bool _isLoadingUpcoming = true;
  bool _showNotifications = false;

  final NotificationService _notificationService = NotificationService();

  // Sample data for smart suggestions
  final List<Map<String, dynamic>> _suggestedTasks = [
    {
      'title': 'Review weekly goals',
      'category': 'Productivity',
      'reason': 'Based on your Monday routine',
    },
    {
      'title': 'Plan meals for the week',
      'category': 'Personal',
      'reason': 'You usually do this on Mondays',
    },
  ];

  // Dark color palette with rich gradients
  final List<Color> _colorPalette = [
    const Color(0xFF050314), // Ultra dark purple/black
    const Color(0xFF0F0524), // Very dark purple
    const Color(0xFF1A0B2E), // Dark purple
    const Color(0xFF00E1FF), // Cyan
    const Color(0xFFFF5B94), // Pink
    const Color(0xFF7B42F6), // Bright purple
  ];

  // Category colors
  final Map<String, Color> _categoryColors = {
    'Work': const Color(0xFF7B42F6),
    'Personal': const Color(0xFF00E1FF),
    'Health': const Color(0xFFFF5B94),
    'Productivity': const Color(0xFFFFD166),
  };

  // Priority colors
  final Map<String, Color> _priorityColors = {
    'High': const Color(0xFFFF5B94),
    'Medium': const Color(0xFFFFD166),
    'Low': const Color(0xFF00E1FF),
  };

  // Get greeting based on time of day
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // Calculate task completion percentage
  double get _completionPercentage {
    if (_todayTasks.isEmpty) return 0.0;
    final completedTasks = _todayTasks.where((task) => task.isCompleted).length;
    return completedTasks / _todayTasks.length;
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: false);

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Card animation controller
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Quick add button animation controller
    _quickAddButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize notification service
    _notificationService.init();

    // Fetch tasks when the screen loads
    _fetchTasks();
    _fetchUpcomingTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _cardAnimationController.dispose();
    _quickAddButtonController.dispose();
    _quickTaskController.dispose();
    super.dispose();
  }

  void _toggleTaskCompletion(String taskId) async {
    try {
      // Toggle task completion in the service
      final updatedTask = await TaskService.toggleTaskCompletion(taskId);

      setState(() {
        // Update the task in the lists
        final taskIndex = _todayTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          _todayTasks[taskIndex] = updatedTask;
        }

        final allTaskIndex = _allTasks.indexWhere((task) => task.id == taskId);
        if (allTaskIndex != -1) {
          _allTasks[allTaskIndex] = updatedTask;
        }

        final upcomingIndex = _upcomingTasks.indexWhere((task) => task.id == taskId);
        if (upcomingIndex != -1) {
          _upcomingTasks[upcomingIndex] = updatedTask;
        }
      });
    } catch (e) {
      print('Error toggling task completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addQuickTask() async {
    if (_quickTaskController.text.isNotEmpty) {
      try {
        // Get today's date
        final today = DateTime.now();

        // Add the task
        final newTask = await TaskService.addTask(
          title: _quickTaskController.text,
          category: 'Personal',
          priority: 'Medium',
          dueDate: today,
        );

        setState(() {
          _todayTasks.add(newTask);
          _allTasks.add(newTask);
          _quickTaskController.clear();
        });

        // Show success animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: _colorPalette[3]),
                const SizedBox(width: 12),
                const Text('Task added successfully'),
              ],
            ),
            backgroundColor: Colors.black.withOpacity(0.7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error adding task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startVoiceInput() {
    // Would implement voice recognition here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: _colorPalette[4]),
            const SizedBox(width: 12),
            const Text('Voice input activated'),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _startFocusMode() {
    // Would navigate to focus mode screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.timer, color: _colorPalette[3]),
            const SizedBox(width: 12),
            const Text('Focus mode activated'),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Add this method to the _HomeScreenState class
  void _showQuickAddTaskForm() {
    // Play button animation
    _quickAddButtonController.forward(from: 0.0);

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuickAddTaskForm(
          onTaskAdded: (Task task) {
            // Refresh tasks after adding a new one
            _fetchTasks();
            _fetchUpcomingTasks();
          },
          colorPalette: _colorPalette,
        );
      },
    );
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }

  // Add this method to test notifications
  void _testNotifications() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Sending test notification...'),
          ],
        ),
        backgroundColor: _colorPalette[2],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Send test notification
    final success = await _notificationService.showTestNotification();

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Test notification sent successfully!'
              : 'Failed to send test notification. Check console for details.',
        ),
        backgroundColor: success ? _colorPalette[5] : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  // Modify the build method to wrap the main content with RepaintBoundary
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _colorPalette[0],
      extendBody: true, // Allow content to go behind bottom nav bar
      body: Stack(
        children: [
          // Animated dark gradient background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: DarkGradientBackgroundPainter(
                  animation: _backgroundController.value,
                  colors: [
                    _colorPalette[0],
                    _colorPalette[1],
                    _colorPalette[2],
                    _colorPalette[5],
                  ],
                ),
                size: size,
              );
            },
          ),

          // Main content wrapped with RepaintBoundary for screenshots
          RepaintBoundary(
            key: _screenshotKey,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar with user greeting and menu
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: true,
                    title: Row(
                      children: [
                        // User avatar with cosmic glow
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    _colorPalette[3],
                                    _colorPalette[4],
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _colorPalette[3].withOpacity(0.3 + 0.2 * _pulseController.value),
                                    blurRadius: 10 + 5 * _pulseController.value,
                                    spreadRadius: 1 + _pulseController.value,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        // Greeting text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      // Notifications button with badge
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, size: 26),
                            onPressed: _toggleNotifications,
                          ),
                          if (_notificationService.unreadCount > 0)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _colorPalette[4],
                                  border: Border.all(
                                    color: _colorPalette[0],
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Test notification button
                      IconButton(
                        icon: const Icon(Icons.notification_add, size: 26),
                        onPressed: _testNotifications,
                        tooltip: 'Test Notifications',
                      ),
                      // Menu button
                      IconButton(
                        icon: const Icon(Icons.menu, size: 26),
                        onPressed: () {
                          // Would open drawer or menu
                        },
                      ),
                    ],
                  ),

                  // Content sections
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),

                        // Task progress and quick add in a row
                        _buildTopRow(),

                        const SizedBox(height: 24),

                        // Today's tasks section
                        _buildTodayTasksSection(),

                        const SizedBox(height: 24),

                        // Upcoming reminders section
                        _buildUpcomingRemindersSection(),

                        const SizedBox(height: 24),

                        // Smart suggestions and Focus mode in a row
                        _buildSuggestionsAndFocusRow(),

                        const SizedBox(height: 24),

                        // Productivity insights section
                        _buildProductivityInsightsSection(),

                        const SizedBox(height: 100), // Bottom padding for FAB and nav bar
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification panel
          if (_showNotifications)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NotificationPanel(
                onClose: _toggleNotifications,
                colorPalette: _colorPalette,
              ),
            ),
        ],
      ),
      // Add a floating action button for taking screenshots
      floatingActionButton: FloatingActionButton(
        backgroundColor: _colorPalette[3],
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () async {
          final path = await ScreenshotUtil.captureAndSaveScreenshot(_screenshotKey);
          if (path != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Screenshot saved to: $path'),
                backgroundColor: _colorPalette[5],
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to take screenshot'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
      // Replace the existing bottomNavigationBar in the Scaffold with this:
      bottomNavigationBar: ModernTabBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          // Here you would handle navigation to different screens
          // For example, using a PageView or Navigator
        },
        activeColor: _colorPalette[3], // Cyan
        backgroundColor: _colorPalette[0].withOpacity(0.9),
        items: const [
          TabItemData(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
          ),
          TabItemData(
            label: 'Tasks',
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
          ),
          TabItemData(
            label: 'Notes',
            icon: Icons.note_outlined,
            activeIcon: Icons.note,
          ),
          TabItemData(
            label: 'Insights',
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
          ),
          TabItemData(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ],
      ),
    );
  }

  // Top row with task progress and quick add
  Widget _buildTopRow() {
    return Column(
      children: [
        // Task progress card (full width)
        _buildAnimatedCard(
          child: _buildTaskProgressSection(),
          delay: 0,
        ),
        const SizedBox(height: 24),
        // Quick add card (full width)
        _buildAnimatedCard(
          child: _buildQuickAddTaskSection(),
          delay: 0.1,
        ),
      ],
    );
  }

  // Suggestions and Focus mode row
  Widget _buildSuggestionsAndFocusRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Smart suggestions (full width)
        _buildAnimatedCard(
          child: _buildSmartSuggestionsSection(),
          delay: 0.3,
        ),
        const SizedBox(height: 24),
        // Focus mode (full width)
        _buildAnimatedCard(
          child: _buildFocusModeLauncher(),
          delay: 0.4,
        ),
      ],
    );
  }

  // Animated card wrapper
  Widget _buildAnimatedCard({required Widget child, required double delay}) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        final delayedAnimation = Curves.easeOutCubic.transform(
          math.max(0, math.min(1, (_cardAnimationController.value - delay) / (1 - delay))),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - delayedAnimation)),
          child: Opacity(
            opacity: delayedAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Task progress section
  Widget _buildTaskProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorPalette[2].withOpacity(0.6),
            _colorPalette[1].withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _refreshTodayTasks,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _colorPalette[3],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingTasks)
            Center(
              child: CircularProgressIndicator(
                color: _colorPalette[3],
              ),
            )
          else
            Row(
              children: [
                // Progress indicator
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Progress circle
                      Center(
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: _completionPercentage),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(_colorPalette[3]),
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                        ),
                      ),
                      // Percentage text
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: _completionPercentage),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Task summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_todayTasks.where((task) => task.isCompleted).length} of ${_todayTasks.length} tasks completed',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _todayTasks.isEmpty
                            ? 'No tasks for today yet'
                            : _completionPercentage < 0.3
                            ? 'Keep going! You\'ve got this.'
                            : _completionPercentage < 0.7
                            ? 'Good progress! Keep it up.'
                            : 'Almost there! Finish strong.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mini task categories
                      if (_todayTasks.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _getCategoryCounts().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildMiniCategory(entry.key, entry.value),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Helper method to count tasks by category
  Map<String, int> _getCategoryCounts() {
    final Map<String, int> categoryCounts = {};

    for (final task in _todayTasks) {
      final category = task.category;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return categoryCounts;
  }

  // Mini category pill
  Widget _buildMiniCategory(String name, int count) {
    final categoryColor = _categoryColors[name] ?? _colorPalette[3];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: categoryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: categoryColor.withOpacity(0.3),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick add task section - Enhanced version
  Widget _buildQuickAddTaskSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3B70), // Deep blue
            const Color(0xFF29539B), // Rich blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3B70).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and subtle glow
          Row(
            children: [
              // Animated glowing icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E1FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E1FF).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_task,
                  color: Color(0xFF00E1FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Title with subtle text shadow
              Text(
                'Quick Add Task',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Premium glass-effect input field
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: TextField(
                  controller: _quickTaskController,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What do you need to do?',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.task_alt,
                      color: const Color(0xFF00E1FF).withOpacity(0.8),
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  onSubmitted: (_) => _showQuickAddTaskForm(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Premium button layout - centered "Add Task" with Voice and Schedule on sides
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add Task button (centered, larger, premium)
              Expanded(
                flex: 5,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E1FF), // Cyan
                        const Color(0xFF00B8FF), // Slightly darker cyan
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E1FF).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _showQuickAddTaskForm,
                      splashColor: Colors.white.withOpacity(0.1),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add Task',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Voice and Schedule buttons in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Voice button (left)
              _buildPremiumActionButton(
                icon: Icons.mic,
                label: 'Voice',
                color: const Color(0xFFFF9D80), // Coral
                onTap: _startVoiceInput,
                width: MediaQuery.of(context).size.width * 0.38,
              ),

              // Schedule button (right)
              _buildPremiumActionButton(
                icon: Icons.calendar_today,
                label: 'Schedule',
                color: const Color(0xFFA78BFA), // Lavender
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule feature coming soon!'),
                      backgroundColor: Color(0xFF29539B),
                    ),
                  );
                },
                width: MediaQuery.of(context).size.width * 0.38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add this premium button builder method
  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withOpacity(0.1),
              highlightColor: color.withOpacity(0.1),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Today's tasks section
  Widget _buildTodayTasksSection() {
    return _buildAnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Would navigate to all tasks
                },
                style: TextButton.styleFrom(
                  foregroundColor: _colorPalette[3],
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: _colorPalette[3],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _colorPalette[3],
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading indicator or empty state
          if (_isLoadingTasks)
            Center(
              child: CircularProgressIndicator(
                color: _colorPalette[3],
              ),
            )
          else if (_todayTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks for today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a task to get started',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          // Task list
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _todayTasks.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final task = _todayTasks[index];
                  final category = task.category;
                  final priority = task.priority;
                  final isCompleted = task.isCompleted;
                  final categoryColor = _categoryColors[category] ?? _colorPalette[3];
                  final priorityColor = _priorityColors[priority] ?? _colorPalette[3];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: index == 0
                          ? const BorderRadius.vertical(top: Radius.circular(20))
                          : index == _todayTasks.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(20))
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: () => _toggleTaskCompletion(task.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? priorityColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.transparent
                                    : priorityColor,
                                width: 2,
                              ),
                              boxShadow: isCompleted
                                  ? [
                                BoxShadow(
                                  color: priorityColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                                  : null,
                            ),
                            child: isCompleted
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Task details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(isCompleted ? 0.5 : 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Category badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: categoryColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Time
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        task.dueTime != null
                                            ? task.dueTime!.format12Hour()
                                            : 'Today',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Priority indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: priorityColor,
                            boxShadow: [
                              BoxShadow(
                                color: priorityColor.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      delay: 0.2,
    );
  }

  // Upcoming reminders section
  Widget _buildUpcomingRemindersSection() {
    return _buildAnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Reminders',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Would navigate to all reminders
                },
                style: TextButton.styleFrom(
                  foregroundColor: _colorPalette[3],
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: _colorPalette[3],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _colorPalette[3],
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal scrolling reminders
          if (_isLoadingUpcoming)
            Center(
              child: CircularProgressIndicator(
                color: _colorPalette[3],
              ),
            )
          else if (_upcomingTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming tasks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _upcomingTasks.length,
                itemBuilder: (context, index) {
                  final task = _upcomingTasks[index];
                  final category = task.category;
                  final priority = task.priority;
                  final categoryColor = _categoryColors[category] ?? _colorPalette[3];
                  final priorityColor = _priorityColors[priority] ?? _colorPalette[3];

                  // Format date for display
                  String formattedDate = 'Upcoming';
                  if (task.dueDate != null) {
                    final now = DateTime.now();
                    final tomorrow = DateTime(now.year, now.month, now.day + 1);
                    final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);

                    if (taskDate.isAtSameMomentAs(tomorrow)) {
                      formattedDate = 'Tomorrow';
                    } else {
                      formattedDate = DateFormat('MMM d').format(task.dueDate!);
                    }
                  }

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          priorityColor.withOpacity(0.3),
                          _colorPalette[1].withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: priorityColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Priority indicator
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: priorityColor,
                              boxShadow: [
                                BoxShadow(
                                  color: priorityColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date and time
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.dueTime != null
                                        ? task.dueTime!.format12Hour()
                                        : 'All day',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Task title
                              Text(
                                task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: categoryColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      delay: 0.3,
    );
  }

  // Smart suggestions section
  Widget _buildSmartSuggestionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorPalette[2].withOpacity(0.6),
            _colorPalette[1].withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: _colorPalette[3],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Suggestions',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Suggestions list
          ...List.generate(_suggestedTasks.length, (index) {
            final task = _suggestedTasks[index];
            final category = task['category'] as String;
            final categoryColor = _categoryColors[category] ?? _colorPalette[3];

            return Padding(
              padding: EdgeInsets.only(bottom: index < _suggestedTasks.length - 1 ? 12 : 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          category == 'Productivity' ? Icons.trending_up : Icons.restaurant_menu,
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Task details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['reason'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add button
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: categoryColor,
                        size: 24,
                      ),
                      onPressed: () async {
                        try {
                          // Get today's date
                          final today = DateTime.now();

                          // Add the suggested task
                          final newTask = await TaskService.addTask(
                            title: task['title'] as String,
                            category: task['category'] as String,
                            priority: 'Medium',
                            dueDate: today,
                            hasReminder: true,
                          );

                          // Refresh tasks
                          _fetchTasks();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added: ${task['title']}'),
                              backgroundColor: Colors.black.withOpacity(0.7),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error adding suggested task: $e');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Focus mode launcher
  Widget _buildFocusModeLauncher() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorPalette[5].withOpacity(0.6),
            _colorPalette[4].withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    Icons.timer_outlined,
                    color: _colorPalette[3],
                    size: 30 + 2 * _pulseController.value,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text and button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Mode',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Boost productivity with Pomodoro timer',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Start button
          ElevatedButton(
            onPressed: _startFocusMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorPalette[3].withOpacity(0.3),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _colorPalette[3].withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Productivity insights section
  Widget _buildProductivityInsightsSection() {
    return _buildAnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _colorPalette[2].withOpacity(0.6),
              _colorPalette[1].withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productivity Insights',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _colorPalette[3],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'This Week',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bar chart
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Sample bar chart data
                  _buildBarChartItem('Mon', 0.6, _colorPalette[3]),
                  _buildBarChartItem('Tue', 0.8, _colorPalette[3]),
                  _buildBarChartItem('Wed', 0.4, _colorPalette[3]),
                  _buildBarChartItem('Thu', 0.9, _colorPalette[3]),
                  _buildBarChartItem('Fri', 0.7, _colorPalette[3]),
                  _buildBarChartItem('Sat', 0.3, _colorPalette[3]),
                  _buildBarChartItem('Sun', 0.5, _colorPalette[3], isToday: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Completed', '24', Icons.check_circle_outline),
                _buildStatItem('Focus Time', '4.5h', Icons.timer_outlined),
                _buildStatItem('Efficiency', '78%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
      delay: 0.5,
    );
  }

// Bar chart item
  Widget _buildBarChartItem(String label, double value, Color color, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: value),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              width: 24,
              height: 100 * value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isToday
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
                border: isToday
                    ? Border.all(
                  color: Colors.white,
                  width: 2,
                )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

// Stat item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _colorPalette[3].withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: _colorPalette[3],
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoadingTasks = true;
    });

    try {
      // Fetch all tasks
      final tasks = await TaskService.getTasks();

      // Get today's date with time set to 00:00:00
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      // Filter tasks for today
      final todayTasks = tasks.where((task) {
        if (task.dueDate == null) return false;

        // Compare only the date part
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        return taskDate.isAtSameMomentAs(today);
      }).toList();

      setState(() {
        _allTasks = tasks;
        _todayTasks = todayTasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _fetchUpcomingTasks() async {
    setState(() {
      _isLoadingUpcoming = true;
    });

    try {
      // Fetch upcoming tasks
      final upcomingTasks = await TaskService.getUpcomingTasks();

      setState(() {
        _upcomingTasks = upcomingTasks;
        _isLoadingUpcoming = false;
      });
    } catch (e) {
      print('Error fetching upcoming tasks: $e');
      setState(() {
        _isLoadingUpcoming = false;
      });
    }
  }

  void _refreshTodayTasks() {
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Refreshing tasks...'),
          ],
        ),
        backgroundColor: _colorPalette[2],
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Fetch tasks
    _fetchTasks();
    _fetchUpcomingTasks();

    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }
}

// Dark gradient background painter
class DarkGradientBackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  DarkGradientBackgroundPainter({required this.animation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Base dark gradient background
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [colors[0], colors[1]],
      stops: const [0.0, 0.7],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Draw deep space nebula effect
    final nebulaCenter = Offset(
      width * 0.8 + math.sin(animation * 0.5) * width * 0.05,
      height * 0.2 + math.cos(animation * 0.5) * height * 0.05,
    );
    final nebulaRadius = width * 0.6;

    // Nebula glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[3].withOpacity(0.1),
          colors[2].withOpacity(0.05),
          colors[0].withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: nebulaCenter,
        radius: nebulaRadius * 1.8,
      ));

    canvas.drawCircle(
      nebulaCenter,
      nebulaRadius * 1.8,
      glowPaint,
    );

    // Draw cosmic dust clouds
    final dustPath = Path();
    final dustPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          colors[2].withOpacity(0.1),
          colors[1].withOpacity(0.05),
          colors[0].withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: nebulaCenter,
        radius: nebulaRadius,
      ));

    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi / 2.5 + animation * 0.2;
      final radius = nebulaRadius * (0.5 + i * 0.1);
      final centerOffset = Offset(
        nebulaCenter.dx + math.cos(angle) * radius * 0.3,
        nebulaCenter.dy + math.sin(angle) * radius * 0.3,
      );

      final cloudPath = Path();
      final cloudSize = radius * (0.3 + i * 0.05);

      // Create cloud-like shapes
      cloudPath.moveTo(centerOffset.dx, centerOffset.dy - cloudSize);

      for (int j = 0; j < 8; j++) {
        final blobAngle = j * math.pi / 4;
        final blobRadius = cloudSize * (0.8 + 0.2 * math.sin(animation * 2 + j));

        cloudPath.quadraticBezierTo(
          centerOffset.dx + math.cos(blobAngle) * blobRadius * 0.8,
          centerOffset.dy + math.sin(blobAngle) * blobRadius * 0.8,
          centerOffset.dx + math.cos(blobAngle + math.pi / 4) * blobRadius,
          centerOffset.dy + math.sin(blobAngle + math.pi / 4) * blobRadius,
        );
      }

      dustPath.addPath(cloudPath, Offset.zero);
    }

    canvas.drawPath(dustPath, dustPaint);

    // Draw subtle gradient waves
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors[3].withOpacity(0.1);

    for (int i = 0; i < 3; i++) {
      final waveRadius = height * (0.3 + i * 0.2);
      final waveRect = Rect.fromCenter(
        center: Offset(width * 0.5, height * 1.2),
        width: width * 2,
        height: waveRadius * 0.5,
      );

      canvas.save();
      canvas.translate(0, animation * 20);
      canvas.drawOval(waveRect, wavePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(DarkGradientBackgroundPainter oldDelegate) => true;
}
