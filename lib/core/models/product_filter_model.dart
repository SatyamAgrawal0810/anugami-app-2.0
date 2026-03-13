// lib/core/models/product_filter_model.dart

class ProductFilterModel {
  // Price filter
  double minPrice;
  double maxPrice;

  // Brand filter
  List<String> selectedBrands;

  // Rating filter
  double? minRating;

  // Discount filter
  double? minDiscount;

  // Stock filter
  bool? inStockOnly;

  // EMI filter (if applicable)
  bool? emiAvailable;

  // Sort options
  SortOption? sortBy;

  ProductFilterModel({
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.selectedBrands = const [],
    this.minRating,
    this.minDiscount,
    this.inStockOnly,
    this.emiAvailable,
    this.sortBy,
  });

  // Check if any filter is active
  bool get hasActiveFilters {
    return selectedBrands.isNotEmpty ||
        minRating != null ||
        minDiscount != null ||
        inStockOnly == true ||
        emiAvailable == true ||
        minPrice > 0 ||
        maxPrice < 100000;
  }

  // Reset all filters
  void reset() {
    minPrice = 0;
    maxPrice = 100000;
    selectedBrands = [];
    minRating = null;
    minDiscount = null;
    inStockOnly = null;
    emiAvailable = null;
    sortBy = null;
  }

  // Copy with method
  ProductFilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedBrands,
    double? minRating,
    double? minDiscount,
    bool? inStockOnly,
    bool? emiAvailable,
    SortOption? sortBy,
  }) {
    return ProductFilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minRating: minRating ?? this.minRating,
      minDiscount: minDiscount ?? this.minDiscount,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      emiAvailable: emiAvailable ?? this.emiAvailable,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SortOption {
  priceHighToLow,
  priceLowToHigh,
  newestFirst,
  popularity,
  rating,
  discount,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.popularity:
        return 'Popularity';
      case SortOption.rating:
        return 'Rating';
      case SortOption.discount:
        return 'Discount';
    }
  }
}
