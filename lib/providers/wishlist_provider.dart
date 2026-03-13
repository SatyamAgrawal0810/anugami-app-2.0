// lib/providers/wishlist_provider.dart
// ✅ FIXED: Auto-loads on app start, retries on error, better state management
import 'package:flutter/material.dart';
import '../api/services/wishlist_service.dart';
import '../api/services/cart_service.dart';
import '../api/services/cart_image_service.dart';
import '../core/models/wishlist_item_model.dart';
import 'dart:async';

class WishlistProvider extends ChangeNotifier {
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  final CartImageService _imageService = CartImageService();

  List<WishlistItemModel> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _wishlistCount = 0;
  Map<String, String> _itemImages = {};
  DateTime? _lastFetch;

  // Getters
  List<WishlistItemModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get wishlistCount => _wishlistCount;
  bool get isEmpty => _wishlistItems.isEmpty;

  String? getItemImageUrl(WishlistItemModel item) {
    return _itemImages['${item.productId}_${item.variantId ?? 'default'}'];
  }

  bool isInWishlist(String productId, {String? variantId}) {
    return _wishlistItems.any(
        (item) => item.productId == productId && item.variantId == variantId);
  }

  WishlistItemModel? getWishlistItem(String productId, {String? variantId}) {
    try {
      return _wishlistItems.firstWhere(
          (item) => item.productId == productId && item.variantId == variantId);
    } catch (e) {
      return null;
    }
  }

  WishlistItemModel? _findWishlistItem(String productId, {String? variantId}) {
    try {
      return _wishlistItems.firstWhere(
        (item) => item.productId == productId && item.variantId == variantId,
      );
    } catch (_) {
      return null;
    }
  }

  // ✅ NEW: Constructor auto-initializes
  WishlistProvider() {
    _initializeProvider();
  }

  // ✅ NEW: Initialize provider on app start
  Future<void> _initializeProvider() async {
    print('🔄 Initializing WishlistProvider...');
    await initialize();
  }

  // ✅ NEW: Public initialize method - call this on app start
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Wishlist already initialized, refreshing...');
      await fetchWishlistItems(forceRefresh: true);
      return;
    }

    print('🚀 Initializing wishlist for first time...');
    await fetchWishlistItems(forceRefresh: true);
    _isInitialized = true;
  }

  // ✅ FIXED: Better error handling with retry logic
  Future<void> fetchWishlistItems({
    bool forceRefresh = false,
    int retryCount = 0,
  }) async {
    if (_isLoading && retryCount == 0) {
      print('⚠️ Wishlist fetch already in progress');
      return;
    }

    // Skip if recently fetched (within 30 seconds)
    if (!forceRefresh &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(seconds: 30) &&
        _wishlistItems.isNotEmpty) {
      print('✅ Using cached wishlist data');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🌐 Fetching wishlist from API...');

      final result = await _wishlistService
          .getWishlistItems()
          .timeout(const Duration(seconds: 15)); // ✅ Longer timeout

      if (result['success']) {
        _wishlistItems = result['data']['items'] ?? [];
        _wishlistCount = result['data']['count'] ?? 0;
        _lastFetch = DateTime.now();
        _errorMessage = null; // ✅ Clear error on success

        print('✅ Loaded ${_wishlistItems.length} wishlist items');

        // Load images in parallel (non-blocking)
        _loadWishlistItemImages();
      } else {
        print('⚠️ API returned error: ${result['message']}');
        _errorMessage = result['message'];
      }
    } on TimeoutException catch (e) {
      print('⏱️ Wishlist API timeout: $e');
      _errorMessage = 'Connection timeout. Please check your internet.';

      // ✅ Retry logic
      if (retryCount < 2) {
        print('🔄 Retrying wishlist fetch (attempt ${retryCount + 1})...');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return fetchWishlistItems(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
    } catch (e) {
      print('❌ Wishlist fetch error: $e');
      _errorMessage = 'Failed to load wishlist';

      // ✅ Retry for network errors
      if (retryCount < 2 && e.toString().contains('SocketException')) {
        print('🔄 Retrying wishlist fetch (attempt ${retryCount + 1})...');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return fetchWishlistItems(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ✅ FIXED: Better image loading with longer timeout
  Future<void> _loadWishlistItemImages() async {
    if (_wishlistItems.isEmpty) return;

    print('🖼️ Loading ${_wishlistItems.length} wishlist item images...');

    final futures = _wishlistItems
        .where((item) => item.productInfo.slug.isNotEmpty)
        .map((item) async {
      try {
        final imageUrl = await _imageService
            .getCartItemImageUrl(item.productInfo.slug, item.variantId)
            .timeout(const Duration(seconds: 5)); // ✅ Longer timeout

        if (imageUrl != null && imageUrl.isNotEmpty) {
          _itemImages['${item.productId}_${item.variantId ?? 'default'}'] =
              imageUrl;
        }
      } catch (e) {
        print('⚠️ Image load failed for ${item.id}: $e');
      }
    }).toList();

    await Future.wait(futures);
    print('✅ Loaded ${_itemImages.length} wishlist images');
    notifyListeners();
  }

  // ✅ FIXED: Add with better error handling
  Future<bool> addToWishlist(String productId, {String? variantId}) async {
    if (_isLoading) {
      print('⚠️ Wishlist operation already in progress');
      return false;
    }

    // Check if already in wishlist
    if (isInWishlist(productId, variantId: variantId)) {
      _setError('Item is already in your wishlist');
      return false;
    }

    print('➕ Adding item to wishlist: $productId');

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _wishlistService
          .addToWishlist(
            productId: productId,
            variantId: variantId,
          )
          .timeout(const Duration(seconds: 10)); // ✅ Longer timeout

      if (result['success']) {
        print('✅ Item added to wishlist');
        await fetchWishlistItems(forceRefresh: true);
        _clearError();
        return true;
      } else {
        print('❌ Add to wishlist failed: ${result['message']}');
        _setError(result['message'] ?? 'Failed to add item to wishlist');
        return false;
      }
    } on TimeoutException catch (e) {
      print('⏱️ Add to wishlist timeout: $e');
      _setError('Connection timeout. Please try again.');
      return false;
    } catch (e) {
      print('❌ Add to wishlist error: $e');
      _setError('Failed to add item');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FIXED: Remove with optimistic update + rollback on failure
  Future<bool> removeFromWishlist(int wishlistId) async {
    if (_isLoading) {
      print('⚠️ Wishlist operation already in progress');
      return false;
    }

    print('🗑️ Removing item from wishlist: $wishlistId');

    // Find the item to remove
    final removedItem = _wishlistItems.firstWhere(
      (item) => item.id == wishlistId,
      orElse: () => WishlistItemModel(
        id: 0,
        productId: '',
        productInfo: ProductInfo(
          id: '',
          name: '',
          slug: '',
          image: '',
          regularPrice: 0,
          salePrice: 0,
          isAvailable: false,
        ),
        addedAt: '',
      ),
    );

    if (removedItem.id == 0) {
      print('⚠️ Item not found in wishlist');
      return false;
    }

    // ✅ Optimistic update - remove from UI immediately
    _wishlistItems.removeWhere((item) => item.id == wishlistId);
    _wishlistCount = _wishlistItems.length;
    _itemImages.remove(
        '${removedItem.productId}_${removedItem.variantId ?? 'default'}');
    notifyListeners();

    try {
      final result = await _wishlistService
          .removeFromWishlist(wishlistId: wishlistId)
          .timeout(const Duration(seconds: 10));

      if (result['success'] == true) {
        print('✅ Item removed from wishlist');
        _clearError();
        return true;
      } else {
        print('❌ Remove from wishlist failed: ${result['message']}');

        // ✅ Revert on failure
        _wishlistItems.add(removedItem);
        _wishlistCount = _wishlistItems.length;
        notifyListeners();
        _setError(result['message'] ?? 'Failed to remove item');
        return false;
      }
    } on TimeoutException catch (e) {
      print('⏱️ Remove timeout: $e');

      // ✅ Revert on timeout
      _wishlistItems.add(removedItem);
      _wishlistCount = _wishlistItems.length;
      notifyListeners();
      _setError('Connection timeout. Please try again.');
      return false;
    } catch (e) {
      print('❌ Remove error: $e');

      // ✅ Revert on error
      _wishlistItems.add(removedItem);
      _wishlistCount = _wishlistItems.length;
      notifyListeners();
      _setError('Failed to remove item');
      return false;
    }
  }

  // ✅ FIXED: Toggle with better state management
  Future<bool> toggleWishlist(String productId, {String? variantId}) async {
    if (_isLoading) {
      print('⚠️ Wishlist operation already in progress');
      return false;
    }

    final wishlistItem = _findWishlistItem(productId, variantId: variantId);

    if (wishlistItem != null) {
      print('🔄 Removing from wishlist: $productId');
      return await removeFromWishlist(wishlistItem.id);
    }

    print('🔄 Adding to wishlist: $productId');
    return await addToWishlist(productId, variantId: variantId);
  }

  // ✅ Clear wishlist
  Future<bool> clearWishlist() async {
    if (_isLoading) return false;

    print('🗑️ Clearing wishlist...');

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _wishlistService
          .clearWishlist()
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        _wishlistItems.clear();
        _wishlistCount = 0;
        _itemImages.clear();
        _clearError();
        print('✅ Wishlist cleared');
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to clear wishlist');
        return false;
      }
    } catch (e) {
      _setError('Clear failed');
      print('❌ Clear wishlist error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Add to cart with timeout
  Future<bool> addWishlistItemToCart(WishlistItemModel item) async {
    print('🛒 Adding wishlist item to cart: ${item.productInfo.name}');

    try {
      final result = await _cartService
          .addToCart(
            productId: item.productId,
            variantId: item.variantId,
            quantity: 1,
            price: item.productInfo.displayPrice,
          )
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        _clearError();
        print('✅ Item added to cart');
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to add item to cart');
        print('❌ Add to cart failed: ${result['message']}');
        return false;
      }
    } on TimeoutException catch (e) {
      _setError('Connection timeout. Please try again.');
      print('⏱️ Add to cart timeout: $e');
      return false;
    } catch (e) {
      _setError('Failed to add to cart');
      print('❌ Add to cart error: $e');
      return false;
    }
  }

  // ✅ Move to cart operation
  Future<bool> moveToCart(WishlistItemModel item) async {
    if (_isLoading) return false;

    print('🔄 Moving item to cart: ${item.productInfo.name}');

    try {
      final addToCartSuccess = await addWishlistItemToCart(item);

      if (addToCartSuccess) {
        final removeFromWishlistSuccess = await removeFromWishlist(item.id);
        print('✅ Item moved to cart');
        return removeFromWishlistSuccess;
      }

      return false;
    } catch (e) {
      _setError('Move to cart failed');
      print('❌ Move to cart error: $e');
      return false;
    }
  }

  // Update item image
  Future<void> updateItemImage(
      String productId, String? variantId, String productSlug) async {
    try {
      final imageUrl = await _imageService
          .getCartItemImageUrl(productSlug, variantId)
          .timeout(const Duration(seconds: 3));

      if (imageUrl != null) {
        _itemImages['${productId}_${variantId ?? 'default'}'] = imageUrl;
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Image update failed: $e');
    }
  }

  // ✅ Refresh wishlist (force reload)
  Future<void> refreshWishlist() async {
    print('🔄 Refreshing wishlist...');
    _lastFetch = null; // Force refresh
    await fetchWishlistItems(forceRefresh: true);
  }

  // Helper methods
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Reset provider state
  void reset() {
    print('🔄 Resetting wishlist provider...');
    _wishlistItems.clear();
    _wishlistCount = 0;
    _isLoading = false;
    _errorMessage = null;
    _itemImages.clear();
    _isInitialized = false;
    _lastFetch = null;
    notifyListeners();
  }
}
