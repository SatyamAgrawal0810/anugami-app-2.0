// lib/core/models/product_model.dart
int toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

double toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool toBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String category;
  final BrandModel brand;
  final String regularPrice;
  final String salePrice;
  final String costPrice;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final List<ImageModel> images;
  final List<VideoModel> videos;
  final List<AttributeModel> attributes;
  final List<ReviewModel> reviews;
  final List<VariantModel> variants;
  final Map<String, List<ImageModel>> colorImages;
  final List<ColorOption> availableColors;
  final Map<String, List<SizeOption>> availableSizes;
  final String createdAt;
  final String updatedAt;
  final SellerModel? sellerInfo;
  final bool isWishlisted;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.category,
    required this.brand,
    required this.regularPrice,
    required this.salePrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.isActive,
    required this.isFeatured,
    required this.images,
    required this.videos,
    required this.attributes,
    required this.reviews,
    required this.variants,
    required this.colorImages,
    required this.availableColors,
    required this.availableSizes,
    required this.createdAt,
    required this.updatedAt,
    this.sellerInfo,
    this.isWishlisted = false,
  });

  // ✅ FIXED: copyWith now correctly uses class properties
  ProductModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? shortDescription,
    String? category,
    BrandModel? brand,
    String? regularPrice,
    String? salePrice,
    String? costPrice,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    List<ImageModel>? images,
    List<VideoModel>? videos,
    List<AttributeModel>? attributes,
    List<ReviewModel>? reviews,
    List<VariantModel>? variants,
    Map<String, List<ImageModel>>? colorImages,
    List<ColorOption>? availableColors,
    Map<String, List<SizeOption>>? availableSizes,
    String? createdAt,
    String? updatedAt,
    SellerModel? sellerInfo,
    bool? isWishlisted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      attributes: attributes ?? this.attributes,
      reviews: reviews ?? this.reviews,
      variants: variants ?? this.variants,
      colorImages: colorImages ?? this.colorImages,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerInfo: sellerInfo ?? this.sellerInfo,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  String get primaryImageUrl {
    try {
      final primaryImage = images.firstWhere((img) => img.isPrimary);
      return primaryImage.imageUrl;
    } catch (_) {
      return images.isNotEmpty ? images.first.imageUrl : '';
    }
  }

  Map<String, dynamic> toCardMap() {
    return {
      'id': id.toString(),
      'name': name,
      'price': formattedSalePrice,
      'image': primaryImageUrl,
      'discount': discountPercentage,
      'inStock': stockQuantity > 0,
    };
  }

  List<ImageModel> getImagesForColor(String? selectedColor) {
    if (selectedColor != null && colorImages.containsKey(selectedColor)) {
      return colorImages[selectedColor]!;
    }
    return images;
  }

  String get discountPercentage {
    try {
      final regular = double.parse(regularPrice);
      final sale = double.parse(salePrice);
      if (regular <= 0 || sale >= regular) return '';
      final discount = ((regular - sale) / regular * 100).round();
      return '$discount%';
    } catch (_) {
      return '';
    }
  }

  String get formattedRegularPrice => '₹$regularPrice';
  String get formattedSalePrice => '₹$salePrice';

  // ✅ FIXED: Using toInt(), toDouble(), toBool() everywhere
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      List<ImageModel> imagesList = [];
      if (json['images'] != null && json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((img) => ImageModel.fromJson(img))
            .toList();
      }

      List<VideoModel> videosList = [];
      if (json['videos'] != null && json['videos'] is List) {
        videosList = (json['videos'] as List)
            .map((video) => VideoModel.fromJson(video))
            .toList();
      }

      List<AttributeModel> attributesList = [];
      if (json['attributes'] != null && json['attributes'] is List) {
        attributesList = (json['attributes'] as List)
            .map((attr) => AttributeModel.fromJson(attr))
            .toList();
      }

      List<ReviewModel> reviewsList = [];
      if (json['reviews'] != null && json['reviews'] is List) {
        reviewsList = (json['reviews'] as List)
            .map((review) => ReviewModel.fromJson(review))
            .toList();
      }

      List<VariantModel> variantsList = [];
      if (json['variants'] != null && json['variants'] is List) {
        variantsList = (json['variants'] as List)
            .map((variant) => VariantModel.fromJson(variant))
            .toList();
      }

      Map<String, List<ImageModel>> colorImagesMap = {};
      if (json['color_images'] != null && json['color_images'] is Map) {
        final colorImagesJson = json['color_images'] as Map<String, dynamic>;
        colorImagesJson.forEach((color, images) {
          if (images is List) {
            colorImagesMap[color] =
                images.map((img) => ImageModel.fromJson(img)).toList();
          }
        });
      }

      List<ColorOption> availableColorsList = [];
      if (json['available_colors'] != null &&
          json['available_colors'] is List) {
        availableColorsList = (json['available_colors'] as List)
            .map((color) => ColorOption.fromJson(color))
            .toList();
      }

      Map<String, List<SizeOption>> availableSizesMap = {};
      if (json['available_sizes'] != null && json['available_sizes'] is Map) {
        final sizesJson = json['available_sizes'] as Map<String, dynamic>;
        sizesJson.forEach((color, sizes) {
          if (sizes is List) {
            availableSizesMap[color] =
                sizes.map((size) => SizeOption.fromJson(size)).toList();
          }
        });
      }

      BrandModel brandModel = BrandModel.empty();

      if (json['brand'] != null && json['brand'] is Map<String, dynamic>) {
        final brandJson = json['brand'] as Map<String, dynamic>;
        final sellerJson = json['seller_info'] as Map<String, dynamic>?;

        brandModel = BrandModel(
          id: brandJson['id']?.toString() ?? '',
          name: brandJson['name']?.toString() ?? '',
          slug: brandJson['slug']?.toString() ?? '',
          description: brandJson['description']?.toString() ?? '',
          logo: brandJson['logo']?.toString() ?? '',
          sellerId: sellerJson?['id']?.toString() ?? '',
          sellerName: sellerJson?['business_name']?.toString() ?? '',
          isVerified: sellerJson?['is_email_verified'] == true,
          productCount: 0, // provider set karega
        );
      }

      SellerModel? sellerModel;
      if (json['seller_info'] != null) {
        sellerModel = SellerModel.fromJson(json['seller_info']);
      }

      return ProductModel(
        id: toInt(json['id']),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        shortDescription: json['short_description']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        brand: brandModel,
        regularPrice: json['regular_price']?.toString() ?? '0.00',
        salePrice: json['sale_price']?.toString() ?? '0.00',
        costPrice: json['cost_price']?.toString() ?? '0.00',
        stockQuantity: toInt(json['stock_quantity']),
        isActive: toBool(json['is_active']),
        isFeatured: toBool(json['is_featured']),
        images: imagesList,
        videos: videosList,
        attributes: attributesList,
        reviews: reviewsList,
        variants: variantsList,
        colorImages: colorImagesMap,
        availableColors: availableColorsList,
        availableSizes: availableSizesMap,
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
        sellerInfo: sellerModel,
        isWishlisted: toBool(json['is_wishlisted']),
      );
    } catch (e, stackTrace) {
      print('Error creating ProductModel from JSON: $e');
      print('Stack trace: $stackTrace');
      return ProductModel.empty();
    }
  }

  factory ProductModel.empty() {
    return ProductModel(
      id: 0,
      name: '',
      slug: '',
      description: '',
      shortDescription: '',
      category: '',
      brand: BrandModel.empty(),
      regularPrice: '0.00',
      salePrice: '0.00',
      costPrice: '0.00',
      stockQuantity: 0,
      isActive: false,
      isFeatured: false,
      images: [],
      videos: [],
      attributes: [],
      reviews: [],
      variants: [],
      colorImages: {},
      availableColors: [],
      availableSizes: {},
      createdAt: '',
      updatedAt: '',
    );
  }
}

// ✅ FIXED: All nested models now use helper functions
class VariantModel {
  final int id;
  final String sku;
  final int stockQuantity;
  final double price;
  final bool isActive;
  final List<VariantAttributeModel> attributes;
  final String createdAt;
  final String updatedAt;

  VariantModel({
    required this.id,
    required this.sku,
    required this.stockQuantity,
    required this.price,
    required this.isActive,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: toInt(json['id']),
      sku: json['sku']?.toString() ?? '',
      stockQuantity: toInt(json['stock_quantity']),
      price: toDouble(json['price']),
      isActive: toBool(json['is_active']),
      attributes: (json['attributes'] as List?)
              ?.map((attr) => VariantAttributeModel.fromJson(attr))
              .toList() ??
          [],
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class VariantAttributeModel {
  final int id;
  final String attributeType;
  final String value;
  final String displayValue;

  VariantAttributeModel({
    required this.id,
    required this.attributeType,
    required this.value,
    required this.displayValue,
  });

  factory VariantAttributeModel.fromJson(Map<String, dynamic> json) {
    return VariantAttributeModel(
      id: toInt(json['id']),
      attributeType: json['attribute_type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      displayValue: json['display_value']?.toString() ?? '',
    );
  }
}

class AttributeModel {
  final int id;
  final int product;
  final String attributeType;
  final String name;
  final String value;
  final String displayValue;
  final String type;
  final bool isVisible;
  final bool isVariation;
  final bool isSearchable;
  final int sortOrder;
  final List<List<String>> availableValues;

  AttributeModel({
    required this.id,
    required this.product,
    required this.attributeType,
    required this.name,
    required this.value,
    required this.displayValue,
    required this.type,
    required this.isVisible,
    required this.isVariation,
    required this.isSearchable,
    required this.sortOrder,
    required this.availableValues,
  });

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      id: toInt(json['id']),
      product: toInt(json['product']),
      attributeType: json['attribute_type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      displayValue: json['display_value']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isVisible: toBool(json['is_visible']),
      isVariation: toBool(json['is_variation']),
      isSearchable: toBool(json['is_searchable']),
      sortOrder: toInt(json['sort_order']),
      availableValues: (json['available_values'] as List?)
              ?.map((item) => List<String>.from(item))
              .toList() ??
          [],
    );
  }
}

class VideoModel {
  final int id;
  final int product;
  final String videoUrl;
  final String title;
  final String description;
  final int sortOrder;
  final String createdAt;

  VideoModel({
    required this.id,
    required this.product,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: toInt(json['id']),
      product: toInt(json['product']),
      videoUrl: json['video_url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sortOrder: toInt(json['sort_order']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String customerName;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: toInt(json['id']),
      rating: toInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ColorOption {
  final String value;
  final String displayValue;
  final bool hasImage;

  ColorOption({
    required this.value,
    required this.displayValue,
    required this.hasImage,
  });

  factory ColorOption.fromJson(Map<String, dynamic> json) {
    return ColorOption(
      value: json['value']?.toString() ?? '',
      displayValue: json['display_value']?.toString() ?? '',
      hasImage: toBool(json['has_image']),
    );
  }
}

class SizeOption {
  final String sizeValue;
  final String sizeDisplay;
  final int stock;
  final int variantId;
  final double price;

  SizeOption({
    required this.sizeValue,
    required this.sizeDisplay,
    required this.stock,
    required this.variantId,
    required this.price,
  });

  factory SizeOption.fromJson(Map<String, dynamic> json) {
    return SizeOption(
      sizeValue: json['size_value']?.toString() ?? '',
      sizeDisplay: json['size_display']?.toString() ?? '',
      stock: toInt(json['stock']),
      variantId: toInt(json['variant_id']),
      price: toDouble(json['price']),
    );
  }

  bool get inStock => stock > 0;
}

class ImageModel {
  final int id;
  final int product;
  final String imageUrl;
  final String altText;
  final bool isPrimary;
  final int sortOrder;
  final String createdAt;
  final String storagePath;
  final String? colorAttribute;

  ImageModel({
    required this.id,
    required this.product,
    required this.imageUrl,
    required this.altText,
    required this.isPrimary,
    required this.sortOrder,
    required this.createdAt,
    required this.storagePath,
    this.colorAttribute,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: toInt(json['id']),
      product: toInt(json['product']),
      imageUrl: json['image_url']?.toString() ?? '',
      altText: json['alt_text']?.toString() ?? '',
      isPrimary: toBool(json['is_primary']),
      sortOrder: toInt(json['sort_order']),
      createdAt: json['created_at']?.toString() ?? '',
      storagePath: json['storage_path']?.toString() ?? '',
      colorAttribute: json['color_attribute']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'image_url': imageUrl,
      'alt_text': altText,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'storage_path': storagePath,
      'color_attribute': colorAttribute,
    };
  }
}

class BrandModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String logo;
  final int productCount;
  final String sellerId;
  final String sellerName;
  final bool isVerified;

  BrandModel({
    this.id = '',
    this.name = '',
    this.slug = '',
    this.description = '',
    this.logo = '',
    this.productCount = 0,
    this.sellerId = '',
    this.sellerName = '',
    this.isVerified = false,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      productCount: toInt(json['product_count']),
      sellerId: json['seller_id']?.toString() ?? '',
      sellerName: json['seller_name']?.toString() ?? '',
      isVerified: toBool(json['is_verified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'logo': logo,
      'product_count': productCount,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'is_verified': isVerified,
    };
  }

  factory BrandModel.empty() {
    return BrandModel();
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? logo,
    int? productCount,
    String? sellerId,
    String? sellerName,
    bool? isVerified,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      productCount: productCount ?? this.productCount,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class SellerModel {
  final int id;
  final String userName;
  final String email;
  final String businessName;
  final String businessAddress;
  final String? logo;
  final bool isEmailVerified;

  SellerModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    this.logo,
    required this.isEmailVerified,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: toInt(json['id']),
      userName: json['user_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      businessAddress: json['business_address']?.toString() ?? '',
      logo: json['logo']?.toString(),
      isEmailVerified: toBool(json['is_email_verified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email': email,
      'business_name': businessName,
      'business_address': businessAddress,
      'logo': logo,
      'is_email_verified': isEmailVerified,
    };
  }
}
