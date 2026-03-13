// lib/providers/product_provider.dart
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../api/services/product_service.dart';
import '../api/services/category_service.dart';
import '../core/models/product_model.dart';
import '../core/models/mobile_variant_model.dart';
import '../core/models/category_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/services/api_config.dart';
import 'package:anu_app/utils/app_notifications.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  // Product lists
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _newArrivals = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _categoryProducts = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _categoryTreeProducts = [];
  List<CategoryModel> _categoryTreeSubcategories = [];
  List<CategoryModel> _categoryBreadcrumbs = [];
  List<ProductModel> _brandProducts = [];

  // New properties for variant support
  ProductModel? _selectedProduct;
  MobileVariantSelector? _selectedProductVariants;
  bool _isLoadingProductDetails = false;
  bool _isLoadingVariants = false;
  String? _productDetailsError;
  String? _variantsError;

  // Loading states
  bool _isLoadingFeatured = false;
  bool _isLoadingNewArrivals = false;
  bool _isLoadingBestSellers = false;
  bool _isLoadingSearch = false;
  bool _isLoadingCategory = false;
  bool _isLoadingAllProducts = false;
  bool _isLoadingCategoryTree = false;
  bool _isLoadingBrand = false;

  // Error messages
  String? _featuredError;
  String? _newArrivalsError;
  String? _bestSellersError;
  String? _searchError;
  String? _categoryError;
  String? _allProductsError;
  String? _categoryTreeError;

  // Pagination data
  int _categoryTotalCount = 0;
  String? _categoryNextPage;
  String? _categoryPreviousPage;

  // Getters for product lists
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get newArrivals => _newArrivals;
  List<ProductModel> get bestSellers => _bestSellers;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get categoryProducts => _categoryProducts;
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get categoryTreeProducts => _categoryTreeProducts;
  List<CategoryModel> get categoryTreeSubcategories =>
      _categoryTreeSubcategories;
  List<CategoryModel> get categoryBreadcrumbs => _categoryBreadcrumbs;
  List<ProductModel> get brandProducts => _brandProducts;

  // Getters for variant support
  ProductModel? get selectedProduct => _selectedProduct;
  MobileVariantSelector? get selectedProductVariants =>
      _selectedProductVariants;
  bool get isLoadingProductDetails => _isLoadingProductDetails;
  bool get isLoadingVariants => _isLoadingVariants;
  String? get productDetailsError => _productDetailsError;
  String? get variantsError => _variantsError;

  // Getters for loading states
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingNewArrivals => _isLoadingNewArrivals;
  bool get isLoadingBestSellers => _isLoadingBestSellers;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingCategory => _isLoadingCategory;
  bool get isLoadingAllProducts => _isLoadingAllProducts;
  bool get isLoadingCategoryTree => _isLoadingCategoryTree;

  // Getters for errors
  String? get featuredError => _featuredError;
  String? get newArrivalsError => _newArrivalsError;
  String? get bestSellersError => _bestSellersError;
  String? get searchError => _searchError;
  String? get categoryError => _categoryError;
  String? get allProductsError => _allProductsError;
  String? get categoryTreeError => _categoryTreeError;

  int get categoryTotalCount => _categoryTotalCount;
  bool get hasMoreCategoryProducts => _categoryNextPage != null;
  bool get isLoadingBrand => _isLoadingBrand;

  Future<void> loadProductsByBrand(String brandSlug) async {
    _isLoadingBrand = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/products?brand=$brandSlug'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _brandProducts = (data['products'] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading brand products: $e');
    } finally {
      _isLoadingBrand = false;
      notifyListeners();
    }
  }

  // Enhanced load product details with variants
  Future<void> loadProductDetailsWithVariants(String slug) async {
    _isLoadingProductDetails = true;
    _isLoadingVariants = true;
    _productDetailsError = null;
    _variantsError = null;
    _selectedProduct = null;
    _selectedProductVariants = null;
    notifyListeners();

    try {
      // Load product details and variants concurrently
      final results = await Future.wait([
        _productService.getProductBySlug(slug),
        _productService.getMobileVariantSelector(slug),
      ]);

      final productResult = results[0];
      final variantResult = results[1];

      _isLoadingProductDetails = false;
      _isLoadingVariants = false;

      if (productResult['success']) {
        _selectedProduct = productResult['data'];
      } else {
        _productDetailsError = productResult['message'];
      }

      if (variantResult['success']) {
        _selectedProductVariants = variantResult['data'];
      } else {
        _variantsError = variantResult['message'];
        // Don't treat variant loading failure as critical
        print('Warning: Could not load variants: ${variantResult['message']}');
      }

      notifyListeners();
    } catch (e) {
      _productDetailsError = e.toString();
      _variantsError = e.toString();
      _isLoadingProductDetails = false;
      _isLoadingVariants = false;
      notifyListeners();
    }
  }

  // Load product details only (existing method, keep for backward compatibility)
  Future<void> loadProductDetails(String slug) async {
    _isLoadingProductDetails = true;
    _productDetailsError = null;
    notifyListeners();

    try {
      final result = await _productService.getProductBySlug(slug);

      if (result['success']) {
        _selectedProduct = result['data'];
        _isLoadingProductDetails = false;
        notifyListeners();
      } else {
        _productDetailsError = result['message'];
        _isLoadingProductDetails = false;
        notifyListeners();
      }
    } catch (e) {
      _productDetailsError = e.toString();
      _isLoadingProductDetails = false;
      notifyListeners();
    }
  }

  // Load variants separately if needed
  Future<void> loadProductVariants(String slug) async {
    _isLoadingVariants = true;
    _variantsError = null;
    notifyListeners();

    try {
      final result = await _productService.getMobileVariantSelector(slug);

      if (result['success']) {
        _selectedProductVariants = result['data'];
        _isLoadingVariants = false;
        notifyListeners();
      } else {
        _variantsError = result['message'];
        _isLoadingVariants = false;
        notifyListeners();
      }
    } catch (e) {
      _variantsError = e.toString();
      _isLoadingVariants = false;
      notifyListeners();
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    _isLoadingFeatured = true;
    _featuredError = null;
    notifyListeners();

    try {
      final result = await _productService.getFeaturedProducts();

      if (result['success']) {
        _featuredProducts = List<ProductModel>.from(result['data']);
        _isLoadingFeatured = false;
        notifyListeners();
      } else {
        _featuredError = result['message'];
        _isLoadingFeatured = false;
        notifyListeners();
      }
    } catch (e) {
      _featuredError = e.toString();
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  // Load new arrivals
  Future<void> loadNewArrivals() async {
    _isLoadingNewArrivals = true;
    _newArrivalsError = null;
    notifyListeners();

    try {
      final result = await _productService.getNewArrivals();

      if (result['success']) {
        _newArrivals = List<ProductModel>.from(result['data']);
        _isLoadingNewArrivals = false;
        notifyListeners();
      } else {
        _newArrivalsError = result['message'];
        _isLoadingNewArrivals = false;
        notifyListeners();
      }
    } catch (e) {
      _newArrivalsError = e.toString();
      _isLoadingNewArrivals = false;
      notifyListeners();
    }
  }

  // Load best sellers
  Future<void> loadBestSellers() async {
    _isLoadingBestSellers = true;
    _bestSellersError = null;
    notifyListeners();

    try {
      final result = await _productService.getBestSellers();

      if (result['success']) {
        _bestSellers = List<ProductModel>.from(result['data']);
        _isLoadingBestSellers = false;
        notifyListeners();
      } else {
        _bestSellersError = result['message'];
        _isLoadingBestSellers = false;
        notifyListeners();
      }
    } catch (e) {
      _bestSellersError = e.toString();
      _isLoadingBestSellers = false;
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _isLoadingSearch = true;
    _searchError = null;
    notifyListeners();

    try {
      final result = await _productService.searchProducts(query);

      if (result['success']) {
        _searchResults = List<ProductModel>.from(result['data']);
        _isLoadingSearch = false;
        notifyListeners();
      } else {
        _searchError = result['message'];
        _isLoadingSearch = false;
        notifyListeners();
      }
    } catch (e) {
      _searchError = e.toString();
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  // Get all products or with specific parameters
  Future<void> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? ordering,
    bool refresh = true,
  }) async {
    if (refresh) {
      _isLoadingAllProducts = true;
      _allProductsError = null;
      _allProducts = [];
      notifyListeners();
    }

    try {
      final result = await _productService.getProducts(
        page: page,
        limit: limit,
        category: category,
        search: search,
        ordering: ordering,
      );

      if (result['success']) {
        if (refresh) {
          _allProducts = List<ProductModel>.from(result['data']);
        } else {
          _allProducts.addAll(List<ProductModel>.from(result['data']));
        }

        _isLoadingAllProducts = false;
        notifyListeners();
      } else {
        _allProductsError = result['message'];
        _isLoadingAllProducts = false;
        notifyListeners();
      }
    } catch (e) {
      _allProductsError = e.toString();
      _isLoadingAllProducts = false;
      notifyListeners();
    }
  }

  // Load products by category
  Future<void> loadProductsByCategory(String categorySlug,
      {bool refresh = true}) async {
    if (refresh) {
      _isLoadingCategory = true;
      _categoryError = null;
      _categoryProducts = [];
      _categoryNextPage = null;
      _categoryPreviousPage = null;
      notifyListeners();
    }

    try {
      final result = await _productService.getProductsByCategory(categorySlug);

      if (result['success']) {
        if (refresh) {
          _categoryProducts = List<ProductModel>.from(result['data']);
        } else {
          _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        }

        _categoryTotalCount = result['count'] ?? 0;
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
        _isLoadingCategory = false;
        notifyListeners();
      } else {
        _categoryError = result['message'];
        _isLoadingCategory = false;
        notifyListeners();
      }
    } catch (e) {
      _categoryError = e.toString();
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  // Load more products for a category (pagination)
  Future<void> loadMoreCategoryProducts(String categorySlug) async {
    if (_categoryNextPage == null || _isLoadingCategory) return;

    _isLoadingCategory = true;
    notifyListeners();

    // Extract page number from next page URL
    Uri nextPageUri = Uri.parse(_categoryNextPage!);
    String? pageStr = nextPageUri.queryParameters['page'];
    int page = int.tryParse(pageStr ?? '1') ?? 1;

    try {
      final result = await _productService.getProductsByCategory(
        categorySlug,
        page: page,
      );

      if (result['success']) {
        _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
        _isLoadingCategory = false;
        notifyListeners();
      } else {
        _categoryError = result['message'];
        _isLoadingCategory = false;
        notifyListeners();
      }
    } catch (e) {
      _categoryError = e.toString();
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  // Load products by category tree with complete details
  Future<void> loadProductsByCategoryTree(String slug,
      {bool refresh = true}) async {
    if (refresh) {
      _isLoadingCategoryTree = true;
      _categoryTreeError = null;
      _categoryTreeProducts = [];
      _categoryTreeSubcategories = [];
      notifyListeners();
    }

    try {
      final categoryService = CategoryService();
      print('Fetching products for category: $slug');
      final result = await categoryService.getProductsByCategoryTree(slug);

      if (result['success']) {
        // Store subcategories
        if (result.containsKey('subcategories')) {
          _categoryTreeSubcategories =
              List<CategoryModel>.from(result['subcategories']);
        }

        // Get basic product data
        final List<Map<String, dynamic>> basicProducts =
            List<Map<String, dynamic>>.from(result['basicProducts'] ?? []);
        print('Fetched ${basicProducts.length} basic products');

        if (basicProducts.isEmpty) {
          _isLoadingCategoryTree = false;
          notifyListeners();
          return;
        }

        // Fetch full details for each product
        List<ProductModel> completeProducts = [];

        // Fetch each product's complete details
        for (var basicProduct in basicProducts) {
          try {
            final String slug = basicProduct['slug'];
            final detailResult = await _productService.getProductBySlug(slug);

            if (detailResult['success'] && detailResult['data'] != null) {
              completeProducts.add(detailResult['data']);
            } else {
              // If can't get detailed info, create simple product from basic info
              final basicInfo = basicProduct['basicInfo'];
              completeProducts.add(ProductModel(
                id: basicInfo['id'] ?? 0,
                name: basicInfo['name'] ?? '',
                slug: basicInfo['slug'] ?? '',
                description: basicInfo['description'] ?? '',
                shortDescription: basicInfo['short_description'] ?? '',
                category: basicInfo['category']?.toString() ?? '',
                brand: BrandModel.empty(),
                regularPrice: basicInfo['regular_price']?.toString() ?? '0.00',
                salePrice: basicInfo['sale_price']?.toString() ?? '0.00',
                costPrice: basicInfo['cost_price']?.toString() ?? '0.00',
                stockQuantity: basicInfo['stock_quantity'] ?? 0,
                isActive: basicInfo['is_active'] ?? false,
                isFeatured: basicInfo['is_featured'] ?? false,
                images: [],
                videos: [],
                attributes: [],
                reviews: [],
                variants: [],
                colorImages: {},
                availableColors: [],
                availableSizes: {},
                createdAt: basicInfo['created_at'] ?? '',
                updatedAt: basicInfo['updated_at'] ?? '',
              ));
            }
          } catch (e) {
            print(
                'Error fetching details for product ${basicProduct['slug']}: $e');
            // Continue with next product
          }
        }

        _categoryTreeProducts = completeProducts;
        _isLoadingCategoryTree = false;
        notifyListeners();
      } else {
        print('Error fetching products: ${result['message']}');
        _categoryTreeError = result['message'];
        _isLoadingCategoryTree = false;
        notifyListeners();
      }
    } catch (e) {
      print('Exception in loadProductsByCategoryTree: $e');
      _categoryTreeError = e.toString();
      _isLoadingCategoryTree = false;
      notifyListeners();
    }
  }

  // Breadcrumb management
  void setCategoryBreadcrumbs(List<CategoryModel> breadcrumbs) {
    _categoryBreadcrumbs = breadcrumbs;
    notifyListeners();
  }

  void addCategoryToBreadcrumbs(CategoryModel category) {
    if (!_categoryBreadcrumbs.any((item) => item.id == category.id)) {
      _categoryBreadcrumbs.add(category);
      notifyListeners();
    }
  }

  void setBreadcrumbsUpToIndex(int index) {
    if (index >= 0 && index < _categoryBreadcrumbs.length) {
      _categoryBreadcrumbs = _categoryBreadcrumbs.sublist(0, index + 1);
      notifyListeners();
    }
  }

  void clearBreadcrumbs() {
    _categoryBreadcrumbs = [];
    notifyListeners();
  }

  Future<void> loadCategoryWithBreadcrumbs(String slug) async {
    try {
      final categoryService = CategoryService();
      final result = await categoryService.getCategoryBySlug(slug);

      if (result['success'] && result['data'] != null) {
        // Check if there's breadcrumb info in the response
        if (result['data']['breadcrumb'] != null &&
            result['data']['breadcrumb'] is List) {
          final breadcrumbData = result['data']['breadcrumb'] as List;
          final breadcrumbs = breadcrumbData
              .map((item) => CategoryModel.fromJson(item))
              .toList();

          // Add current category if not already included
          final currentCategory = CategoryModel.fromJson(result['data']);
          if (!breadcrumbs.any((item) => item.id == currentCategory.id)) {
            breadcrumbs.add(currentCategory);
          }

          setCategoryBreadcrumbs(breadcrumbs);
        } else {
          // If no breadcrumb info, just use the current category
          final currentCategory = CategoryModel.fromJson(result['data']);
          setCategoryBreadcrumbs([currentCategory]);
        }
      }
    } catch (e) {
      print('Error loading category breadcrumbs: $e');
    }
  }

  // Updated method for lib/providers/product_provider.dart

// Enhanced toggle wishlist with API integration
  Future<void> toggleWishlist(
      ProductModel product, BuildContext context) async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    try {
      // Convert product ID to string to match API expectations
      final productId = product.id.toString();

      // Call the API through WishlistProvider
      final success = await wishlistProvider.toggleWishlist(
        productId,
        variantId: null, // Add variant support if needed
      );

      if (success) {
        // Update the local product state
        final updatedProduct =
            product.copyWith(isWishlisted: !product.isWishlisted);
        _updateProductInLists(updatedProduct);
        notifyListeners();

        // Show user feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updatedProduct.isWishlisted
                  ? '${product.name} added to wishlist'
                  : '${product.name} removed from wishlist'),
              backgroundColor: updatedProduct.isWishlisted
                  ? const Color(0xFFF96A4C)
                  : const Color(0xFFFF9800),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error toggling wishlist: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update wishlist. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper to update a product in all lists
  void _updateProductInLists(ProductModel updatedProduct) {
    // Update in featured products
    final featuredIndex =
        _featuredProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (featuredIndex >= 0) {
      _featuredProducts[featuredIndex] = updatedProduct;
    }

    // Update in new arrivals
    final newArrivalsIndex =
        _newArrivals.indexWhere((p) => p.id == updatedProduct.id);
    if (newArrivalsIndex >= 0) {
      _newArrivals[newArrivalsIndex] = updatedProduct;
    }

    // Update in best sellers
    final bestSellersIndex =
        _bestSellers.indexWhere((p) => p.id == updatedProduct.id);
    if (bestSellersIndex >= 0) {
      _bestSellers[bestSellersIndex] = updatedProduct;
    }

    // Update in category products
    final categoryIndex =
        _categoryProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (categoryIndex >= 0) {
      _categoryProducts[categoryIndex] = updatedProduct;
    }

    // Update in category tree products
    final categoryTreeIndex =
        _categoryTreeProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (categoryTreeIndex >= 0) {
      _categoryTreeProducts[categoryTreeIndex] = updatedProduct;
    }

    // Update in search results
    final searchIndex =
        _searchResults.indexWhere((p) => p.id == updatedProduct.id);
    if (searchIndex >= 0) {
      _searchResults[searchIndex] = updatedProduct;
    }

    // Update in all products
    final allProductsIndex =
        _allProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (allProductsIndex >= 0) {
      _allProducts[allProductsIndex] = updatedProduct;
    }

    // Update selected product if it's the same
    if (_selectedProduct != null && _selectedProduct!.id == updatedProduct.id) {
      _selectedProduct = updatedProduct;
    }
  }

  // Convert product to map for product card
  List<Map<String, dynamic>> convertProductsToCardMaps(
      List<ProductModel> products) {
    return products.map((product) => product.toCardMap()).toList();
  }

  // Clear errors
  void clearErrors() {
    _featuredError = null;
    _newArrivalsError = null;
    _bestSellersError = null;
    _searchError = null;
    _categoryError = null;
    _allProductsError = null;
    _productDetailsError = null;
    _variantsError = null;
    _categoryTreeError = null;
    notifyListeners();
  }

  // Clear selected product data
  void clearSelectedProduct() {
    _selectedProduct = null;
    _selectedProductVariants = null;
    _productDetailsError = null;
    _variantsError = null;
    notifyListeners();
  }
}
