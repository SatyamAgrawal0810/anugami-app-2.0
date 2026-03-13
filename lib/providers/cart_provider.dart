// lib/providers/cart_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/services/cart_service.dart';
import '../api/services/cart_image_service.dart';
import '../core/models/cart_item_model.dart';
import '../core/models/product_model.dart';
import '../api/services/cache_service.dart';
import '../config/theme.dart';
import '../api/services/auth_service.dart';

class CartProvider with ChangeNotifier {
  static const String _guestCartKey = 'guest_cart_items';
  static const String _guestCartTimestampKey = 'guest_cart_timestamp';
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  final CartService _cartService = CartService();
  final CartImageService _imageService = CartImageService();
  late CacheService _cacheService;
  bool _isCacheInitialized = false;
  bool _isInitialized = false;

  List<CartItem> _items = [];
  Set<int> _selectedItemIds = {}; // ✅ NEW: Track selected items
  bool _isLoading = false;
  String? _error;
  Map<String, String> _itemImages = {};
  DateTime? _lastFetch;

  // ─── Basic Getters ──────────────────────────────────────────────────────────
  List<CartItem> get items => [..._items];
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.length;
  bool get isInitialized => _isInitialized;

  // ─── Selection Getters ──────────────────────────────────────────────────────
  List<CartItem> get selectedItems =>
      _items.where((item) => _selectedItemIds.contains(item.id)).toList();

  int get selectedCount => selectedItems.length;
  bool get allSelected =>
      _items.isNotEmpty && _selectedItemIds.length == _items.length;
  bool get noneSelected => _selectedItemIds.isEmpty;
  bool isSelected(int itemId) => _selectedItemIds.contains(itemId);

  // ─── Selection Actions ──────────────────────────────────────────────────────
  void toggleItemSelection(int itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
    } else {
      _selectedItemIds.add(itemId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedItemIds = _items.map((e) => e.id).toSet();
    notifyListeners();
  }

  void deselectAll() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  void _syncSelectionWithItems() {
    // Remove selected IDs that no longer exist in items
    _selectedItemIds.removeWhere(
      (id) => !_items.any((item) => item.id == id),
    );
    // Auto-select newly added items
    for (final item in _items) {
      _selectedItemIds.add(item.id);
    }
  }

  // ─── Price Calculations (ALL items) ─────────────────────────────────────────
  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  // ─── Price Calculations (SELECTED items only) ────────────────────────────────
  /// Sum of regularPrice × qty for selected items (original MRP)
  double get selectedOriginalTotal => selectedItems.fold(0.0, (sum, item) {
        return sum + (item.regularPrice * item.quantity);
      });

  /// Total discount on selected items
  double get selectedDiscount => selectedItems.fold(0.0, (sum, item) {
        if (item.hasDiscount) {
          return sum + ((item.regularPrice - item.salePrice) * item.quantity);
        }
        return sum;
      });

  /// Subtotal after discount (salePrice × qty)
  double get subtotal =>
      selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Shipping: free above ₹500
  double get shippingCost =>
      subtotal >= 500 ? 0.0 : (subtotal > 0 ? 50.0 : 0.0);

  double get taxAmount => subtotal * 0.0; // No tax currently
  double get finalTotal => subtotal + shippingCost + taxAmount;

  double get totalSavings => selectedDiscount;

  bool get hasItems => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  String get estimatedDeliveryDate {
    final d = DateTime.now().add(const Duration(days: 3));
    return '${d.day}/${d.month}/${d.year}';
  }

  String? getItemImageUrl(CartItem item) {
    return _itemImages['${item.productId}_${item.variantId ?? 'default'}'];
  }

  CartItem? getItemById(int itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (_) {
      return null;
    }
  }

  // ─── Init ───────────────────────────────────────────────────────────────────
  CartProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _initializeCache();
    await initialize();
  }

  Future<void> _initializeCache() async {
    try {
      _cacheService = await CacheService.getInstance();
      _isCacheInitialized = true;
    } catch (e) {
      print('❌ Cache init failed: $e');
    }
  }

  Future<void> _ensureCacheInitialized() async {
    if (!_isCacheInitialized) await _initializeCache();
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      await fetchCartItems(forceRefresh: true);
      return;
    }
    await fetchCartItems(forceRefresh: true);
    _isInitialized = true;
  }

  // ─── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchCartItems({
    bool forceRefresh = false,
    int retryCount = 0,
  }) async {
    if (_isLoading && retryCount == 0) return;

    if (!forceRefresh &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration &&
        _items.isNotEmpty) {
      return;
    }

    await _ensureCacheInitialized();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        await _fetchLoggedInCart(forceRefresh);
      } else {
        await _loadGuestCart();
      }

      _syncSelectionWithItems(); // ✅ Keep selection in sync
      _lastFetch = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to load cart';
      print('❌ Cart fetch error: $e');

      if (retryCount < 2 && e.toString().contains('SocketException')) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return fetchCartItems(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLoggedInCart(bool forceRefresh) async {
    if (_isCacheInitialized) {
      try {
        final cachedCart = await _cacheService.getCart();
        if (cachedCart != null && cachedCart['items'] != null) {
          final List<dynamic> itemsJson = cachedCart['items'];
          if (itemsJson.isNotEmpty) {
            _items = itemsJson.map((item) => CartItem.fromJson(item)).toList();
            notifyListeners();
            _loadCartItemImages();
          }
        }
      } catch (e) {
        print('⚠️ Cache read error: $e');
      }
    }
    await _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    try {
      final result = await _cartService
          .getCartItems()
          .timeout(const Duration(seconds: 15));

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> itemsJson = data['items'] ?? [];
        _items = itemsJson.map((item) => CartItem.fromJson(item)).toList();

        if (_isCacheInitialized) {
          await _cacheService.saveCart(data);
        }
        _loadCartItemImages();
      } else {
        _error = result['message'];
      }
    } on TimeoutException {
      _error = 'Connection timeout. Please check your internet.';
    } catch (e) {
      _error = 'Network error. Please try again.';
    }
  }

  Future<void> _loadCartItemImages() async {
    if (_items.isEmpty) return;
    final futures = _items
        .where((item) => item.productInfo?.slug != null)
        .map((item) async {
      try {
        final imageUrl = await _imageService
            .getCartItemImageUrl(item.productInfo!.slug, item.variantId)
            .timeout(const Duration(seconds: 5));
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _itemImages['${item.productId}_${item.variantId ?? 'default'}'] =
              imageUrl;
        }
      } catch (_) {}
    }).toList();
    await Future.wait(futures);
    notifyListeners();
  }

  // ─── Guest Cart ─────────────────────────────────────────────────────────────
  Future<void> _loadGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> cartList = json.decode(cartJson);
        _items = cartList.map((item) => CartItem.fromJson(item)).toList();
      } else {
        _items = [];
      }
    } catch (e) {
      _items = [];
    }
  }

  Future<void> _saveGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson =
          json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_guestCartKey, cartJson);
      await prefs.setInt(
          _guestCartTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Guest cart save error: $e');
    }
  }

  Future<void> mergeGuestCartWithUserCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      if (cartJson == null || cartJson.isEmpty) return;

      final List<dynamic> guestCartList = json.decode(cartJson);
      final guestItems =
          guestCartList.map((item) => CartItem.fromJson(item)).toList();

      final futures = guestItems
          .map((item) => _cartService
              .addToCart(
                productId: item.productId,
                variantId: item.variantId,
                quantity: item.quantity,
                price: item.price,
              )
              .timeout(const Duration(seconds: 5)))
          .toList();

      await Future.wait(futures, eagerError: false);
      await prefs.remove(_guestCartKey);
      await prefs.remove(_guestCartTimestampKey);
      await fetchCartItems(forceRefresh: true);
    } catch (e) {
      print('❌ Cart merge error: $e');
    }
  }

  // ─── Add Item ────────────────────────────────────────────────────────────────
  Future<void> addItem(
    ProductModel product, {
    int quantity = 1,
    String? variantId,
    double? price,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      final productPrice = price ??
          (double.tryParse(product.salePrice) ??
              double.tryParse(product.regularPrice) ??
              0.0);

      if (isLoggedIn) {
        final result = await _cartService
            .addToCart(
              productId: product.id.toString(),
              variantId: variantId,
              quantity: quantity,
              price: productPrice,
            )
            .timeout(const Duration(seconds: 10));

        if (result['success']) {
          await fetchCartItems(forceRefresh: true);
        } else {
          _error = result['message'];
        }
      } else {
        await _addToGuestCart(product, quantity, variantId, productPrice);
      }
    } catch (e) {
      _error = 'Failed to add item';
      print('❌ Add item error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _addToGuestCart(ProductModel product, int quantity,
      String? variantId, double price) async {
    final existingIndex = _items.indexWhere((item) =>
        item.productId == product.id.toString() && item.variantId == variantId);

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = CartItem(
        id: existing.id,
        productId: existing.productId,
        variantId: existing.variantId,
        quantity: existing.quantity + quantity,
        price: existing.price,
        totalPrice: (existing.quantity + quantity) * existing.price,
        addedAt: existing.addedAt,
        updatedAt: DateTime.now().toIso8601String(),
        productInfo: existing.productInfo,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id.toString(),
        variantId: variantId,
        quantity: quantity,
        price: price,
        totalPrice: quantity * price,
        addedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        productInfo: ProductInfo(
          id: product.id.toString(),
          name: product.name,
          slug: product.slug,
          image: product.primaryImageUrl,
          regularPrice: double.tryParse(product.regularPrice) ?? 0.0,
          salePrice: double.tryParse(product.salePrice) ?? 0.0,
          isAvailable: true,
        ),
      ));
    }
    await _saveGuestCart();
  }

  // ─── Change Variant ──────────────────────────────────────────────────────────
  Future<bool> changeItemVariant({
    required int itemId,
    required String newVariantId,
    required double price,
  }) async {
    final item = getItemById(itemId);
    if (item == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        // Remove old item, add new with new variant
        final removeResult = await _cartService
            .removeFromCart(
                productId: item.productId, variantId: item.variantId)
            .timeout(const Duration(seconds: 5));

        if (removeResult['success']) {
          final addResult = await _cartService
              .addToCart(
                productId: item.productId,
                variantId: newVariantId,
                quantity: item.quantity,
                price: price,
              )
              .timeout(const Duration(seconds: 5));

          if (addResult['success']) {
            await fetchCartItems(forceRefresh: true);
            return true;
          }
        }
        return false;
      } else {
        // Guest cart: update variant locally
        final index = _items.indexWhere((i) => i.id == itemId);
        if (index >= 0) {
          final existing = _items[index];
          _items[index] = CartItem(
            id: existing.id,
            productId: existing.productId,
            variantId: newVariantId,
            quantity: existing.quantity,
            price: price,
            totalPrice: existing.quantity * price,
            addedAt: existing.addedAt,
            updatedAt: DateTime.now().toIso8601String(),
            productInfo: existing.productInfo,
          );
          await _saveGuestCart();
          _syncSelectionWithItems();
          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      print('❌ Change variant error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Increment / Decrement / Remove ─────────────────────────────────────────
  Future<void> incrementQuantity(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;
    final item = _items[index];
    final newQty = item.quantity + 1;

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        final result = await _cartService
            .updateCartItemQuantity(itemId: itemId, quantity: newQty)
            .timeout(const Duration(seconds: 5));
        if (result['success']) {
          await fetchCartItems(forceRefresh: true);
        } else {
          _error = result['message'];
          notifyListeners();
        }
      } else {
        _items[index] = CartItem(
          id: item.id,
          productId: item.productId,
          variantId: item.variantId,
          quantity: newQty,
          price: item.price,
          totalPrice: newQty * item.price,
          addedAt: item.addedAt,
          updatedAt: DateTime.now().toIso8601String(),
          productInfo: item.productInfo,
        );
        await _saveGuestCart();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Update failed';
      notifyListeners();
    }
  }

  Future<void> decrementQuantity(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;
    final item = _items[index];
    if (item.quantity <= 1) {
      await removeItem(itemId);
      return;
    }
    final newQty = item.quantity - 1;

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        final result = await _cartService
            .updateCartItemQuantity(itemId: itemId, quantity: newQty)
            .timeout(const Duration(seconds: 5));
        if (result['success']) {
          await fetchCartItems(forceRefresh: true);
        } else {
          _error = result['message'];
          notifyListeners();
        }
      } else {
        _items[index] = CartItem(
          id: item.id,
          productId: item.productId,
          variantId: item.variantId,
          quantity: newQty,
          price: item.price,
          totalPrice: newQty * item.price,
          addedAt: item.addedAt,
          updatedAt: DateTime.now().toIso8601String(),
          productInfo: item.productInfo,
        );
        await _saveGuestCart();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Update failed';
      notifyListeners();
    }
  }

  Future<void> removeItem(int itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;
    final item = _items[index];

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        final result = await _cartService
            .removeFromCart(
                productId: item.productId, variantId: item.variantId)
            .timeout(const Duration(seconds: 5));
        if (result['success']) {
          _selectedItemIds.remove(itemId);
          _itemImages
              .remove('${item.productId}_${item.variantId ?? 'default'}');
          await fetchCartItems(forceRefresh: true);
        } else {
          _error = result['message'];
          notifyListeners();
        }
      } else {
        _items.removeAt(index);
        _selectedItemIds.remove(itemId);
        await _saveGuestCart();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Remove failed';
      notifyListeners();
    }
  }

  // ─── Clear / Misc ────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearCart() async {
    await _ensureCacheInitialized();
    _isLoading = true;
    notifyListeners();

    try {
      final futures = _items
          .map((item) => _cartService
              .removeFromCart(
                  productId: item.productId, variantId: item.variantId)
              .timeout(const Duration(seconds: 5)))
          .toList();
      await Future.wait(futures, eagerError: false);
      _items = [];
      _selectedItemIds.clear();
      _itemImages.clear();
      if (_isCacheInitialized) await _cacheService.clearCart();
    } catch (e) {
      _error = 'Clear failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clear() => clearCart();
  Future<void> refreshCart() => fetchCartItems(forceRefresh: true);
  Future<void> refresh() => fetchCartItems(forceRefresh: true);

  bool isProductInCart(String productId, {String? variantId}) {
    return _items.any(
        (item) => item.productId == productId && item.variantId == variantId);
  }

  int getProductQuantity(String productId, {String? variantId}) {
    try {
      return _items
          .firstWhere((item) =>
              item.productId == productId && item.variantId == variantId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }

  int getQuantityForProduct(String productId, {String? variantId}) =>
      getProductQuantity(productId, variantId: variantId);

  String getCartSummary() {
    if (isEmpty) return 'Cart is empty';
    return '$itemCount items • ₹${totalAmount.toStringAsFixed(0)}';
  }

  bool get needsUpdate => false;
}
