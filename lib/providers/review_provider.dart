import 'package:flutter/foundation.dart';
import '../api/services/review_service.dart';
import '../core/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;
  String? _currentProductSlug;
  DateTime? _lastFetch;

  static const Duration _cacheValidDuration = Duration(minutes: 5);

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ OPTIMIZED: Get reviews with cache check
  Future<void> getProductReviews(String productSlug,
      {bool forceRefresh = false}) async {
    // Skip if recently fetched for same product
    if (!forceRefresh &&
        _currentProductSlug == productSlug &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentProductSlug = productSlug;
    notifyListeners();

    try {
      final result = await _reviewService
          .getProductReviews(productSlug)
          .timeout(const Duration(seconds: 8));

      if (result['success']) {
        _reviews = result['data'];
        _lastFetch = DateTime.now();
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Failed to load reviews: ${e.toString().split(':').first}';
      print('❌ Review fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ OPTIMIZED: Create review with timeout
  Future<bool> createReview({
    required String productSlug,
    required int rating,
    required String title,
    required String comment,
  }) async {
    if (_isLoading) return false;

    try {
      final result = await _reviewService
          .createReview(
            productSlug: productSlug,
            rating: rating,
            title: title,
            comment: comment,
          )
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        final newReview = result['data'];
        _reviews.insert(0, newReview); // Add to top
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to create review: ${e.toString().split(':').first}';
      print('❌ Create review error: $e');
      notifyListeners();
      return false;
    }
  }

  // ✅ OPTIMIZED: Update review with timeout
  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    if (_isLoading) return false;

    try {
      final result = await _reviewService
          .updateReview(
            reviewId: reviewId,
            rating: rating,
            title: title,
            comment: comment,
          )
          .timeout(const Duration(seconds: 10));

      if (result['success']) {
        final updatedReview = result['data'];
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = updatedReview;
          notifyListeners();
        }
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update review: ${e.toString().split(':').first}';
      print('❌ Update review error: $e');
      notifyListeners();
      return false;
    }
  }

  // ✅ OPTIMIZED: Delete review with optimistic update
  Future<bool> deleteReview(int reviewId) async {
    if (_isLoading) return false;

    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return false;

    final removedReview = _reviews[index];

    // Optimistic UI update
    _reviews.removeAt(index);
    notifyListeners();

    try {
      final result = await _reviewService
          .deleteReview(reviewId)
          .timeout(const Duration(seconds: 8));

      if (result['success']) {
        return true;
      } else {
        // rollback
        _reviews.insert(index, removedReview);
        notifyListeners();
        _error = result['message'];
        return false;
      }
    } catch (e) {
      // rollback
      _reviews.insert(index, removedReview);
      notifyListeners();
      _error = 'Failed to delete review';
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _reviews = [];
    _error = null;
    _isLoading = false;
    _currentProductSlug = null;
    _lastFetch = null;
    notifyListeners();
  }
}
