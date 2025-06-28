import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:smart_todo/screens/home_screen.dart';

class EmailVerificationSuccessScreen extends StatefulWidget {
  final String userName;

  const EmailVerificationSuccessScreen({
    super.key,
    required this.userName,
  });

  @override
  State<EmailVerificationSuccessScreen> createState() => _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState extends State<EmailVerificationSuccessScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentAnimationController;
  late AnimationController _confettiController;

  // Dark color palette with rich gradients
  final List<Color> _colorPalette = [
    const Color(0xFF050314), // Ultra dark purple/black
    const Color(0xFF0F0524), // Very dark purple
    const Color(0xFF1A0B2E), // Dark purple
    const Color(0xFF00E1FF), // Cyan
    const Color(0xFFFF5B94), // Pink
    const Color(0xFF7B42F6), // Bright purple
  ];

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: false);

    // Content animation controller
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Confetti animation controller
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          userName: widget.userName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 0.1);
          var end = Offset.zero;
          var curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
          (route) => false,
    );
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

          // Confetti animation
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  animation: _confettiController.value,
                  colors: [
                    _colorPalette[3],
                    _colorPalette[4],
                    _colorPalette[5],
                    Colors.white,
                  ],
                ),
                size: size,
              );
            },
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon with animation
                    AnimatedBuilder(
                      animation: _contentAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _contentAnimationController.value,
                          child: Opacity(
                            opacity: _contentAnimationController.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    _colorPalette[3],
                                    _colorPalette[5],
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _colorPalette[3].withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Success message with animation
                    AnimatedBuilder(
                      animation: _contentAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _contentAnimationController.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _contentAnimationController.value)),
                            child: Column(
                              children: [
                                // Title
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      _colorPalette[3],
                                      _colorPalette[4],
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Email Verified!',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Description
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Your email has been successfully verified. You can now access all features of SmarTodo.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Continue button with animation
                    AnimatedBuilder(
                      animation: _contentAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _contentAnimationController.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _contentAnimationController.value)),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    _colorPalette[3],
                                    _colorPalette[4],
                                    _colorPalette[5],
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _colorPalette[3].withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _navigateToHome,
                                  splashColor: Colors.white.withOpacity(0.1),
                                  highlightColor: Colors.white.withOpacity(0.05),
                                  child: const Center(
                                    child: Text(
                                      'CONTINUE TO APP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
  }

  @override
  bool shouldRepaint(DarkGradientBackgroundPainter oldDelegate) => true;
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final int confettiCount = 100;
  final math.Random random = math.Random(42);
  final List<Map<String, dynamic>> confetti = [];

  ConfettiPainter({required this.animation, required this.colors}) {
    // Initialize confetti
    for (int i = 0; i < confettiCount; i++) {
      confetti.add({
        'x': random.nextDouble() * 1.2 - 0.1, // -0.1 to 1.1
        'y': random.nextDouble() * 0.5 - 0.5, // -0.5 to 0
        'size': 5.0 + random.nextDouble() * 10.0,
        'speed': 0.3 + random.nextDouble() * 0.7,
        'angle': random.nextDouble() * 2 * math.pi,
        'spin': (random.nextDouble() * 0.2 - 0.1) * math.pi,
        'color': colors[random.nextInt(colors.length)],
        'shape': random.nextInt(3), // 0: square, 1: circle, 2: line
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (animation < 0.1) return; // Wait a bit before starting

    for (final particle in confetti) {
      final x = particle['x'] as double;
      final y = particle['y'] as double;
      final baseSize = particle['size'] as double;
      final speed = particle['speed'] as double;
      final angle = particle['angle'] as double;
      final spin = particle['spin'] as double;
      final color = particle['color'] as Color;
      final shape = particle['shape'] as int;

      // Calculate position with gravity and wind
      final progress = math.min(1.0, animation / 0.8); // Complete by 80% of animation
      final gravity = speed * progress * 2;
      final wind = math.sin(progress * 3 * math.pi) * 0.1;

      final posX = (x + wind) * width;
      final posY = (y + gravity) * height;

      // Skip if out of bounds
      if (posY > height) continue;

      // Calculate rotation
      final rotation = angle + spin * progress * 10;

      // Set paint
      final paint = Paint()
        ..color = color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      // Save canvas state for rotation
      canvas.save();
      canvas.translate(posX, posY);
      canvas.rotate(rotation);

      // Draw shape
      final size = baseSize * (1.0 - progress * 0.3);
      switch (shape) {
        case 0: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: size,
              height: size,
            ),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(
            Offset.zero,
            size / 2,
            paint,
          );
          break;
        case 2: // Line
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: size,
              height: size / 4,
            ),
            paint,
          );
          break;
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
