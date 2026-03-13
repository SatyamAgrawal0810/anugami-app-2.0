// lib/core/models/mobile_variant_model.dart
class MobileVariantSelector {
  final int productId;
  final String productName;
  final double basePrice;
  final List<MobileColorOption> colors;

  // ── Seller / Brand info (used to show same data for guest & logged-in) ──
  final String? brandName;
  final String? sellerBusinessName;
  final String? sellerUsername;

  MobileVariantSelector({
    required this.productId,
    required this.productName,
    required this.basePrice,
    required this.colors,
    this.brandName,
    this.sellerBusinessName,
    this.sellerUsername,
  });

  factory MobileVariantSelector.fromJson(Map<String, dynamic> json) {
    return MobileVariantSelector(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      colors: (json['colors'] as List?)
              ?.map((color) => MobileColorOption.fromJson(color))
              .toList() ??
          [],
      // ── Pull seller/brand from API response ──
      brandName: json['brand_name'],
      sellerBusinessName: json['seller_business_name'],
      sellerUsername: json['seller_username'],
    );
  }

  // Get all available sizes across all colors
  List<String> getAllAvailableSizes() {
    final Set<String> sizeSet = {};
    for (final color in colors) {
      for (final size in color.availableSizes) {
        sizeSet.add(size.sizeValue);
      }
    }
    return sizeSet.toList()..sort();
  }

  // Get price range
  String getPriceRange() {
    if (colors.isEmpty) return '₹${basePrice.toStringAsFixed(2)}';

    double minPrice = double.infinity;
    double maxPrice = 0;

    for (final color in colors) {
      for (final size in color.availableSizes) {
        if (size.price < minPrice) minPrice = size.price;
        if (size.price > maxPrice) maxPrice = size.price;
      }
    }

    if (minPrice == maxPrice) {
      return '₹${minPrice.toStringAsFixed(2)}';
    } else {
      return '₹${minPrice.toStringAsFixed(2)} - ₹${maxPrice.toStringAsFixed(2)}';
    }
  }
}

class MobileColorOption {
  final String colorValue;
  final String colorDisplay;
  final String? imageUrl;
  final List<MobileSizeOption> availableSizes;
  final bool hasStock;

  MobileColorOption({
    required this.colorValue,
    required this.colorDisplay,
    this.imageUrl,
    required this.availableSizes,
    required this.hasStock,
  });

  factory MobileColorOption.fromJson(Map<String, dynamic> json) {
    return MobileColorOption(
      colorValue: json['color_value'] ?? '',
      colorDisplay: json['color_display'] ?? '',
      imageUrl: json['image_url'],
      availableSizes: (json['available_sizes'] as List?)
              ?.map((size) => MobileSizeOption.fromJson(size))
              .toList() ??
          [],
      hasStock: json['has_stock'] ?? false,
    );
  }

  List<MobileSizeOption> getInStockSizes() {
    return availableSizes.where((size) => size.inStock).toList();
  }

  String getPriceRange() {
    if (availableSizes.isEmpty) return '';

    double minPrice = availableSizes.first.price;
    double maxPrice = availableSizes.first.price;

    for (final size in availableSizes) {
      if (size.price < minPrice) minPrice = size.price;
      if (size.price > maxPrice) maxPrice = size.price;
    }

    if (minPrice == maxPrice) {
      return '₹${minPrice.toStringAsFixed(2)}';
    } else {
      return '₹${minPrice.toStringAsFixed(2)} - ₹${maxPrice.toStringAsFixed(2)}';
    }
  }
}

class MobileSizeOption {
  final String sizeValue;
  final String sizeDisplay;
  final int variantId;
  final double price;
  final int stock;
  final bool inStock;

  MobileSizeOption({
    required this.sizeValue,
    required this.sizeDisplay,
    required this.variantId,
    required this.price,
    required this.stock,
    required this.inStock,
  });

  factory MobileSizeOption.fromJson(Map<String, dynamic> json) {
    return MobileSizeOption(
      sizeValue: json['size_value'] ?? '',
      sizeDisplay: json['size_display'] ?? '',
      variantId: json['variant_id'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      inStock: json['in_stock'] ?? false,
    );
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get stockStatus {
    if (!inStock) return 'Out of Stock';
    if (stock <= 5) return 'Only $stock left';
    return 'In Stock';
  }
}
