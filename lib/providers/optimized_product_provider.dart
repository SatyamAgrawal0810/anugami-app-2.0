// lib/providers/optimized_product_provider.dart
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import '../api/services/product_service.dart';
import '../api/services/category_service.dart';
import '../core/models/product_model.dart';
import '../core/models/mobile_variant_model.dart';
import '../core/models/category_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/services/api_config.dart';
import 'package:anu_app/utils/app_notifications.dart';

class OptimizedProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

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

  ProductModel? _selectedProduct;
  MobileVariantSelector? _selectedProductVariants;
  bool _isLoadingProductDetails = false;
  bool _isLoadingVariants = false;
  String? _productDetailsError;
  String? _variantsError;

  bool _isLoadingFeatured = false;
  bool _isLoadingNewArrivals = false;
  bool _isLoadingBestSellers = false;
  bool _isLoadingSearch = false;
  bool _isLoadingCategory = false;
  bool _isLoadingAllProducts = false;
  bool _isLoadingCategoryTree = false;
  bool _isLoadingBrand = false;

  String? _featuredError;
  String? _newArrivalsError;
  String? _bestSellersError;
  String? _searchError;
  String? _categoryError;
  String? _allProductsError;
  String? _categoryTreeError;

  int _categoryTotalCount = 0;
  String? _categoryNextPage;
  String? _categoryPreviousPage;
  Timer? _searchDebounce;

  DateTime? _featuredLastFetch;
  DateTime? _newArrivalsLastFetch;
  DateTime? _bestSellersLastFetch;
  DateTime? _categoryLastFetch;
  String? _lastCategorySlug;

  static const Duration _cacheValidDuration = Duration(minutes: 5);

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

  ProductModel? get selectedProduct => _selectedProduct;
  MobileVariantSelector? get selectedProductVariants =>
      _selectedProductVariants;
  bool get isLoadingProductDetails => _isLoadingProductDetails;
  bool get isLoadingVariants => _isLoadingVariants;
  String? get productDetailsError => _productDetailsError;
  String? get variantsError => _variantsError;

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingNewArrivals => _isLoadingNewArrivals;
  bool get isLoadingBestSellers => _isLoadingBestSellers;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingCategory => _isLoadingCategory;
  bool get isLoadingAllProducts => _isLoadingAllProducts;
  bool get isLoadingCategoryTree => _isLoadingCategoryTree;
  bool get isLoadingBrand => _isLoadingBrand;

  String? get featuredError => _featuredError;
  String? get newArrivalsError => _newArrivalsError;
  String? get bestSellersError => _bestSellersError;
  String? get searchError => _searchError;
  String? get categoryError => _categoryError;
  String? get allProductsError => _allProductsError;
  String? get categoryTreeError => _categoryTreeError;

  int get categoryTotalCount => _categoryTotalCount;
  bool get hasMoreCategoryProducts => _categoryNextPage != null;

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Request timeout. Please check your internet connection.';
    } else if (error is SocketException) {
      return 'No internet connection. Please try again.';
    } else if (error.toString().contains('Failed host lookup')) {
      return 'Cannot reach server. Check your connection.';
    } else {
      return 'Failed to load. Please try again.';
    }
  }

  // ✅ FIXED: Brand products - slug se ID fetch, phir us ID se products
  Future<void> loadProductsByBrand(String brandSlug,
      {int retryCount = 0}) async {
    const maxRetries = 2;

    if (_isLoadingBrand && retryCount == 0) return;

    if (retryCount == 0) {
      _isLoadingBrand = true;
      _brandProducts = [];
      notifyListeners();
    }

    try {
      print('🔄 Step 1: Brand info fetch kar rahe hain slug: $brandSlug');

      // Step 1: Brand slug se brand ID fetch karo
      final brandResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/brands/brands/?slug=$brandSlug'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (brandResponse.statusCode != 200) {
        print('❌ Brand fetch failed: ${brandResponse.statusCode}');
        _brandProducts = [];
        _isLoadingBrand = false;
        notifyListeners();
        return;
      }

      final brandData = json.decode(brandResponse.body);
      final List brandList =
          brandData is List ? brandData : (brandData['results'] ?? []);

      if (brandList.isEmpty) {
        print('❌ Koi brand nahi mila slug ke liye: $brandSlug');
        _brandProducts = [];
        _isLoadingBrand = false;
        notifyListeners();
        return;
      }

      final brand = brandList.first;
      final brandId = brand['id']?.toString() ?? '';
      final brandName = brand['name']?.toString() ?? brandSlug;
      print('✅ Brand mila: $brandName (ID: $brandId)');

      // Step 2: Brand ID se sirf us brand ke products fetch karo
      List<ProductModel> allProducts = [];

      print('🔄 Step 2: Brand ID $brandId ke products fetch kar rahe hain');

      // Pehle no_page=true try karo (saare ek saath)
      final productsResponse = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/products/products/?brand=$brandId&no_page=true'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (productsResponse.statusCode == 200) {
        final productsData = json.decode(productsResponse.body);
        final List results = productsData is List
            ? productsData
            : (productsData['results'] ?? []);

        allProducts = results.map((e) => ProductModel.fromJson(e)).toList();
        print(
            '✅ ${allProducts.length} products load hue brand: $brandName ke liye');
      } else {
        // Fallback: page by page fetch karo
        print('⚠️ no_page kaam nahi kiya, paginated try kar rahe hain...');
        String? pageUrl =
            '${ApiConfig.baseUrl}/api/v1/products/products/?brand=$brandId';

        while (pageUrl != null) {
          final res = await http.get(
            Uri.parse(pageUrl),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200) {
            final d = json.decode(res.body);
            final List results = d['results'] ?? [];
            allProducts.addAll(results.map((e) => ProductModel.fromJson(e)));
            final next = d['next'];
            pageUrl = (next != null && next.toString().isNotEmpty)
                ? next.toString()
                : null;
          } else {
            break;
          }
        }
        print('✅ Paginated: ${allProducts.length} products load hue');
      }

      _brandProducts = allProducts;
    } on TimeoutException catch (e) {
      print('⏱️ Brand products timeout: $e');
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadProductsByBrand(brandSlug, retryCount: retryCount + 1);
      }
      _brandProducts = [];
    } on SocketException catch (e) {
      print('📡 Brand products network error: $e');
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadProductsByBrand(brandSlug, retryCount: retryCount + 1);
      }
      _brandProducts = [];
    } catch (e) {
      print('❌ Brand products error: $e');
      _brandProducts = [];
    } finally {
      _isLoadingBrand = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedProducts(
      {bool forceRefresh = false, int retryCount = 0}) async {
    const maxRetries = 2;

    if (!forceRefresh &&
        _featuredLastFetch != null &&
        DateTime.now().difference(_featuredLastFetch!) < _cacheValidDuration &&
        _featuredProducts.isNotEmpty) {
      print('📦 Cached featured products use kar rahe hain');
      return;
    }

    if (_isLoadingFeatured && retryCount == 0) return;

    if (retryCount == 0) {
      _isLoadingFeatured = true;
      _featuredError = null;
      notifyListeners();
    }

    try {
      print(
          '🔄 Featured products load ho rahe hain... (Attempt ${retryCount + 1})');
      final result = await _productService
          .getFeaturedProducts()
          .timeout(const Duration(seconds: 30));

      if (result['success']) {
        _featuredProducts = List<ProductModel>.from(result['data']);
        _featuredLastFetch = DateTime.now();
        _featuredError = null;
        print('✅ ${_featuredProducts.length} featured products load hue');
      } else {
        _featuredError = result['message'];
      }
    } on TimeoutException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadFeaturedProducts(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _featuredError = _getErrorMessage(e);
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadFeaturedProducts(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _featuredError = _getErrorMessage(e);
    } catch (e) {
      _featuredError = _getErrorMessage(e);
      print('❌ Featured products error: $e');
    } finally {
      if (retryCount == 0 || retryCount >= maxRetries) {
        _isLoadingFeatured = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNewArrivals(
      {bool forceRefresh = false, int retryCount = 0}) async {
    const maxRetries = 2;

    if (!forceRefresh &&
        _newArrivalsLastFetch != null &&
        DateTime.now().difference(_newArrivalsLastFetch!) <
            _cacheValidDuration &&
        _newArrivals.isNotEmpty) {
      return;
    }

    if (_isLoadingNewArrivals && retryCount == 0) return;

    if (retryCount == 0) {
      _isLoadingNewArrivals = true;
      _newArrivalsError = null;
      notifyListeners();
    }

    try {
      final result = await _productService
          .getNewArrivals()
          .timeout(const Duration(seconds: 30));

      if (result['success']) {
        _newArrivals = List<ProductModel>.from(result['data']);
        _newArrivalsLastFetch = DateTime.now();
        _newArrivalsError = null;
      } else {
        _newArrivalsError = result['message'];
      }
    } on TimeoutException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadNewArrivals(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _newArrivalsError = _getErrorMessage(e);
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadNewArrivals(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _newArrivalsError = _getErrorMessage(e);
    } catch (e) {
      _newArrivalsError = _getErrorMessage(e);
      print('❌ New arrivals error: $e');
    } finally {
      if (retryCount == 0 || retryCount >= maxRetries) {
        _isLoadingNewArrivals = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBestSellers(
      {bool forceRefresh = false, int retryCount = 0}) async {
    const maxRetries = 2;

    if (!forceRefresh &&
        _bestSellersLastFetch != null &&
        DateTime.now().difference(_bestSellersLastFetch!) <
            _cacheValidDuration &&
        _bestSellers.isNotEmpty) {
      return;
    }

    if (_isLoadingBestSellers && retryCount == 0) return;

    if (retryCount == 0) {
      _isLoadingBestSellers = true;
      _bestSellersError = null;
      notifyListeners();
    }

    try {
      final result = await _productService
          .getBestSellers()
          .timeout(const Duration(seconds: 30));

      if (result['success']) {
        _bestSellers = List<ProductModel>.from(result['data']);
        _bestSellersLastFetch = DateTime.now();
        _bestSellersError = null;
      } else {
        _bestSellersError = result['message'];
      }
    } on TimeoutException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadBestSellers(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _bestSellersError = _getErrorMessage(e);
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return loadBestSellers(
            forceRefresh: forceRefresh, retryCount: retryCount + 1);
      }
      _bestSellersError = _getErrorMessage(e);
    } catch (e) {
      _bestSellersError = _getErrorMessage(e);
      print('❌ Best sellers error: $e');
    } finally {
      if (retryCount == 0 || retryCount >= maxRetries) {
        _isLoadingBestSellers = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadProductDetailsWithVariants(String slug) async {
    if (_isLoadingProductDetails || _isLoadingVariants) return;

    _isLoadingProductDetails = true;
    _isLoadingVariants = true;
    _productDetailsError = null;
    _variantsError = null;
    _selectedProduct = null;
    _selectedProductVariants = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _productService
            .getProductBySlug(slug)
            .timeout(const Duration(seconds: 8)),
        _productService
            .getMobileVariantSelector(slug)
            .timeout(const Duration(seconds: 5)),
      ]);

      final productResult = results[0];
      final variantResult = results[1];

      if (productResult['success']) {
        _selectedProduct = productResult['data'];
      } else {
        _productDetailsError = productResult['message'];
      }

      if (variantResult['success']) {
        _selectedProductVariants = variantResult['data'];
      } else {
        _variantsError = variantResult['message'];
      }
    } catch (e) {
      _productDetailsError = 'Load failed: ${e.toString().split(':').first}';
      _variantsError = _productDetailsError;
      print('❌ Product details error: $e');
    } finally {
      _isLoadingProductDetails = false;
      _isLoadingVariants = false;
      notifyListeners();
    }
  }

  Future<void> loadProductDetails(String slug) async {
    if (_isLoadingProductDetails) return;

    _isLoadingProductDetails = true;
    _productDetailsError = null;
    notifyListeners();

    try {
      final result = await _productService
          .getProductBySlug(slug)
          .timeout(const Duration(seconds: 8));

      if (result['success']) {
        _selectedProduct = result['data'];
      } else {
        _productDetailsError = result['message'];
      }
    } catch (e) {
      _productDetailsError = 'Load failed: ${e.toString().split(':').first}';
      print('❌ Product details error: $e');
    } finally {
      _isLoadingProductDetails = false;
      notifyListeners();
    }
  }

  Future<void> loadProductVariants(String slug) async {
    if (_isLoadingVariants) return;

    _isLoadingVariants = true;
    _variantsError = null;
    notifyListeners();

    try {
      final result = await _productService
          .getMobileVariantSelector(slug)
          .timeout(const Duration(seconds: 5));

      if (result['success']) {
        _selectedProductVariants = result['data'];
      } else {
        _variantsError = result['message'];
      }
    } catch (e) {
      _variantsError = 'Load failed: ${e.toString().split(':').first}';
      print('❌ Variants error: $e');
    } finally {
      _isLoadingVariants = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query, {int retryCount = 0}) async {
    const maxRetries = 2;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    if (_isLoadingSearch && retryCount == 0) return;

    if (retryCount == 0) {
      _isLoadingSearch = true;
      _searchError = null;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/products/search/')
            .replace(queryParameters: {'q': query.trim()}),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<ProductModel> products = [];

        if (data is List) {
          products = data.map((json) => ProductModel.fromJson(json)).toList();
        } else if (data is Map) {
          if (data.containsKey('results')) {
            products = (data['results'] as List)
                .map((json) => ProductModel.fromJson(json))
                .toList();
          } else if (data.containsKey('data')) {
            products = (data['data'] as List)
                .map((json) => ProductModel.fromJson(json))
                .toList();
          }
        }

        _searchResults = products;
        _searchError = null;
      } else if (response.statusCode == 404) {
        _searchResults = [];
        _searchError = null;
      } else {
        _searchResults = [];
        _searchError = 'Failed to search products. Please try again.';
      }
    } on TimeoutException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return searchProducts(query, retryCount: retryCount + 1);
      }
      _searchResults = [];
      _searchError = _getErrorMessage(e);
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 2));
        return searchProducts(query, retryCount: retryCount + 1);
      }
      _searchResults = [];
      _searchError = _getErrorMessage(e);
    } catch (e) {
      _searchResults = [];
      _searchError = _getErrorMessage(e);
    } finally {
      if (retryCount == 0 || retryCount >= maxRetries) {
        _isLoadingSearch = false;
        notifyListeners();
      }
    }
  }

  void searchProductsDebounced(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      searchProducts(query);
    });
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    _searchDebounce?.cancel();
    notifyListeners();
  }

  Future<void> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? ordering,
    bool refresh = true,
  }) async {
    if (_isLoadingAllProducts && refresh) return;

    if (refresh) {
      _isLoadingAllProducts = true;
      _allProductsError = null;
      _allProducts = [];
      notifyListeners();
    }

    try {
      final result = await _productService
          .getProducts(
            page: page,
            limit: limit,
            category: category,
            search: search,
            ordering: ordering,
          )
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        if (refresh) {
          _allProducts = List<ProductModel>.from(result['data']);
        } else {
          _allProducts.addAll(List<ProductModel>.from(result['data']));
        }
      } else {
        _allProductsError = result['message'];
      }
    } catch (e) {
      _allProductsError = 'Load failed: ${e.toString().split(':').first}';
      print('❌ Get products error: $e');
    } finally {
      _isLoadingAllProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadProductsByCategory(String categorySlug,
      {bool refresh = true}) async {
    if (!refresh &&
        _lastCategorySlug == categorySlug &&
        _categoryLastFetch != null &&
        DateTime.now().difference(_categoryLastFetch!) < _cacheValidDuration &&
        _categoryProducts.isNotEmpty) {
      return;
    }

    if (_isLoadingCategory && refresh) return;

    if (refresh) {
      _isLoadingCategory = true;
      _categoryError = null;
      _categoryProducts = [];
      _categoryNextPage = null;
      _categoryPreviousPage = null;
      notifyListeners();
    }

    try {
      final result = await _productService
          .getProductsByCategory(categorySlug)
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        if (refresh) {
          _categoryProducts = List<ProductModel>.from(result['data']);
        } else {
          _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        }

        _categoryTotalCount = result['count'] ?? 0;
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
        _lastCategorySlug = categorySlug;
        _categoryLastFetch = DateTime.now();
      } else {
        _categoryError = result['message'];
      }
    } catch (e) {
      _categoryError = 'Load failed: ${e.toString().split(':').first}';
      print('❌ Category products error: $e');
    } finally {
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCategoryProducts(String categorySlug) async {
    if (_categoryNextPage == null || _isLoadingCategory) return;

    _isLoadingCategory = true;
    notifyListeners();

    Uri nextPageUri = Uri.parse(_categoryNextPage!);
    String? pageStr = nextPageUri.queryParameters['page'];
    int page = int.tryParse(pageStr ?? '1') ?? 1;

    try {
      final result = await _productService
          .getProductsByCategory(categorySlug, page: page)
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        _categoryProducts.addAll(List<ProductModel>.from(result['data']));
        _categoryNextPage = result['next'];
        _categoryPreviousPage = result['previous'];
      } else {
        _categoryError = result['message'];
      }
    } catch (e) {
      _categoryError = 'Load more failed: ${e.toString().split(':').first}';
      print('❌ Load more error: $e');
    } finally {
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  Future<void> loadProductsByCategoryTree(String slug,
      {bool refresh = true}) async {
    if (_isLoadingCategoryTree && refresh) return;

    if (refresh) {
      _isLoadingCategoryTree = true;
      _categoryTreeError = null;
      _categoryTreeProducts = [];
      _categoryTreeSubcategories = [];
      notifyListeners();
    }

    try {
      final categoryService = CategoryService();
      final result = await categoryService
          .getProductsByCategoryTree(slug)
          .timeout(const Duration(seconds: 12));

      if (result['success']) {
        if (result.containsKey('subcategories')) {
          _categoryTreeSubcategories =
              List<CategoryModel>.from(result['subcategories']);
        }

        final List<Map<String, dynamic>> basicProducts =
            List<Map<String, dynamic>>.from(result['basicProducts'] ?? []);

        if (basicProducts.isEmpty) {
          _isLoadingCategoryTree = false;
          notifyListeners();
          return;
        }

        List<ProductModel> completeProducts = [];
        const chunkSize = 5;

        for (int i = 0; i < basicProducts.length; i += chunkSize) {
          final chunk = basicProducts.skip(i).take(chunkSize).toList();

          final chunkResults = await Future.wait(
            chunk.map((basicProduct) async {
              try {
                final String productSlug = basicProduct['slug'];
                final detailResult = await _productService
                    .getProductBySlug(productSlug)
                    .timeout(const Duration(seconds: 5));

                if (detailResult['success'] && detailResult['data'] != null) {
                  return detailResult['data'] as ProductModel;
                }
              } catch (e) {
                print('⚠️ Product fetch timeout: ${basicProduct['slug']}');
              }

              final basicInfo = basicProduct['basicInfo'];
              return ProductModel(
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
              );
            }),
            eagerError: false,
          );

          completeProducts.addAll(chunkResults.whereType<ProductModel>());

          if (i == 0) {
            _categoryTreeProducts = completeProducts;
            _isLoadingCategoryTree = false;
            notifyListeners();
          }
        }

        _categoryTreeProducts = completeProducts;
      } else {
        _categoryTreeError = result['message'];
      }
    } catch (e) {
      _categoryTreeError = 'Load failed: ${e.toString().split(':').first}';
      print('❌ Category tree error: $e');
    } finally {
      _isLoadingCategoryTree = false;
      notifyListeners();
    }
  }

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
      final result = await categoryService
          .getCategoryBySlug(slug)
          .timeout(const Duration(seconds: 8));

      if (result['success'] && result['data'] != null) {
        if (result['data']['breadcrumb'] != null &&
            result['data']['breadcrumb'] is List) {
          final breadcrumbData = result['data']['breadcrumb'] as List;
          final breadcrumbs = breadcrumbData
              .map((item) => CategoryModel.fromJson(item))
              .toList();
          final currentCategory = CategoryModel.fromJson(result['data']);
          if (!breadcrumbs.any((item) => item.id == currentCategory.id)) {
            breadcrumbs.add(currentCategory);
          }
          setCategoryBreadcrumbs(breadcrumbs);
        } else {
          final currentCategory = CategoryModel.fromJson(result['data']);
          setCategoryBreadcrumbs([currentCategory]);
        }
      }
    } catch (e) {
      print('❌ Breadcrumb load error: $e');
    }
  }

  Future<void> toggleWishlist(
      ProductModel product, BuildContext context) async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    try {
      final productId = product.id.toString();
      final success =
          await wishlistProvider.toggleWishlist(productId, variantId: null);

      if (success) {
        final updatedProduct =
            product.copyWith(isWishlisted: !product.isWishlisted);
        _updateProductInLists(updatedProduct);
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updatedProduct.isWishlisted
                  ? '${product.name} added to wishlist'
                  : '${product.name} removed from wishlist'),
              backgroundColor: updatedProduct.isWishlisted
                  ? const Color(0xFFF96A4C)
                  : Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('❌ Wishlist toggle error: $e');
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

  void _updateProductInLists(ProductModel updatedProduct) {
    _updateListIfContains(_featuredProducts, updatedProduct);
    _updateListIfContains(_newArrivals, updatedProduct);
    _updateListIfContains(_bestSellers, updatedProduct);
    _updateListIfContains(_categoryProducts, updatedProduct);
    _updateListIfContains(_categoryTreeProducts, updatedProduct);
    _updateListIfContains(_searchResults, updatedProduct);
    _updateListIfContains(_allProducts, updatedProduct);

    if (_selectedProduct != null && _selectedProduct!.id == updatedProduct.id) {
      _selectedProduct = updatedProduct;
    }
  }

  void _updateListIfContains(
      List<ProductModel> list, ProductModel updatedProduct) {
    final index = list.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) list[index] = updatedProduct;
  }

  List<Map<String, dynamic>> convertProductsToCardMaps(
      List<ProductModel> products) {
    return products.map((product) => product.toCardMap()).toList();
  }

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

  void clearSelectedProduct() {
    _selectedProduct = null;
    _selectedProductVariants = null;
    _productDetailsError = null;
    _variantsError = null;
    notifyListeners();
  }
}
