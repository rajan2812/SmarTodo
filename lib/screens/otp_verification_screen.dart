import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:smart_todo/screens/home_screen.dart';
import 'package:smart_todo/services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String verificationId;
  final String userId;
  final String? testOtp; // Add this parameter for testing

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.verificationId,
    required this.userId,
    this.testOtp, // Optional parameter for testing
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _formAnimationController;
  late AnimationController _pulseController;

  // OTP text controllers
  final List<TextEditingController> _otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );

  // Focus nodes for OTP fields
  final List<FocusNode> _focusNodes = List.generate(
    6,
        (index) => FocusNode(),
  );

  // State variables
  bool _isVerifying = false;
  bool _isResending = false;
  String _errorMessage = '';

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

    // Form animation controller
    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Start animations
    _formAnimationController.forward();

    // Add listeners to focus nodes
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _otpControllers[i].text.isNotEmpty) {
          _otpControllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[i].text.length,
          );
        }
      });
    }

    // If we have a test OTP, pre-fill the fields
    if (widget.testOtp != null && widget.testOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = widget.testOtp![i];
        }
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _formAnimationController.dispose();
    _pulseController.dispose();

    // Dispose controllers and focus nodes
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].dispose();
      _focusNodes[i].dispose();
    }

    super.dispose();
  }

  // Handle OTP input
  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all digits are entered
        _verifyOtp();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // Get full OTP code
  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    final otpCode = _getOtpCode();

    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.verifyOtp(
        widget.userId,
        otpCode,
      );

      if (response['success']) {
        // Save auth token
        await ApiService.setAuthToken(response['token']);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Navigate to home screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
                userName: response['user']['name'],
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
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Verification failed';
          _isVerifying = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isVerifying = false;
      });
      print('OTP verification error: $error');
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.resendOtp(widget.email);

      if (response['success']) {
        setState(() {
          _isResending = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to ${widget.email}'),
            backgroundColor: _colorPalette[5],
            duration: Duration(seconds: 3),
          ),
        );

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }

        // Focus on first field
        _focusNodes[0].requestFocus();

        // If we have a test OTP, pre-fill the fields
        if (response['testOtp'] != null && response['testOtp'].toString().length == 6) {
          for (int i = 0; i < 6; i++) {
            _otpControllers[i].text = response['testOtp'].toString()[i];
          }

          // Show test OTP in a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Test OTP'),
              content: Text('For testing purposes, your OTP is: ${response['testOtp']}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to resend code';
          _isResending = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isResending = false;
      });
      print('Resend OTP error: $error');
    }
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Title with animation
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _formAnimationController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    _colorPalette[3],
                                    _colorPalette[4],
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Text(
                                  'Verification',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Subtitle with animation
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _formAnimationController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                              child: Text(
                                'Enter the 6-digit code sent to ${widget.email}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // OTP input fields
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _formAnimationController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                      (index) => _buildOtpDigitField(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Error message
                      if (_errorMessage.isNotEmpty)
                        AnimatedBuilder(
                          animation: _formAnimationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _formAnimationController.value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _colorPalette[4],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 40),

                      // Verify button
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _formAnimationController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                              child: _buildPremiumButton(
                                text: _isVerifying ? 'VERIFYING...' : 'VERIFY',
                                onPressed: _isVerifying ? null : _verifyOtp,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Resend code
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _formAnimationController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Didn\'t receive the code?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isResending ? null : _resendOtp,
                                    child: Text(
                                      _isResending ? 'Sending...' : 'Resend',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _colorPalette[3],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // If we have a test OTP, show it
                      if (widget.testOtp != null)
                        AnimatedBuilder(
                          animation: _formAnimationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _formAnimationController.value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - _formAnimationController.value)),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _colorPalette[5].withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _colorPalette[5].withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: _colorPalette[3],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Test OTP: ${widget.testOtp}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
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

                      const Spacer(),
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

  // Build OTP digit field
  Widget _buildOtpDigitField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? _colorPalette[3]
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: _focusNodes[index].hasFocus
            ? [
          BoxShadow(
            color: _colorPalette[3].withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            onChanged: (value) => _onOtpChanged(value, index),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: '•',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build premium button
  Widget _buildPremiumButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: onPressed == null
                  ? [
                Colors.grey.withOpacity(0.3),
                Colors.grey.withOpacity(0.5),
              ]
                  : [
                _colorPalette[3],
                _colorPalette[4],
                _colorPalette[5],
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: onPressed == null
                ? null
                : [
              BoxShadow(
                color: _colorPalette[3].withOpacity(0.3 + 0.2 * _pulseController.value),
                blurRadius: 15 + 5 * _pulseController.value,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
