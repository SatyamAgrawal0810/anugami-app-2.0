// lib/utils/app_notifications.dart
// ✅ FIX: Removed self-import (was causing compile error)
// ✅ PRODUCTION-READY NOTIFICATION SYSTEM

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNotifications {
  /// Show ERROR message — Always visible (user must know about errors)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show SUCCESS message
  /// - Debug mode: always shown
  /// - Production: only shown when alwaysShow = true (critical actions)
  static void showSuccess(
    BuildContext context,
    String message, {
    bool alwaysShow = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    if (!kDebugMode && !alwaysShow) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF96A4C),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show INFO message — Debug mode only
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    if (!kDebugMode) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show WARNING message — Always visible
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Debug-only message — Never shown in production
  static void debug(BuildContext context, String message) {
    if (!context.mounted || !kDebugMode) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '[DEBUG] $message',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Usage guide:
///
/// // ✅ Always visible — use for errors
/// AppNotifications.showError(context, 'Failed to load products');
///
/// // ✅ Critical success — visible in production
/// AppNotifications.showSuccess(context, 'Order placed!', alwaysShow: true);
///
/// // ⚠️ Hidden in production — debug only
/// AppNotifications.showSuccess(context, 'Item added to cart');
/// AppNotifications.showInfo(context, 'Loading...');
/// AppNotifications.debug(context, 'API call successful');
///
/// // ✅ Always visible — use for warnings
/// AppNotifications.showWarning(context, 'Stock running low');
