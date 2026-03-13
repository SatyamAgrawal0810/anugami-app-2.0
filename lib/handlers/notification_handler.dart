// lib/handlers/notification_handler.dart
// ✅ FIX: Uses snake_case keys (order_id, offer_id, product_id) to match Django backend
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anu_app/core/error_handler.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  void handleNotificationTap(Map<String, dynamic> data) {
    ErrorHandler.logInfo('Handling notification: $data',
        tag: 'NotificationHandler');

    final type = data['type']?.toString().toLowerCase() ?? '';
    final context = navigatorKey.currentContext;

    if (context == null) {
      ErrorHandler.logWarning('Navigation context not available');
      return;
    }

    try {
      switch (type) {
        case 'order_confirmed':
        case 'order_placed':
        case 'order_shipped':
        case 'order_out_for_delivery':
        case 'order_delivered':
        case 'order_cancelled':
        case 'payment_success':
        case 'refund_initiated':
          _handleOrderNotification(context, data);
          break;

        case 'offer':
          _handleOfferNotification(context, data);
          break;

        case 'product':
          _handleProductNotification(context, data);
          break;

        case 'cart_reminder':
          context.push('/cart');
          break;

        case 'wishlist_price_drop':
          _handlePriceDrop(context, data);
          break;

        default:
          ErrorHandler.logWarning('Unknown notification type: $type');
          context.go('/home');
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'Failed to handle notification',
        error: e,
        stackTrace: stackTrace,
      );
      context.go('/home');
    }
  }

  void _handleOrderNotification(
      BuildContext context, Map<String, dynamic> data) {
    // ✅ FIX: Django sends 'order_id' (snake_case), not 'orderId' (camelCase)
    final orderId = data['order_id']?.toString();

    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
    } else {
      context.push('/orders');
    }
  }

  void _handleOfferNotification(
      BuildContext context, Map<String, dynamic> data) {
    // ✅ FIX: 'offer_id' not 'offerId'
    final offerId = data['offer_id']?.toString();

    if (offerId != null && offerId.isNotEmpty) {
      context.push('/offers/$offerId');
    } else {
      context.push('/offers');
    }
  }

  void _handleProductNotification(
      BuildContext context, Map<String, dynamic> data) {
    // ✅ FIX: 'product_id' not 'productId'
    final productId = data['product_id']?.toString();

    if (productId != null && productId.isNotEmpty) {
      context.push('/products/$productId');
    } else {
      context.go('/home');
    }
  }

  void _handlePriceDrop(BuildContext context, Map<String, dynamic> data) {
    // ✅ FIX: 'product_id' not 'productId'
    final productId = data['product_id']?.toString();

    if (productId != null && productId.isNotEmpty) {
      context.push('/products/$productId');
    } else {
      context.push('/wishlist');
    }
  }
}
