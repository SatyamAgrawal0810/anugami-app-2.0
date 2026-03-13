// lib/core/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final ParentDetails? parentDetails;
  final bool isActive;
  final bool isFeatured;
  final bool showInMenu;
  final int productCount;
  final int childrenCount;
  final int menuOrder;
  final int displayOrder;
  final String? imageUrl;
  final String? iconUrl;
  final String? bannerUrl;
  final String? description;
  final String? shortDescription;
  final String? customUrl;
  final String? redirectUrl;
  final String? createdAt;
  final String? updatedAt;
  final List<CategoryModel> children;
  final int level;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.parentDetails,
    required this.isActive,
    this.isFeatured = false,
    this.showInMenu = false,
    this.productCount = 0,
    this.childrenCount = 0,
    this.menuOrder = 0,
    this.displayOrder = 0,
    this.imageUrl,
    this.iconUrl,
    this.bannerUrl,
    this.description,
    this.shortDescription,
    this.customUrl,
    this.redirectUrl,
    this.createdAt,
    this.updatedAt,
    this.children = const [],
    this.level = 0,
  });

  // Parse a flat category list
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      showInMenu: json['show_in_menu'] ?? false,
      productCount: json['product_count'] ?? 0,
      childrenCount: json['subcategory_count'] ?? 0,
      menuOrder: json['menu_order'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
      imageUrl: json['image_url'],
      iconUrl: json['icon_url'],
      bannerUrl: json['banner_url'],
    );
  }

  // Parse from the tree structure API
  factory CategoryModel.fromTreeJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      showInMenu: json['show_in_menu'] ?? false,
      productCount: json['product_count'] ?? 0,
      childrenCount: json['subcategory_count'] ?? 0,
      menuOrder: json['menu_order'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
      imageUrl: json['image_url'],
      iconUrl: json['icon_url'],
      bannerUrl: json['banner_url'],
      children: (json['children'] as List?)
              ?.map((child) => CategoryModel.fromTreeJson(child))
              .toList() ??
          [],
    );
  }

  // Parse from detailed category response
  factory CategoryModel.fromDetailJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      showInMenu: json['show_in_menu'] ?? false,
      productCount: json['product_count'] ?? 0,
      childrenCount: json['subcategory_count'] ?? 0,
      menuOrder: json['menu_order'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
      imageUrl: json['image_url'],
      iconUrl: json['icon_url'],
      bannerUrl: json['banner_url'],
      description: json['description'],
      shortDescription: json['short_description'],
      customUrl: json['custom_url'],
      redirectUrl: json['redirect_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      children: (json['children'] as List?)
              ?.map((child) => CategoryModel.fromDetailJson(child))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent_id': parentId,
      'parent_details': parentDetails?.toJson(),
      'is_active': isActive,
      'is_featured': isFeatured,
      'show_in_menu': showInMenu,
      'product_count': productCount,
      'children_count': childrenCount,
      'menu_order': menuOrder,
      'display_order': displayOrder,
      'image_url': imageUrl,
      'icon_url': iconUrl,
      'banner_url': bannerUrl,
      'description': description,
      'short_description': shortDescription,
      'custom_url': customUrl,
      'redirect_url': redirectUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'children': children.map((child) => child.toJson()).toList(),
      'level': level,
    };
  }
}

class ParentDetails {
  final String id;
  final String name;
  final String slug;

  ParentDetails({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ParentDetails.fromJson(Map<String, dynamic> json) {
    return ParentDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}