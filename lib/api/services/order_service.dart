// lib/api/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anu_app/core/error_handler.dart';

class OrderService {
  // ✅ Base URL — endpoints append /orders/... to get full path
  final String baseUrl = 'https://anugami.com/api/v1';

  // ── Get all orders ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/orders/my_orders/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final data = json.decode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch orders',
        'errors': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ── Get single order details ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/orders/$orderId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final data = json.decode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch order details',
        'errors': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ── Cancel order ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    required String reason,
    required String note,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final fcmToken = await _getFcmToken();
      if (fcmToken == null) {
        ErrorHandler.logWarning(
          '⚠️ FCM token is NULL — backend will skip push notification',
          tag: 'OrderService.cancelOrder',
        );
      } else {
        ErrorHandler.logInfo(
          '✅ FCM token found: ${fcmToken.substring(0, 20)}...',
          tag: 'OrderService.cancelOrder',
        );
      }

      final payload = <String, dynamic>{
        'reason': reason,
        'note': note,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      ErrorHandler.logInfo(
        '📦 cancelOrder payload keys: ${payload.keys.toList()}',
        tag: 'OrderService.cancelOrder',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/orders/orders/$orderId/cancel/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      ErrorHandler.logInfo(
        '📡 cancelOrder response: ${response.statusCode}',
        tag: 'OrderService.cancelOrder',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Order cancelled successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Cancellation failed',
        'errors': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Cancel order failed: $e'};
    }
  }

  // ── Checkout ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkout({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    String? couponCode,
    bool clearCart = true,
    bool autoCreateShipments = false,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final fcmToken = await _getFcmToken();
      if (fcmToken == null) {
        ErrorHandler.logWarning(
          '⚠️ FCM token is NULL — backend will skip push notification',
          tag: 'OrderService.checkout',
        );
      } else {
        ErrorHandler.logInfo(
          '✅ FCM token found: ${fcmToken.substring(0, 20)}...',
          tag: 'OrderService.checkout',
        );
      }

      final payload = <String, dynamic>{
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'auto_create_shipments': autoCreateShipments,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      if (couponCode != null && couponCode.isNotEmpty) {
        payload['coupon'] = couponCode;
      }
      if (callbackUrl != null) payload['callback_url'] = callbackUrl;
      if (redirectUrl != null) payload['redirect_url'] = redirectUrl;

      ErrorHandler.logInfo(
        '📦 checkout payload keys: ${payload.keys.toList()}',
        tag: 'OrderService.checkout',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/orders/orders/checkout/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      ErrorHandler.logInfo(
        '📡 checkout response: ${response.statusCode}',
        tag: 'OrderService.checkout',
      );

      if (response.headers['content-type']?.contains('text/html') == true) {
        return {
          'success': false,
          'message':
              'Server returned HTML error page. Status: ${response.statusCode}',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid JSON response from server',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      }
      return {
        'success': false,
        'message': responseData['error'] ??
            responseData['message'] ??
            'Checkout failed',
        'errors': responseData,
        'status_code': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Verify payment ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/orders/verify-payment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final data = json.decode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? 'Payment verification failed',
        'errors': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ── Track order ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/orders/$orderId/track/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      final data = json.decode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? 'Failed to track order',
        'errors': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ── Get order status ────────────────────────────────────────────────────────
  Future<String?> getOrderStatus(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/orders/orders/$orderId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    ErrorHandler.logInfo(
      token != null
          ? '🔑 SharedPrefs fcm_token exists (${token.length} chars)'
          : '❌ SharedPrefs fcm_token is missing/null',
      tag: 'OrderService._getFcmToken',
    );
    return token;
  }
}
