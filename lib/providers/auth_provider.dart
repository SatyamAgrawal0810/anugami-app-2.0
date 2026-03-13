// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../api/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _currentUser;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
    String? captchaId,
    String? captchaAnswer,
  }) async {
    _setLoading(true);

    try {
      final result = await _authService.login(
        email,
        password,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );

      if (result['success']) {
        _currentUser = email;
        _userData = {
          'id': result['customer_id'],
          'email': result['email'],
          'full_name': result['full_name'],
        };
        notifyListeners();
      }

      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user account
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _setLoading(true);

    try {
      final result = await _authService.register(userData);
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Request OTP for email verification
  Future<Map<String, dynamic>> requestOTP(String email) async {
    _setLoading(true);

    try {
      final result = await _authService.requestOTP(email);
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP and activate account
  Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otp, {
    String? captchaId,
    String? captchaAnswer,
  }) async {
    _setLoading(true);

    try {
      final result = await _authService.verifyOTP(
        email,
        otp,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
      );

      if (result['success']) {
        _currentUser = email;
        _userData = {
          'id': result['customer_id'],
          'email': result['email'],
          'full_name': result['full_name'],
        };
        notifyListeners();
      }

      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend OTP for email verification
  Future<Map<String, dynamic>> resendOTP(String email) async {
    _setLoading(true);

    try {
      final result = await _authService.resendOTP(email);
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Request password reset OTP
  // ✅ FIXED: was 'requestPasswordReset' → correct name is 'requestPasswordResetOTP'
  Future<Map<String, dynamic>> requestPasswordResetOTP(String email) async {
    _setLoading(true);

    try {
      final result = await _authService.requestPasswordResetOTP(email);
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend password reset OTP
  Future<Map<String, dynamic>> resendPasswordResetOTP(String email) async {
    _setLoading(true);

    try {
      final result = await _authService.resendPasswordResetOTP(email);
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password with OTP (verify OTP + set new password in one call)
  // ✅ FIXED: was 'verifyResetToken' + 'resetPassword' → merged into 'resetPasswordWithOTP'
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);

    try {
      final result = await _authService.resetPasswordWithOTP(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
      _currentUser = null;
      _userData = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is currently logged in
  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final userData = await _authService.getUserData();
        if (userData != null) {
          _currentUser = userData['email'];
          _userData = userData;
          notifyListeners();
        }
      } else {
        _currentUser = null;
        _userData = null;
        notifyListeners();
      }

      return isLoggedIn;
    } catch (e) {
      developer.log('Error checking auth status: $e');
      return false;
    }
  }

  /// Initialize provider (check existing auth state)
  Future<void> initialize() async {
    await checkAuthStatus();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
