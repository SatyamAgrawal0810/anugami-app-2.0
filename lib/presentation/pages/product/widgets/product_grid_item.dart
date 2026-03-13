// lib/presentation/pages/product/widgets/product_grid_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/utils/app_notifications.dart';
import '../../../../core/models/product_model.dart';
import '../../../../providers/wishlist_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class ProductGridItem extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;

  const ProductGridItem({
    Key? key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
  }) : super(key: key);

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem>
    with TickerProviderStateMixin {
  bool _isAddingToCart = false;
  late AnimationController _cartAnimationController;

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    super.dispose();
  }

  bool _isAddToCartEnabled() => widget.product.stockQuantity > 0;

  Future<void> _addToCart() async {
    if (!_isAddToCartEnabled() || _isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      await cartProvider.addItem(
        widget.product,
        quantity: 1,
        price: double.tryParse(widget.product.salePrice) ??
            double.tryParse(widget.product.regularPrice) ??
            0.0,
      );

      if (mounted) {
        AppNotifications.showError(context, 'Success message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _incrementQuantity(CartProvider cartProvider) async {
    final productId = widget.product.id.toString();
    try {
      final cartItem = cartProvider.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );
      await cartProvider.incrementQuantity(cartItem.id);
    } catch (e) {
      debugPrint('❌ Increment quantity error: $e');
    }
  }

  Future<void> _decrementQuantity(CartProvider cartProvider) async {
    final productId = widget.product.id.toString();
    try {
      final cartItem = cartProvider.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );
      await cartProvider.decrementQuantity(cartItem.id);
    } catch (e) {
      debugPrint('❌ Decrement quantity error: $e');
    }
  }

  /// Inline +/- stepper widget
  Widget _buildQuantityStepper(CartProvider cartProvider, int currentQty) {
    return SizedBox(
      width: double.infinity,
      height: 26,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // — button
            InkWell(
              onTap: () => _decrementQuantity(cartProvider),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: const SizedBox(
                width: 26,
                height: 26,
                child: Icon(Icons.remove, color: Colors.white, size: 13),
              ),
            ),

            // count
            Text(
              '$currentQty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),

            // + button
            InkWell(
              onTap: () => _incrementQuantity(cartProvider),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: const SizedBox(
                width: 26,
                height: 26,
                child: Icon(Icons.add, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= IMAGE =================
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[100],
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, color: Colors.grey),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),

                  // ❤️ Wishlist
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, _) {
                        final isWishlisted = wishlistProvider
                            .isInWishlist(product.id.toString());

                        return InkWell(
                          onTap: wishlistProvider.isLoading
                              ? null
                              : () async {
                                  if (widget.onWishlistTap != null) {
                                    widget.onWishlistTap!();
                                  } else {
                                    await wishlistProvider
                                        .toggleWishlist(product.id.toString());
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: wishlistProvider.isLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: LogoLoader(),
                                  )
                                : Icon(
                                    isWishlisted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: isWishlisted
                                        ? const Color(0xFFFF4947)
                                        : Colors.grey,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        product.formattedSalePrice,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (product.discountPercentage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                product.formattedRegularPrice,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.discountPercentage.replaceAll('%', '')}% OFF',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        Icon(
                          product.stockQuantity > 0
                              ? Icons.check_circle
                              : Icons.error,
                          size: 9,
                          color: product.stockQuantity > 0
                              ? const Color(0xFFF96A4C)
                              : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            product.stockQuantity > 0
                                ? 'In Stock'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 8,
                              color: product.stockQuantity > 0
                                  ? const Color(0xFFF96A4C)
                                  : Colors.red,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ✅ Add to Cart / Quantity Stepper / Out of Stock
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        final productId = product.id.toString();
                        final inCart = cartProvider.isProductInCart(productId);
                        final qty = cartProvider.getProductQuantity(productId);

                        if (!_isAddToCartEnabled()) {
                          return Container(
                            width: double.infinity,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          );
                        }

                        if (inCart && qty > 0) {
                          return _buildQuantityStepper(cartProvider, qty);
                        }

                        // Add to Cart button
                        return SizedBox(
                          width: double.infinity,
                          height: 26,
                          child: InkWell(
                            onTap: _isAddingToCart ? null : _addToCart,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isAddingToCart
                                    ? LinearGradient(colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ])
                                    : AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: _isAddingToCart
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: LogoLoader(),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Colors.white,
                                            size: 11,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
