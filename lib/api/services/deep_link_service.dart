// lib/services/deep_link_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'webhook_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final WebhookService _webhookService = WebhookService();

  // Initialize deep link handling
  Future<void> initialize() async {
    // Initialize deep link handling
    // This would listen for app links from PhonePe redirect
    print('Deep link service initialized');
  }

  // Handle deep link from PhonePe redirect
  void handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final queryParams = uri.queryParameters;

    // Extract payment information from PhonePe redirect
    final transactionId = queryParams['transactionId'];
    final status = queryParams['status'];
    final orderId = queryParams['orderId'];

    if (transactionId != null && status != null && orderId != null) {
      _handlePaymentRedirect({
        'order_id': int.tryParse(orderId) ?? 0,
        'transaction_id': transactionId,
        'status': status,
        'payment_method': 'PhonePe-UPI',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handlePaymentRedirect(Map<String, dynamic> data) {
    try {
      final webhookData = PaymentWebhookData.fromJson(data);
      _webhookService.simulatePaymentWebhook(webhookData);
    } catch (e) {
      print('Error parsing payment redirect: $e');
    }
  }
}
