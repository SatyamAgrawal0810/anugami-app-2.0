// lib/api/services/category_service.dart
import 'dart:convert';
import 'package:anu_app/core/models/product_model.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import '../../core/models/category_model.dart';

class CategoryService {
  final String baseUrl = 'https://anugami.com/api/v1/categories';
  // Fetch flat list of categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/'));
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        print(results);

        return results.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Fetch hierarchical tree structure of categories
  Future<List<CategoryModel>> getCategoryTree() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/tree/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(data);

        return data.map((item) => CategoryModel.fromTreeJson(item)).toList();
      } else {
        throw Exception('Failed to load category tree: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category tree: $e');
    }
  }

  // Get Category By Slug

  Future<Map<String, dynamic>> getCategoryBySlug(String slug) async {
    try {
      print(slug);
      final response = await http.get(Uri.parse('$baseUrl/categories/$slug'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load category details: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching category details: $e',
      };
    }
  }

  // Get featured categories
  Future<List<CategoryModel>> getFeaturedCategories() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/categories/?is_featured=true'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load featured categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured categories: $e');
    }
  }
// lib/api/services/category_service.dart - Update this method

  // Get products and subcategories by category tree
  Future<Map<String, dynamic>> getProductsByCategoryTree(String slug) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://anugami.com/api/v1/products/by-category-tree/?slug=$slug'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract product IDs or slugs from the results
        final List<dynamic> results = data['results'] ?? [];
        final List<Map<String, dynamic>> basicProducts = [];

        // Convert each result to a simple map with basic info
        for (var item in results) {
          try {
            basicProducts.add({
              'id': item['id'],
              'slug': item['slug'],
              'name': item['name'],
              'basicInfo': item // Store the original data
            });
          } catch (e) {
            print('Error parsing basic product info: $e');
          }
        }

        // Also get subcategories for this category
        final subcategoriesResponse = await http.get(
          Uri.parse('$baseUrl/categories/$slug'),
        );

        List<CategoryModel> subcategories = [];
        if (subcategoriesResponse.statusCode == 200) {
          final subcategoryData = json.decode(subcategoriesResponse.body);
          // Check if there's a children array containing subcategories
          if (subcategoryData.containsKey('children') &&
              subcategoryData['children'] is List) {
            subcategories = (subcategoryData['children'] as List)
                .map((item) => CategoryModel.fromJson(item))
                .toList();
          }
        }

        return {
          'success': true,
          'basicProducts': basicProducts,
          'count': data['count'] ?? basicProducts.length,
          'next': data['next'],
          'previous': data['previous'],
          'subcategories': subcategories
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load category products: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in getProductsByCategoryTree: $e');
      return {
        'success': false,
        'message': 'Error fetching category products: $e',
      };
    }
  }
}
