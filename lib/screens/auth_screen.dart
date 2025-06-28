import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:smart_todo/screens/home_screen.dart';
import 'package:smart_todo/screens/otp_verification_screen.dart';
import 'package:smart_todo/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _formAnimationController;
  late AnimationController _floatingElementsController;
  late AnimationController _pulseController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;

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

    // Initialize API service
    ApiService.initHeaders();

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

    // Floating elements animation controller
    _floatingElementsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: false);

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Animations
    _fadeInAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations
    _formAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _formAnimationController.dispose();
    _floatingElementsController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
      _formAnimationController.reset();
      _formAnimationController.forward();
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _toggleRememberMe() {
    setState(() {
      _rememberMe = !_rememberMe;
    });
  }

  // Validate form
  bool _validateForm() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return false;
    }

    // Validate email format
    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return false;
    }

    if (!_isLogin) {
      if (_nameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Name is required';
        });
        return false;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return false;
      }

      if (_passwordController.text.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters';
        });
        return false;
      }
    }

    return true;
  }

  // Check server connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final baseUrl = ApiService.baseUrl;
      print('Checking connectivity to server at: $baseUrl');

      // Try to connect to the backend server
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('Connectivity check response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connectivity check failed with detailed error: $e');

      // Provide more specific error messages based on the exception type
      String errorMessage = 'Connection error: ';

      if (e.toString().contains('SocketException')) {
        errorMessage += 'Cannot reach the server. Please check if the server is running and accessible.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage += 'Connection timed out. The server might be slow or unreachable.';
      } else {
        errorMessage += e.toString();
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      return false;
    }
  }

  Future<void> _testServerConnectivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = 'Testing server connectivity...';
    });

    try {
      final isConnected = await ApiService.testServerConnectivity();

      if (isConnected) {
        setState(() {
          _errorMessage = 'Server is reachable! You can now login or register.';
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Connection Successful'),
            content: Text('Successfully connected to the server'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Cannot connect to the server. Please check if your server is running.';
          _isLoading = false;
        });

        // Show error dialog with specific instructions for physical devices
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Connection Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not connect to the server. Please check:'),
                SizedBox(height: 16),
                Text('1. The server is running (npm run dev in Backend folder)'),
                Text('2. You have updated the API service with your computer\'s IP address'),
                Text('3. Your phone and computer are on the same network'),
                SizedBox(height: 16),
                Text('For physical Android device:'),
                Text('• You MUST use your computer\'s actual IP address'),
                Text('• Make sure your computer\'s firewall allows connections'),
                Text('• Try accessing the server from a browser on your phone'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: _testServerConnectivity,
                child: Text('Test Again'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during connectivity test: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Check if server is running and accessible
  Future<void> _ensureServerConnection() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = 'Checking server connection...';
    });

    try {
      final isConnected = await ApiService.testServerConnectivity();

      if (!isConnected) {
        setState(() {
          _errorMessage = 'Cannot connect to the server. Please check if your server is running and network settings.';
          _isLoading = false;
        });

        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Connection Error'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not connect to the server. Please check:'),
                  SizedBox(height: 16),
                  Text('1. The server is running (npm run dev in Backend folder)'),
                  Text('2. The server is accessible from your device'),
                  Text('3. The correct URL is being used'),
                  SizedBox(height: 16),
                  Text('If using a physical device:'),
                  Text('• Make sure your device is on the same WiFi network as your server'),
                  Text('• Try using your computer\'s actual IP address instead of localhost'),
                  Text('• Check if your firewall is blocking connections'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: _testServerConnectivity,
                child: Text('Test Again'),
              ),
            ],
          ),
        );

        return;
      }

      setState(() {
        _errorMessage = '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking server connection: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Handle authentication
  Future<void> _authenticate() async {
    if (!_validateForm()) {
      return;
    }

    // First, ensure server connection
    await _ensureServerConnection();

    // If there's an error message, it means the server connection failed
    if (_errorMessage.isNotEmpty && _errorMessage.contains('Cannot connect to the server')) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        // Login
        final response = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (response['success']) {
          // Save auth token
          await ApiService.setAuthToken(response['token']);

          // Navigate to home screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
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
            );
          }
        } else {
          // Check if email verification is required
          if (response['verificationId'] != null && response['userId'] != null) {
            if (mounted) {
              // Show a dialog explaining that verification is needed
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Email Verification Required'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Your account needs to be verified. We\'ll send you a verification code.'),
                      if (response['testOtp'] != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Test OTP: ${response['testOtp']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to OTP verification screen
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => OtpVerificationScreen(
                              email: _emailController.text,
                              verificationId: response['verificationId'],
                              userId: response['userId'],
                              testOtp: response['testOtp'],
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
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } else {
            setState(() {
              _errorMessage = response['message'] ?? 'Login failed';
            });
          }
        }
      } else {
        // Register
        final response = await ApiService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (response['success']) {
          // Show success dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Registration Successful'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your account has been created! Please check your email for a verification code to activate your account.',
                      style: TextStyle(height: 1.5),
                    ),
                    if (response['testOtp'] != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Test OTP: ${response['testOtp']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to OTP verification screen
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => OtpVerificationScreen(
                            email: _emailController.text,
                            verificationId: response['verificationId'],
                            userId: response['userId'],
                            testOtp: response['testOtp'],
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
                    },
                    child: Text('Verify Now'),
                  ),
                ],
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Registration failed';
          });
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: ${error.toString()}';
        print('Authentication error: $error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

          // Animated floating elements
          AnimatedBuilder(
            animation: _floatingElementsController,
            builder: (context, child) {
              return CustomPaint(
                painter: FloatingElementsPainter(
                  animation: _floatingElementsController.value,
                  pulseValue: _pulseController.value,
                  colors: [
                    _colorPalette[3],
                    _colorPalette[4],
                    _colorPalette[5],
                  ],
                ),
                size: size,
              );
            },
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: EnhancedStarfieldPainter(
                  animation: _backgroundController.value,
                  colors: [
                    Colors.white,
                    _colorPalette[3],
                    _colorPalette[4],
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // App logo and name
                    Row(
                      children: [
                        // Animated logo
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 48,
                              height: 48,
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
                                    blurRadius: 15 + 5 * _pulseController.value,
                                    spreadRadius: 2 + _pulseController.value,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              _colorPalette[3],
                              _colorPalette[4],
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'SmarTodo',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Mode toggle button with glassmorphism
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _toggleAuthMode,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      _isLogin ? 'Sign Up' : 'Login',
                                      style: TextStyle(
                                        color: _colorPalette[3],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Title with animation
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  _colorPalette[3],
                                  _colorPalette[4],
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                _isLogin ? 'Welcome Back!' : 'Create Account',
                                style: GoogleFonts.outfit(
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

                    const SizedBox(height: 20),

                    // Subtitle
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Text(
                              _isLogin
                                  ? 'Sign in to continue using SmarTodo'
                                  : 'Create a new account to get started',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Form fields
                    if (!_isLogin)
                      _buildEnhancedTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline,
                        textInputType: TextInputType.name,
                        index: 0,
                      ),

                    if (!_isLogin) const SizedBox(height: 16),

                    _buildEnhancedTextField(
                      controller: _emailController,
                      hintText: 'Email Address',
                      icon: Icons.email_outlined,
                      textInputType: TextInputType.emailAddress,
                      index: _isLogin ? 0 : 1,
                    ),

                    const SizedBox(height: 16),

                    _buildEnhancedTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: _togglePasswordVisibility,
                      index: _isLogin ? 1 : 2,
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),

                      _buildEnhancedTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: _toggleConfirmPasswordVisibility,
                        index: 3,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Remember me and forgot password
                    if (_isLogin)
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeInAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: _buildRememberMeRow(),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 40),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      AnimatedBuilder(
                        animation: _formAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeInAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontSize: 14,
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

                    if (_errorMessage.isNotEmpty) const SizedBox(height: 20),

                    // Login/Register button
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: _buildPremiumButton(
                              text: _isLoading
                                  ? (_isLogin ? 'SIGNING IN...' : 'CREATING ACCOUNT...')
                                  : (_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
                              onPressed: _isLoading ? null : _authenticate,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Test connectivity button
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: _testServerConnectivity,
                                icon: Icon(
                                  Icons.wifi_tethering,
                                  color: _colorPalette[3],
                                  size: 18,
                                ),
                                label: Text(
                                  'Test Server Connection',
                                  style: TextStyle(
                                    color: _colorPalette[3],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Social login section
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withOpacity(0.2),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Or continue with',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withOpacity(0.2),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Social login buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildEnhancedSocialButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      color: Colors.white,
                                      onPressed: () {
                                        // Google login
                                      },
                                      index: 0,
                                    ),
                                    _buildEnhancedSocialButton(
                                      icon: Icons.apple,
                                      color: Colors.white,
                                      onPressed: () {
                                        // Apple login
                                      },
                                      index: 1,
                                    ),
                                    _buildEnhancedSocialButton(
                                      icon: Icons.facebook,
                                      color: Colors.blue,
                                      onPressed: () {
                                        // Facebook login
                                      },
                                      index: 2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Bottom text
                    AnimatedBuilder(
                      animation: _formAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Center(
                              child: _buildBottomText(),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: bottomPadding + 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType textInputType = TextInputType.text,
    required int index,
  }) {
    // Staggered animation delay based on index
    final delay = 0.1 * index;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
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
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colorPalette[5].withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: TextField(
                    controller: controller,
                    obscureText: isPassword && obscureText,
                    keyboardType: textInputType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 16,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _colorPalette[3].withOpacity(0.2),
                              _colorPalette[4].withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                      suffixIcon: isPassword
                          ? IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.5),
                          size: 22,
                        ),
                        onPressed: onToggleVisibility,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleRememberMe,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: _rememberMe
                  ? LinearGradient(
                colors: [
                  _colorPalette[3],
                  _colorPalette[4],
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              border: Border.all(
                color: _rememberMe
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: _rememberMe ? [
                BoxShadow(
                  color: _colorPalette[3].withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: _rememberMe
                ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Remember me',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // Implement forgot password
            debugPrint('Forgot password');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: _colorPalette[3],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildEnhancedSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required int index,
  }) {
    // Staggered animation delay based on index
    final delay = 0.1 * index;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.05),
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
                        color: _colorPalette[index % 3 + 3].withOpacity(0.1 + 0.05 * _pulseController.value),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPressed,
                          splashColor: Colors.white.withOpacity(0.1),
                          highlightColor: Colors.white.withOpacity(0.05),
                          child: Center(
                            child: Icon(
                              icon,
                              color: color,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: _isLogin
                      ? 'Don\'t have an account? '
                      : 'Already have an account? ',
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: _toggleAuthMode,
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Login',
                      style: TextStyle(
                        color: _colorPalette[3],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

// Enhanced starfield painter
class EnhancedStarfieldPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final int starCount = 150;
  final math.Random random = math.Random(42);
  final List<Map<String, dynamic>> stars = [];

  EnhancedStarfieldPainter({required this.animation, required this.colors}) {
    // Initialize stars
    for (int i = 0; i < starCount; i++) {
      stars.add({
        'x': random.nextDouble(),
        'y': random.nextDouble(),
        'size': random.nextDouble() * 2 + 0.5,
        'twinkle': random.nextDouble(),
        'color': colors[random.nextInt(colors.length)],
        'speed': 0.2 + random.nextDouble() * 0.8,
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw stars
    for (final star in stars) {
      final x = star['x'] * width;
      final y = star['y'] * height;
      final baseSize = star['size'] as double;
      final twinkle = star['twinkle'] as double;
      final color = star['color'] as Color;
      final speed = star['speed'] as double;

      // Calculate star size with twinkle effect
      final twinkleOffset = math.sin((animation * speed + twinkle) * 2 * math.pi);
      final starSize = baseSize * (0.7 + 0.3 * twinkleOffset);

      // Draw star
      canvas.drawCircle(
        Offset(x, y),
        starSize,
        Paint()
          ..color = color.withOpacity(0.7 + 0.3 * twinkleOffset)
          ..style = PaintingStyle.fill,
      );

      // Draw glow
      canvas.drawCircle(
        Offset(x, y),
        starSize * 3,
        Paint()
          ..color = color.withOpacity(0.2 * twinkleOffset)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(EnhancedStarfieldPainter oldDelegate) => true;
}

// Floating elements painter
class FloatingElementsPainter extends CustomPainter {
  final double animation;
  final double pulseValue;
  final List<Color> colors;
  final int elementCount = 8;
  final math.Random random = math.Random(42);
  final List<Map<String, dynamic>> elements = [];

  FloatingElementsPainter({
    required this.animation,
    required this.pulseValue,
    required this.colors,
  }) {
    // Initialize floating elements
    for (int i = 0; i < elementCount; i++) {
      elements.add({
        'x': 0.1 + random.nextDouble() * 0.8,
        'y': 0.1 + random.nextDouble() * 0.8,
        'size': 20.0 + random.nextDouble() * 40.0,
        'speed': 0.2 + random.nextDouble() * 0.3,
        'offset': random.nextDouble() * math.pi * 2,
        'color': colors[i % colors.length],
        'shape': random.nextInt(3), // 0: circle, 1: square, 2: triangle
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    for (final element in elements) {
      final baseX = element['x'] * width;
      final baseY = element['y'] * height;
      final baseSize = element['size'] as double;
      final speed = element['speed'] as double;
      final offset = element['offset'] as double;
      final color = element['color'] as Color;
      final shape = element['shape'] as int;

      // Animate position
      final animationValue = (animation * speed + offset) % 1.0;
      final x = baseX + math.sin(animationValue * 2 * math.pi) * 30;
      final y = baseY + math.cos(animationValue * 2 * math.pi) * 30;

      // Animate size with pulse
      final size = baseSize * (0.9 + 0.1 * pulseValue);

      // Set paint
      final paint = Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      // Draw shape
      switch (shape) {
        case 0: // Circle
          canvas.drawCircle(Offset(x, y), size / 2, paint);
          break;
        case 1: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y),
              width: size,
              height: size,
            ),
            paint,
          );
          break;
        case 2: // Triangle
          final path = Path();
          path.moveTo(x, y - size / 2);
          path.lineTo(x + size / 2, y + size / 2);
          path.lineTo(x - size / 2, y + size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(FloatingElementsPainter oldDelegate) =>
      oldDelegate.animation != animation ||
          oldDelegate.pulseValue != pulseValue;
}
