import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/review_model.dart';

class ReviewService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // Get product reviews
  Future<Map<String, dynamic>> getProductReviews(String productSlug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/reviews/?product_slug=$productSlug'),
      );
      print(productSlug);
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final reviews =
            results.map((item) => ReviewModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': reviews,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load reviews: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching reviews: $e',
      };
    }
  }

  // Create review
  Future<Map<String, dynamic>> createReview({
    required String productSlug,
    required int rating,
    required String title,
    required String comment,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/products/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'product_slug': productSlug,
          'rating': rating,
          'title': title,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': ReviewModel.fromJson(responseData),
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create review',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Update review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/products/reviews/$reviewId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'rating': rating,
          'title': title,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': ReviewModel.fromJson(responseData),
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update review',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Delete review
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/reviews/$reviewId/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
