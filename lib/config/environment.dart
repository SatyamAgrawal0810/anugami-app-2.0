// lib/config/environment.dart
/// Production-ready environment configuration
/// Handles different environments (dev, staging, production)

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  // Current environment
  static const Environment _environment =
      Environment.production; // Change as needed

  // Environment-specific API URLs
  static const Map<Environment, String> _apiUrls = {
    Environment.development: 'http://localhost:3000',
    Environment.staging: 'https://staging-api.anugami.com',
    Environment.production: 'https://anugami.com',
  };

  // Environment-specific feature flags
  static const Map<Environment, Map<String, bool>> _featureFlags = {
    Environment.development: {
      'enableDebugMode': true,
      'enableAnalytics': false,
      'enableCrashReporting': false,
      'enablePerformanceMonitoring': false,
      'showDebugBanner': true,
    },
    Environment.staging: {
      'enableDebugMode': true,
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enablePerformanceMonitoring': true,
      'showDebugBanner': true,
    },
    Environment.production: {
      'enableDebugMode': false,
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enablePerformanceMonitoring': true,
      'showDebugBanner': false,
    },
  };

  // Getters
  static Environment get environment => _environment;
  static String get apiUrl => _apiUrls[_environment]!;
  static bool get isProduction => _environment == Environment.production;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;

  // Feature flags
  static bool getFeatureFlag(String flag) {
    return _featureFlags[_environment]?[flag] ?? false;
  }

  // App version and build number (update before each release)
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // API timeouts (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // Cache settings
  static const int imageCacheMaxAge = 7; // days
  static const int dataCacheMaxAge = 24; // hours

  // App constants
  static const String appName = 'Anugami E-commerce';
  static const String supportEmail = 'support@anugami.com';
  static const String privacyPolicyUrl = 'https://anugami.com/privacy';
  static const String termsOfServiceUrl = 'https://anugami.com/terms';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Security
  static const bool enforceSSL = true;
  static const bool validateCertificates = true;

  // Print configuration (for debugging)
  static void printConfig() {
    print('========================================');
    print('🚀 Environment Configuration');
    print('========================================');
    print('Environment: ${_environment.name}');
    print('API URL: $apiUrl');
    print('App Version: $appVersion');
    print('Build Number: $buildNumber');
    print('Debug Mode: ${getFeatureFlag('enableDebugMode')}');
    print('Analytics: ${getFeatureFlag('enableAnalytics')}');
    print('Crash Reporting: ${getFeatureFlag('enableCrashReporting')}');
    print('========================================');
  }
}
