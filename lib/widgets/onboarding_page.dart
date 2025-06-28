import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'dart:ui';

class OnboardingPage extends StatefulWidget {
  final String title;
  final String description;
  final String lottieAsset;
  final Color color1;
  final Color color2;
  final Color accent1;
  final Color accent2;
  final IconData icon;
  final int pageIndex;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.lottieAsset,
    required this.color1,
    required this.color2,
    required this.accent1,
    required this.accent2,
    required this.icon,
    required this.pageIndex,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_animationController);

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_animationController);

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOutCubic))
        .animate(_animationController);

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Animated illustration
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _fadeInAnimation.value) * -20),
                  child: Opacity(
                    opacity: _fadeInAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value * 0.05 * math.pi,
                      child: _buildIllustration(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Content with title and description
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      children: [
                        // Title with gradient text
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [widget.accent1, widget.accent2],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // This will be replaced by the gradient
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description with glassmorphism effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
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
                                widget.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.color2.withOpacity(0.2),
            widget.color1.withOpacity(0.05),
          ],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent1.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner circle with gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.6),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),

          // Icon with glow
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [widget.accent1, widget.accent2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(
              widget.icon,
              size: 60,
              color: Colors.white,
            ),
          ),

          // Decorative dots
          for (int i = 0; i < 8; i++)
            Positioned(
              top: 90 + 70 * math.sin(i * math.pi / 4),
              left: 90 + 70 * math.cos(i * math.pi / 4),
              child: Container(
                width: i % 2 == 0 ? 6 : 4,
                height: i % 2 == 0 ? 6 : 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i % 2 == 0 ? widget.accent1 : widget.accent2,
                  boxShadow: [
                    BoxShadow(
                      color: (i % 2 == 0 ? widget.accent1 : widget.accent2).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

          // Animated ring
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accent1.withOpacity(0.3),
                      width: 1,
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

