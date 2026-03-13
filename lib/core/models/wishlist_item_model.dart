// lib/core/models/wishlist_item_model.dart
class WishlistItemModel {
  final int id;
  final String productId;
  final String? variantId;
  final ProductInfo productInfo;
  final String addedAt;

  WishlistItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productInfo,
    required this.addedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      productInfo: ProductInfo.fromJson(json['product_info'] ?? {}),
      addedAt: json['added_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'product_info': productInfo.toJson(),
      'added_at': addedAt,
    };
  }

  // Create an empty wishlist item for fallback
  factory WishlistItemModel.empty() {
    return WishlistItemModel(
      id: 0,
      productId: '',
      variantId: null,
      productInfo: ProductInfo.empty(),
      addedAt: '',
    );
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String? brandName;
  final String? sellerUsername;
  final String? sellerBusinessName;
  final String slug;
  final String? image;
  final double? regularPrice;
  final double? salePrice;
  final bool isAvailable;

  ProductInfo({
    required this.id,
    required this.name,
    this.brandName,
    this.sellerUsername,
    this.sellerBusinessName,
    required this.slug,
    this.image,
    this.regularPrice,
    this.salePrice,
    required this.isAvailable,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Product not found',
      brandName: json['brand_name'],
      sellerUsername: json['seller_username'],
      sellerBusinessName: json['seller_business_name'],
      slug: json['slug'] ?? '',
      image: json['image'],
      regularPrice: json['regular_price'] != null
          ? (json['regular_price'] as num).toDouble()
          : null,
      salePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : null,
      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'seller_username': sellerUsername,
      'seller_business_name': sellerBusinessName,
      'slug': slug,
      'image': image,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'is_available': isAvailable,
    };
  }

  // Helper methods
  double get displayPrice {
    if (salePrice != null && salePrice! > 0) return salePrice!;
    if (regularPrice != null && regularPrice! > 0) return regularPrice!;
    return 0.0;
  }

  bool get hasDiscount =>
      salePrice != null &&
      regularPrice != null &&
      salePrice! > 0 &&
      salePrice! < regularPrice!;

  double get discountPercentage =>
      hasDiscount ? ((regularPrice! - salePrice!) / regularPrice! * 100) : 0;

  String get formattedPrice => displayPrice > 0
      ? '₹${displayPrice.toStringAsFixed(0)}'
      : 'Price not available';

  String get formattedRegularPrice => regularPrice != null && regularPrice! > 0
      ? '₹${regularPrice!.toStringAsFixed(0)}'
      : '';

  bool get hasValidPrice => displayPrice > 0;

  // Create an empty product info for fallback
  factory ProductInfo.empty() {
    return ProductInfo(
      id: '',
      name: 'Unknown Product',
      slug: '',
      image: null,
      regularPrice: null,
      salePrice: null,
      isAvailable: false,
    );
  }
}
