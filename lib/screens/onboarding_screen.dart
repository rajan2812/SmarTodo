import 'package:flutter/material.dart';
import 'package:smart_todo/widgets/onboarding_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:smart_todo/screens/auth_screen.dart';

// Pattern painter class defined outside of any other class
class PatternPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  PatternPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    // Draw grid pattern
    for (int i = 0; i < size.width; i += 20) {
      // Vertical lines
      paint.color = i % 40 == 0 ? color1.withOpacity(0.15) : color2.withOpacity(0.1);
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );

      // Horizontal lines
      paint.color = i % 40 == 0 ? color2.withOpacity(0.15) : color1.withOpacity(0.1);
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) =>
      oldDelegate.color1 != color1 || oldDelegate.color2 != color2;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  int _currentPage = 0;
  final int _numPages = 4;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Voice-Powered Tasks',
      'description': 'Create tasks effortlessly using voice commands with natural language understanding',
      'lottie': 'assets/animations/voice_command.json',
      'color1': const Color(0xFF0B0F2F), // Dark blue
      'color2': const Color(0xFF1E3B70), // Medium blue
      'accent1': const Color(0xFF00E1FF), // Cyan
      'accent2': const Color(0xFF7B42F6), // Purple
      'icon': Icons.mic,
    },
    {
      'title': 'Smart Reminders',
      'description': 'Never miss important deadlines with intelligent, context-aware notifications',
      'lottie': 'assets/animations/notifications.json',
      'color1': const Color(0xFF1A0B2E), // Dark purple
      'color2': const Color(0xFF42275F), // Medium purple
      'accent1': const Color(0xFFE958FF), // Pink
      'accent2': const Color(0xFF5E52FF), // Blue-purple
      'icon': Icons.notifications_active,
    },
    {
      'title': 'Productivity Insights',
      'description': 'Gain valuable insights into your productivity patterns and task completion rates',
      'lottie': 'assets/animations/analytics.json',
      'color1': const Color(0xFF0A0A18), // Very dark blue
      'color2': const Color(0xFF2E1B4D), // Dark purple
      'accent1': const Color(0xFF00FFDD), // Teal
      'accent2': const Color(0xFFFF3D98), // Hot pink
      'icon': Icons.insights,
    },
    {
      'title': 'Focus Mode',
      'description': 'Boost your concentration with Pomodoro timer and distraction-free environment',
      'lottie': 'assets/animations/focus.json',
      'color1': const Color(0xFF0F0524), // Very dark purple
      'color2': const Color(0xFF3B1578), // Medium purple
      'accent1': const Color(0xFFFF5B94), // Pink
      'accent2': const Color(0xFF3CBBFF), // Light blue
      'icon': Icons.timer,
    },
  ];

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_buttonAnimationController);
  }

  void _onNextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Navigate to auth screen with a fancy transition
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Combine fade and slide transitions
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
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient that changes with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  _pages[_currentPage]['color1'] as Color,
                  _pages[_currentPage]['color2'] as Color,
                ],
              ),
            ),
          ),

          // Background pattern
          Opacity(
            opacity: 0.15,
            child: CustomPaint(
              painter: PatternPainter(
                color1: _pages[_currentPage]['accent1'] as Color,
                color2: _pages[_currentPage]['accent2'] as Color,
              ),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Onboarding pages
          PageView.builder(
            controller: _pageController,
            itemCount: _numPages,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                title: _pages[index]['title'] as String,
                description: _pages[index]['description'] as String,
                lottieAsset: _pages[index]['lottie'] as String,
                color1: _pages[index]['color1'] as Color,
                color2: _pages[index]['color2'] as Color,
                accent1: _pages[index]['accent1'] as Color,
                accent2: _pages[index]['accent2'] as Color,
                icon: _pages[index]['icon'] as IconData,
                pageIndex: index,
              );
            },
          ),

          // Bottom navigation with glassmorphism effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(bottom: bottomPadding + 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (_pages[_currentPage]['color1'] as Color).withOpacity(0.1),
                        (_pages[_currentPage]['color1'] as Color).withOpacity(0.6),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),

                      // Custom animated page indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _numPages,
                        effect: CustomizableEffect(
                          activeDotDecoration: DotDecoration(
                            width: 24,
                            height: 8,
                            color: _pages[_currentPage]['accent1'] as Color,
                            borderRadius: BorderRadius.circular(4),
                            dotBorder: DotBorder(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          dotDecoration: DotDecoration(
                            width: 8,
                            height: 8,
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            dotBorder: DotBorder(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          spacing: 8,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Animated button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTapDown: (_) => _buttonAnimationController.forward(),
                          onTapUp: (_) => _buttonAnimationController.reverse(),
                          onTapCancel: () => _buttonAnimationController.reverse(),
                          onTap: _onNextPage,
                          child: AnimatedBuilder(
                            animation: _buttonAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _buttonScaleAnimation.value,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _pages[_currentPage]['accent1'] as Color,
                                        _pages[_currentPage]['accent2'] as Color,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_pages[_currentPage]['accent1'] as Color).withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentPage == _numPages - 1 ? 'Get Started' : 'Next',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip button
                      if (_currentPage < _numPages - 1)
                        TextButton(
                          onPressed: () {
                            _pageController.animateToPage(
                              _numPages - 1,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: (_pages[_currentPage]['accent1'] as Color).withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

