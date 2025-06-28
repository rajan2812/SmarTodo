import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  // Base URL for the API - Using computer's IP address for physical Android device
  // Replace this with your computer's actual IP address
  static String baseUrl = 'http://192.168.255.218:5000/api';

  // Headers
  static Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // This method will test if the server is reachable
  static Future<bool> testServerConnectivity() async {
    try {
      // First try the root URL
      final rootUrl = baseUrl.replaceAll('/api', '');
      print('Testing connectivity to root: $rootUrl');

      try {
        final rootResponse = await http.get(
          Uri.parse(rootUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        print('Root connectivity response: ${rootResponse.statusCode} - ${rootResponse.body}');

        if (rootResponse.statusCode == 200) {
          print('Successfully connected to server root');
          return true;
        }
      } catch (e) {
        print('Root connection error: ${e.toString()}');
      }

      // Then try the health endpoint
      final healthUrl = baseUrl.replaceAll('/api', '/health');
      print('Testing connectivity to health: $healthUrl');

      try {
        final healthResponse = await http.get(
          Uri.parse(healthUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        print('Health connectivity response: ${healthResponse.statusCode} - ${healthResponse.body}');

        if (healthResponse.statusCode == 200) {
          print('Successfully connected to server health endpoint');
          return true;
        }
      } catch (e) {
        print('Health connection error: ${e.toString()}');
      }

      // Finally try the API endpoint
      print('Testing connectivity to API: $baseUrl');

      final apiResponse = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('API connectivity response: ${apiResponse.statusCode} - ${apiResponse.body}');

      if (apiResponse.statusCode == 200) {
        print('Successfully connected to server API endpoint');
        return true;
      } else {
        print('Server API responded with status code: ${apiResponse.statusCode}');
        return false;
      }
    } catch (e) {
      print('Connection error: ${e.toString()}');
      return false;
    }
  }

  // Set auth token
  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _headers['Authorization'] = 'Bearer $token';
  }

  // Get auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Initialize headers with token if available
  static Future<void> initHeaders() async {
    final token = await getAuthToken();
    if (token != null) {
      _headers['Authorization'] = 'Bearer $token';
    }
  }

  // Clear auth token
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _headers.remove('Authorization');
  }

  // Register user
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      // First, test connectivity
      final isConnected = await testServerConnectivity();
      if (!isConnected) {
        return {
          'success': false,
          'message': 'Cannot connect to the server. Please check if the server is running.',
        };
      }

      final fullUrl = '$baseUrl/auth/register';
      print('Sending registration request to: $fullUrl');
      print('Request body: ${jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      })}');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // First, test connectivity
      final isConnected = await testServerConnectivity();
      if (!isConnected) {
        return {
          'success': false,
          'message': 'Cannot connect to the server. Please check if the server is running.',
        };
      }

      final fullUrl = '$baseUrl/auth/login';
      print('Sending login request to: $fullUrl');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String userId, String code) async {
    try {
      final fullUrl = '$baseUrl/auth/verify-otp';
      print('Sending OTP verification request to: $fullUrl');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'code': code,
        }),
      );

      print('OTP verification response status: ${response.statusCode}');
      print('OTP verification response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('OTP verification error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final fullUrl = '$baseUrl/auth/resend-otp';
      print('Sending resend OTP request to: $fullUrl');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      print('Resend OTP response status: ${response.statusCode}');
      print('Resend OTP response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Resend OTP error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Add this method to verify email token
  static Future<Map<String, dynamic>> verifyEmailToken(String userId, String token) async {
    try {
      final fullUrl = '$baseUrl/auth/verify-email-token';
      print('Sending email token verification request to: $fullUrl');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'token': token,
        }),
      );

      print('Email token verification response status: ${response.statusCode}');
      print('Email token verification response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Email token verification error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
