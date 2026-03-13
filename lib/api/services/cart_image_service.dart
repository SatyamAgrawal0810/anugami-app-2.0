// lib/api/services/cart_image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/product_model.dart';

class CartImageService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // Cache for storing image URLs to avoid repeated API calls
  static final Map<String, String> _imageCache = {};
  static const int _cacheTimeoutMinutes = 30;
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Get product image URL for cart item with caching
  Future<String?> getCartItemImageUrl(
      String productSlug, String? variantId) async {
    final cacheKey = '${productSlug}_${variantId ?? 'default'}';

    // Check cache first
    if (_isValidCachedImage(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/products/$productSlug/'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final product = ProductModel.fromJson(data);

        String? imageUrl = await _getVariantSpecificImage(product, variantId);

        // Cache the result
        if (imageUrl != null) {
          _cacheImage(cacheKey, imageUrl);
        }

        return imageUrl;
      } else {
        print('Failed to fetch product details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching cart item image: $e');
      return null;
    }
  }

  // Get variant-specific image with fallback logic
  Future<String?> _getVariantSpecificImage(
      ProductModel product, String? variantId) async {
    // If variant ID exists, try to find variant-specific image
    if (variantId != null && variantId.isNotEmpty) {
      try {
        // Find the specific variant
        final variant = product.variants.firstWhere(
          (v) => v.id.toString() == variantId,
          orElse: () => throw Exception('Variant not found'),
        );

        // Get color attribute from variant
        String? colorValue = _extractColorFromVariant(variant);

        // Try to get color-specific images
        if (colorValue != null) {
          String? colorImage = _getColorSpecificImage(product, colorValue);
          if (colorImage != null) {
            return colorImage;
          }
        }

        // If no color-specific image, try to find image with matching color_attribute
        if (colorValue != null) {
          String? matchingImage = _getMatchingColorImage(product, colorValue);
          if (matchingImage != null) {
            return matchingImage;
          }
        }
      } catch (e) {
        print('Error processing variant image: $e');
      }
    }

    // Fallback to primary product image
    return _getPrimaryProductImage(product);
  }

  // Extract color value from variant attributes
  String? _extractColorFromVariant(VariantModel variant) {
    try {
      for (final attr in variant.attributes) {
        if (attr.attributeType.toLowerCase() == 'color') {
          return attr.value;
        }
      }
    } catch (e) {
      print('Error extracting color from variant: $e');
    }
    return null;
  }

  // Get color-specific image from colorImages map
  String? _getColorSpecificImage(ProductModel product, String colorValue) {
    try {
      if (product.colorImages.containsKey(colorValue)) {
        final colorImages = product.colorImages[colorValue]!;
        if (colorImages.isNotEmpty) {
          // Try to find primary image first
          final primaryImage = colorImages.firstWhere(
            (img) => img.isPrimary,
            orElse: () => colorImages.first,
          );
          return primaryImage.imageUrl;
        }
      }
    } catch (e) {
      print('Error getting color-specific image: $e');
    }
    return null;
  }

  // Get image with matching color attribute
  String? _getMatchingColorImage(ProductModel product, String colorValue) {
    try {
      final matchingImage = product.images.firstWhere(
        (img) => img.colorAttribute?.toLowerCase() == colorValue.toLowerCase(),
        orElse: () => throw Exception('No matching color image'),
      );
      return matchingImage.imageUrl;
    } catch (e) {
      print('No matching color image found: $e');
      return null;
    }
  }

  // Get primary product image
  String? _getPrimaryProductImage(ProductModel product) {
    try {
      if (product.images.isNotEmpty) {
        final primaryImage = product.images.firstWhere(
          (img) => img.isPrimary,
          orElse: () => product.images.first,
        );
        return primaryImage.imageUrl;
      }
    } catch (e) {
      print('Error getting primary product image: $e');
    }
    return null;
  }

  // Check if cached image is still valid
  bool _isValidCachedImage(String cacheKey) {
    if (!_imageCache.containsKey(cacheKey) ||
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference < _cacheTimeoutMinutes;
  }

  // Cache image URL with timestamp
  void _cacheImage(String cacheKey, String imageUrl) {
    _imageCache[cacheKey] = imageUrl;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  // Clear cache (useful for memory management)
  static void clearCache() {
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  // Get cached image without API call
  String? getCachedImageUrl(String productSlug, String? variantId) {
    final cacheKey = '${productSlug}_${variantId ?? 'default'}';
    return _isValidCachedImage(cacheKey) ? _imageCache[cacheKey] : null;
  }

  // Preload images for multiple cart items
  Future<void> preloadCartItemImages(
      List<Map<String, dynamic>> cartItems) async {
    final futures = cartItems.map((item) async {
      try {
        final productSlug = item['product_slug'] as String?;
        final variantId = item['variant_id']?.toString();

        if (productSlug != null) {
          await getCartItemImageUrl(productSlug, variantId);
        }
      } catch (e) {
        print('Error preloading image for item: $e');
      }
    });

    await Future.wait(futures);
  }

  // Get multiple cart item images in parallel
  Future<Map<String, String?>> getMultipleCartItemImages(
    List<Map<String, String?>> items,
  ) async {
    final Map<String, String?> results = {};

    final futures = items.map((item) async {
      final productSlug = item['productSlug'];
      final variantId = item['variantId'];
      final key = item['key'] ?? '${productSlug}_${variantId ?? 'default'}';

      if (productSlug != null) {
        try {
          final imageUrl = await getCartItemImageUrl(productSlug, variantId);
          results[key] = imageUrl;
        } catch (e) {
          print('Error loading image for $key: $e');
          results[key] = null;
        }
      }
    });

    await Future.wait(futures);
    return results;
  }

  // Validate image URL accessibility
  Future<bool> validateImageUrl(String imageUrl) async {
    try {
      final response = await http
          .head(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Image validation failed for $imageUrl: $e');
      return false;
    }
  }

  // Get image URL with retry mechanism
  Future<String?> getCartItemImageUrlWithRetry(
    String productSlug,
    String? variantId, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final imageUrl = await getCartItemImageUrl(productSlug, variantId);
        if (imageUrl != null) {
          return imageUrl;
        }
      } catch (e) {
        print('Attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          print('All attempts failed for $productSlug');
          return null;
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return null;
  }
}
