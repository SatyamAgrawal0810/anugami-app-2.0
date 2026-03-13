// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:anu_app/core/error_handler.dart';
import 'dart:developer' as developer;

/// Production-ready Notification Service
/// Handles push notifications and local notifications for orders
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local Notifications instance
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification handlers
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(Map<String, dynamic>)? onBackgroundNotification;

  // Notification channels
  static const String _orderChannelId = 'order_notifications';
  static const String _orderChannelName = 'Order Notifications';
  static const String _orderChannelDescription =
      'Notifications for order updates';

  static const String _generalChannelId = 'general_notifications';
  static const String _generalChannelName = 'General Notifications';
  static const String _generalChannelDescription = 'General app notifications';

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup Firebase messaging handlers
      await _setupFirebaseMessaging();

      // Get FCM token
      final token = await getFCMToken();
      ErrorHandler.logInfo('FCM Token: $token', tag: 'Notifications');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Failed to initialize notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      ErrorHandler.logInfo(
        'Notification permission: ${settings.authorizationStatus}',
        tag: 'Notifications',
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      ErrorHandler.logError('Permission request failed', error: e);
      return false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS local notification
        if (payload != null) {
          _handleNotificationTap(jsonDecode(payload));
        }
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationTap(jsonDecode(details.payload!));
        }
      },
    );

    // Create notification channels (Android)
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // Order notifications channel
    const orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      _orderChannelName,
      description: _orderChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // General notifications channel
    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDescription,
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Setup Firebase messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message handler is registered in main.dart (top-level function)
    // Do NOT register here again — duplicate registration causes issues

    // Notification opened app from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // Notification opened app from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    ErrorHandler.logInfo(
      'Foreground message: ${message.notification?.title}',
      tag: 'Notifications',
    );

    // Show local notification when app is in foreground
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
        notificationType: _getNotificationType(message.data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    ErrorHandler.logInfo('Notification tapped: $data', tag: 'Notifications');

    if (onNotificationTapped != null) {
      onNotificationTapped!(data);
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      ErrorHandler.logError('Failed to get FCM token', error: e);
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      ErrorHandler.logInfo('Subscribed to topic: $topic', tag: 'Notifications');
    } catch (e) {
      ErrorHandler.logError('Failed to subscribe to topic', error: e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      ErrorHandler.logInfo('Unsubscribed from topic: $topic',
          tag: 'Notifications');
    } catch (e) {
      ErrorHandler.logError('Failed to unsubscribe from topic', error: e);
    }
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType notificationType = NotificationType.general,
  }) async {
    try {
      final channelId = notificationType == NotificationType.order
          ? _orderChannelId
          : _generalChannelId;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        notificationType == NotificationType.order
            ? _orderChannelName
            : _generalChannelName,
        channelDescription: notificationType == NotificationType.order
            ? _orderChannelDescription
            : _generalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification', // ✅ White icon for notification bar
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Anugami',
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'Anugami',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to show local notification', error: e);
    }
  }

  /// Show order confirmation notification
  Future<void> showOrderConfirmation({
    required String orderId,
    required String orderTotal,
  }) async {
    final data = {
      'type': 'order_confirmed',
      'orderId': orderId,
      'orderTotal': orderTotal,
    };

    await showLocalNotification(
      title: '✅ Order Confirmed!',
      body: 'Your order #$orderId has been confirmed. Total: ₹$orderTotal',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show order shipped notification
  Future<void> showOrderShipped({
    required String orderId,
    String? trackingNumber,
  }) async {
    final data = {
      'type': 'order_shipped',
      'orderId': orderId,
      'trackingNumber': trackingNumber,
    };

    await showLocalNotification(
      title: '📦 Order Shipped!',
      body: trackingNumber != null
          ? 'Your order #$orderId is on the way! Tracking: $trackingNumber'
          : 'Your order #$orderId is on the way!',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show order out for delivery notification
  Future<void> showOrderOutForDelivery({
    required String orderId,
    String? estimatedDelivery,
  }) async {
    final data = {
      'type': 'order_out_for_delivery',
      'orderId': orderId,
      'estimatedDelivery': estimatedDelivery,
    };

    await showLocalNotification(
      title: '🚚 Out for Delivery!',
      body: estimatedDelivery != null
          ? 'Your order #$orderId will be delivered by $estimatedDelivery'
          : 'Your order #$orderId is out for delivery!',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show order delivered notification
  Future<void> showOrderDelivered({
    required String orderId,
  }) async {
    final data = {
      'type': 'order_delivered',
      'orderId': orderId,
    };

    await showLocalNotification(
      title: '🎉 Order Delivered!',
      body: 'Your order #$orderId has been delivered successfully!',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show order cancelled notification
  Future<void> showOrderCancelled({
    required String orderId,
    String? reason,
  }) async {
    final data = {
      'type': 'order_cancelled',
      'orderId': orderId,
      'reason': reason,
    };

    await showLocalNotification(
      title: '❌ Order Cancelled',
      body: reason != null
          ? 'Your order #$orderId has been cancelled. Reason: $reason'
          : 'Your order #$orderId has been cancelled.',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show payment success notification
  Future<void> showPaymentSuccess({
    required String orderId,
    required String amount,
    required String paymentMethod,
  }) async {
    final data = {
      'type': 'payment_success',
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
    };

    await showLocalNotification(
      title: '💳 Payment Successful!',
      body: 'Payment of ₹$amount received for order #$orderId',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show refund initiated notification
  Future<void> showRefundInitiated({
    required String orderId,
    required String amount,
  }) async {
    final data = {
      'type': 'refund_initiated',
      'orderId': orderId,
      'amount': amount,
    };

    await showLocalNotification(
      title: '💰 Refund Initiated',
      body: 'Refund of ₹$amount for order #$orderId has been initiated',
      payload: jsonEncode(data),
      notificationType: NotificationType.order,
    );
  }

  /// Show offer/discount notification
  Future<void> showOfferNotification({
    required String title,
    required String description,
    String? offerId,
  }) async {
    final data = {
      'type': 'offer',
      'offerId': offerId,
    };

    await showLocalNotification(
      title: '🎁 $title',
      body: description,
      payload: jsonEncode(data),
      notificationType: NotificationType.general,
    );
  }

  /// Get notification type from data
  NotificationType _getNotificationType(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';

    if (type.contains('order') || type.contains('payment')) {
      return NotificationType.order;
    }

    return NotificationType.general;
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message: ${message.notification?.title}',
    name: 'Notifications',
  );
}

/// Notification types
enum NotificationType {
  order,
  general,
}
