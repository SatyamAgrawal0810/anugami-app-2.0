// lib/utils/app_logger.dart
// Production-ready logging utility with different log levels

import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class AppLogger {
  // Prevent instantiation
  AppLogger._();

  // Configure whether to show logs in production
  static bool enableLogsInProduction = false;

  // Log level threshold (only logs at or above this level will be shown)
  static LogLevel logLevelThreshold = LogLevel.info;

  /// Logs a debug message (only in debug mode by default)
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  /// Logs an info message
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  /// Logs a warning message
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  /// Logs an error message with optional error and stack trace
  static void error(
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, message, tag, error, stackTrace);
  }

  /// Logs a critical error (always shown)
  static void critical(
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.critical, message, tag, error, stackTrace);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message,
    String? tag, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    // Only log if in debug mode or if production logging is enabled
    if (!kDebugMode && !enableLogsInProduction) {
      // In production without logging enabled:
      // - Still log errors to crash reporting service (implement your service here)
      if (level == LogLevel.error || level == LogLevel.critical) {
        _reportToCrashService(message, error, stackTrace);
      }
      return;
    }

    // Check if this log level should be shown
    if (level.index < logLevelThreshold.index) {
      return;
    }

    // Format the log message
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag]' : '';
    final fullMessage = '$timestamp $levelStr $tagStr $message';

    // Print to console (in production, you might want to send to a logging service)
    if (kDebugMode) {
      // Use debugPrint in debug mode for better Flutter DevTools integration
      debugPrint(fullMessage);
    } else {
      // In production, send to logging service (e.g., Firebase Crashlytics, Sentry)
      print(fullMessage);
    }

    // If there's an error or stack trace, log those too
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  Stack trace:\n$stackTrace');
    }
  }

  /// Get string representation of log level
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO ';
      case LogLevel.warning:
        return '⚠️  WARN ';
      case LogLevel.error:
        return '❌ ERROR';
      case LogLevel.critical:
        return '🔥 CRITICAL';
    }
  }

  /// Report critical errors to crash reporting service
  /// TODO: Implement your crash reporting service here (Firebase Crashlytics, Sentry, etc.)
  static void _reportToCrashService(
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    // Example implementation:
    // FirebaseCrashlytics.instance.recordError(
    //   error ?? Exception(message),
    //   stackTrace,
    //   reason: message,
    // );

    // For now, just print in debug mode
    if (kDebugMode) {
      debugPrint('CRASH REPORT: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
    }
  }

  /// Log network requests (useful for debugging API calls)
  static void logApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? params,
    int? statusCode,
    String? response,
  }) {
    if (!kDebugMode && !enableLogsInProduction) return;

    final buffer = StringBuffer();
    buffer.writeln('🌐 API Call: $method $endpoint');
    if (params != null && params.isNotEmpty) {
      buffer.writeln('   Params: $params');
    }
    if (statusCode != null) {
      buffer.writeln('   Status: $statusCode');
    }
    if (response != null && kDebugMode) {
      buffer.writeln(
          '   Response: ${response.length > 200 ? '${response.substring(0, 200)}...' : response}');
    }

    debug(buffer.toString(), 'API');
  }

  /// Log user actions (useful for analytics)
  static void logUserAction(String action, [Map<String, dynamic>? properties]) {
    if (!kDebugMode && !enableLogsInProduction) {
      // In production, send to analytics service
      // TODO: Implement analytics service (Firebase Analytics, Mixpanel, etc.)
      // FirebaseAnalytics.instance.logEvent(
      //   name: action,
      //   parameters: properties,
      // );
      return;
    }

    final propertiesStr = properties != null ? ' - $properties' : '';
    info('User Action: $action$propertiesStr', 'USER_ACTION');
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    if (!kDebugMode && !enableLogsInProduction) return;

    info('Performance: $operation took ${duration.inMilliseconds}ms',
        'PERFORMANCE');
  }
}

/// Extension for easy timing of operations
extension LoggerTiming on Future<T> Function<T>() {
  Future<T> timed<T>(String operationName) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await this();
      stopwatch.stop();
      AppLogger.logPerformance(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Operation failed: $operationName (${stopwatch.elapsed})',
          'PERFORMANCE', e);
      rethrow;
    }
  }
}
