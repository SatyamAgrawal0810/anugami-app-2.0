// lib/api/services/order_service_with_notifications.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anu_app/api/services/api_config_production.dart';
import 'package:anu_app/core/error_handler.dart';
import 'package:anu_app/api/services/notification_service.dart';

/// Order Service with Notification Integration
/// Handles order operations and triggers notifications
class OrderServiceWithNotifications {
  // Singleton pattern
  static final OrderServiceWithNotifications _instance =
      OrderServiceWithNotifications._internal();
  factory OrderServiceWithNotifications() => _instance;
  OrderServiceWithNotifications._internal();

  final NotificationService _notificationService = NotificationService();

  /// Place new order
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethod,
    required double totalAmount,
    String? couponCode,
  }) async {
    try {
      // Prepare order data
      final orderData = {
        'items': items,
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'couponCode': couponCode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Make API call
      final response = await http.post(
        Uri.parse(ApiConfigProduction.getUrl('/api/orders')),
        headers: ApiConfigProduction.getHeaders(),
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final orderId = result['orderId']?.toString() ?? '';
        final orderTotal = totalAmount.toString();

        // ✅ Show order confirmation notification
        if (orderId.isNotEmpty) {
          await _notificationService.showOrderConfirmation(
            orderId: orderId,
            orderTotal: orderTotal,
          );
        }

        return {
          'success': true,
          'orderId': orderId,
          'data': result,
          'message': 'Order placed successfully!',
        };
      } else {
        throw Exception('Failed to place order: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Order placement failed',
        error: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': ErrorHandler().handleError(e, context: 'PlaceOrder'),
      };
    }
  }

  /// Update order status (called when backend updates status)
  Future<void> handleOrderStatusUpdate({
    required String orderId,
    required String status,
    String? trackingNumber,
    String? estimatedDelivery,
    String? cancellationReason,
  }) async {
    try {
      final statusLower = status.toLowerCase();

      switch (statusLower) {
        case 'confirmed':
          // Order confirmed notification already sent on order placement
          break;

        case 'shipped':
        case 'dispatched':
          await _notificationService.showOrderShipped(
            orderId: orderId,
            trackingNumber: trackingNumber,
          );
          break;

        case 'out_for_delivery':
        case 'out for delivery':
          await _notificationService.showOrderOutForDelivery(
            orderId: orderId,
            estimatedDelivery: estimatedDelivery,
          );
          break;

        case 'delivered':
          await _notificationService.showOrderDelivered(
            orderId: orderId,
          );
          break;

        case 'cancelled':
          await _notificationService.showOrderCancelled(
            orderId: orderId,
            reason: cancellationReason,
          );
          break;

        default:
          ErrorHandler.logWarning('Unknown order status: $status');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Failed to handle order status update',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle payment success
  Future<void> handlePaymentSuccess({
    required String orderId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await _notificationService.showPaymentSuccess(
        orderId: orderId,
        amount: amount.toString(),
        paymentMethod: paymentMethod,
      );

      ErrorHandler.logInfo(
        'Payment success notification sent for order: $orderId',
        tag: 'OrderService',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Failed to send payment notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle refund
  Future<void> handleRefundInitiated({
    required String orderId,
    required double amount,
  }) async {
    try {
      await _notificationService.showRefundInitiated(
        orderId: orderId,
        amount: amount.toString(),
      );

      ErrorHandler.logInfo(
        'Refund notification sent for order: $orderId',
        tag: 'OrderService',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Failed to send refund notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfigProduction.getUrl('/api/orders/$orderId')),
        headers: ApiConfigProduction.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        throw Exception('Failed to get order details');
      }
    } catch (e) {
      return {
        'success': false,
        'error': ErrorHandler().handleError(e, context: 'GetOrderDetails'),
      };
    }
  }

  /// Get all orders
  Future<Map<String, dynamic>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfigProduction.getUrl('/api/orders')),
        headers: ApiConfigProduction.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? [],
        };
      } else {
        throw Exception('Failed to get orders');
      }
    } catch (e) {
      return {
        'success': false,
        'error': ErrorHandler().handleError(e, context: 'GetAllOrders'),
      };
    }
  }

  /// Cancel order
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfigProduction.getUrl('/api/orders/$orderId/cancel')),
        headers: ApiConfigProduction.getHeaders(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        // Show cancellation notification
        await _notificationService.showOrderCancelled(
          orderId: orderId,
          reason: reason,
        );

        return {
          'success': true,
          'message': 'Order cancelled successfully',
        };
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      return {
        'success': false,
        'error': ErrorHandler().handleError(e, context: 'CancelOrder'),
      };
    }
  }

  /// Track order
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfigProduction.getUrl('/api/orders/$orderId/track')),
        headers: ApiConfigProduction.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'trackingInfo': data,
        };
      } else {
        throw Exception('Failed to track order');
      }
    } catch (e) {
      return {
        'success': false,
        'error': ErrorHandler().handleError(e, context: 'TrackOrder'),
      };
    }
  }
}
