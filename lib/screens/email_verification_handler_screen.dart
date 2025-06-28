import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:smart_todo/screens/email_verification_success_screen.dart';
import 'package:smart_todo/screens/home_screen.dart';
import 'package:smart_todo/services/api_service.dart';

class EmailVerificationHandlerScreen extends StatefulWidget {
  final String token;
  final String userId;

  const EmailVerificationHandlerScreen({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<EmailVerificationHandlerScreen> createState() => _EmailVerificationHandlerScreenState();
}

class _EmailVerificationHandlerScreenState extends State<EmailVerificationHandlerScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _loadingController;

  bool _isLoading = true;
  bool _isSuccess = false;
  String _errorMessage = '';
  String _userName = '';

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

    // Loading animation controller
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Verify email token
    _verifyEmailToken();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmailToken() async {
    try {
      final response = await ApiService.verifyEmailToken(
        widget.userId,
        widget.token,
      );

      if (response['success']) {
        // Save auth token
        await ApiService.setAuthToken(response['token']);

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _userName = response['user']['name'] ?? 'User';
        });

        // Navigate to success screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => EmailVerificationSuccessScreen(
                  userName: _userName,
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
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = response['message'] ?? 'Verification failed';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
      print('Email token verification error: $error');
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          userName: _userName.isNotEmpty ? _userName : 'User',
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

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading) ...[
                      // Loading animation
                      AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  _colorPalette[3].withOpacity(0.0),
                                  _colorPalette[3],
                                ],
                                stops: const [0.0, 1.0],
                                startAngle: 0,
                                endAngle: 2 * math.pi,
                                transform: GradientRotation(_loadingController.value * 2 * math.pi),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _colorPalette[3].withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _colorPalette[0],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.email_outlined,
                                    color: _colorPalette[3],
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Loading text
                      Text(
                        'Verifying your email...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Please wait while we verify your email address.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (_isSuccess) ...[
                      // Success icon
                      Container(
                        width: 80,
                        height: 80,
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
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Success text
                      Text(
                        'Email Verified!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Your email has been successfully verified. Redirecting...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // Error icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _colorPalette[4],
                              _colorPalette[5],
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _colorPalette[4].withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Error text
                      Text(
                        'Verification Failed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : 'There was a problem verifying your email. Please try again.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // Try again button
                      Container(
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
                            onTap: _verifyEmailToken,
                            splashColor: Colors.white.withOpacity(0.1),
                            highlightColor: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Text(
                                'TRY AGAIN',
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

                      const SizedBox(height: 16),

                      // Go to home button
                      TextButton(
                        onPressed: _navigateToHome,
                        child: Text(
                          'Skip Verification',
                          style: TextStyle(
                            color: _colorPalette[3],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
