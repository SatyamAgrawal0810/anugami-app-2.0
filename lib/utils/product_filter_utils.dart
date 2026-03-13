// lib/utils/product_filter_utils.dart

import 'package:anu_app/core/models/product_model.dart';
import 'package:anu_app/core/models/product_filter_model.dart';

class ProductFilterUtils {
  /// Filter products based on filter criteria
  static List<ProductModel> filterProducts(
    List<ProductModel> products,
    ProductFilterModel filters,
  ) {
    List<ProductModel> filtered = products;

    // Filter by price range
    filtered = filtered.where((product) {
      final price = double.tryParse(product.salePrice) ?? 0;
      return price >= filters.minPrice && price <= filters.maxPrice;
    }).toList();

    // Filter by brands
    if (filters.selectedBrands.isNotEmpty) {
      filtered = filtered.where((product) {
        return filters.selectedBrands.contains(product.brand.name);
      }).toList();
    }

    // Filter by minimum rating
    if (filters.minRating != null) {
      filtered = filtered.where((product) {
        final avgRating = _calculateAverageRating(product.reviews);
        return avgRating >= filters.minRating!;
      }).toList();
    }

    // Filter by minimum discount
    if (filters.minDiscount != null) {
      filtered = filtered.where((product) {
        final discount = _calculateDiscountPercentage(product);
        return discount >= filters.minDiscount!;
      }).toList();
    }

    // Filter by stock availability
    if (filters.inStockOnly == true) {
      filtered = filtered.where((product) {
        return product.stockQuantity > 0;
      }).toList();
    }

    // Filter by EMI availability
    // NOTE: You'll need to add 'emiAvailable' field to ProductModel
    // For now, we'll assume products above ₹5000 have EMI
    if (filters.emiAvailable == true) {
      filtered = filtered.where((product) {
        final price = double.tryParse(product.salePrice) ?? 0;
        return price >= 5000; // Products above ₹5000 eligible for EMI
      }).toList();
    }

    return filtered;
  }

  /// Sort products based on sort option
  static List<ProductModel> sortProducts(
    List<ProductModel> products,
    SortOption? sortBy,
  ) {
    if (sortBy == null) return products;

    List<ProductModel> sorted = List.from(products);

    switch (sortBy) {
      case SortOption.priceHighToLow:
        sorted.sort((a, b) {
          final priceA = double.tryParse(a.salePrice) ?? 0;
          final priceB = double.tryParse(b.salePrice) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;

      case SortOption.priceLowToHigh:
        sorted.sort((a, b) {
          final priceA = double.tryParse(a.salePrice) ?? 0;
          final priceB = double.tryParse(b.salePrice) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;

      case SortOption.newestFirst:
        sorted.sort((a, b) {
          return b.createdAt.compareTo(a.createdAt);
        });
        break;

      case SortOption.popularity:
        // Sort by number of reviews (you can change this logic)
        sorted.sort((a, b) {
          return b.reviews.length.compareTo(a.reviews.length);
        });
        break;

      case SortOption.rating:
        sorted.sort((a, b) {
          final ratingA = _calculateAverageRating(a.reviews);
          final ratingB = _calculateAverageRating(b.reviews);
          return ratingB.compareTo(ratingA);
        });
        break;

      case SortOption.discount:
        sorted.sort((a, b) {
          final discountA = _calculateDiscountPercentage(a);
          final discountB = _calculateDiscountPercentage(b);
          return discountB.compareTo(discountA);
        });
        break;
    }

    return sorted;
  }

  /// Apply both filters and sorting
  static List<ProductModel> applyFiltersAndSort(
    List<ProductModel> products,
    ProductFilterModel filters,
  ) {
    // First filter
    List<ProductModel> filtered = filterProducts(products, filters);

    // Then sort
    List<ProductModel> sorted = sortProducts(filtered, filters.sortBy);

    return sorted;
  }

  /// Get unique brands from products
  static List<String> getUniqueBrands(List<ProductModel> products) {
    final brands = products.map((p) => p.brand.name).toSet().toList();
    brands.sort();
    return brands;
  }

  /// Calculate average rating for a product
  static double _calculateAverageRating(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;

    final totalRating = reviews.fold<int>(
      0,
      (sum, review) => sum + review.rating,
    );

    return totalRating / reviews.length;
  }

  /// Calculate discount percentage
  static double _calculateDiscountPercentage(ProductModel product) {
    try {
      final regular = double.parse(product.regularPrice);
      final sale = double.parse(product.salePrice);

      if (regular <= 0 || sale >= regular) return 0.0;

      return ((regular - sale) / regular * 100);
    } catch (_) {
      return 0.0;
    }
  }

  /// Get price range from products
  static Map<String, double> getPriceRange(List<ProductModel> products) {
    if (products.isEmpty) {
      return {'min': 0.0, 'max': 100000.0};
    }

    double min = double.infinity;
    double max = 0.0;

    for (var product in products) {
      final price = double.tryParse(product.salePrice) ?? 0;
      if (price < min) min = price;
      if (price > max) max = price;
    }

    return {
      'min': min.floorToDouble(),
      'max': max.ceilToDouble(),
    };
  }
}
