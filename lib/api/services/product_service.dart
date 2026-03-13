// lib/api/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/product_model.dart';
import '../../core/models/mobile_variant_model.dart';

class ProductService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // Get single product details by slug
  Future<Map<String, dynamic>> getProductBySlug(String slug) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/products/products/$slug/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': ProductModel.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load product details: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching product details: $e',
      };
    }
  }

  // Brand products fetch karne ke liye method
  Future<Map<String, dynamic>> getProductsByBrand(String brandsSlug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products?brands=$brandsSlug'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<ProductModel> products = [];

        // Check different possible response structures
        if (data['products'] != null) {
          products = (data['products'] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data['results'] != null) {
          products = (data['results'] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data is List) {
          products = (data as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        }

        return {
          'success': true,
          'data': products,
          'count': data['count'] ?? products.length,
          'message': 'Products loaded successfully',
        };
      } else {
        return {
          'success': false,
          'data': <ProductModel>[],
          'message': 'Failed to load products: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in getProductsByBrand: $e');
      return {
        'success': false,
        'data': <ProductModel>[],
        'message': 'Error: $e',
      };
    }
  }

  // Get mobile variant selector data
  Future<Map<String, dynamic>> getMobileVariantSelector(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/mobile-variant-selector/$slug/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': MobileVariantSelector.fromJson(data),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load variant data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching variant data: $e',
      };
    }
  }

  // Fetch all products with optional parameters
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
    String? ordering,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional parameters if provided
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final uri = Uri.parse('$baseUrl/products/products/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert results to ProductModel list
        final List<dynamic> results = data['results'];
        final products =
            results.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': products,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching products: $e',
      };
    }
  }

  // Get new arrivals - most recently created products
  Future<Map<String, dynamic>> getNewArrivals({int limit = 10}) async {
    return getProducts(ordering: '-created_at', limit: limit);
  }

  // Get best sellers - products with highest order count
  Future<Map<String, dynamic>> getBestSellers({int limit = 10}) async {
    return getProducts(ordering: '-order_count', limit: limit);
  }

  Future<Map<String, dynamic>> getFeaturedProducts({int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/featured/');

      // Get token if available
      final String? token = await _getToken();
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        print(response.body);

        // Check if the response is a Map or List
        if (decodedData is Map<String, dynamic>) {
          // If it's a Map, extract the results array
          final List<dynamic> data =
              decodedData['results'] ?? decodedData['data'] ?? [];

          // Process the featured products
          final products = await _processSimplifiedProducts(data);

          return {
            'success': true,
            'data': products,
            'count': decodedData['count'] ?? products.length,
            'next': decodedData['next'],
            'previous': decodedData['previous'],
          };
        } else if (decodedData is List<dynamic>) {
          // If it's already a List, process directly
          final products = await _processSimplifiedProducts(decodedData);

          return {
            'success': true,
            'data': products,
            'count': products.length,
          };
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format from featured products API',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load featured products: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in getFeaturedProducts: $e');
      return {
        'success': false,
        'message': 'Error fetching featured products: $e',
      };
    }
  }

  // Helper to process the simplified product format from the featured products endpoint
  Future<List<ProductModel>> _processSimplifiedProducts(
      List<dynamic> data) async {
    List<ProductModel> products = [];

    for (var item in data) {
      // Get detailed product info for each featured product
      try {
        final slug = item['slug'] ?? '';
        final detailResult = await getProductBySlug(slug);

        if (detailResult['success'] && detailResult['data'] != null) {
          products.add(detailResult['data']);
        } else {
          // Create a basic product model from the limited data
          products.add(ProductModel(
            id: item['id'] ?? 0,
            name: item['name'] ?? '',
            slug: item['slug'] ?? '',
            description: item['description'] ?? '',
            shortDescription: item['short_description'] ?? '',
            category: item['category'] ?? '',
            brand: BrandModel.empty(),
            regularPrice: item['regular_price'] ?? '0.00',
            salePrice: item['sale_price'] ?? '0.00',
            costPrice: item['cost_price'] ?? '0.00',
            stockQuantity: item['stock_quantity'] ?? 0,
            isActive: item['is_active'] ?? false,
            isFeatured: true,
            images: [],
            videos: [],
            attributes: [],
            reviews: [],
            variants: [],
            colorImages: {},
            availableColors: [],
            availableSizes: {},
            createdAt: '',
            updatedAt: '',
          ));
        }
      } catch (e) {
        print('Error processing featured product: $e');
      }
    }

    return products;
  }

  // Get products by category
  Future<Map<String, dynamic>> getProductsByCategory(String categorySlug,
      {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/products/products/').replace(
          queryParameters: {
            'category': categorySlug,
            'page': page.toString(),
            'limit': limit.toString()
          });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert results to ProductModel list
        final List<dynamic> results = data['results'];
        final products =
            results.map((item) => ProductModel.fromJson(item)).toList();

        return {
          'success': true,
          'data': products,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching products: $e',
      };
    }
  }

  // Search products
  Future<Map<String, dynamic>> searchProducts(String query,
      {int page = 1, int limit = 20}) async {
    return getProducts(search: query, page: page, limit: limit);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
