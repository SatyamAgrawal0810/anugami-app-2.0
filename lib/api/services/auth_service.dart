// lib/api/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'https://anugami.com/api/v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Register a new user (now with email OTP)
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      final responseData = json.decode(response.body);
      print('Registration response: $responseData');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ??
              'Registration successful. Please check your email for verification code.',
          'email': responseData['email'],
          'requires_verification':
              responseData['requires_verification'] ?? true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ??
              responseData['message'] ??
              'Registration failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Request OTP for email verification
  Future<Map<String, dynamic>> requestOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/request-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      print('Request OTP response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'OTP sent successfully to your email',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('Request OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // ✅ Verify OTP and activate account — captcha support added
  Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otp, {
    String? captchaId, // ✅ optional — only sent when CAPTCHA visible
    String? captchaAnswer, // ✅ optional — only sent when CAPTCHA visible
  }) async {
    try {
      // ✅ Build payload — add captcha fields only if present
      final Map<String, dynamic> payload = {
        'email': email,
        'otp': otp,
      };
      if (captchaId != null && captchaAnswer != null) {
        payload['captcha_id'] = captchaId;
        payload['captcha_answer'] = captchaAnswer;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/verify-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseData = json.decode(response.body);
      print('Verify OTP response: $responseData');

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          await _saveToken(responseData['token']);

          final userData = {
            'id': responseData['customer_id'] ?? '',
            'email': responseData['email'] ?? '',
            'full_name': responseData['full_name'] ?? '',
          };

          await _saveUserData(userData);
        }

        return {
          'success': true,
          'message': responseData['message'] ??
              'Email verified successfully! Account activated.',
          'token': responseData['token'],
          'customer_id': responseData['customer_id'],
          'email': responseData['email'],
          'full_name': responseData['full_name'],
          'data': responseData,
        };
      } else {
        // ✅ CAPTCHA required (5+ failed OTP attempts)
        if (responseData['captcha_required'] == true) {
          return {
            'success': false,
            'captcha_required': true,
            'error': responseData['error'],
            'message': responseData['error'] ??
                'Too many failed attempts. Please complete the security check.',
            'failed_attempts': responseData['failed_attempts'],
            'remaining_attempts': responseData['remaining_attempts'],
          };
        }

        return {
          'success': false,
          'message': responseData['error'] ?? 'OTP verification failed',
          'remaining_attempts': responseData['remaining_attempts'],
        };
      }
    } catch (e) {
      print('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/resend-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      print('Resend OTP response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ??
              'New OTP sent successfully to your email',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      print('Resend OTP error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // ✅ Login user — captcha support added
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? captchaId, // ✅ optional — only sent when CAPTCHA visible
    String? captchaAnswer, // ✅ optional — only sent when CAPTCHA visible
  }) async {
    try {
      // ✅ Build payload — add captcha fields only if present
      final Map<String, dynamic> payload = {
        'email': email,
        'password': password,
      };
      if (captchaId != null && captchaAnswer != null) {
        payload['captcha_id'] = captchaId;
        payload['captcha_answer'] = captchaAnswer;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/customers/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseData = json.decode(response.body);
      print('Login response: $responseData');

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          await _saveToken(responseData['token']);

          final userData = {
            'id': responseData['customer_id'] ?? '',
            'email': responseData['email'] ?? '',
            'full_name': responseData['full_name'] ?? '',
          };

          await _saveUserData(userData);
          await _secureStorage.write(key: 'user_password', value: password);

          // ✅ Send saved FCM token to backend now that user is logged in
          await _sendFcmTokenToBackend(responseData['token']);
        }
        return {
          'success': true,
          'data': responseData,
          'token': responseData['token'],
          'customer_id': responseData['customer_id'],
          'email': responseData['email'],
          'full_name': responseData['full_name'],
        };
      } else if (response.statusCode == 403 &&
          responseData['requires_verification'] == true) {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Please verify your email before logging in',
          'error': responseData['error'] ?? 'Email not verified',
          'requires_verification': true,
          'email': responseData['email'] ?? email,
        };
      } else {
        // ✅ CAPTCHA required (5+ failed login attempts)
        if (responseData['captcha_required'] == true) {
          return {
            'success': false,
            'captcha_required': true,
            'error': responseData['error'],
            'message': responseData['error'] ??
                'Too many failed attempts. Please complete the security check.',
            'failed_attempts': responseData['failed_attempts'],
          };
        }

        return {
          'success': false,
          'message': responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Login failed',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // ✅ Send FCM token to backend after login
  Future<void> _sendFcmTokenToBackend(String authToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/customers/fcm-token/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: json.encode({'fcm_token': fcmToken}),
      );
      print('FCM token sent to backend: ${response.statusCode}');
    } catch (e) {
      print('FCM token backend update failed: $e');
    }
  }

  // ── Password-reset endpoints ──
  final String _resetBaseUrl = 'https://anugami.com/api/v1';

  /// POST helper that manually follows 301/302 redirects as POST.
  Future<http.Response> _postWithRedirect(
    String url,
    Map<String, dynamic> body, {
    int maxRedirects = 3,
  }) async {
    final client = http.Client();
    try {
      Uri uri = Uri.parse(url);
      final bodyStr = jsonEncode(body);
      const headers = {'Content-Type': 'application/json'};

      for (int i = 0; i <= maxRedirects; i++) {
        final request = http.Request('POST', uri)
          ..headers.addAll(headers)
          ..body = bodyStr;

        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        print('[$i] POST $uri → ${response.statusCode}');

        if (response.statusCode == 301 || response.statusCode == 302) {
          final location = response.headers['location'];
          if (location == null) return response;
          uri = location.startsWith('http')
              ? Uri.parse(location)
              : Uri.parse('${uri.scheme}://${uri.host}$location');
          continue;
        }
        return response;
      }
      throw Exception('Too many redirects for $url');
    } finally {
      client.close();
    }
  }

  // ✅ STEP 1: Request password reset OTP
  Future<Map<String, dynamic>> requestPasswordResetOTP(String email) async {
    try {
      final response = await _postWithRedirect(
        '$_resetBaseUrl/customers/password-reset/request-otp/',
        {'email': email},
      );

      print(
          'Request password reset OTP [${response.statusCode}]: ${response.body}');

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {}
      }

      final bool isSuccess =
          response.statusCode == 200 || response.statusCode == 201;

      return {
        'success': isSuccess,
        'message': data['message'] ??
            data['error'] ??
            (isSuccess
                ? 'OTP sent to your email'
                : 'Failed to send OTP. Please try again.'),
      };
    } catch (e) {
      print('Request password reset OTP error: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  // ✅ STEP 2: Resend password reset OTP
  Future<Map<String, dynamic>> resendPasswordResetOTP(String email) async {
    try {
      final response = await _postWithRedirect(
        '$_resetBaseUrl/customers/password-reset/resend-otp/',
        {'email': email},
      );

      print(
          'Resend password reset OTP [${response.statusCode}]: ${response.body}');

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {}
      }

      final bool isSuccess = response.statusCode == 200;

      return {
        'success': isSuccess,
        'message': data['message'] ??
            data['error'] ??
            (isSuccess ? 'OTP resent successfully' : 'Failed to resend OTP.'),
      };
    } catch (e) {
      print('Resend password reset OTP error: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  // ✅ STEP 3: Verify OTP + Reset password (single API call)
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _postWithRedirect(
        '$_resetBaseUrl/customers/password-reset/verify-otp/',
        {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      print(
          'Reset password with OTP [${response.statusCode}]: ${response.body}');

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {}
      }

      final bool isSuccess = response.statusCode == 200;

      if (isSuccess) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully!',
        };
      } else {
        String errorMsg = 'Verification failed. Please try again.';
        if (data['email'] != null) {
          errorMsg = data['email'] is List ? data['email'][0] : data['email'];
        } else if (data['otp'] != null) {
          errorMsg = data['otp'] is List ? data['otp'][0] : data['otp'];
        } else if (data['new_password'] != null) {
          errorMsg = data['new_password'] is List
              ? data['new_password'][0]
              : data['new_password'];
        } else if (data['confirm_password'] != null) {
          errorMsg = data['confirm_password'] is List
              ? data['confirm_password'][0]
              : data['confirm_password'];
        } else if (data['error'] != null) {
          errorMsg = data['error'];
        }

        return {
          'success': false,
          'message': errorMsg,
          'remaining_attempts': data['remaining_attempts'],
          'field_errors': data,
        };
      }
    } catch (e) {
      print('Reset password with OTP error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _getToken();

      if (token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/customers/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        print('Logout response: ${response.body}');
      }

      await _clearUserData();

      return {
        'success': true,
        'message': 'Successfully logged out',
      };
    } catch (e) {
      await _clearUserData();
      print('Logout error: $e');
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Add a new address for the customer
  Future<Map<String, dynamic>> addAddress(
      Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      if (!addressData.containsKey('phone')) {
        addressData['phone'] = '';
      }

      if (!addressData.containsKey('country')) {
        addressData['country'] = 'India';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/customers/addresses/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(addressData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['error'] ??
              'Failed to add address',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Get saved password
  Future<String?> getSavedPassword() async {
    return await _secureStorage.read(key: 'user_password');
  }

  // Get authorization headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await _secureStorage.delete(key: 'user_password');
  }
}
