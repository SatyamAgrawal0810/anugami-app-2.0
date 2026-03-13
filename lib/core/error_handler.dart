// lib/core/error_handler.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:anu_app/config/environment.dart';

/// Production-ready error handler
/// Handles all types of errors with proper logging and user-friendly messages
class ErrorHandler {
  // Singleton pattern
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Error types
  static const String networkError = 'NETWORK_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String authError = 'AUTH_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';

  /// Handle error and return user-friendly message
  String handleError(dynamic error, {String? context}) {
    // Log error in development/staging
    if (!EnvironmentConfig.isProduction) {
      developer.log(
        'Error occurred${context != null ? ' in $context' : ''}',
        error: error,
        name: 'ErrorHandler',
      );
    }

    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    if (EnvironmentConfig.getFeatureFlag('enableCrashReporting')) {
      _reportToCrashService(error, context);
    }

    // Return user-friendly message
    return _getUserFriendlyMessage(error);
  }

  /// Get user-friendly error message
  String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'कृपया अपना इंटरनेट कनेक्शन जांचें।\nPlease check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'अनुरोध समय समाप्त हो गया। कृपया पुनः प्रयास करें।\nRequest timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('401')) {
      return 'सत्र समाप्त हो गया। कृपया फिर से लॉगिन करें।\nSession expired. Please login again.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('server') ||
        errorString.contains('internal error')) {
      return 'सर्वर त्रुटि। कृपया बाद में पुनः प्रयास करें।\nServer error. Please try again later.';
    }

    // Validation errors
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'अमान्य डेटा। कृपया अपनी जानकारी जांचें।\nInvalid data. Please check your information.';
    }

    // Default error message
    return 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।\nSomething went wrong. Please try again.';
  }

  /// Report error to crash reporting service
  void _reportToCrashService(dynamic error, String? context) {
    // TODO: Implement crash reporting
    // Example: FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
    if (kDebugMode) {
      developer.log(
        'Would report to crash service: ${error.toString()}',
        name: 'ErrorHandler',
      );
    }
  }

  /// Log error for debugging
  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!EnvironmentConfig.isProduction) {
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        name: 'AppError',
      );
    }
  }

  /// Log info for debugging
  static void logInfo(String message, {String? tag}) {
    if (!EnvironmentConfig.isProduction) {
      developer.log(
        message,
        name: tag ?? 'AppInfo',
      );
    }
  }

  /// Log warning
  static void logWarning(String message, {String? tag}) {
    if (!EnvironmentConfig.isProduction) {
      developer.log(
        '⚠️ $message',
        name: tag ?? 'AppWarning',
      );
    }
  }
}

/// Custom exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String? message])
      : super(message ?? 'Network error occurred', code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException([String? message])
      : super(message ?? 'Server error occurred', code: 'SERVER_ERROR');
}

class AuthException extends AppException {
  AuthException([String? message])
      : super(message ?? 'Authentication failed', code: 'AUTH_ERROR');
}

class ValidationException extends AppException {
  ValidationException([String? message])
      : super(message ?? 'Validation failed', code: 'VALIDATION_ERROR');
}
