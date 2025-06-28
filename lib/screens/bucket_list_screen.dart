import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;

  // Sample bucket list items
  final List<Map<String, dynamic>> _bucketListItems = [
    {
      'title': 'Visit Japan during cherry blossom season',
      'category': 'Travel',
      'priority': 'High',
      'deadline': '2026',
      'isCompleted': false,
    },
    {
      'title': 'Learn to play the guitar',
      'category': 'Skill',
      'priority': 'Medium',
      'deadline': 'No deadline',
      'isCompleted': false,
    },
    {
      'title': 'Run a marathon',
      'category': 'Health',
      'priority': 'Medium',
      'deadline': '2025',
      'isCompleted': false,
    },
    {
      'title': 'Write a book',
      'category': 'Creative',
      'priority': 'Low',
      'deadline': 'No deadline',
      'isCompleted': false,
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
    'Travel': const Color(0xFF7B42F6),
    'Skill': const Color(0xFF00E1FF),
    'Health': const Color(0xFFFF5B94),
    'Creative': const Color(0xFFFFD166),
  };

  // Priority colors
  final Map<String, Color> _priorityColors = {
    'High': const Color(0xFFFF5B94),
    'Medium': const Color(0xFFFFD166),
    'Low': const Color(0xFF00E1FF),
  };

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _toggleItemCompletion(int index) {
    setState(() {
      _bucketListItems[index]['isCompleted'] = !_bucketListItems[index]['isCompleted'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _colorPalette[0],
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

          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  floating: true,
                  title: Text(
                    'Bucket List',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    // Filter button
                    IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        // Would show filter options
                      },
                    ),
                    // Add button
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: _colorPalette[3]),
                      onPressed: () {
                        // Would show add bucket list item dialog
                      },
                    ),
                  ],
                ),

                // Intro section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _colorPalette[5].withOpacity(0.3),
                            _colorPalette[4].withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: _colorPalette[3],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Dream Big',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your bucket list is a collection of experiences, achievements, and goals you want to accomplish in your lifetime.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bucket list items
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = _bucketListItems[index];
                        final category = item['category'] as String;
                        final priority = item['priority'] as String;
                        final isCompleted = item['isCompleted'] as bool;
                        final categoryColor = _categoryColors[category] ?? _colorPalette[3];
                        final priorityColor = _priorityColors[priority] ?? _colorPalette[3];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Checkbox
                                        GestureDetector(
                                          onTap: () => _toggleItemCompletion(index),
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
                                        // Title
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(isCompleted ? 0.5 : 0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              decoration: isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Details row
                                    Row(
                                      children: [
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
                                        const SizedBox(width: 8),
                                        // Priority
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: priorityColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: priorityColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.flag,
                                                color: priorityColor,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                priority,
                                                style: TextStyle(
                                                  color: priorityColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Deadline
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: Colors.white.withOpacity(0.7),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['deadline'] as String,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        // Options button
                                        IconButton(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.white.withOpacity(0.7),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            // Would show options menu
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _bucketListItems.length,
                    ),
                  ),
                ),

                // Bottom padding for tab bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
