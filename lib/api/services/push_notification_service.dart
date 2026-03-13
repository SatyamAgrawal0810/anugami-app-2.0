// lib/services/push_notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'webhook_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final WebhookService _webhookService = WebhookService();

  // Initialize push notifications (Firebase/OneSignal)
  Future<void> initialize() async {
    // Initialize your push notification service here
    // This would typically be Firebase Messaging or OneSignal
    print('Push notification service initialized');
  }

  // Handle incoming push notification
  void handlePushNotification(Map<String, dynamic> data) {
    final notificationType = data['type'] ?? '';

    switch (notificationType) {
      case 'payment_update':
        _handlePaymentNotification(data);
        break;
      case 'shipping_update':
        _handleShippingNotification(data);
        break;
      default:
        print('Unknown notification type: $notificationType');
    }
  }

  void _handlePaymentNotification(Map<String, dynamic> data) {
    try {
      final webhookData = PaymentWebhookData.fromJson(data);
      _webhookService.simulatePaymentWebhook(webhookData);
    } catch (e) {
      print('Error parsing payment notification: $e');
    }
  }

  void _handleShippingNotification(Map<String, dynamic> data) {
    try {
      final webhookData = ShippingWebhookData.fromJson(data);
      _webhookService.simulateShippingWebhook(webhookData);
    } catch (e) {
      print('Error parsing shipping notification: $e');
    }
  }
}
