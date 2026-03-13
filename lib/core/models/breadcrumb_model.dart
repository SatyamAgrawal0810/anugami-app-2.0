// lib/core/models/breadcrumb_model.dart
class BreadcrumbModel {
  final String id;
  final String name;
  final String slug;

  BreadcrumbModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory BreadcrumbModel.fromJson(Map<String, dynamic> json) {
    return BreadcrumbModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
