// lib/api/services/wishlist_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/wishlist_item_model.dart';

class WishlistService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // Add item to wishlist
  Future<Map<String, dynamic>> addToWishlist({
    required String productId,
    String? variantId,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final payload = {
        'product_id': productId,
      };

      if (variantId != null) {
        payload['variant_id'] = variantId;
      }

      print('Adding to wishlist with payload: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/customers/wishlist/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(payload),
      );

      print('Add to wishlist response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Item added to wishlist successfully',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Failed to add item to wishlist',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get wishlist items
  Future<Map<String, dynamic>> getWishlistItems() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      print('Fetching wishlist items...');

      final response = await http.get(
        Uri.parse('$baseUrl/customers/wishlist/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print('Get wishlist response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Parse wishlist items
        List<WishlistItemModel> wishlistItems = [];
        if (responseData['items'] != null) {
          wishlistItems = (responseData['items'] as List)
              .map((item) => WishlistItemModel.fromJson(item))
              .toList();
        }

        return {
          'success': true,
          'data': {
            'items': wishlistItems,
            'count': responseData['count'] ?? 0,
          },
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Failed to fetch wishlist items',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // ✅ FIXED: Remove item from wishlist - using product_id instead of wishlist_id
  Future<Map<String, dynamic>> removeFromWishlist({
    required int wishlistId,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // ✅ FIX: First get the wishlist item to extract product_id
      print(
          'Fetching wishlist to get product_id for wishlist item $wishlistId');
      final wishlistResponse = await getWishlistItems();

      if (!wishlistResponse['success']) {
        return {
          'success': false,
          'message': 'Failed to fetch wishlist items',
        };
      }

      final items =
          wishlistResponse['data']['items'] as List<WishlistItemModel>;

      WishlistItemModel? targetItem;
      try {
        targetItem = items.firstWhere((item) => item.id == wishlistId);
      } catch (e) {
        return {
          'success': false,
          'message': 'Wishlist item not found',
        };
      }

      // ✅ Use product_id from the wishlist item (API requirement)
      final payload = <String, dynamic>{
        'product_id': targetItem.productId,
      };

      // Add variant_id if exists
      if (targetItem.variantId != null) {
        payload['variant_id'] = targetItem.variantId!;
      }

      print('Removing wishlist item with payload: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/customers/wishlist/remove/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(payload),
      );

      print('Remove response: ${response.statusCode}');
      print('Remove response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Item removed from wishlist successfully',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              responseData['error'] ??
              'Failed to remove item from wishlist',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Clear entire wishlist
  Future<Map<String, dynamic>> clearWishlist() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      print('Clearing wishlist...');

      final response = await http.post(
        Uri.parse('$baseUrl/customers/wishlist/clear/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print('Clear wishlist response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Wishlist cleared successfully',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['detail'] ??
              'Failed to clear wishlist',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Error clearing wishlist: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get saved auth token from shared preferences
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}
