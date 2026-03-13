// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../api/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user's full name
  String get fullName =>
      _userData != null && _userData!.containsKey('full_name')
          ? _userData!['full_name']
          : 'Guest User';

  // Get user's email
  String get email => _userData != null && _userData!.containsKey('email')
      ? _userData!['email']
      : '';

  // Get user's ID
  String get userId => _userData != null && _userData!.containsKey('id')
      ? _userData!['id'].toString()
      : '';

  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _userData = await _authService.getUserData();
        developer.log('UserProvider initialized with data: $_userData');
      } else {
        developer.log('UserProvider initialized: user not logged in');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      developer.log('Error initializing UserProvider: $_error');
      notifyListeners();
    }
  }

  // Set user data after login or registration
  void setUserData(Map<String, dynamic> userData) {
    developer.log('UserProvider: Setting user data: $userData');
    _userData = userData;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Update user data - merge with existing data
  void updateUserData(Map<String, dynamic> newData) {
    if (_userData != null) {
      _userData = {..._userData!, ...newData};
    } else {
      _userData = newData;
    }
    _isLoggedIn = true;
    notifyListeners();
  }

  // Process registration response data
  void processRegistrationData(Map<String, dynamic> responseData) {
    final userData = {
      'id': responseData['id'] ?? '',
      'email': responseData['email'] ?? '',
      'full_name': responseData['full_name'] ?? '',
    };

    setUserData(userData);
  }

  // Process login response data
  void processLoginData(Map<String, dynamic> responseData) {
    final userData = {
      'id': responseData['customer_id'] ?? '',
      'email': responseData['email'] ?? '',
      'full_name': responseData['full_name'] ?? '',
    };

    setUserData(userData);
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoggedIn = false;
      _userData = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
