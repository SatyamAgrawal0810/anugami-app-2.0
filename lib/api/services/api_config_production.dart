// lib/api/services/api_config_production.dart
import 'package:anu_app/config/environment.dart';
import 'dart:io';

/// Production-ready API Configuration
/// Handles API endpoints, headers, timeouts, and error handling
class ApiConfigProduction {
  // Base URL from environment
  static String get baseUrl => EnvironmentConfig.apiUrl;

  // API endpoints
  static const String productsEndpoint = '/api/products';
  static const String categoriesEndpoint = '/api/categories';
  static const String authEndpoint = '/api/auth';
  static const String cartEndpoint = '/api/cart';
  static const String ordersEndpoint = '/api/orders';
  static const String wishlistEndpoint = '/api/wishlist';
  static const String reviewsEndpoint = '/api/reviews';
  static const String addressEndpoint = '/api/addresses';
  static const String profileEndpoint = '/api/profile';
  static const String brandsEndpoint = '/api/brands';
  static const String notificationsEndpoint = '/api/notifications';
  static const String searchEndpoint = '/api/search';

  // API version
  static const String apiVersion = 'v1';

  // Timeouts
  static Duration get connectTimeout =>
      Duration(seconds: EnvironmentConfig.connectTimeout);
  static Duration get receiveTimeout =>
      Duration(seconds: EnvironmentConfig.receiveTimeout);
  static Duration get sendTimeout =>
      Duration(seconds: EnvironmentConfig.sendTimeout);

  // Get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Common headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': EnvironmentConfig.appVersion,
      'X-Platform': Platform.isAndroid ? 'android' : 'ios',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // HTTP Status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;

  // Check if status code indicates success
  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // Check if status code indicates client error
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  // Check if status code indicates server error
  static bool isServerError(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }

  // Error messages
  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case statusBadRequest:
        return 'Invalid request. Please check your input.';
      case statusUnauthorized:
        return 'Session expired. Please login again.';
      case statusForbidden:
        return 'You do not have permission to perform this action.';
      case statusNotFound:
        return 'The requested resource was not found.';
      case statusServerError:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Network check
  static Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
