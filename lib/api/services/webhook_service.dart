// lib/services/webhook_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebhookService {
  static final WebhookService _instance = WebhookService._internal();
  factory WebhookService() => _instance;
  WebhookService._internal();

  // Stream controllers for real-time updates
  final _paymentStatusController =
      StreamController<PaymentWebhookData>.broadcast();
  final _shippingStatusController =
      StreamController<ShippingWebhookData>.broadcast();

  // Getters for streams
  Stream<PaymentWebhookData> get paymentStatusStream =>
      _paymentStatusController.stream;
  Stream<ShippingWebhookData> get shippingStatusStream =>
      _shippingStatusController.stream;

  // Simulate webhook reception (in real app, this would come from push notifications or deep links)
  void simulatePaymentWebhook(PaymentWebhookData data) {
    _paymentStatusController.add(data);
  }

  void simulateShippingWebhook(ShippingWebhookData data) {
    _shippingStatusController.add(data);
  }

  // Listen for payment updates for a specific order
  StreamSubscription<PaymentWebhookData> listenForPaymentUpdates({
    required int orderId,
    required Function(PaymentWebhookData) onUpdate,
  }) {
    return paymentStatusStream
        .where((data) => data.orderId == orderId)
        .listen(onUpdate);
  }

  // Listen for shipping updates for a specific order
  StreamSubscription<ShippingWebhookData> listenForShippingUpdates({
    required int orderId,
    required Function(ShippingWebhookData) onUpdate,
  }) {
    return shippingStatusStream
        .where((data) => data.orderId == orderId)
        .listen(onUpdate);
  }

  void dispose() {
    _paymentStatusController.close();
    _shippingStatusController.close();
  }
}

// Models for webhook data
class PaymentWebhookData {
  final int orderId;
  final String transactionId;
  final String status; // PAYMENT_SUCCESS, PAYMENT_FAILED, etc.
  final String paymentMethod;
  final double amount;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  PaymentWebhookData({
    required this.orderId,
    required this.transactionId,
    required this.status,
    required this.paymentMethod,
    required this.amount,
    required this.timestamp,
    this.additionalData = const {},
  });

  factory PaymentWebhookData.fromJson(Map<String, dynamic> json) {
    return PaymentWebhookData(
      orderId: json['order_id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      amount: double.parse(json['amount']?.toString() ?? '0'),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      additionalData: json['additional_data'] ?? {},
    );
  }
}

class ShippingWebhookData {
  final int orderId;
  final String trackingId;
  final String status;
  final String? courierName;
  final String? location;
  final String? activity;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  ShippingWebhookData({
    required this.orderId,
    required this.trackingId,
    required this.status,
    this.courierName,
    this.location,
    this.activity,
    required this.timestamp,
    this.additionalData = const {},
  });

  factory ShippingWebhookData.fromJson(Map<String, dynamic> json) {
    return ShippingWebhookData(
      orderId: json['order_id'] ?? 0,
      trackingId: json['tracking_id'] ?? '',
      status: json['status'] ?? '',
      courierName: json['courier_name'],
      location: json['location'],
      activity: json['activity'],
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      additionalData: json['additional_data'] ?? {},
    );
  }
}

// Enhanced OrderService with webhook integration
// Add these methods to your existing OrderService class:

/*
// lib/api/services/order_service.dart - Additional methods

class OrderService {
  // ... existing methods ...

  // Register device for push notifications
  Future<Map<String, dynamic>> registerForNotifications({
    required String deviceToken,
    required int userId,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final payload = {
        'device_token': deviceToken,
        'user_id': userId,
        'platform': 'android', // or 'ios'
      };

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/register/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to register for notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Update payment callback URLs to include app deep links
  Future<Map<String, dynamic>> initiatePaymentWithWebhooks({
    required int orderId,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    // Use app deep link for redirect to handle payment completion
    final appRedirectUrl = 'yourapp://payment/callback?orderId=$orderId';

    return await initiatePayment(
      orderId: orderId,
      callbackUrl: callbackUrl ?? 'https://yourdomain.com/api/v1/orders/webhooks/phonepe/',
      redirectUrl: redirectUrl ?? appRedirectUrl,
    );
  }
}
*/
