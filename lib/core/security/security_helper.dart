// lib/core/security/security_helper.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:anu_app/core/error_handler.dart';

/// Production-ready security helper
/// Handles secure storage, encryption, and data validation
class SecurityHelper {
  // Singleton pattern
  static final SecurityHelper _instance = SecurityHelper._internal();
  factory SecurityHelper() => _instance;
  SecurityHelper._internal();

  // Secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDeviceId = 'device_id';

  /// Save auth token securely
  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      ErrorHandler.logError('Failed to save auth token', error: e);
      rethrow;
    }
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _keyAuthToken);
    } catch (e) {
      ErrorHandler.logError('Failed to read auth token', error: e);
      return null;
    }
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _keyRefreshToken, value: token);
    } catch (e) {
      ErrorHandler.logError('Failed to save refresh token', error: e);
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (e) {
      ErrorHandler.logError('Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Save user data securely
  Future<void> saveUserData({
    required String userId,
    required String email,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _keyUserId, value: userId),
        _secureStorage.write(key: _keyUserEmail, value: email),
      ]);
    } catch (e) {
      ErrorHandler.logError('Failed to save user data', error: e);
      rethrow;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _keyUserId);
    } catch (e) {
      ErrorHandler.logError('Failed to read user ID', error: e);
      return null;
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _secureStorage.read(key: _keyUserEmail);
    } catch (e) {
      ErrorHandler.logError('Failed to read user email', error: e);
      return null;
    }
  }

  /// Clear all secure data (logout)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      ErrorHandler.logInfo('All secure data cleared');
    } catch (e) {
      ErrorHandler.logError('Failed to clear secure data', error: e);
      rethrow;
    }
  }

  /// Hash password (for local verification only, NEVER send to server)
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number (Indian format)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Validate password strength
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final score = [
      hasMinLength,
      hasUppercase,
      hasLowercase,
      hasDigit,
      hasSpecialChar,
    ].where((e) => e).length;

    String strength;
    if (score <= 2) {
      strength = 'Weak';
    } else if (score <= 3) {
      strength = 'Medium';
    } else if (score <= 4) {
      strength = 'Strong';
    } else {
      strength = 'Very Strong';
    }

    return {
      'isValid': hasMinLength && hasUppercase && hasLowercase && hasDigit,
      'strength': strength,
      'score': score,
      'requirements': {
        'minLength': hasMinLength,
        'uppercase': hasUppercase,
        'lowercase': hasLowercase,
        'digit': hasDigit,
        'specialChar': hasSpecialChar,
      },
    };
  }

  /// Sanitize input (prevent XSS)
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Generate device ID (for device fingerprinting)
  Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _keyDeviceId);
    
    if (deviceId == null || deviceId.isEmpty) {
      // Generate new device ID
      deviceId = _generateDeviceId();
      await _secureStorage.write(key: _keyDeviceId, value: deviceId);
    }
    
    return deviceId;
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode ^ 12345).toString();
    return hashPassword('$timestamp-$random').substring(0, 32);
  }
}
