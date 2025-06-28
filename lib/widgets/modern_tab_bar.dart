import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class ModernTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<TabItemData> items;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double height;
  final bool showLabels;

  const ModernTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xFF00E1FF),
    this.inactiveColor = Colors.white,
    this.backgroundColor = const Color(0xFF0F0524),
    this.height = 70.0,
    this.showLabels = true,
  });

  @override
  State<ModernTabBar> createState() => _ModernTabBarState();
}

class _ModernTabBarState extends State<ModernTabBar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    // Main animation controller for tab transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Pulse animation for active tab
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Rotation animation for active tab icon
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(ModernTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.reset();
      _animationController.forward();
      _rotateController.reset();
      _rotateController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: widget.height + bottomPadding,
      width: double.infinity,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Stack(
        children: [
          // Blurred background with cosmic effect
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.backgroundColor.withOpacity(0.85),
                      Color.lerp(widget.backgroundColor, Colors.black, 0.3)!.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Cosmic nebula effect
          Positioned.fill(
            child: CustomPaint(
              painter: CosmicNebulaPainter(
                animation: _pulseController.value,
                activeColor: widget.activeColor,
                activeIndex: widget.currentIndex,
                itemCount: widget.items.length,
              ),
            ),
          ),

          // Glossy overlay
          Positioned.fill(
            child: CustomPaint(
              painter: EnhancedGlossyOverlayPainter(),
            ),
          ),

          // Active tab indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: 8,
            left: size.width / widget.items.length * widget.currentIndex + (size.width / widget.items.length * 0.2),
            child: Container(
              width: size.width / widget.items.length * 0.6,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.activeColor.withOpacity(0.7),
                    widget.activeColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: widget.activeColor.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Tab items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isActive = index == widget.currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow for active tab
                      if (isActive)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.activeColor.withOpacity(0.2 + 0.1 * _pulseController.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            );
                          },
                        ),

                      // Tab content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with animation
                          AnimatedBuilder(
                            animation: Listenable.merge([_animationController, _pulseController, _rotateController]),
                            builder: (context, child) {
                              // Scale and rotation for active tab
                              double scale = isActive
                                  ? 1.0 + (_pulseController.value * 0.1)
                                  : 1.0;

                              double rotation = 0.0;
                              if (isActive && index == widget.currentIndex) {
                                rotation = _rotateController.value * 0.1 * math.pi;
                              }

                              return Transform.scale(
                                scale: scale,
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: isActive
                                            ? [
                                          widget.activeColor,
                                          Color.lerp(widget.activeColor, Colors.white, 0.3)!,
                                        ]
                                            : [
                                          widget.inactiveColor.withOpacity(0.7),
                                          widget.inactiveColor.withOpacity(0.7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcIn,
                                    child: Icon(
                                      isActive ? (item.activeIcon ?? item.icon) : item.icon,
                                      size: isActive ? 28 : 24,
                                      color: Colors.white, // This will be replaced by the shader
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Label with animation
                          if (widget.showLabels) ...[
                            const SizedBox(height: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: isActive
                                    ? widget.activeColor
                                    : widget.inactiveColor.withOpacity(0.7),
                                fontSize: isActive ? 12 : 11,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                letterSpacing: isActive ? 0.5 : 0,
                                shadows: isActive
                                    ? [
                                  Shadow(
                                    color: widget.activeColor.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ]
                                    : null,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ],
                      ),

                      // Ripple effect on tap
                      if (isActive && index == widget.currentIndex)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (1 - _fadeAnimation.value),
                              child: Container(
                                width: 60 * _fadeAnimation.value,
                                height: 60 * _fadeAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: widget.activeColor.withOpacity(0.5 * (1 - _fadeAnimation.value)),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Enhanced glossy overlay painter for premium 3D effect
class EnhancedGlossyOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Top highlight with curved shape
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.0),
      ],
    );

    final topRect = Rect.fromLTWH(0, 0, width, height * 0.6);
    final topPaint = Paint()..shader = topGradient.createShader(topRect);

    final topPath = Path()
      ..moveTo(0, 30)
      ..lineTo(0, height * 0.4)
      ..quadraticBezierTo(width * 0.5, height * 0.6, width, height * 0.4)
      ..lineTo(width, 30)
      ..quadraticBezierTo(width * 0.5, 0, 0, 30)
      ..close();

    canvas.drawPath(topPath, topPaint);

    // Bottom shadow for depth
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.center,
      colors: [
        Colors.black.withOpacity(0.15),
        Colors.transparent,
      ],
    );

    final bottomRect = Rect.fromLTWH(0, height * 0.5, width, height * 0.5);
    final bottomPaint = Paint()..shader = bottomGradient.createShader(bottomRect);

    canvas.drawRect(bottomRect, bottomPaint);

    // Subtle edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final edgePath = Path()
      ..moveTo(20, 0)
      ..lineTo(width - 20, 0);

    canvas.drawPath(edgePath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cosmic nebula effect painter
class CosmicNebulaPainter extends CustomPainter {
  final double animation;
  final Color activeColor;
  final int activeIndex;
  final int itemCount;

  CosmicNebulaPainter({
    required this.animation,
    required this.activeColor,
    required this.activeIndex,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Calculate the center of the active tab
    final tabWidth = width / itemCount;
    final activeCenter = Offset(
      tabWidth * (activeIndex + 0.5),
      height * 0.4,
    );

    // Draw cosmic nebula glow under the active tab
    final glowRadius = 40.0 + 5.0 * animation;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          activeColor.withOpacity(0.3),
          activeColor.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: activeCenter,
        radius: glowRadius,
      ));

    canvas.drawCircle(
      activeCenter,
      glowRadius,
      glowPaint,
    );

    // Draw subtle cosmic dust particles
    final random = math.Random(42);
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final particleX = activeCenter.dx + (random.nextDouble() - 0.5) * glowRadius * 2;
      final particleY = activeCenter.dy + (random.nextDouble() - 0.5) * glowRadius;
      final particleSize = 1.0 + random.nextDouble() * 2.0 * animation;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        particlePaint..color = activeColor.withOpacity(0.1 + 0.3 * random.nextDouble()),
      );
    }

    // Draw subtle light rays
    final rayPaint = Paint()
      ..color = activeColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + animation * math.pi;
      final rayLength = 30.0 + 10.0 * animation;

      canvas.drawLine(
        activeCenter,
        Offset(
          activeCenter.dx + math.cos(angle) * rayLength,
          activeCenter.dy + math.sin(angle) * rayLength,
        ),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CosmicNebulaPainter oldDelegate) =>
      oldDelegate.animation != animation ||
          oldDelegate.activeIndex != activeIndex;
}

// Data class for tab items
class TabItemData {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const TabItemData({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}
