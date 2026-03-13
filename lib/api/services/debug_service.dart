import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DebugService {
  final String baseUrl = 'https://anugami.com/api/v1/orders';

  // Test authentication and user info
  Future<Map<String, dynamic>> testAuth() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      // Test profile endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/customers/profile/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Auth Test Response Status: ${response.statusCode}');
      print('Auth Test Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': 'Auth failed with status: ${response.statusCode}',
          'response': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Auth test error: $e',
      };
    }
  }

  // Test cart contents
  Future<Map<String, dynamic>> testCart() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/customers/cart/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Cart Test Response Status: ${response.statusCode}');
      print('Cart Test Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Cart test failed with status: ${response.statusCode}',
          'response': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cart test error: $e',
      };
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
