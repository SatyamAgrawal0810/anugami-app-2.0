// lib/core/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive caching service for all app data
class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  // Cache duration constants (in hours)
  static const int PRODUCTS_CACHE_DURATION = 2;
  static const int CATEGORIES_CACHE_DURATION = 24;
  static const int CART_CACHE_DURATION = 1;
  static const int WISHLIST_CACHE_DURATION = 12;
  static const int PRODUCT_DETAILS_CACHE_DURATION = 6;

  // Cache keys
  static const String _FEATURED_PRODUCTS_KEY = 'cached_featured_products';
  static const String _NEW_ARRIVALS_KEY = 'cached_new_arrivals';
  static const String _BEST_SELLERS_KEY = 'cached_best_sellers';
  static const String _ALL_PRODUCTS_KEY = 'cached_all_products';
  static const String _CATEGORIES_KEY = 'cached_categories';
  static const String _CART_KEY = 'cached_cart';
  static const String _WISHLIST_KEY = 'cached_wishlist';
  static const String _PRODUCT_DETAILS_PREFIX = 'cached_product_';
  static const String _CATEGORY_PRODUCTS_PREFIX = 'cached_category_products_';

  // Timestamp keys
  static const String _TIMESTAMP_SUFFIX = '_timestamp';

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // Clean up expired cache on init
    await _cleanupExpiredCache();
  }

  /// Generic method to save data with timestamp
  Future<bool> _saveWithTimestamp(
      String key, String data, int durationHours) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _prefs?.setString(key, data);
      await _prefs?.setInt('$key$_TIMESTAMP_SUFFIX', timestamp);
      return true;
    } catch (e) {
      print('Error saving cache for $key: $e');
      return false;
    }
  }

  /// Generic method to get cached data if not expired
  Future<String?> _getIfValid(String key, int durationHours) async {
    try {
      final data = _prefs?.getString(key);
      final timestamp = _prefs?.getInt('$key$_TIMESTAMP_SUFFIX');

      if (data == null || timestamp == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      final maxAge =
          durationHours * 60 * 60 * 1000; // Convert hours to milliseconds

      if (age > maxAge) {
        // Cache expired, remove it
        await _remove(key);
        return null;
      }

      return data;
    } catch (e) {
      print('Error reading cache for $key: $e');
      return null;
    }
  }

  /// Remove specific cache entry
  Future<void> _remove(String key) async {
    await _prefs?.remove(key);
    await _prefs?.remove('$key$_TIMESTAMP_SUFFIX');
  }

  // ==================== FEATURED PRODUCTS ====================

  Future<bool> saveFeaturedProducts(List<Map<String, dynamic>> products) async {
    return await _saveWithTimestamp(
      _FEATURED_PRODUCTS_KEY,
      jsonEncode(products),
      PRODUCTS_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getFeaturedProducts() async {
    final data =
        await _getIfValid(_FEATURED_PRODUCTS_KEY, PRODUCTS_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing featured products cache: $e');
      return null;
    }
  }

  // ==================== NEW ARRIVALS ====================

  Future<bool> saveNewArrivals(List<Map<String, dynamic>> products) async {
    return await _saveWithTimestamp(
      _NEW_ARRIVALS_KEY,
      jsonEncode(products),
      PRODUCTS_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getNewArrivals() async {
    final data = await _getIfValid(_NEW_ARRIVALS_KEY, PRODUCTS_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing new arrivals cache: $e');
      return null;
    }
  }

  // ==================== BEST SELLERS ====================

  Future<bool> saveBestSellers(List<Map<String, dynamic>> products) async {
    return await _saveWithTimestamp(
      _BEST_SELLERS_KEY,
      jsonEncode(products),
      PRODUCTS_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getBestSellers() async {
    final data = await _getIfValid(_BEST_SELLERS_KEY, PRODUCTS_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing best sellers cache: $e');
      return null;
    }
  }

  // ==================== ALL PRODUCTS ====================

  Future<bool> saveAllProducts(List<Map<String, dynamic>> products) async {
    return await _saveWithTimestamp(
      _ALL_PRODUCTS_KEY,
      jsonEncode(products),
      PRODUCTS_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getAllProducts() async {
    final data = await _getIfValid(_ALL_PRODUCTS_KEY, PRODUCTS_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing all products cache: $e');
      return null;
    }
  }

  // ==================== PRODUCT DETAILS ====================

  Future<bool> saveProductDetails(
      String slug, Map<String, dynamic> product) async {
    return await _saveWithTimestamp(
      '$_PRODUCT_DETAILS_PREFIX$slug',
      jsonEncode(product),
      PRODUCT_DETAILS_CACHE_DURATION,
    );
  }

  Future<Map<String, dynamic>?> getProductDetails(String slug) async {
    final data = await _getIfValid(
      '$_PRODUCT_DETAILS_PREFIX$slug',
      PRODUCT_DETAILS_CACHE_DURATION,
    );
    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing product details cache for $slug: $e');
      return null;
    }
  }

  // ==================== CATEGORY PRODUCTS ====================

  Future<bool> saveCategoryProducts(
      String categorySlug, List<Map<String, dynamic>> products) async {
    return await _saveWithTimestamp(
      '$_CATEGORY_PRODUCTS_PREFIX$categorySlug',
      jsonEncode(products),
      PRODUCTS_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getCategoryProducts(
      String categorySlug) async {
    final data = await _getIfValid(
      '$_CATEGORY_PRODUCTS_PREFIX$categorySlug',
      PRODUCTS_CACHE_DURATION,
    );
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing category products cache: $e');
      return null;
    }
  }

  // ==================== CATEGORIES ====================

  Future<bool> saveCategories(List<Map<String, dynamic>> categories) async {
    return await _saveWithTimestamp(
      _CATEGORIES_KEY,
      jsonEncode(categories),
      CATEGORIES_CACHE_DURATION,
    );
  }

  Future<List<Map<String, dynamic>>?> getCategories() async {
    final data = await _getIfValid(_CATEGORIES_KEY, CATEGORIES_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing categories cache: $e');
      return null;
    }
  }

  // ==================== CART ====================

  Future<bool> saveCart(Map<String, dynamic> cart) async {
    return await _saveWithTimestamp(
      _CART_KEY,
      jsonEncode(cart),
      CART_CACHE_DURATION,
    );
  }

  Future<Map<String, dynamic>?> getCart() async {
    final data = await _getIfValid(_CART_KEY, CART_CACHE_DURATION);
    if (data == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing cart cache: $e');
      return null;
    }
  }

  Future<void> clearCart() async {
    await _remove(_CART_KEY);
  }

  // ==================== WISHLIST ====================

  Future<bool> saveWishlist(List<String> productIds) async {
    return await _saveWithTimestamp(
      _WISHLIST_KEY,
      jsonEncode(productIds),
      WISHLIST_CACHE_DURATION,
    );
  }

  Future<List<String>?> getWishlist() async {
    final data = await _getIfValid(_WISHLIST_KEY, WISHLIST_CACHE_DURATION);
    if (data == null) return null;

    try {
      return List<String>.from(jsonDecode(data));
    } catch (e) {
      print('Error parsing wishlist cache: $e');
      return null;
    }
  }

  Future<void> clearWishlist() async {
    await _remove(_WISHLIST_KEY);
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('cached_')) {
        await _prefs?.remove(key);
      }
    }
    print('All cache cleared');
  }

  /// Clear expired cache entries
  Future<void> _cleanupExpiredCache() async {
    final keys = _prefs?.getKeys() ?? {};
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.endsWith(_TIMESTAMP_SUFFIX)) {
        final timestamp = _prefs?.getInt(key);
        if (timestamp != null) {
          final age = now - timestamp;
          // Remove if older than 7 days (7 * 24 * 60 * 60 * 1000)
          if (age > 604800000) {
            final dataKey = key.replaceAll(_TIMESTAMP_SUFFIX, '');
            await _remove(dataKey);
            print('Removed expired cache: $dataKey');
          }
        }
      }
    }
  }

  /// Clear specific product cache
  Future<void> clearProductCache(String slug) async {
    await _remove('$_PRODUCT_DETAILS_PREFIX$slug');
  }

  /// Clear category products cache
  Future<void> clearCategoryCache(String categorySlug) async {
    await _remove('$_CATEGORY_PRODUCTS_PREFIX$categorySlug');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final keys = _prefs?.getKeys() ?? {};
    int totalCached = 0;
    int totalSize = 0;

    for (final key in keys) {
      if (key.startsWith('cached_') && !key.endsWith(_TIMESTAMP_SUFFIX)) {
        totalCached++;
        final data = _prefs?.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }

    return {
      'total_cached_items': totalCached,
      'total_size_bytes': totalSize,
      'total_size_kb': (totalSize / 1024).toStringAsFixed(2),
    };
  }
}
