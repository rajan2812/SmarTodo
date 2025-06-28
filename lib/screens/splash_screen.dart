import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_todo/screens/onboarding_screen.dart';
import 'dart:math' as math;
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _particleController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;

  // Modern color palette
  final List<Color> _colorPalette = [
    const Color(0xFF0F0524), // Deep purple background
    const Color(0xFF3B1578), // Medium purple
    const Color(0xFF7B42F6), // Bright purple
    const Color(0xFF00E1FF), // Cyan
    const Color(0xFFFF5B94), // Pink
  ];

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: false);

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: false);

    // Content animation controller
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animations
    _fadeInAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUpAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Start animations
    _contentController.forward();

    // Auto-navigate to onboarding after delay
    Future.delayed(const Duration(seconds: 3), () {
      _navigateToOnboarding();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _colorPalette[0],
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: ModernBackgroundPainter(
                  animation: _backgroundController.value,
                  colors: [
                    _colorPalette[0],
                    _colorPalette[1],
                    _colorPalette[2],
                  ],
                ),
                size: size,
              );
            },
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  animation: _particleController.value,
                  colors: [
                    _colorPalette[3],
                    _colorPalette[4],
                    _colorPalette[2],
                  ],
                ),
                size: size,
              );
            },
          ),

          // Subtle grid overlay
          CustomPaint(
            painter: GridPainter(
              color: Colors.white.withOpacity(0.05),
              lineWidth: 0.2,
              spacing: 20,
            ),
            size: size,
          ),

          // Content
          AnimatedBuilder(
            animation: _contentController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUpAnimation.value),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo container with glow
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _colorPalette[1].withOpacity(0.2),
                                _colorPalette[0].withOpacity(0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _colorPalette[3].withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Inner circle
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),

                              // Logo
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    _colorPalette[3],
                                    _colorPalette[4],
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),

                              // Decorative dots
                              for (int i = 0; i < 8; i++)
                                Positioned(
                                  top: 75 + 60 * math.sin(i * math.pi / 4),
                                  left: 75 + 60 * math.cos(i * math.pi / 4),
                                  child: Container(
                                    width: i % 2 == 0 ? 6 : 4,
                                    height: i % 2 == 0 ? 6 : 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i % 2 == 0 ? _colorPalette[3] : _colorPalette[4],
                                      boxShadow: [
                                        BoxShadow(
                                          color: (i % 2 == 0 ? _colorPalette[3] : _colorPalette[4]).withOpacity(0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // App name with modern gradient
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              _colorPalette[3],
                              _colorPalette[4],
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'SmarTodo',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline in a modern container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Your Day, the Smart Way.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Modern background painter
class ModernBackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  ModernBackgroundPainter({required this.animation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create gradient paint
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw background gradient
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [colors[0], colors[1]],
    );

    canvas.drawRect(rect, paint..shader = gradient.createShader(rect));

    // Draw animated wave
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors[1], colors[2]],
      ).createShader(Rect.fromLTWH(0, height * 0.6, width, height * 0.4));

    final path = Path();
    path.moveTo(0, height);

    final waveHeight = height * 0.05;
    final frequency = 3.0;
    final phase = animation * 2 * math.pi;

    for (double x = 0; x <= width; x += 5) {
      final y = height - height * 0.2 -
          waveHeight * math.sin((x / width * frequency * math.pi) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(ModernBackgroundPainter oldDelegate) => true;
}

// Particles painter
class ParticlesPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final int particleCount = 30;
  final math.Random random = math.Random(42);

  ParticlesPainter({required this.animation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    for (int i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * width;
      final baseY = random.nextDouble() * height;
      final baseSize = 2.0 + random.nextDouble() * 4.0;
      final colorIndex = i % colors.length;

      // Animate position
      final offset = 0.1 * i;
      final animationValue = (animation + offset) % 1.0;
      final x = baseX + math.sin(animationValue * 2 * math.pi) * 20;
      final y = baseY + math.cos(animationValue * 2 * math.pi) * 20;

      // Animate size
      final size = baseSize * (0.8 + 0.4 * math.sin(animationValue * math.pi));

      // Set paint
      final paint = Paint()
        ..color = colors[colorIndex].withOpacity(0.6)
        ..style = PaintingStyle.fill;

      // Draw particle
      canvas.drawCircle(Offset(x, y), size, paint);

      // Draw glow
      canvas.drawCircle(
        Offset(x, y),
        size * 2,
        Paint()
          ..color = colors[colorIndex].withOpacity(0.2)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// Grid painter
class GridPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double spacing;

  GridPainter({
    required this.color,
    required this.lineWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.color != color ||
          oldDelegate.lineWidth != lineWidth ||
          oldDelegate.spacing != spacing;
}

