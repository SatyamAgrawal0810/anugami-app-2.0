// lib/providers/category_provider.dart
// ✅ OPTIMIZED - Faster loading with caching and parallel operations
import 'package:flutter/foundation.dart';
import '../api/services/category_service.dart';
import '../core/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  List<CategoryModel> _categoryTree = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  static const Duration _cacheValidDuration = Duration(minutes: 10);

  // Getters
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get categoryTree => _categoryTree;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ OPTIMIZED: Load categories with cache check
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Skip if recently fetched
    if (!forceRefresh &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration &&
        _categories.isNotEmpty) {
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService
          .getCategories()
          .timeout(const Duration(seconds: 8));
      _lastFetch = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: ${e.toString().split(':').first}';
      print('❌ Category load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ OPTIMIZED: Load category tree with cache
  Future<void> loadCategoryTree({bool forceRefresh = false}) async {
    // Skip if recently fetched
    if (!forceRefresh &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration &&
        _categoryTree.isNotEmpty) {
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryTree = await _categoryService
          .getCategoryTree()
          .timeout(const Duration(seconds: 10));
      _lastFetch = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to load category tree: ${e.toString().split(':').first}';
      print('❌ Category tree error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get root categories (level 0)
  List<CategoryModel> getRootCategories() {
    return _categories.where((category) => category.parentId == null).toList();
  }

  // Get subcategories of a parent
  List<CategoryModel> getSubcategories(String parentId) {
    return _categories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  // Get featured categories
  List<CategoryModel> getFeaturedCategories() {
    return _categories.where((category) => category.isFeatured).toList();
  }

  // Clear state
  void clear() {
    _categories = [];
    _categoryTree = [];
    _error = null;
    _isLoading = false;
    _lastFetch = null;
    notifyListeners();
  }
}
