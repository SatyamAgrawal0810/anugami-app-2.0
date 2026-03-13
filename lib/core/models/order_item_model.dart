// lib/core/models/order_item_model.dart
class OrderItemModel {
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double price;
  final String? variantInfo; // e.g., "Color: Red, Size: M"

  OrderItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.price,
    this.variantInfo,
  });
}