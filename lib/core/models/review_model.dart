class ReviewModel {
  final int id;
  final int product;
  final int user;
  final int rating;
  final String title; // Make sure this field exists
  final String comment;
  final bool isVerified;
  final bool isApproved;
  final String createdAt;
  final String updatedAt;

  ReviewModel({
    required this.id,
    required this.product,
    required this.user,
    required this.rating,
    required this.title, // Add this if missing
    required this.comment,
    required this.isVerified,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      user: json['user'] ?? 0,
      rating: json['rating'] ?? 0,
      title: json['title'] ?? '', // Add this if missing
      comment: json['comment'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isApproved: json['is_approved'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
