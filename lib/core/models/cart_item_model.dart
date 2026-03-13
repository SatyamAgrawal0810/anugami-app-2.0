// lib/core/models/cart_item_model.dart

class CartItem {
  final int id;
  final String productId;
  final String? variantId;
  final int quantity;
  final double price;
  final double totalPrice;
  final ProductInfo? productInfo;
  final String addedAt;
  final String updatedAt;

  CartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.productInfo,
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      productInfo: json['product_info'] != null
          ? ProductInfo.fromJson(json['product_info'])
          : null,
      addedAt: json['added_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  CartItem copyWith({
    int? id,
    String? productId,
    String? variantId,
    int? quantity,
    double? price,
    double? totalPrice,
    ProductInfo? productInfo,
    String? addedAt,
    String? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      productInfo: productInfo ?? this.productInfo,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
      'added_at': addedAt,
      'updated_at': updatedAt,
      'product_info': productInfo?.toJson(),
    };
  }

  // Helper getters (Same as Wishlist)
  String get name => productInfo?.name ?? 'Product';
  String get imageUrl => productInfo?.image ?? '';
  bool get isAvailable => productInfo?.isAvailable ?? false;
  double get regularPrice => productInfo?.regularPrice ?? 0.0;
  double get salePrice => productInfo?.salePrice ?? 0.0;
  bool get hasDiscount => salePrice > 0 && salePrice < regularPrice;

  // 🔥 IMPORTANT - Now these will always work
  String get brandName => productInfo?.brandName ?? '';
  String get sellerUsername => productInfo?.sellerUsername ?? '';
  String get sellerBusinessName => productInfo?.sellerBusinessName ?? '';
}

class ProductInfo {
  final String id;
  final String name;
  final String slug;
  final String? brandName;
  final String? sellerUsername;
  final String? sellerBusinessName;
  final String? image;
  final double regularPrice;
  final double salePrice;
  final bool isAvailable;

  ProductInfo({
    required this.id,
    required this.name,
    required this.slug,
    this.brandName,
    this.sellerUsername,
    this.sellerBusinessName,
    this.image,
    required this.regularPrice,
    required this.salePrice,
    required this.isAvailable,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',

      // ✅ Flexible parsing (Wishlist jaisa hi)
      brandName: json['brand_name'] ?? json['brand']?['name'] ?? json['brand'],

      sellerUsername: json['seller_username'] ?? json['seller']?['username'],

      sellerBusinessName: json['seller_business_name'] ??
          json['seller']?['business_name'] ??
          json['seller_business'],

      image: json['image'],

      regularPrice:
          double.tryParse(json['regular_price']?.toString() ?? '0') ?? 0.0,

      salePrice: double.tryParse(json['sale_price']?.toString() ?? '0') ?? 0.0,

      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'brand_name': brandName,
      'seller_username': sellerUsername,
      'seller_business_name': sellerBusinessName,
      'image': image,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'is_available': isAvailable,
    };
  }

  double get displayPrice => salePrice > 0 ? salePrice : regularPrice;
  bool get hasDiscount => salePrice > 0 && salePrice < regularPrice;

  double get discountPercentage =>
      hasDiscount ? ((regularPrice - salePrice) / regularPrice * 100) : 0;

  String get formattedPrice => '₹${displayPrice.toStringAsFixed(0)}';
  String get formattedRegularPrice => '₹${regularPrice.toStringAsFixed(0)}';

  factory ProductInfo.empty() {
    return ProductInfo(
      id: '',
      name: 'Unknown Product',
      slug: '',
      brandName: null,
      sellerUsername: null,
      sellerBusinessName: null,
      image: null,
      regularPrice: 0.0,
      salePrice: 0.0,
      isAvailable: false,
    );
  }
}
